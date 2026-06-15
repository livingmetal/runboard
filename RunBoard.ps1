param(
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

function Get-BaseDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return Split-Path -Parent $MyInvocation.MyCommand.Path
}

function ConvertTo-SafeId {
    param([string]$Value)
    $safe = ($Value -replace '[^a-zA-Z0-9_-]', '-')
    $safe = ($safe -replace '-+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($safe)) { return "app" }
    return $safe.ToLowerInvariant()
}

function Expand-PathValue {
    param([string]$PathValue)
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $PathValue }
    $expanded = [Environment]::ExpandEnvironmentVariables($PathValue)
    if ([System.IO.Path]::IsPathRooted($expanded)) { return $expanded }
    return Join-Path (Get-BaseDirectory) $expanded
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Bad {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Show-Popup {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info", "Warning", "Question")]
        [string]$Kind = "Info"
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop | Out-Null
        $icon = [System.Windows.Forms.MessageBoxIcon]::Information
        $buttons = [System.Windows.Forms.MessageBoxButtons]::OK

        if ($Kind -eq "Warning") { $icon = [System.Windows.Forms.MessageBoxIcon]::Warning }
        if ($Kind -eq "Question") {
            $icon = [System.Windows.Forms.MessageBoxIcon]::Question
            $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
        }

        return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $buttons, $icon)
    }
    catch {
        Write-Warn "[$Title] $Message"
        if ($Kind -eq "Question") {
            $answer = Read-Host "Continue? (Y/N)"
            if ($answer -match '^[Yy]') { return "Yes" }
            return "No"
        }
        return "OK"
    }
}

function Get-DefaultConfigPath {
    if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) { return $ConfigPath }
    return Join-Path (Get-BaseDirectory) "runboard.config.json"
}

function New-InitialConfig {
    param([string]$Path)

    Write-Info "RunBoard config was not found. Initial setup starts."
    Write-Host ""

    do {
        $targetPath = Read-Host "Target exe path"
        $targetPath = Expand-PathValue $targetPath
        if (-not (Test-Path $targetPath -PathType Leaf)) {
            Write-Bad "Target exe was not found: $targetPath"
        }
    } while (-not (Test-Path $targetPath -PathType Leaf))

    $defaultName = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
    $appName = Read-Host "App display name [$defaultName]"
    if ([string]::IsNullOrWhiteSpace($appName)) { $appName = $defaultName }

    $targetArgs = Read-Host "Target arguments [empty]"
    $workingDirectory = Read-Host "Working directory [target exe directory]"
    if ([string]::IsNullOrWhiteSpace($workingDirectory)) {
        $workingDirectory = Split-Path -Parent $targetPath
    }

    do {
        $controlRoot = Read-Host "Log/reservation root path"
        $controlRoot = Expand-PathValue $controlRoot
        if ([string]::IsNullOrWhiteSpace($controlRoot)) {
            Write-Bad "Control root is required."
        }
    } while ([string]::IsNullOrWhiteSpace($controlRoot))

    $appId = ConvertTo-SafeId $appName

    $config = [ordered]@{
        appId = $appId
        appName = $appName
        targetPath = $targetPath
        targetArgs = $targetArgs
        workingDirectory = $workingDirectory
        controlRoot = $controlRoot
        heartbeatIntervalSeconds = 30
        reservationWarningMinutes = @(15, 5, 0)
        preventOverlappingReservations = $true
    }

    $dir = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $Path
    Write-Info "Config created: $Path"
    return [pscustomobject]$config
}

function Get-Config {
    $path = Get-DefaultConfigPath
    if (-not (Test-Path $path -PathType Leaf)) {
        return New-InitialConfig -Path $path
    }

    $config = Get-Content -Raw -Path $path | ConvertFrom-Json
    if (-not $config.appId) { $config | Add-Member -NotePropertyName appId -NotePropertyValue (ConvertTo-SafeId $config.appName) }
    return $config
}

function Get-Paths {
    param($Config)
    $root = Expand-PathValue $Config.controlRoot
    return [pscustomobject]@{
        Root = $root
        ReservationsDir = Join-Path $root "reservations"
        ReservationsFile = Join-Path $root "reservations\reservations.json"
        ReservationsLock = Join-Path $root "reservations\reservations.lock"
        RunningDir = Join-Path $root "sessions\running"
        ClosedDir = Join-Path $root "sessions\closed"
        HeartbeatsDir = Join-Path $root "heartbeats"
        LogsDir = Join-Path $root "logs"
    }
}

