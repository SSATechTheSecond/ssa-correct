function Invoke-SsaMailboxDelegation {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Add','Remove')]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$MailboxUpn,

    [Parameter(Mandatory)]
    [string]$DelegateUpn,

    [Parameter(Mandatory)]
    [ValidateSet('FullAccess','SendAs','SendOnBehalf','Calendar')]
    [string]$Type,

    [ValidateSet('Reviewer','Editor','Owner')]
    [string]$CalendarAccess = 'Reviewer'
  )

  $job = New-SsaJobFolder -JobName "Delegation-$Action-$Type" -Target $MailboxUpn

  switch ($Type) {
    'FullAccess' {
      if ($Action -eq 'Add') {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Add FullAccess for $DelegateUpn")) {
          Add-MailboxPermission -Identity $MailboxUpn -User $DelegateUpn -AccessRights FullAccess -InheritanceType All -AutoMapping:$false
        }
      } else {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Remove FullAccess for $DelegateUpn")) {
          Remove-MailboxPermission -Identity $MailboxUpn -User $DelegateUpn -AccessRights FullAccess -InheritanceType All -Confirm:$false
        }
      }
    }
    'SendAs' {
      if ($Action -eq 'Add') {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Add SendAs for $DelegateUpn")) {
          Add-RecipientPermission -Identity $MailboxUpn -Trustee $DelegateUpn -AccessRights SendAs -Confirm:$false
        }
      } else {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Remove SendAs for $DelegateUpn")) {
          Remove-RecipientPermission -Identity $MailboxUpn -Trustee $DelegateUpn -AccessRights SendAs -Confirm:$false
        }
      }
    }
    'SendOnBehalf' {
      if ($Action -eq 'Add') {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Add SendOnBehalf for $DelegateUpn")) {
          Set-Mailbox -Identity $MailboxUpn -GrantSendOnBehalfTo @{Add=$DelegateUpn}
        }
      } else {
        if ($PSCmdlet.ShouldProcess($MailboxUpn, "Remove SendOnBehalf for $DelegateUpn")) {
          Set-Mailbox -Identity $MailboxUpn -GrantSendOnBehalfTo @{Remove=$DelegateUpn}
        }
      }
    }
    'Calendar' {
      $folderId = "${MailboxUpn}:\Calendar"

      if ($Action -eq 'Add') {
        if ($PSCmdlet.ShouldProcess($folderId, "Add Calendar permission ($CalendarAccess) for $DelegateUpn")) {
          Add-MailboxFolderPermission -Identity $folderId -User $DelegateUpn -AccessRights $CalendarAccess
        }
      } else {
        if ($PSCmdlet.ShouldProcess($folderId, "Remove Calendar permission for $DelegateUpn")) {
          Remove-MailboxFolderPermission -Identity $folderId -User $DelegateUpn -Confirm:$false
        }
      }
    }
  }

  $row = [pscustomobject]@{
    Action = $Action
    Type = $Type
    MailboxUpn = $MailboxUpn
    DelegateUpn = $DelegateUpn
    CalendarAccess = if ($Type -eq 'Calendar') { $CalendarAccess } else { $null }
    TimestampUtc = (Get-Date).ToUniversalTime().ToString('o')
  }

  $out = Select-SsaOutputMode
  $null = Write-SsaResult -Rows @($row) -OutputMode $out -JobFolder $job -BaseName 'delegation'
}
