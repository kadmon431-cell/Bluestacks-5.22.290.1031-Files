
$rx = '(?i)BlueStacks|Bstk|HD-|now\.gg'

$services = Get-CimInstance Win32_Service |
    Where-Object {
        $_.Name -match $rx -or
        $_.DisplayName -match $rx -or
        $_.PathName -match $rx
    } |
    Select-Object Name, DisplayName, State, StartMode, StartName, PathName

$processes = Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -match $rx -or
        $_.ExecutablePath -match $rx -or
        $_.CommandLine -match $rx
    } |
    Select-Object ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine

$drivers = Get-CimInstance Win32_SystemDriver |
    Where-Object {
        $_.Name -match $rx -or
        $_.DisplayName -match $rx -or
        $_.PathName -match $rx
    } |
    Select-Object Name, DisplayName, State, StartMode, PathName

$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
    ForEach-Object {
        $task = $_
        $actions = ($task.Actions | ForEach-Object {
            "$($_.Execute) $($_.Arguments)"
        }) -join '; '

        if ($task.TaskName -match $rx -or
            $task.TaskPath -match $rx -or
            $actions -match $rx) {
            [PSCustomObject]@{
                TaskName = $task.TaskName
                TaskPath = $task.TaskPath
                State    = $task.State
                Actions  = $actions
            }
        }
    }

$startup = Get-CimInstance Win32_StartupCommand |
    Where-Object {
        $_.Name -match $rx -or
        $_.Command -match $rx
    } |
    Select-Object Name, Command, Location, User

$report = @(
    "========== SERVICES =========="
    ($services | Format-List | Out-String)
    "========== PROCESSES =========="
    ($processes | Format-List | Out-String)
    "========== DRIVERS =========="
    ($drivers | Format-List | Out-String)
    "========== SCHEDULED TASKS =========="
    ($tasks | Format-List | Out-String)
    "========== STARTUP =========="
    ($startup | Format-List | Out-String)
)

$tag = Read-Host "Enter CLOSED or RUNNING"
$report | Set-Content "$env:USERPROFILE\Desktop\BlueStacks_$tag.txt" -Encoding UTF8

Write-Host "Report saved to Desktop."