function Initialize-Storage {
    param($Paths)
    @(
        $Paths.ReservationsDir,
        $Paths.RunningDir,
        $Paths.ClosedDir,
        $Paths.HeartbeatsDir,
        $Paths.LogsDir
    ) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

    if (-not (Test-Path $Paths.ReservationsFile -PathType Leaf)) {
        "[]" | Set-Content -Encoding UTF8 -Path $Paths.ReservationsFile
    }
}

function Invoke-WithFileLock {
    param(
        [string]$LockPath,
        [scriptblock]$Action,
        [int]$TimeoutSeconds = 15
    )

    $lockDir = Split-Path -Parent $LockPath
    New-Item -ItemType Directory -Force -Path $lockDir | Out-Null
    $start = Get-Date
    $stream = $null

    while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSeconds) {
        try {
            $stream = [System.IO.File]::Open($LockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            $stream.SetLength(0)
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.WriteLine("user=$env:USERDOMAIN\$env:USERNAME")
            $writer.WriteLine("computer=$env:COMPUTERNAME")
            $writer.WriteLine("time=$((Get-Date).ToString('s'))")
            $writer.Flush()
            $stream.Position = 0
            return & $Action
        }
        catch {
            if ($stream) { $stream.Dispose(); $stream = $null }
            Start-Sleep -Milliseconds 300
        }
        finally {
            if ($stream) {
                $stream.Dispose()
                $stream = $null
                try { Remove-Item -Force -Path $LockPath -ErrorAction SilentlyContinue } catch {}
            }
        }
    }

    throw "Could not acquire lock: $LockPath"
}

function Get-CurrentUserName {
    if ([string]::IsNullOrWhiteSpace($env:USERDOMAIN)) { return $env:USERNAME }
    return "$env:USERDOMAIN\$env:USERNAME"
}

function Get-Reservations {
    param($Paths)
    if (-not (Test-Path $Paths.ReservationsFile -PathType Leaf)) { return @() }
    $raw = Get-Content -Raw -Path $Paths.ReservationsFile
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $items = $raw | ConvertFrom-Json
    if ($null -eq $items) { return @() }
    if ($items -is [array]) { return @($items) }
    return @($items)
}

function Save-Reservations {
    param($Paths, [array]$Reservations)
    $Reservations | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $Paths.ReservationsFile
}

function Format-Time {
    param($Value)
    if ($null -eq $Value) { return "" }
    return ([datetime]$Value).ToString("yyyy-MM-dd HH:mm")
}

function Show-Reservations {
    param($Paths, [int]$Days = 7)
    $now = Get-Date
    $until = $now.Date.AddDays($Days)
    $reservations = Get-Reservations $Paths | Where-Object {
        $_.status -eq "reserved" -and ([datetime]$_.endTime) -ge $now.Date -and ([datetime]$_.startTime) -lt $until
    } | Sort-Object { [datetime]$_.startTime }

    Write-Host ""
    Write-Info "Reservations"
    if (-not $reservations -or $reservations.Count -eq 0) {
        Write-Host "No reservations."
        return
    }

    $reservations | Select-Object `
        @{Name="Start";Expression={Format-Time $_.startTime}},
        @{Name="End";Expression={Format-Time $_.endTime}},
        @{Name="User";Expression={$_.user}},
        @{Name="Purpose";Expression={$_.purpose}} | Format-Table -AutoSize
}

function Get-OverlappingReservations {
    param($Paths, [datetime]$Start, [datetime]$End)
    Get-Reservations $Paths | Where-Object {
        $_.status -eq "reserved" -and $Start -lt ([datetime]$_.endTime) -and $End -gt ([datetime]$_.startTime)
    }
}

function Add-Reservation {
    param($Paths)

    Write-Host ""
    Write-Info "Add reservation"
    Write-Host "Date format: yyyy-MM-dd HH:mm"
    $startText = Read-Host "Start time or blank to cancel"
    if ([string]::IsNullOrWhiteSpace($startText)) { return }

    $endText = Read-Host "End time"
    $start = [datetime]::Parse($startText)
    $end = [datetime]::Parse($endText)

    if ($end -le $start) {
        Write-Bad "End time must be later than start time."
        return
    }

    $purpose = Read-Host "Purpose [optional]"
    $currentUser = Get-CurrentUserName

    Invoke-WithFileLock -LockPath $Paths.ReservationsLock -Action {
        $conflicts = @(Get-OverlappingReservations -Paths $Paths -Start $start -End $end)
        if ($conflicts.Count -gt 0) {
            Write-Bad "Reservation conflict."
            $conflicts | Select-Object `
                @{Name="Start";Expression={Format-Time $_.startTime}},
                @{Name="End";Expression={Format-Time $_.endTime}},
                @{Name="User";Expression={$_.user}},
                @{Name="Purpose";Expression={$_.purpose}} | Format-Table -AutoSize
            return
        }

        $reservations = @(Get-Reservations $Paths)
        $reservationId = "{0}-{1}-{2}" -f $start.ToString("yyyyMMdd-HHmmss"), (ConvertTo-SafeId $currentUser), ([guid]::NewGuid().ToString("N").Substring(0, 8))
        $item = [ordered]@{
            reservationId = $reservationId
            user = $currentUser
            computer = $env:COMPUTERNAME
            startTime = $start.ToString("s")
            endTime = $end.ToString("s")
            purpose = $purpose
            status = "reserved"
            createdAt = (Get-Date).ToString("s")
        }
        Save-Reservations -Paths $Paths -Reservations (@($reservations) + [pscustomobject]$item)
        Write-Info "Reservation added."
    }
}

