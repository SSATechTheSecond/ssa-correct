function Invoke-SsaExchangeGui {
  <#
  .SYNOPSIS
    Launches the SSA Correct WPF GUI for bulk export management.

  .DESCRIPTION
    Opens the Windows Presentation Foundation (WPF) graphical interface for SSA Correct.
    Provides visual tools for:
    - Building export queues from Exchange Online
    - Managing bulk PST export workflows
    - Monitoring connection status
    - Controlling unattended mode and Windows lock

  .EXAMPLE
    Invoke-SsaExchangeGui
    Launches the GUI application.

  .NOTES
    Requires Windows PowerShell 5.1 and appropriate Microsoft 365 admin permissions.
  #>

  [CmdletBinding()]
  param()

  Add-Type -AssemblyName PresentationFramework
  Add-Type -AssemblyName PresentationCore
  Add-Type -AssemblyName WindowsBase

  $scriptRoot = Split-Path -Parent $PSScriptRoot
  $xamlPath = Join-Path $scriptRoot 'Private\Gui\MainWindow.xaml'

  if (-not (Test-Path $xamlPath)) {
    throw "MainWindow.xaml not found at: $xamlPath"
  }

  # Load XAML
  [xml]$xaml = Get-Content $xamlPath
  $reader = New-Object System.Xml.XmlNodeReader $xaml
  $window = [Windows.Markup.XamlReader]::Load($reader)

  # Get UI elements
  $controls = @{}
  $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    $name = $_.Name
    if ($name) {
      $controls[$name] = $window.FindName($name)
    }
  }

  # Initialize state
  $script:ConnectionState = @{
    ExoConnected = $false
    ComplianceConnected = $false
    GraphConnected = $false
    AdminUPN = $null
  }

  $script:QueueState = @{
    Items = @()
    Running = $false
    CaseName = "BulkExport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
  }

  # Set initial case name
  $controls['CaseNameTextbox'].Text = $script:QueueState.CaseName

  #region Helper Functions

  function Update-ConnectionStatus {
    param(
      [string]$Service,
      [bool]$Connected
    )

    switch ($Service) {
      'Exo' {
        $script:ConnectionState.ExoConnected = $Connected
        if ($Connected) {
          $controls['ExoStatusLight'].Fill = 'LimeGreen'
          $controls['ExoStatusText'].Text = 'Exchange Online: Connected'
        }
        else {
          $controls['ExoStatusLight'].Fill = 'Gray'
          $controls['ExoStatusText'].Text = 'Exchange Online: Disconnected'
        }
      }
      'Compliance' {
        $script:ConnectionState.ComplianceConnected = $Connected
        if ($Connected) {
          $controls['ComplianceStatusLight'].Fill = 'LimeGreen'
          $controls['ComplianceStatusText'].Text = 'Compliance: Connected'
        }
        else {
          $controls['ComplianceStatusLight'].Fill = 'Gray'
          $controls['ComplianceStatusText'].Text = 'Compliance: Disconnected'
        }
      }
      'Graph' {
        $script:ConnectionState.GraphConnected = $Connected
        if ($Connected) {
          $controls['GraphStatusLight'].Fill = 'LimeGreen'
          $controls['GraphStatusText'].Text = 'Graph: Connected'
        }
        else {
          $controls['GraphStatusLight'].Fill = 'Gray'
          $controls['GraphStatusText'].Text = 'Graph: Disconnected'
        }
      }
    }

    # Enable/disable buttons based on connection
    $anyConnected = $script:ConnectionState.ExoConnected -or
                   $script:ConnectionState.ComplianceConnected -or
                   $script:ConnectionState.GraphConnected

    $controls['DisconnectButton'].IsEnabled = $anyConnected
    $controls['BuildQueueButton'].IsEnabled = $script:ConnectionState.ExoConnected
    $controls['PreviewCountButton'].IsEnabled = $script:ConnectionState.ExoConnected
  }

  function Update-StatusBar {
    param([string]$Message)
    $controls['StatusBarText'].Text = $Message
  }

  function Update-QueueStats {
    $total = $script:QueueState.Items.Count
    $completed = ($script:QueueState.Items | Where-Object { $_.Status -eq 'Completed' }).Count
    $failed = ($script:QueueState.Items | Where-Object { $_.Status -eq 'Failed' }).Count

    $controls['QueueStatsText'].Text = "Queue: $total total, $completed completed, $failed failed"
  }

  function Lock-Workstation {
    # Call Windows API to lock workstation
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
      [System.Runtime.InteropServices.DllImport("user32.dll")]
      public static extern bool LockWorkStation();
"@
    [Win32.NativeMethods]::LockWorkStation() | Out-Null
  }

  #endregion

  #region Event Handlers

  # Connect Button
  $controls['ConnectButton'].Add_Click({
    Update-StatusBar "Connecting to Microsoft 365 services..."

    try {
      # Prompt for admin UPN
      Add-Type -AssemblyName Microsoft.VisualBasic
      $adminUPN = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your admin UPN:", "Connect to M365", "")

      if ([string]::IsNullOrWhiteSpace($adminUPN)) {
        Update-StatusBar "Connection cancelled"
        return
      }

      $script:ConnectionState.AdminUPN = $adminUPN

      # Disable Connect button during connection
      $controls['ConnectButton'].IsEnabled = $false
      Update-StatusBar "Connecting to Exchange Online..."

      # Minimize window so browser auth popup is visible
      $window.WindowState = [System.Windows.WindowState]::Minimized

      # Call the actual Connect-SsaM365 function
      Connect-SsaM365 -AdminUpn $adminUPN

      # Restore window after connection
      $window.WindowState = [System.Windows.WindowState]::Normal
      $window.Activate()

      # Get session state to check what connected
      $session = Get-SsaSession

      # Update status indicators based on actual connection state
      Update-ConnectionStatus -Service 'Exo' -Connected $session.Connected.ExchangeOnline
      Update-ConnectionStatus -Service 'Compliance' -Connected $session.Connected.Compliance
      Update-ConnectionStatus -Service 'Graph' -Connected $session.Connected.Graph

      Update-StatusBar "Connected as: $adminUPN"

      # Re-enable Connect button
      $controls['ConnectButton'].IsEnabled = $true
    }
    catch {
      [System.Windows.MessageBox]::Show("Connection failed: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
      Update-StatusBar "Connection failed"
      $controls['ConnectButton'].IsEnabled = $true
    }
  })

  # Disconnect Button
  $controls['DisconnectButton'].Add_Click({
    Update-StatusBar "Disconnecting..."

    try {
      # Call the actual Disconnect-SsaM365 function
      Disconnect-SsaM365

      # Update UI to reflect disconnected state
      Update-ConnectionStatus -Service 'Exo' -Connected $false
      Update-ConnectionStatus -Service 'Compliance' -Connected $false
      Update-ConnectionStatus -Service 'Graph' -Connected $false

      $script:ConnectionState.AdminUPN = $null
      Update-StatusBar "Disconnected"
    }
    catch {
      [System.Windows.MessageBox]::Show("Disconnect failed: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
  })

  # Build Queue Button
  $controls['BuildQueueButton'].Add_Click({
    Update-StatusBar "Building queue from Exchange Online..."

    try {
      # Determine which load strategy is selected
      $loadStrategy = 'Inactive'
      if ($controls['Top10MailboxSizeRadio'].IsChecked) {
        $loadStrategy = 'Top10Mailbox'
      }
      elseif ($controls['Top10ArchiveSizeRadio'].IsChecked) {
        $loadStrategy = 'Top10Archive'
      }
      elseif ($controls['LoadAllRadio'].IsChecked) {
        $loadStrategy = 'LoadAll'
      }

      # Get mailbox scope filter
      $scopeIndex = $controls['MailboxScopeCombo'].SelectedIndex
      $recipientTypeFilter = switch ($scopeIndex) {
        0 { @('UserMailbox', 'SharedMailbox') } # User + Shared
        1 { @('UserMailbox') } # User only
        2 { @('SharedMailbox') } # Shared only
        default { $null } # All types
      }

      # Query mailboxes based on load strategy
      $mailboxes = @()

      switch ($loadStrategy) {
        'Top10Mailbox' {
          Update-StatusBar "Loading top 10 mailboxes by size..."

          # Get all mailboxes with filter
          if ($recipientTypeFilter) {
            $allMbx = Get-Mailbox -ResultSize Unlimited | Where-Object { $recipientTypeFilter -contains $_.RecipientTypeDetails }
          }
          else {
            $allMbx = Get-Mailbox -ResultSize Unlimited
          }

          # Get statistics and sort by TotalItemSize
          $mailboxes = $allMbx | ForEach-Object {
            $stats = Get-MailboxStatistics -Identity $_.PrimarySmtpAddress -ErrorAction SilentlyContinue
            [PSCustomObject]@{
              Mailbox = $_
              Stats = $stats
              SizeBytes = if ($stats.TotalItemSize) {
                [long]($stats.TotalItemSize.ToString() -replace '.*\(([0-9,]+).*', '$1' -replace ',', '')
              } else { 0 }
            }
          } | Sort-Object -Property SizeBytes -Descending | Select-Object -First 10
        }

        'Top10Archive' {
          Update-StatusBar "Loading top 10 archives by size..."

          # Get mailboxes with archives
          if ($recipientTypeFilter) {
            $allMbx = Get-Mailbox -ResultSize Unlimited -Archive | Where-Object { $recipientTypeFilter -contains $_.RecipientTypeDetails }
          }
          else {
            $allMbx = Get-Mailbox -ResultSize Unlimited -Archive
          }

          # Get archive statistics and sort
          $mailboxes = $allMbx | Where-Object { $_.ArchiveGuid -ne [Guid]::Empty } | ForEach-Object {
            $stats = Get-MailboxStatistics -Identity $_.PrimarySmtpAddress -Archive -ErrorAction SilentlyContinue
            [PSCustomObject]@{
              Mailbox = $_
              Stats = $stats
              SizeBytes = if ($stats.TotalItemSize) {
                [long]($stats.TotalItemSize.ToString() -replace '.*\(([0-9,]+).*', '$1' -replace ',', '')
              } else { 0 }
            }
          } | Sort-Object -Property SizeBytes -Descending | Select-Object -First 10
        }

        'LoadAll' {
          Update-StatusBar "Loading all mailboxes (this may take a while)..."

          # Get all mailboxes
          if ($recipientTypeFilter) {
            $allMbx = Get-Mailbox -ResultSize Unlimited | Where-Object { $recipientTypeFilter -contains $_.RecipientTypeDetails }
          }
          else {
            $allMbx = Get-Mailbox -ResultSize Unlimited
          }

          # Get basic stats for each
          $mailboxes = $allMbx | ForEach-Object {
            $stats = Get-MailboxStatistics -Identity $_.PrimarySmtpAddress -ErrorAction SilentlyContinue
            [PSCustomObject]@{
              Mailbox = $_
              Stats = $stats
              SizeBytes = 0
            }
          }
        }

        default {
          # Inactive only
          $thresholdDays = switch ($controls['InactiveThresholdCombo'].SelectedIndex) {
            0 { 30 }
            1 { 90 }
            2 { 180 }
            3 { 365 }
            default { 180 }
          }
          $thresholdDate = (Get-Date).AddDays(-$thresholdDays)
          $includeBlanks = $controls['IncludeBlanksCheckbox'].IsChecked

          Update-StatusBar "Loading inactive mailboxes (older than $thresholdDays days)..."

          # Get mailboxes
          if ($recipientTypeFilter) {
            $allMbx = Get-Mailbox -ResultSize Unlimited | Where-Object { $recipientTypeFilter -contains $_.RecipientTypeDetails }
          }
          else {
            $allMbx = Get-Mailbox -ResultSize Unlimited
          }

          # Filter by last logon time
          $mailboxes = $allMbx | ForEach-Object {
            $stats = Get-MailboxStatistics -Identity $_.PrimarySmtpAddress -ErrorAction SilentlyContinue
            $lastLogon = $stats.LastLogonTime

            # Include if: no last logon (and blanks enabled) OR last logon older than threshold
            if ((-not $lastLogon -and $includeBlanks) -or ($lastLogon -and $lastLogon -lt $thresholdDate)) {
              [PSCustomObject]@{
                Mailbox = $_
                Stats = $stats
                SizeBytes = 0
              }
            }
          } | Where-Object { $_ -ne $null }
        }
      }

      # Convert to queue items
      $script:QueueState.Items = @($mailboxes | ForEach-Object {
        $mbx = $_.Mailbox
        $stats = $_.Stats
        $sizeBytes = $_.SizeBytes

        # Convert size to GB for display
        $sizeGB = if ($sizeBytes -gt 0) {
          [math]::Round($sizeBytes / 1GB, 2)
        } else { 0 }

        [PSCustomObject]@{
          PrimarySmtp = $mbx.PrimarySmtpAddress
          DisplayName = $mbx.DisplayName
          MailboxType = $mbx.RecipientTypeDetails
          MailboxSizeGB = $sizeGB
          HasArchive = if ($mbx.ArchiveGuid -and $mbx.ArchiveGuid -ne [Guid]::Empty) { 'Yes' } else { 'No' }
          LastLogon = if ($stats.LastLogonTime) { $stats.LastLogonTime.ToString('yyyy-MM-dd') } else { '' }
          Status = 'NotStarted'
          Error = ''
        }
      })

      $controls['QueueDataGrid'].ItemsSource = $script:QueueState.Items
      Update-QueueStats
      Update-StatusBar "Queue built: $($script:QueueState.Items.Count) mailboxes using strategy '$loadStrategy'"

      $controls['StartButton'].IsEnabled = $true
    }
    catch {
      [System.Windows.MessageBox]::Show("Failed to build queue: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
      Update-StatusBar "Failed to build queue"
    }
  })

  # Unattended Mode Checkbox
  $controls['UnattendedModeCheckbox'].Add_Checked({
    if ($script:QueueState.Running) {
      $controls['LockWindowsButton'].IsEnabled = $true
    }
  })

  $controls['UnattendedModeCheckbox'].Add_Unchecked({
    $controls['LockWindowsButton'].IsEnabled = $false
  })

  # Lock Windows Button
  $controls['LockWindowsButton'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
      "This will lock the workstation while the job continues running. Continue?",
      "Lock Windows",
      [System.Windows.MessageBoxButton]::YesNo,
      [System.Windows.MessageBoxImage]::Warning
    )

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
      Lock-Workstation
    }
  })

  # Start Button
  $controls['StartButton'].Add_Click({
    Update-StatusBar "Starting export queue..."
    $script:QueueState.Running = $true

    $controls['StartButton'].IsEnabled = $false
    $controls['PauseButton'].IsEnabled = $true

    if ($controls['UnattendedModeCheckbox'].IsChecked) {
      $controls['LockWindowsButton'].IsEnabled = $true
    }

    # TODO: Implement actual queue processing
    Update-StatusBar "Queue running..."
  })

  # Pause Button
  $controls['PauseButton'].Add_Click({
    Update-StatusBar "Pausing queue..."
    $script:QueueState.Running = $false

    $controls['PauseButton'].IsEnabled = $false
    $controls['ResumeButton'].IsEnabled = $true
    $controls['LockWindowsButton'].IsEnabled = $false

    Update-StatusBar "Queue paused"
  })

  # Resume Button
  $controls['ResumeButton'].Add_Click({
    Update-StatusBar "Resuming queue..."
    $script:QueueState.Running = $true

    $controls['ResumeButton'].IsEnabled = $false
    $controls['PauseButton'].IsEnabled = $true

    if ($controls['UnattendedModeCheckbox'].IsChecked) {
      $controls['LockWindowsButton'].IsEnabled = $true
    }

    Update-StatusBar "Queue resumed"
  })

  #endregion

  # Initialize UI state
  Update-StatusBar "Ready - Please connect to Microsoft 365 services"

  # Show window
  $window.ShowDialog() | Out-Null
}
