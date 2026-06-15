param(
    [Parameter(Mandatory=$true)] [int]$ProcessId,
    [Parameter(Mandatory=$true)] [string]$SessionFile,
    [Parameter(Mandatory=$true)] [string]$HeartbeatFile,
    [Parameter(Mandatory=$true)] [string]$ClosedFile,
    [Parameter(Mandatory=$true)] [string]$ReservationFile,
    [int]$HeartbeatIntervalSeconds = 30,
    [int[]]$ReservationWarningMinutes = @(15, 5, 0)
)

$ErrorActionPreference = "Stop"

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path -PathType Leaf)) { return $null }
    $raw = Get-Content -Raw -Path $Path -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return $raw | ConvertFrom-Json
}

function Write-JsonFile {
    param([string]$Path, $Object)
    $dir = Split-Path -Parent $Path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Object | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Show-Popup {
    param([string]$Title, [string]$Message)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop | Out-Null
        [System.Windows.Forms.MessageBox]::Show(
            $Message,
            $Title,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
    catch {
        # Watcher is allowed to run without interactive desktop access.
    }
}

function Get-Reservations {
    param([string]$Path)
    $items = Read-JsonFile $Path
    if ($null -eq $items) { return @() }
    if ($items -is [array]) { return @($items) }
    return @($items)
}

function Format-Time {
    param($Value)
    if ($null -eq $Value) { return "" }
    return ([datetime]$Value).ToString("yyyy-MM-dd HH:mm")
}

function Get-CurrentOtherReservations {
    param($Session, [string]$Path)
    $now = Get-Date
    @(Get-Reservations $Path | Where-Object {
        $_.status -eq "reserved" -and
        $_.user -ine $Session.user -and
        $now -ge ([datetime]$_.startTime) -and
        $now -lt ([datetime]$_.endTime)
    } | Sort-Object { [datetime]$_.startTime })
}

function Get-NextOtherReservation {
    param($Session, [string]$Path)
    $now = Get-Date
    @(Get-Reservations $Path | Where-Object {
        $_.status -eq "reserved" -and
        $_.user -ine $Session.user -and
        ([datetime]$_.startTime) -gt $now
    } | Sort-Object { [datetime]$_.startTime } | Select-Object -First 1)
}

function Add-ArrayItem {
    param($ArrayValue, $Item)
    $arr = @()
    if ($null -ne $ArrayValue) { $arr = @($ArrayValue) }
    return @($arr) + $Item
}

$session = Read-JsonFile $SessionFile
if ($null -eq $session) { exit 2 }

$shown = @{}

while ($true) {
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    $now = Get-Date

    if ($null -eq $process) {
        $session.status = "closed"
        $session.endTime = $now.ToString("s")
        $session.lastSeen = $now.ToString("s")
        $session.exitCode = $null
        $session.closedBy = "watcher"

        Write-JsonFile -Path $ClosedFile -Object $session
        Remove-Item -Force -Path $SessionFile -ErrorAction SilentlyContinue
        Remove-Item -Force -Path $HeartbeatFile -ErrorAction SilentlyContinue
        exit 0
    }

    $session.lastSeen = $now.ToString("s")
    $session.status = "running"

    try {
        Write-JsonFile -Path $SessionFile -Object $session
        $now.ToString("s") | Set-Content -Encoding ASCII -Path $HeartbeatFile
    }
    catch {
        # If the share hiccups, do not kill the target process.
    }

    $next = Get-NextOtherReservation -Session $session -Path $ReservationFile
    if ($next) {
        foreach ($m in $ReservationWarningMinutes | Where-Object { [int]$_ -gt 0 }) {
            $minutesLeft = (([datetime]$next.startTime) - $now).TotalMinutes
            $key = "$($next.reservationId)-before-$m"
            if ($minutesLeft -gt 0 -and $minutesLeft -le [int]$m -and -not $shown.ContainsKey($key)) {
                $shown[$key] = $true
                $session.warningsShown = Add-ArrayItem $session.warningsShown $key
                Show-Popup -Title "RunBoard 예약 알림" -Message "다른 사용자의 예약 시간이 $m분 이내에 시작됩니다.`r`n`r`n예약자: $($next.user)`r`n예약 시간: $(Format-Time $next.startTime) ~ $(Format-Time $next.endTime)`r`n목적: $($next.purpose)"
            }
        }
    }

    foreach ($r in @(Get-CurrentOtherReservations -Session $session -Path $ReservationFile)) {
        $key = "$($r.reservationId)-started"
        if (-not $shown.ContainsKey($key)) {
            $shown[$key] = $true
            $session.warningsShown = Add-ArrayItem $session.warningsShown $key
            $overlap = [pscustomobject]@{
                reservationId = $r.reservationId
                user = $r.user
                startTime = $r.startTime
                endTime = $r.endTime
                purpose = $r.purpose
            }
            $session.overlappedReservations = Add-ArrayItem $session.overlappedReservations $overlap
            Show-Popup -Title "RunBoard 예약 시작" -Message "다른 사용자의 예약 시간이 시작되었습니다.`r`n`r`n예약자: $($r.user)`r`n예약 시간: $(Format-Time $r.startTime) ~ $(Format-Time $r.endTime)`r`n목적: $($r.purpose)`r`n`r`n가능하면 작업을 정리해 주세요."
        }
    }

    Start-Sleep -Seconds $HeartbeatIntervalSeconds
}