function Cancel-MyReservation {
    param($Paths)
    $currentUser = Get-CurrentUserName
    $now = Get-Date

    Invoke-WithFileLock -LockPath $Paths.ReservationsLock -Action {
        $reservations = @(Get-Reservations $Paths)
        $mine = @($reservations | Where-Object {
            $_.status -eq "reserved" -and $_.user -ieq $currentUser -and ([datetime]$_.endTime) -ge $now
        } | Sort-Object { [datetime]$_.startTime })

        if ($mine.Count -eq 0) {
            Write-Host "No active reservations for $currentUser."
            return
        }

        Write-Host ""
        for ($i = 0; $i -lt $mine.Count; $i++) {
            $n = $i + 1
            Write-Host ("{0}. {1} ~ {2} | {3}" -f $n, (Format-Time $mine[$i].startTime), (Format-Time $mine[$i].endTime), $mine[$i].purpose)
        }
        $choice = Read-Host "Select reservation to cancel or blank to go back"
        if ([string]::IsNullOrWhiteSpace($choice)) { return }
        $index = [int]$choice - 1
        if ($index -lt 0 -or $index -ge $mine.Count) {
            Write-Bad "Invalid selection."
            return
        }

        $cancelId = $mine[$index].reservationId
        foreach ($r in $reservations) {
            if ($r.reservationId -eq $cancelId) {
                $r.status = "cancelled"
                $r.cancelledAt = (Get-Date).ToString("s")
            }
        }
        Save-Reservations -Paths $Paths -Reservations $reservations
        Write-Info "Reservation cancelled."
    }
}

function Show-CurrentSessions {
    param($Paths)
    $now = Get-Date
    $files = @(Get-ChildItem -Path $Paths.RunningDir -Filter "*.json" -ErrorAction SilentlyContinue)
    Write-Host ""
    Write-Info "Current sessions"
    if ($files.Count -eq 0) {
        Write-Host "No running sessions."
        return
    }

    $items = foreach ($file in $files) {
        try {
            $s = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
            $last = [datetime]$s.lastSeen
            $age = [math]::Round(($now - $last).TotalMinutes, 1)
            [pscustomobject]@{
                State = $(if ($age -le 5) { "running" } else { "stale" })
                User = $s.user
                Computer = $s.computer
                Start = Format-Time $s.startTime
                LastSeen = Format-Time $s.lastSeen
                AgeMin = $age
            }
        } catch {}
    }
    $items | Format-Table -AutoSize
}

function Get-CurrentOtherReservations {
    param($Paths)
    $now = Get-Date
    $user = Get-CurrentUserName
    @(Get-Reservations $Paths | Where-Object {
        $_.status -eq "reserved" -and $_.user -ine $user -and $now -ge ([datetime]$_.startTime) -and $now -lt ([datetime]$_.endTime)
    } | Sort-Object { [datetime]$_.startTime })
}

