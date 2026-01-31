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
      # TODO: Call Connect-SsaM365 or implement connection logic
      # For now, simulate connection
      $adminUPN = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your admin UPN:", "Connect to M365", "")

      if ([string]::IsNullOrWhiteSpace($adminUPN)) {
        Update-StatusBar "Connection cancelled"
        return
      }

      $script:ConnectionState.AdminUPN = $adminUPN

      # Simulate connections (replace with actual Connect-SsaM365 call)
      Update-ConnectionStatus -Service 'Exo' -Connected $true
      Update-ConnectionStatus -Service 'Compliance' -Connected $true
      Update-ConnectionStatus -Service 'Graph' -Connected $true

      Update-StatusBar "Connected as: $adminUPN"
    }
    catch {
      [System.Windows.MessageBox]::Show("Connection failed: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
      Update-StatusBar "Connection failed"
    }
  })

  # Disconnect Button
  $controls['DisconnectButton'].Add_Click({
    Update-StatusBar "Disconnecting..."

    try {
      # TODO: Call Disconnect-SsaM365 or implement disconnection logic

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

      # TODO: Implement actual EXO query logic based on load strategy
      # For now, add sample data based on strategy
      switch ($loadStrategy) {
        'Top10Mailbox' {
          Update-StatusBar "Loading top 10 mailboxes by size..."
          $script:QueueState.Items = @(
            [PSCustomObject]@{
              PrimarySmtp = 'large1@contoso.com'
              DisplayName = 'Large Mailbox 1'
              MailboxType = 'UserMailbox'
              HasArchive = 'Yes'
              LastLogon = '2026-01-15'
              Status = 'NotStarted'
              Error = ''
            },
            [PSCustomObject]@{
              PrimarySmtp = 'large2@contoso.com'
              DisplayName = 'Large Mailbox 2'
              MailboxType = 'UserMailbox'
              HasArchive = 'Yes'
              LastLogon = '2026-01-10'
              Status = 'NotStarted'
              Error = ''
            }
          )
        }
        'Top10Archive' {
          Update-StatusBar "Loading top 10 archives by size..."
          $script:QueueState.Items = @(
            [PSCustomObject]@{
              PrimarySmtp = 'archive1@contoso.com'
              DisplayName = 'Large Archive 1'
              MailboxType = 'UserMailbox'
              HasArchive = 'Yes'
              LastLogon = '2026-01-20'
              Status = 'NotStarted'
              Error = ''
            },
            [PSCustomObject]@{
              PrimarySmtp = 'archive2@contoso.com'
              DisplayName = 'Large Archive 2'
              MailboxType = 'UserMailbox'
              HasArchive = 'Yes'
              LastLogon = '2026-01-18'
              Status = 'NotStarted'
              Error = ''
            }
          )
        }
        'LoadAll' {
          Update-StatusBar "Loading all mailboxes (this may take a while)..."
          $script:QueueState.Items = @(
            [PSCustomObject]@{
              PrimarySmtp = 'all1@contoso.com'
              DisplayName = 'All Users 1'
              MailboxType = 'UserMailbox'
              HasArchive = 'No'
              LastLogon = '2026-01-25'
              Status = 'NotStarted'
              Error = ''
            }
          )
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
          Update-StatusBar "Loading inactive mailboxes (older than $thresholdDays days)..."
          $script:QueueState.Items = @(
            [PSCustomObject]@{
              PrimarySmtp = 'inactive1@contoso.com'
              DisplayName = 'Inactive User 1'
              MailboxType = 'SharedMailbox'
              HasArchive = 'No'
              LastLogon = '2025-06-01'
              Status = 'NotStarted'
              Error = ''
            },
            [PSCustomObject]@{
              PrimarySmtp = 'inactive2@contoso.com'
              DisplayName = 'Inactive User 2'
              MailboxType = 'UserMailbox'
              HasArchive = 'Yes'
              LastLogon = ''
              Status = 'NotStarted'
              Error = ''
            }
          )
        }
      }

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
