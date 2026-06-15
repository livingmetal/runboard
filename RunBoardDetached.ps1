param([string]$ConfigPath = "")
$ErrorActionPreference = "Stop"

function BaseDir { if ($PSScriptRoot) { return $PSScriptRoot }; Split-Path -Parent $MyInvocation.MyCommand.Path }
function SafeId([string]$Text) { $s=($Text -replace '[^a-zA-Z0-9_-]','-'); $s=($s -replace '-+','-').Trim('-'); if([string]::IsNullOrWhiteSpace($s)){"app"}else{$s.ToLowerInvariant()} }
function ExpandPath([string]$Path) { if([string]::IsNullOrWhiteSpace($Path)){return $Path}; $p=[Environment]::ExpandEnvironmentVariables($Path); if([IO.Path]::IsPathRooted($p)){return $p}; Join-Path (BaseDir) $p }
function Info($m){Write-Host $m -ForegroundColor Cyan}; function Warn($m){Write-Host $m -ForegroundColor Yellow}; function Bad($m){Write-Host $m -ForegroundColor Red}
function CurrentUser { if([string]::IsNullOrWhiteSpace($env:USERDOMAIN)){$env:USERNAME}else{"$env:USERDOMAIN\$env:USERNAME"} }
function ConfigFile { if(-not [string]::IsNullOrWhiteSpace($ConfigPath)){return $ConfigPath}; Join-Path (BaseDir) "runboard.config.json" }
function Popup($title,$msg,[bool]$question){try{Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop|Out-Null; if($question){return [System.Windows.Forms.MessageBox]::Show($msg,$title,[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)}; return [System.Windows.Forms.MessageBox]::Show($msg,$title,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)}catch{Warn "[$title] $msg"; if($question){$a=Read-Host "Continue? (Y/N)"; if($a -match '^[Yy]'){"Yes"}else{"No"}}else{"OK"}}}

function LoadConfig {
    $file=ConfigFile
    if(Test-Path $file -PathType Leaf){
        $c=Get-Content -Raw -Path $file -Encoding UTF8|ConvertFrom-Json
        if(-not $c.appId){$c|Add-Member appId (SafeId $c.appName)}
        if(-not $c.heartbeatIntervalSeconds){$c|Add-Member heartbeatIntervalSeconds 30}
        if(-not $c.reservationWarningMinutes){$c|Add-Member reservationWarningMinutes @(15,5,0)}
        return $c
    }
    Info "Config was not found. Initial setup starts."
    do{$target=ExpandPath (Read-Host "Target exe path"); if(-not(Test-Path $target -PathType Leaf)){Bad "Target exe was not found: $target"}}while(-not(Test-Path $target -PathType Leaf))
    $default=[IO.Path]::GetFileNameWithoutExtension($target)
    $name=Read-Host "App display name [$default]"; if([string]::IsNullOrWhiteSpace($name)){$name=$default}
    $args=Read-Host "Target arguments [empty]"
    $work=Read-Host "Working directory [target exe directory]"; if([string]::IsNullOrWhiteSpace($work)){$work=Split-Path -Parent $target}
    do{$root=ExpandPath (Read-Host "Log/reservation root path"); if([string]::IsNullOrWhiteSpace($root)){Bad "Control root is required."}}while([string]::IsNullOrWhiteSpace($root))
    $c=[ordered]@{appId=SafeId $name; appName=$name; targetPath=$target; targetArgs=$args; workingDirectory=$work; controlRoot=$root; heartbeatIntervalSeconds=30; reservationWarningMinutes=@(15,5,0); preventOverlappingReservations=$true}
    $dir=Split-Path -Parent $file; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}
    $c|ConvertTo-Json -Depth 10|Set-Content -Path $file -Encoding UTF8
    Info "Config created: $file"
    [pscustomobject]$c
}

