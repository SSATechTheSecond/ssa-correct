function ConvertTo-SsaBytesFromTotalItemSize {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    $TotalItemSize
  )

  if ($null -eq $TotalItemSize) { return $null }

  # Often formats like: "1.234 GB (1,234,567,890 bytes)"
  $m = [regex]::Match($TotalItemSize.ToString(), '\((?<bytes>[0-9,]+) bytes\)')
  if ($m.Success) {
    return [int64]($m.Groups['bytes'].Value -replace ',', '')
  }

  return $null
}

function Get-SsaMailboxSizeReport {
  [CmdletBinding()]
  param(
    [int]$Top = 0
  )

  if (-not (Test-SsaCommand -Name 'Get-ExoMailboxStatistics')) {
    throw 'Get-ExoMailboxStatistics not found. Ensure ExchangeOnlineManagement is installed and Connect-SsaM365 completed successfully.'
  }

  # Fast path for Top N:
  # - Get primary mailbox stats in one call
  # - Pick Top N
  # - Only then fetch archive stats for those Top N
  if ($Top -gt 0) {
    Write-Host ''
    Write-Host "Collecting mailbox statistics to find Top $Top... (this can take a bit on large tenants)"

    try {
      if (-not (Test-SsaCommand -Name 'Get-ExoMailbox')) {
        throw 'Get-ExoMailbox not found. Ensure ExchangeOnlineManagement is installed and Connect-SsaM365 completed successfully.'
      }

      # Get-ExoMailboxStatistics is a single-object cmdlet (no -ResultSize). Use mailbox enumeration + pipeline instead.
      $allStats = @(
        Get-ExoMailbox -ResultSize Unlimited -PropertySets Minimum | Get-ExoMailboxStatistics
      )

      if ($allStats.Count -eq 0) {
        Write-Warning 'No mailbox statistics were returned. Verify Exchange Online connection/permissions.'
        Write-SsaLog -Level 'WARN' -Message 'Mailbox size report returned 0 stats in fast path'
        return @()
      }

      $rows = foreach ($s in $allStats) {
        $id = $null

        # Get-ExoMailboxStatistics output varies by module version; try a few common identity fields.
        foreach ($p in @(
          'UserPrincipalName',
          'PrimarySmtpAddress',
          'MailboxOwnerUPN',
          'MailboxOwnerId',
          'ExternalDirectoryObjectId',
          'MailboxGuid',
          'ExchangeGuid',
          'Guid',
          'Identity'
        )) {
          if ($s.PSObject.Properties.Match($p).Count -gt 0 -and $s.$p) {
            $id = "$($s.$p)".Trim()
            if (-not [string]::IsNullOrWhiteSpace($id)) { break }
          }
        }

        if ([string]::IsNullOrWhiteSpace($id)) { continue }

        $primaryBytes = ConvertTo-SsaBytesFromTotalItemSize -TotalItemSize $s.TotalItemSize

        [pscustomobject][ordered]@{
          DisplayName = $s.DisplayName
          UserPrincipalName = $id
          PrimarySize = $s.TotalItemSize
          PrimaryBytes = $primaryBytes
          ArchiveSize = $null
          ArchiveBytes = $null
        }
      }

      $rows = @($rows)

      if ($rows.Count -eq 0 -and $allStats.Count -gt 0) {
        $sample = $allStats | Select-Object -First 1
        $props = @($sample.PSObject.Properties.Name) -join ','
        Write-Warning 'Mailbox statistics were returned, but no mailbox identifier could be extracted from the objects. See log for details.'
        Write-SsaLog -Level 'WARN' -Message 'Mailbox size report produced 0 rows after parsing stats (fast path)' -Data @{ StatCount = $allStats.Count; SampleType = $sample.GetType().FullName; SampleIdentity = "$($sample.Identity)"; SampleProperties = $props }
        return @()
      }

      $rows = @(
        $rows |
          Sort-Object -Property @{ Expression = 'PrimaryBytes'; Descending = $true } |
          Select-Object -First $Top
      )

      # Archive stats only for top N (to avoid the app "freezing" for a long time)
      $i = 0
      foreach ($row in $rows) {
        $i++
        $pct = [int](($i / [math]::Max(1, $rows.Count)) * 100)
        Write-Progress -Activity 'Fetching archive mailbox sizes (Top list only)' -Status "$i/$($rows.Count) $($row.UserPrincipalName)" -PercentComplete $pct

        try {
          $a = Get-ExoMailboxStatistics -Identity $row.UserPrincipalName -Archive
          $row.ArchiveSize = $a.TotalItemSize
          $row.ArchiveBytes = ConvertTo-SsaBytesFromTotalItemSize -TotalItemSize $a.TotalItemSize
        } catch {
          # No archive, or insufficient rights; ignore.
        }
      }
      Write-Progress -Activity 'Fetching archive mailbox sizes (Top list only)' -Completed

      return $rows
    } catch {
      Write-Warning "Fast path failed; falling back to per-mailbox stats. Error: $($_.Exception.Message)"
      # fall through to slow path
    }
  }

  # Slow path (all mailboxes): per-mailbox statistics calls.
  if (-not (Test-SsaCommand -Name 'Get-ExoMailbox')) {
    throw 'Get-ExoMailbox not found. Ensure ExchangeOnlineManagement is installed and Connect-SsaM365 completed successfully.'
  }

  Write-Host ''
  Write-Host 'Collecting mailbox statistics for ALL mailboxes... (can take a long time)'

  $mailboxes = @(Get-ExoMailbox -ResultSize Unlimited -PropertySets Minimum)
  $total = $mailboxes.Count

  if ($total -eq 0) {
    Write-Warning 'No mailboxes were returned. Verify Exchange Online connection/permissions.'
    Write-SsaLog -Level 'WARN' -Message 'Mailbox size report returned 0 mailboxes'
    return @()
  }
  $i = 0

  $rows = foreach ($mbx in $mailboxes) {
    $i++
    $pct = [int](($i / [math]::Max(1, $total)) * 100)
    Write-Progress -Activity 'Mailbox size report' -Status "$i/$total $($mbx.UserPrincipalName)" -PercentComplete $pct

    $stats = $null
    $archiveStats = $null

    try {
      $stats = Get-ExoMailboxStatistics -Identity $mbx.UserPrincipalName
    } catch {
      $stats = $null
    }

    try {
      $archiveStats = Get-ExoMailboxStatistics -Identity $mbx.UserPrincipalName -Archive
    } catch {
      $archiveStats = $null
    }

    $primaryBytes = if ($stats) { ConvertTo-SsaBytesFromTotalItemSize -TotalItemSize $stats.TotalItemSize } else { $null }
    $archiveBytes = if ($archiveStats) { ConvertTo-SsaBytesFromTotalItemSize -TotalItemSize $archiveStats.TotalItemSize } else { $null }

    [pscustomobject]@{
      DisplayName = $mbx.DisplayName
      UserPrincipalName = $mbx.UserPrincipalName
      PrimarySize = if ($stats) { $stats.TotalItemSize } else { $null }
      PrimaryBytes = $primaryBytes
      ArchiveSize = if ($archiveStats) { $archiveStats.TotalItemSize } else { $null }
      ArchiveBytes = $archiveBytes
    }
  }

  Write-Progress -Activity 'Mailbox size report' -Completed

  $rows = @(
    $rows | Sort-Object -Property @{ Expression = 'PrimaryBytes'; Descending = $true }
  )
  return $rows
}
