function Invoke-SsaPstExportSearchJob {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$MailboxUpn,

    [Parameter(Mandatory)]
    [ValidateSet('Primary','Archive')]
    [string]$ExportType,

    [string]$CaseName = 'SSA Exchange Exports',

    [int]$PollSeconds = 15
  )

  if (-not (Test-SsaCommand -Name 'New-ComplianceSearch')) {
    throw 'Compliance cmdlets not found (New-ComplianceSearch). Ensure Connect-IPPSSession succeeded.'
  }

  # Compliance searches require valid Exchange locations (typically UPN or primary SMTP), not arbitrary GUIDs.
  # Accept a mailbox identifier and best-effort resolve it to a usable UPN/SMTP for ExchangeLocation.
  $resolvedLocation = $MailboxUpn
  if ($MailboxUpn -notmatch '@') {
    if (Test-SsaCommand -Name 'Get-ExoMailbox') {
      try {
        $mbx = Get-ExoMailbox -Identity $MailboxUpn -PropertySets Minimum -ErrorAction Stop
        $resolvedLocation = if ($mbx.UserPrincipalName) { $mbx.UserPrincipalName } elseif ($mbx.PrimarySmtpAddress) { "$($mbx.PrimarySmtpAddress)" } else { $MailboxUpn }
        if ($resolvedLocation -ne $MailboxUpn) {
          Write-Host "Resolved mailbox identifier '$MailboxUpn' -> '$resolvedLocation'"
          Write-SsaLog -Level 'INFO' -Message 'Resolved mailbox identifier for compliance search' -Data @{ Input = $MailboxUpn; Resolved = $resolvedLocation }
        }
      } catch {
        # We'll keep the original value and let the compliance cmdlet throw a precise error.
        Write-SsaLog -Level 'WARN' -Message 'Failed to resolve mailbox identifier via Get-ExoMailbox; using input as ExchangeLocation' -Data (Get-SsaErrorData -ErrorRecord $_)
      }
    }
  }

  $job = New-SsaJobFolder -JobName "PST-$ExportType" -Target $resolvedLocation

  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $safeUpn = ($MailboxUpn -replace '[^a-zA-Z0-9\-_.@]+', '_') -replace '@','_'
  $searchName = "SSA_${ExportType}_${safeUpn}_${stamp}"

  # Best-effort create case
  if ((Test-SsaCommand -Name 'Get-ComplianceCase') -and (Test-SsaCommand -Name 'New-ComplianceCase')) {
    try {
      $existing = $null
      try { $existing = Get-ComplianceCase -Identity $CaseName -ErrorAction Stop } catch { $existing = $null }
      if (-not $existing) {
        Write-Host "Creating compliance case: $CaseName"
        New-ComplianceCase -Name $CaseName | Out-Null
      }
    } catch {
      Write-SsaLog -Level 'ERROR' -Message 'Compliance case creation failed' -Data (Get-SsaErrorData -ErrorRecord $_)
      throw
    }
  } else {
    Write-Warning 'Compliance case cmdlets not available; will still try to create the search with a -Case parameter if supported.'
  }

  Write-Host "Creating compliance search '$searchName' for mailbox '$resolvedLocation' ($ExportType)..."

  # Note: archive vs primary is typically chosen in the Purview export step. We still create distinct searches for clarity.
  $newParams = @{
    Name = $searchName
    ExchangeLocation = $resolvedLocation
  }

  # If -Case is supported, use it.
  try {
    $cmd = Get-Command -Name New-ComplianceSearch -ErrorAction Stop | Select-Object -First 1
    if ($cmd.Parameters.ContainsKey('Case')) {
      $newParams.Case = $CaseName
    }

    New-ComplianceSearch @newParams | Out-Null
  } catch {
    $d = Get-SsaErrorData -ErrorRecord $_
    $d.Params = $newParams
    Write-SsaLog -Level 'ERROR' -Message 'New-ComplianceSearch failed' -Data $d
    throw
  }

  Write-Host 'Starting search...'
  try {
    Start-ComplianceSearch -Identity $searchName | Out-Null
  } catch {
    Write-SsaLog -Level 'ERROR' -Message 'Start-ComplianceSearch failed' -Data (Get-SsaErrorData -ErrorRecord $_)
    throw
  }

  while ($true) {
    Start-Sleep -Seconds $PollSeconds

    try {
      $s = Get-ComplianceSearch -Identity $searchName
    } catch {
      Write-SsaLog -Level 'ERROR' -Message 'Get-ComplianceSearch failed' -Data (Get-SsaErrorData -ErrorRecord $_)
      throw
    }

    Write-Host "Status: $($s.Status)"

    if ($s.Status -match 'Completed|PartiallySucceeded|Failed|Stopped') {
      break
    }
  }

  $details = [ordered]@{
    MailboxUpn = $resolvedLocation
    ExportType = $ExportType
    CaseName = $CaseName
    SearchName = $searchName
    Status = $s.Status
    CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    Note = 'PowerShell export actions (New-ComplianceSearchAction -Export) were retired May 26, 2025; use the Purview portal to export PST for this search.'
  }

  ($details | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 -Path (Join-Path $job 'job-details.json')

  $instructions = @(
    'PST download instructions (manual portal step):',
    '',
    'Microsoft Purview portal:',
    '  URL: https://purview.microsoft.com',
    '  Markdown: [Microsoft Purview portal](https://purview.microsoft.com)',
    '',
    'Exchange Online PowerShell module info (EXO V3):',
    '  URL: https://aka.ms/exov3-module',
    '  Markdown: [Exchange Online PowerShell module (EXO V3)](https://aka.ms/exov3-module)',
    '',
    '1) Open the Microsoft Purview portal in your browser.',
    '2) Go to eDiscovery, open the case:',
    "   Case: $CaseName",
    '3) Find the search:',
    "   Search: $searchName",
    '4) Create an export for the search results and choose PST as the export format.',
    "   Export type requested in SSA app: $ExportType",
    '   - If exporting Archive content, select the option in the export flow to include the mailbox archive.',
    '   - If exporting Primary only, do not include archive content.',
    '',
    "Job folder: $job",
    'Job details saved: job-details.json'
  )

  $instructions | Set-Content -Encoding UTF8 -Path (Join-Path $job 'DOWNLOAD-INSTRUCTIONS.txt')

  Write-Host ''
  Write-Host 'Search job created.'
  Write-Host "Case:   $CaseName"
  Write-Host "Search: $searchName"
  Write-Host "Status: $($s.Status)"
  Write-Host "Job folder: $job"
  Write-Host ''
  Write-Host 'Next step: follow DOWNLOAD-INSTRUCTIONS.txt to export/download PST in the Purview portal.'
}