function Get-NextOtherReservation {
    param($Paths)
    $now = Get-Date
    $user = Get-CurrentUserName
    @(Get-Reservations $Paths | Where-Object {
        $_.status -eq "reserved" -and $_.user -ine $user -and ([datetime]$_.startTime) -gt $now
    } | Sort-Object { [datetime]$_.startTime } | Select-Object -First 1)
}

function Write-JsonFileSafe {
    param([string]$Path, $Object)
    $Object | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 -Path $Path
}

function Start-TargetProgram {
    param($Config, $Paths)

    $targetPath = Expand-PathValue $Config.targetPath
    if (-not (Test-Path $targetPath -PathType Leaf)) {
        Write-Bad "Target exe not found: $targetPath"
        return
    }

    $workingDirectory = Expand-PathValue $Config.workingDirectory
    if ([string]::IsNullOrWhiteSpace($workingDirectory) -or -not (Test-Path $workingDirectory -PathType Container)) {
        $workingDirectory = Split-Path -Parent $targetPath
    }

    Show-CurrentSessions $Paths

    $currentOthers = @(Get-CurrentOtherReservations $Paths)
    if ($currentOthers.Count -gt 0) {
        $r = $currentOthers[0]
        $message = "Current time overlaps another user's reservation.`r`n`r`nUser: $($r.user)`r`nTime: $(Format-Time $r.startTime) ~ $(Format-Time $r.endTime)`r`nPurpose: $($r.purpose)`r`n`r`nRun anyway?"
        $answer = Show-Popup -Title "RunBoard reservation warning" -Message $message -Kind Question
        if ($answer -ne "Yes") {
            Write-Warn "Run cancelled by user."
            return
        }
    }

    $now = Get-Date
    $user = Get-CurrentUserName
    $sessionId = "{0}-{1}-{2}-{3}" -f $Config.appId, $now.ToString("yyyyMMdd-HHmmss"), (ConvertTo-SafeId $env:COMPUTERNAME), (ConvertTo-SafeId $env:USERNAME)
    $sessionFile = Join-Path $Paths.RunningDir "$sessionId.json"
    $closedFile = Join-Path $Paths.ClosedDir "$sessionId.json"
    $heartbeatFile = Join-Path $Paths.HeartbeatsDir "$sessionId.hb"

    $startInfo = @{
        FilePath = $targetPath
        WorkingDirectory = $workingDirectory
        PassThru = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($Config.targetArgs)) {
        $startInfo.ArgumentList = $Config.targetArgs
    }

    Write-Info "Starting: $targetPath"
    $process = Start-Process @startInfo

    $session = [ordered]@{
        sessionId = $sessionId
        appId = $Config.appId
        appName = $Config.appName
        user = $user
        computer = $env:COMPUTERNAME
        pid = $process.Id
        targetPath = $targetPath
        startTime = $now.ToString("s")
        lastSeen = $now.ToString("s")
        endTime = $null
        status = "running"
        exitCode = $null
        warningsShown = @()
        overlappedReservations = @()
    }
    Write-JsonFileSafe -Path $sessionFile -Object $session
    $now.ToString("s") | Set-Content -Encoding ASCII -Path $heartbeatFile

    $warningMinutes = @($Config.reservationWarningMinutes)
    if ($warningMinutes.Count -eq 0) { $warningMinutes = @(15, 5, 0) }
    $shown = @{}

    while (-not $process.HasExited) {
        Start-Sleep -Seconds ([int]$Config.heartbeatIntervalSeconds)
        $tick = Get-Date

        $session.lastSeen = $tick.ToString("s")
        try {
            Write-JsonFileSafe -Path $sessionFile -Object $session
            $tick.ToString("s") | Set-Content -Encoding ASCII -Path $heartbeatFile
        }
        catch {
            $log = Join-Path $Paths.LogsDir ("{0}-{1}.log" -f $Config.appId, (Get-Date).ToString("yyyyMMdd"))
            "$(Get-Date -Format s) heartbeat write failed: $($_.Exception.Message)" | Add-Content -Encoding UTF8 -Path $log
        }

        $next = Get-NextOtherReservation $Paths
        if ($next) {
            foreach ($m in $warningMinutes | Where-Object { [int]$_ -gt 0 }) {
                $minutesLeft = (([datetime]$next.startTime) - $tick).TotalMinutes
                $key = "$($next.reservationId)-before-$m"
                if ($minutesLeft -gt 0 -and $minutesLeft -le [int]$m -and -not $shown.ContainsKey($key)) {
                    $shown[$key] = $true
                    $session.warningsShown += $key
                    $msg = "Another user's reservation starts within $m minute(s).`r`n`r`nUser: $($next.user)`r`nTime: $(Format-Time $next.startTime) ~ $(Format-Time $next.endTime)`r`nPurpose: $($next.purpose)"
                    Show-Popup -Title "RunBoard reservation notice" -Message $msg -Kind Warning | Out-Null
                }
            }
        }

        $current = @(Get-CurrentOtherReservations $Paths)
        foreach ($r in $current) {
            $key = "$($r.reservationId)-started"
            if (-not $shown.ContainsKey($key)) {
                $shown[$key] = $true
                $session.warningsShown += $key
                $session.overlappedReservations += [pscustomobject]@{
                    reservationId = $r.reservationId
                    user = $r.user
                    startTime = $r.startTime
                    endTime = $r.endTime
                    purpose = $r.purpose
                }
                $msg = "Another user's reservation has started.`r`n`r`nUser: $($r.user)`r`nTime: $(Format-Time $r.startTime) ~ $(Format-Time $r.endTime)`r`nPurpose: $($r.purpose)`r`n`r`nPlease wrap up when possible."
                Show-Popup -Title "RunBoard reservation started" -Message $msg -Kind Warning | Out-Null
            }
        }
    }

    $end = Get-Date
    $session.status = "closed"
    $session.endTime = $end.ToString("s")
    $session.lastSeen = $end.ToString("s")
    $session.exitCode = $process.ExitCode
    Write-JsonFileSafe -Path $closedFile -Object $session
    Remove-Item -Force -Path $sessionFile -ErrorAction SilentlyContinue
    Remove-Item -Force -Path $heartbeatFile -ErrorAction SilentlyContinue
    Write-Info "Program closed. Exit code: $($process.ExitCode)"
}

