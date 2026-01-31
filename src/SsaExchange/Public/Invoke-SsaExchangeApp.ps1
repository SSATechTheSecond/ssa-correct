function Invoke-SsaExchangeApp {
  [CmdletBinding()]
  param()

  $exportRoot = Initialize-SsaExportRoot
  $logPath = Initialize-SsaLogging -ExportRoot $exportRoot

  Write-Host "Log file: $logPath"

  # Show greeting + terminology BEFORE prompting for credentials.
  Write-SsaGreeting
  Pause-Ssa

  try {
    $adminUpn = Read-SsaNonEmpty -Prompt 'Enter admin UPN (e.g. admin@contoso.com)'
    Write-SsaLog -Level 'INFO' -Message 'Admin UPN entered' -Data @{ AdminUpn = $adminUpn }

    Connect-SsaM365 -AdminUpn $adminUpn

    while ($true) {
      Clear-Host
      Write-Host '=== SSA Exchange ==='
      Write-Host '1) User Management'
      Write-Host '2) Access Management'
      Write-Host '3) Admin Management'
      Write-Host '4) Exit'

      $mainChoice = Read-SsaMenuChoice -Min 1 -Max 4 -Prompt 'Main menu'

      $choiceName = switch ($mainChoice) {
        1 { 'User Management' }
        2 { 'Access Management' }
        3 { 'Admin Management' }
        4 { 'Exit' }
      }
      Write-SsaLog -Level 'INFO' -Message 'Main menu selection' -Data @{ Choice = $choiceName }

      switch ($mainChoice) {
        1 {
          try {
            Invoke-SsaMenuUserManagement
          } catch {
            Write-SsaLog -Level 'ERROR' -Message 'User Management menu error' -Data (Get-SsaErrorData -ErrorRecord $_)
            Write-Host "Error: $($_.Exception.Message)"
            Pause-Ssa
          }
        }
        2 {
          try {
            Invoke-SsaMenuAccessManagement
          } catch {
            Write-SsaLog -Level 'ERROR' -Message 'Access Management menu error' -Data (Get-SsaErrorData -ErrorRecord $_)
            Write-Host "Error: $($_.Exception.Message)"
            Pause-Ssa
          }
        }
        3 {
          try {
            Invoke-SsaMenuAdminManagement
          } catch {
            Write-SsaLog -Level 'ERROR' -Message 'Admin Management menu error' -Data (Get-SsaErrorData -ErrorRecord $_)
            Write-Host "Error: $($_.Exception.Message)"
            Pause-Ssa
          }
        }
        4 { return }
      }
    }
  }
  catch {
    Write-SsaLog -Level 'ERROR' -Message 'Unhandled error' -Data @{ Error = $_.Exception.Message }
    throw
  }
  finally {
    Disconnect-SsaM365
    Stop-SsaLogging
  }
}

function Invoke-SsaMenuUserManagement {
  [CmdletBinding()]
  param()

  while ($true) {
    Clear-Host
    Write-Host '=== User Management ==='
    Write-Host '1) Reset password'
    Write-Host '2) Enable account'
    Write-Host '3) Disable account'
    Write-Host '4) Delete user (with optional export)'
    Write-Host '5) Export user info'
    Write-Host '6) Back'

    $c = Read-SsaMenuChoice -Min 1 -Max 6 -Prompt 'User Management'

    switch ($c) {
      1 {
        $upn = Read-SsaNonEmpty -Prompt 'Target user UPN'
        Write-SsaLog -Level 'INFO' -Message 'Reset password selected' -Data @{ TargetUpn = $upn }
        try {
          Invoke-SsaUserResetPassword -TargetUpn $upn
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Reset password failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }
        Pause-Ssa
      }
      2 {
        $upn = Read-SsaNonEmpty -Prompt 'Target user UPN'
        Write-SsaLog -Level 'INFO' -Message 'Enable account selected' -Data @{ TargetUpn = $upn }
        try {
          Invoke-SsaUserSetEnabled -TargetUpn $upn -Enabled:$true
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Enable account failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }
        Pause-Ssa
      }
      3 {
        $upn = Read-SsaNonEmpty -Prompt 'Target user UPN'
        Write-SsaLog -Level 'INFO' -Message 'Disable account selected' -Data @{ TargetUpn = $upn }
        try {
          Invoke-SsaUserSetEnabled -TargetUpn $upn -Enabled:$false
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Disable account failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }
        Pause-Ssa
      }
      4 {
        $upn = Read-SsaNonEmpty -Prompt 'Target user UPN'
        Write-SsaLog -Level 'INFO' -Message 'Delete user selected' -Data @{ TargetUpn = $upn }
        try {
          Invoke-SsaUserDelete -TargetUpn $upn
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Delete user failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }
        Pause-Ssa
      }
      5 {
        $upn = Read-SsaNonEmpty -Prompt 'Target user UPN'
        Write-SsaLog -Level 'INFO' -Message 'Export user selected' -Data @{ TargetUpn = $upn }
        try {
          Invoke-SsaUserExport -TargetUpn $upn
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Export user failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }
        Pause-Ssa
      }
      6 { return }
    }
  }
}