function Paths($c){$root=ExpandPath $c.controlRoot; [pscustomobject]@{root=$root;reservationDir=Join-Path $root "reservations";reservationFile=Join-Path $root "reservations\reservations.json";lockFile=Join-Path $root "reservations\reservations.lock";runningDir=Join-Path $root "sessions\running";closedDir=Join-Path $root "sessions\closed";heartbeatDir=Join-Path $root "heartbeats";logDir=Join-Path $root "logs"}}
function InitStore($p){@($p.reservationDir,$p.runningDir,$p.closedDir,$p.heartbeatDir,$p.logDir)|%{New-Item -ItemType Directory -Force -Path $_|Out-Null}; if(-not(Test-Path $p.reservationFile)){"[]"|Set-Content -Path $p.reservationFile -Encoding UTF8}}
function WithLock($p,[scriptblock]$block){$start=Get-Date;$stream=$null;while(((Get-Date)-$start).TotalSeconds -lt 15){try{$stream=[IO.File]::Open($p.lockFile,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None);$r=&$block;return $r}catch{Start-Sleep -Milliseconds 300}finally{if($stream){$stream.Dispose();$stream=$null;Remove-Item $p.lockFile -Force -ErrorAction SilentlyContinue}}};throw "Could not acquire reservation lock."}
function Reservations($p){$raw=Get-Content -Raw -Path $p.reservationFile -Encoding UTF8;if([string]::IsNullOrWhiteSpace($raw)){return @()};$x=$raw|ConvertFrom-Json;if($null -eq $x){return @()};if($x -is [array]){@($x)}else{@($x)}}
function SaveReservations($p,[array]$items){$items|ConvertTo-Json -Depth 10|Set-Content -Path $p.reservationFile -Encoding UTF8}
function FTime($v){if($null -eq $v){return ""};([datetime]$v).ToString("yyyy-MM-dd HH:mm")}

function ShowReservations($p){$now=Get-Date;$list=Reservations $p|?{$_.status -eq "reserved" -and ([datetime]$_.endTime) -ge $now.Date}|sort{[datetime]$_.startTime};Write-Host "";Info "Reservations";if($list.Count -eq 0){Write-Host "No reservations.";return};$list|Select @{n="Start";e={FTime $_.startTime}},@{n="End";e={FTime $_.endTime}},@{n="User";e={$_.user}},@{n="Purpose";e={$_.purpose}}|ft -AutoSize}
function AddReservation($p){Write-Host "";Info "Add reservation";Write-Host "Date format: yyyy-MM-dd HH:mm";$st=Read-Host "Start time, blank to cancel";if([string]::IsNullOrWhiteSpace($st)){return};$et=Read-Host "End time";$s=[datetime]::Parse($st);$e=[datetime]::Parse($et);if($e -le $s){Bad "End time must be later than start time.";return};$purpose=Read-Host "Purpose [optional]";$user=CurrentUser;WithLock $p {$items=@(Reservations $p);$conflict=@($items|?{$_.status -eq "reserved" -and $s -lt ([datetime]$_.endTime) -and $e -gt ([datetime]$_.startTime)});if($conflict.Count -gt 0){Bad "Reservation conflict.";$conflict|Select @{n="Start";e={FTime $_.startTime}},@{n="End";e={FTime $_.endTime}},@{n="User";e={$_.user}},@{n="Purpose";e={$_.purpose}}|ft -AutoSize;return};$id="{0}-{1}-{2}" -f $s.ToString("yyyyMMdd-HHmmss"),(SafeId $user),([guid]::NewGuid().ToString("N").Substring(0,8));$new=[pscustomobject][ordered]@{reservationId=$id;user=$user;computer=$env:COMPUTERNAME;startTime=$s.ToString("s");endTime=$e.ToString("s");purpose=$purpose;status="reserved";createdAt=(Get-Date).ToString("s")};SaveReservations $p (@($items)+$new);Info "Reservation added."}}
function CancelMine($p){$user=CurrentUser;$now=Get-Date;WithLock $p {$items=@(Reservations $p);$mine=@($items|?{$_.status -eq "reserved" -and $_.user -ieq $user -and ([datetime]$_.endTime) -ge $now}|sort{[datetime]$_.startTime});if($mine.Count -eq 0){Write-Host "No active reservation for $user.";return};for($i=0;$i -lt $mine.Count;$i++){Write-Host ("{0}. {1} ~ {2} | {3}" -f ($i+1),(FTime $mine[$i].startTime),(FTime $mine[$i].endTime),$mine[$i].purpose)};$choice=Read-Host "Select reservation to cancel, blank to go back";if([string]::IsNullOrWhiteSpace($choice)){return};$idx=[int]$choice-1;if($idx -lt 0 -or $idx -ge $mine.Count){Bad "Invalid selection.";return};$id=$mine[$idx].reservationId;foreach($r in $items){if($r.reservationId -eq $id){$r.status="cancelled"}};SaveReservations $p $items;Info "Reservation cancelled."}}
function CurrentOtherReservations($p){$now=Get-Date;$user=CurrentUser;@(Reservations $p|?{$_.status -eq "reserved" -and $_.user -ine $user -and $now -ge ([datetime]$_.startTime) -and $now -lt ([datetime]$_.endTime)})}
function NextOtherReservation($p){$now=Get-Date;$user=CurrentUser;@(Reservations $p|?{$_.status -eq "reserved" -and $_.user -ine $user -and ([datetime]$_.startTime) -gt $now}|sort{[datetime]$_.startTime}|select -First 1)}
function ShowSessions($p){Write-Host "";Info "Current sessions";$files=@(gci $p.runningDir -Filter "*.json" -ea SilentlyContinue);if($files.Count -eq 0){Write-Host "No running sessions.";return};$now=Get-Date;$rows=foreach($f in $files){try{$s=gc -Raw $f.FullName -Encoding UTF8|ConvertFrom-Json;$age=[math]::Round(($now-([datetime]$s.lastSeen)).TotalMinutes,1);[pscustomobject]@{State=$(if($age -le 5){"running"}else{"stale"});User=$s.user;Computer=$s.computer;Start=FTime $s.startTime;LastSeen=FTime $s.lastSeen;AgeMin=$age}}catch{}};$rows|ft -AutoSize}

