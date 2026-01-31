# Performance Note - Background Processing

## Current Issue

The Build Queue operation runs synchronously on the UI thread, causing the window to freeze for 10+ minutes when querying mailbox statistics.

## Why It's Slow

- `Get-Mailbox -ResultSize Unlimited` retrieves all mailboxes
- `Get-MailboxStatistics` is called for each mailbox (1-2 seconds each)
- With 100+ mailboxes, this takes 10-20 minutes
- All processing blocks the UI thread

## Proper Solution: PowerShell Runspaces

Implementing background processing requires:

1. **Create Runspace**
   ```powershell
   $runspace = [runspacefactory]::CreateRunspace()
   $runspace.ApartmentState = "STA"
   $runspace.ThreadOptions = "ReuseThread"
   $runspace.Open()
   ```

2. **Create PowerShell instance**
   ```powershell
   $ps = [powershell]::Create().AddScript($scriptBlock)
   $ps.Runspace = $runspace
   ```

3. **Start async execution**
   ```powershell
   $handle = $ps.BeginInvoke()
   ```

4. **Poll with DispatcherTimer**
   ```powershell
   $timer = New-Object System.Windows.Threading.DispatcherTimer
   $timer.Interval = [TimeSpan]::FromMilliseconds(500)
   $timer.Add_Tick({
     if ($handle.IsCompleted) {
       $result = $ps.EndInvoke($handle)
       # Update UI via Dispatcher
       $window.Dispatcher.Invoke([action]{
         # Update DataGrid, etc
       })
       $timer.Stop()
     }
   })
   $timer.Start()
   ```

## Immediate Workarounds

Until background processing is implemented:

1. **Use smaller result sets**: Top 10 strategies only
2. **Avoid "Load All"** with large tenants
3. **User expectation**: Show message "This may take 10-15 minutes..."
4. **Progress feedback**: Status messages show it's working

## Implementation Priority

This is marked as **HIGH PRIORITY** in TODO.md and should be implemented before v1.0.0 release.

## Estimated Implementation Time

- 2-4 hours for proper runspace implementation
- Testing with real tenant data
- Error handling and cleanup

---
*Created: 2026-01-31*
