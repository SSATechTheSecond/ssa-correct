function Write-SsaGreeting {
  [CmdletBinding()]
  param()

  Write-Host ''
  Write-Host 'Hello — I hope you enjoy this free software built by Lourens. Thank you for using it.'
  Write-Host ''
  Write-Host 'Quick terms (so prompts make sense):'
  Write-Host "- Admin UPN: your admin sign-in, usually looks like an email (e.g. admin@contoso.com)."
  Write-Host "- Mailbox UPN / Primary SMTP: the user mailbox identity, usually user@contoso.com (either value typically works)."
  Write-Host "- Primary vs Archive: 'Primary' is the main mailbox; 'Archive' is the online archive (if enabled)."
  Write-Host "- Purview Compliance Search: the app creates a search; you then export PST in the Purview portal."
  Write-Host ''
  Write-Host 'Notes:'
  Write-Host "- If a prompt asks for a mailbox, prefer entering a UPN/email — not a GUID."
  Write-Host "- Logs and export job folders are created under the Export Root you choose at startup."
  Write-Host ''
}

function Pause-Ssa {
  [CmdletBinding()]
  param(
    [string]$Message = 'Press Enter to continue'
  )
  [void](Read-Host $Message)
}

function Read-SsaNonEmpty {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Prompt
  )

  while ($true) {
    $v = Read-Host $Prompt
    if (-not [string]::IsNullOrWhiteSpace($v)) { return $v.Trim() }
    Write-Host 'Value cannot be blank.'
  }
}

function Read-SsaMenuChoice {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [int]$Min,

    [Parameter(Mandatory)]
    [int]$Max,

    [string]$Prompt = 'Select an option'
  )

  while ($true) {
    $raw = Read-Host "$Prompt ($Min-$Max)"
    $n = 0
    if ([int]::TryParse($raw, [ref]$n) -and $n -ge $Min -and $n -le $Max) { return $n }
    Write-Host "Please enter a number between $Min and $Max."
  }
}

function Confirm-Ssa {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Prompt,

    [bool]$DefaultYes = $false
  )

  $suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }

  while ($true) {
    $raw = Read-Host "$Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($raw)) { return $DefaultYes }

    switch ($raw.Trim().ToLowerInvariant()) {
      'y' { return $true }
      'yes' { return $true }
      'n' { return $false }
      'no' { return $false }
      default { Write-Host 'Please enter y or n.' }
    }
  }
}