function StartWatcher($p, $sessionFile, $heartbeatFile, $closedFile, $processId, $c){
    $watcher = Join-Path (BaseDir) "RunBoardWatcher.ps1"
    if(-not(Test-Path $watcher -PathType Leaf)){throw "RunBoardWatcher.ps1 not found: $watcher"}
    $warns = @($c.reservationWarningMinutes) -join ","
    $arg = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$watcher`"","-ProcessId",$processId,"-SessionFile","`"$sessionFile`"","-HeartbeatFile","`"$heartbeatFile`"","-ClosedFile","`"$closedFile`"","-ReservationFile","`"$($p.reservationFile)`"","-HeartbeatIntervalSeconds",$c.heartbeatIntervalSeconds,"-ReservationWarningMinutes",$warns) -join " "
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList $arg | Out-Null
}

function RunNow($c,$p){
    $target=ExpandPath $c.targetPath
    if(-not(Test-Path $target -PathType Leaf)){Bad "Target exe not found: $target";return $null}
    $work=ExpandPath $c.workingDirectory
    if(-not(Test-Path $work -PathType Container)){$work=Split-Path -Parent $target}
    ShowSessions $p
    $others=@(CurrentOtherReservations $p)
    if($others.Count -gt 0){$r=$others[0];$msg="Current time overlaps another user's reservation.`r`n`r`nUser: $($r.user)`r`nTime: $(FTime $r.startTime) ~ $(FTime $r.endTime)`r`nPurpose: $($r.purpose)`r`n`r`nRun anyway?";if((Popup "RunBoard reservation warning" $msg $true) -ne "Yes"){Warn "Run cancelled by user.";return $null}}
    $now=Get-Date
    $sid="{0}-{1}-{2}-{3}" -f $c.appId,$now.ToString("yyyyMMdd-HHmmss"),(SafeId $env:COMPUTERNAME),(SafeId $env:USERNAME)
    $sessionFile=Join-Path $p.runningDir "$sid.json"
    $closedFile=Join-Path $p.closedDir "$sid.json"
    $heartbeatFile=Join-Path $p.heartbeatDir "$sid.hb"
    $si=@{FilePath=$target;WorkingDirectory=$work;PassThru=$true}
    if(-not [string]::IsNullOrWhiteSpace($c.targetArgs)){$si.ArgumentList=$c.targetArgs}
    Info "Starting: $target"
    $proc=Start-Process @si
    $session=[ordered]@{sessionId=$sid;appId=$c.appId;appName=$c.appName;user=(CurrentUser);computer=$env:COMPUTERNAME;pid=$proc.Id;targetPath=$target;startTime=$now.ToString("s");lastSeen=$now.ToString("s");endTime=$null;status="running";exitCode=$null;warningsShown=@();overlappedReservations=@();watcher="detached"}
    $session|ConvertTo-Json -Depth 10|Set-Content $sessionFile -Encoding UTF8
    $now.ToString("s")|Set-Content $heartbeatFile -Encoding ASCII
    StartWatcher $p $sessionFile $heartbeatFile $closedFile $proc.Id $c
    Info "Detached watcher started. This RunBoard window will close when the target process exits."
    return $proc.Id
}