function Show-ReservationMenu {
    param($Paths)
    while ($true) {
        Write-Host ""
        Write-Host "1. Add reservation"
        Write-Host "2. Cancel my reservation"
        Write-Host "3. Show reservations"
        Write-Host "4. Back"
        $choice = Read-Host "Select"
        switch ($choice) {
            "1" { Add-Reservation $Paths }
            "2" { Cancel-MyReservation $Paths }
            "3" { Show-Reservations $Paths }
            "4" { return }
            default { Write-Warn "Invalid selection." }
        }
    }
}

function Show-Header {
    param($Config, $Paths)
    Clear-Host
    Write-Host "========================================"
    Write-Host " RunBoard - $($Config.appName)"
    Write-Host "========================================"
    Write-Host "User       : $(Get-CurrentUserName)"
    Write-Host "Computer   : $env:COMPUTERNAME"
    Write-Host "Target     : $(Expand-PathValue $Config.targetPath)"
    Write-Host "ControlRoot: $(Expand-PathValue $Config.controlRoot)"
    Write-Host ""
}

function Start-RunBoard {
    $config = Get-Config
    $paths = Get-Paths $config
    Initialize-Storage $paths

    while ($true) {
        Show-Header -Config $config -Paths $paths
        Show-CurrentSessions $paths
        $next = Get-NextOtherReservation $paths
        if ($next) {
            Write-Host ""
            Write-Info ("Next other reservation: {0} ~ {1} | {2} | {3}" -f (Format-Time $next.startTime), (Format-Time $next.endTime), $next.user, $next.purpose)
        }
        Write-Host ""
        Write-Host "1. Reservation"
        Write-Host "2. Run now"
        Write-Host "3. Exit"
        $choice = Read-Host "Select"
        switch ($choice) {
            "1" { Show-ReservationMenu $paths }
            "2" { Start-TargetProgram -Config $config -Paths $paths; Read-Host "Press Enter to continue" | Out-Null }
            "3" { return }
            default { Write-Warn "Invalid selection."; Start-Sleep -Seconds 1 }
        }
    }
}

try {
    Start-RunBoard
}
catch {
    Write-Bad $_.Exception.Message
    Write-Bad $_.ScriptStackTrace
    Read-Host "Press Enter to exit" | Out-Null
    exit 1
}