function Invoke-SsaMenuAccessManagement {
  [CmdletBinding()]
  param()

  while ($true) {
    Clear-Host
    Write-Host '=== Access Management (Mailbox Delegation) ==='
    Write-Host '1) Add delegation'
    Write-Host '2) Remove delegation'
    Write-Host '3) Back'

    $c = Read-SsaMenuChoice -Min 1 -Max 3 -Prompt 'Access Management'
    if ($c -eq 3) { return }

    $action = if ($c -eq 1) { 'Add' } else { 'Remove' }

    $mailboxUpn = Read-SsaNonEmpty -Prompt 'Mailbox UPN'
    $delegateUpn = Read-SsaNonEmpty -Prompt 'Delegate-to UPN'

    Write-Host ''
    Write-Host 'Delegation type:'
    Write-Host '1) FullAccess'
    Write-Host '2) SendAs'
    Write-Host '3) SendOnBehalf'
    Write-Host '4) Folder permission (Calendar)'

    $t = Read-SsaMenuChoice -Min 1 -Max 4 -Prompt 'Delegation type'
    $type = switch ($t) {
      1 { 'FullAccess' }
      2 { 'SendAs' }
      3 { 'SendOnBehalf' }
      4 { 'Calendar' }
    }

    Write-SsaLog -Level 'INFO' -Message 'Mailbox delegation selected' -Data @{ Action = $action; MailboxUpn = $mailboxUpn; DelegateUpn = $delegateUpn; Type = $type }

    try {
      Invoke-SsaMailboxDelegation -Action $action -MailboxUpn $mailboxUpn -DelegateUpn $delegateUpn -Type $type
    } catch {
      Write-SsaLog -Level 'ERROR' -Message 'Mailbox delegation failed' -Data (Get-SsaErrorData -ErrorRecord $_)
      Write-Host "Error: $($_.Exception.Message)"
    }

    Pause-Ssa
  }
}

function Invoke-SsaMenuAdminManagement {
  [CmdletBinding()]
  param()

  while ($true) {
    Clear-Host
    Write-Host '=== Admin Management ==='
    Write-Host '1) List all mailbox sizes'
    Write-Host '2) Top 10 mailbox sizes'
    Write-Host '3) Create PST export search job (Primary/Archive)'
    Write-Host '4) Back'

    $c = Read-SsaMenuChoice -Min 1 -Max 4 -Prompt 'Admin Management'

    switch ($c) {
      1 {
        $out = Select-SsaOutputMode
        $job = New-SsaJobFolder -JobName 'MailboxSizes-All'
        Write-SsaLog -Level 'INFO' -Message 'Mailbox size report (all) selected' -Data @{ JobFolder = $job }

        try {
          $rows = Get-SsaMailboxSizeReport
          $null = Write-SsaResult -Rows $rows -OutputMode $out -JobFolder $job -BaseName 'mailbox-sizes'
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Mailbox size report (all) failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }

        Pause-Ssa
      }
      2 {
        $out = Select-SsaOutputMode
        $job = New-SsaJobFolder -JobName 'MailboxSizes-Top10'
        Write-SsaLog -Level 'INFO' -Message 'Mailbox size report (top 10) selected' -Data @{ JobFolder = $job }

        try {
          $rows = Get-SsaMailboxSizeReport -Top 10
          $null = Write-SsaResult -Rows $rows -OutputMode $out -JobFolder $job -BaseName 'mailbox-sizes-top10'
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'Mailbox size report (top 10) failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }

        Pause-Ssa
      }
      3 {
        $mbx = Read-SsaNonEmpty -Prompt 'Mailbox UPN or primary SMTP (e.g. user@contoso.com)'
        Write-Host ''
        Write-Host 'Export type:'
        Write-Host '1) Primary'
        Write-Host '2) Archive'
        $t = Read-SsaMenuChoice -Min 1 -Max 2 -Prompt 'Export type'
        $type = if ($t -eq 1) { 'Primary' } else { 'Archive' }

        Write-SsaLog -Level 'INFO' -Message 'PST export search job selected' -Data @{ MailboxUpn = $mbx; ExportType = $type }

        try {
          Invoke-SsaPstExportSearchJob -MailboxUpn $mbx -ExportType $type
        } catch {
          Write-SsaLog -Level 'ERROR' -Message 'PST export search job failed' -Data (Get-SsaErrorData -ErrorRecord $_)
          Write-Host "Error: $($_.Exception.Message)"
        }

        Pause-Ssa
      }
      4 { return }
    }
  }
}