function WaitForTargetThenExit($processId){
    if(-not $processId){return}
    Info "Waiting for target process to exit. Close this RunBoard window if you only want the watcher to remain."
    while(Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue){
        Start-Sleep -Seconds 2
    }
    Info "Target process exited. Closing RunBoard."
}

function StopOwnedTargets($c,$p){
    $user = CurrentUser
    $computer = $env:COMPUTERNAME
    $files = @(Get-ChildItem $p.runningDir -Filter "*.json" -ErrorAction SilentlyContinue)
    $targets = @()
    foreach($f in $files){
        try{
            $s = Get-Content -Raw $f.FullName -Encoding UTF8 | ConvertFrom-Json
            if($s.appId -eq $c.appId -and $s.user -ieq $user -and $s.computer -ieq $computer -and $s.pid){
                $proc = Get-Process -Id ([int]$s.pid) -ErrorAction SilentlyContinue
                if($proc){ $targets += [pscustomobject]@{Process=$proc; Session=$s} }
            }
        }catch{}
    }
    if($targets.Count -eq 0){ Info "No owned target process to stop."; return }
    Info "Stopping $($targets.Count) owned target process(es)."
    foreach($t in $targets){
        $proc = $t.Process
        try{
            Info "Stopping PID $($proc.Id) ($($proc.ProcessName))"
            if($proc.MainWindowHandle -ne 0){
                [void]$proc.CloseMainWindow()
                Start-Sleep -Seconds 5
                $proc = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
            }
            if($proc){ Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        }catch{ Warn "Failed to stop PID $($t.Process.Id): $($_.Exception.Message)" }
    }
    Info "Exit requested. Watcher will move sessions to closed shortly."
}

function ReservationMenu($p){while($true){Write-Host "";Write-Host "1. Add reservation";Write-Host "2. Cancel my reservation";Write-Host "3. Show reservations";Write-Host "4. Back";switch(Read-Host "Select"){"1"{AddReservation $p}"2"{CancelMine $p}"3"{ShowReservations $p}"4"{return}default{Warn "Invalid selection."}}}}
function Header($c){Clear-Host;Write-Host "========================================";Write-Host " RunBoard - $($c.appName)";Write-Host "========================================";Write-Host "User       : $(CurrentUser)";Write-Host "Computer   : $env:COMPUTERNAME";Write-Host "Target     : $(ExpandPath $c.targetPath)";Write-Host "ControlRoot: $(ExpandPath $c.controlRoot)"}

try{
    $config=LoadConfig
    $paths=Paths $config
    InitStore $paths
    while($true){
        Header $config
        ShowSessions $paths
        $next=NextOtherReservation $paths
        if($next){Info "Next other reservation: $(FTime $next.startTime) ~ $(FTime $next.endTime) | $($next.user) | $($next.purpose)"}
        Write-Host ""
        Write-Host "1. Reservation"
        Write-Host "2. Run now"
        Write-Host "3. Exit"
        switch(Read-Host "Select"){
            "1"{ReservationMenu $paths}
            "2"{$pid=RunNow $config $paths; if($pid){WaitForTargetThenExit $pid; return}; Read-Host "Press Enter to continue"|Out-Null}
            "3"{StopOwnedTargets $config $paths; return}
            default{Warn "Invalid selection."; Start-Sleep 1}
        }
    }
}catch{Bad $_.Exception.Message;Bad $_.ScriptStackTrace;Read-Host "Press Enter to exit"|Out-Null;exit 1}
