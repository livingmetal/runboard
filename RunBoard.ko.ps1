param([string]$ConfigPath = "")
$ErrorActionPreference = "Stop"

$M = @{
  config_missing="7ISk7KCVIO2MjOydvOydtCDsl4bsirXri4jri6QuIOy1nOy0iCDshKTsoJXsnYQg7Iuc7J6R7ZWp64uI64ukLg=="
  target_prompt="7Iuk7ZaJ7ZWgIEVYRSDqsr3roZw="
  target_not_found="7Iuk7ZaJIO2MjOydvOydhCDssL7snYQg7IiYIOyXhuyKteuLiOuLpDog"
  app_name_prompt="7ZSE66Gc6re4656oIO2RnOyLnCDsnbTrpoQ="
  args_prompt="7Iuk7ZaJIOyduOyekCBb7JeG7Jy866m0IEVudGVyXQ=="
  work_prompt="7J6R7JeFIOuUlOugie2EsOumrCBb6riw67O46rCSOiDsi6Ttlokg7YyM7J28IO2PtOuNlF0="
  root_prompt="66Gc6re4L+yYiOyVvSDsoIDsnqUg66Oo7Yq4IOqyveuhnA=="
  root_required="66Gc6re4L+yYiOyVvSDsoIDsnqUg66Oo7Yq4IOqyveuhnOuKlCDtlYTsiJjsnoXri4jri6Qu"
  config_created="7ISk7KCVIO2MjOydvOydhCDsg53shLHtlojsirXri4jri6Q6IA=="
  lock_fail="7JiI7JW9IO2MjOydvCDsnqDquIjsnYQg7ZmV67O07ZWY7KeAIOuqu+2WiOyKteuLiOuLpC4="
  reservations="7JiI7JW9IOuqqeuhnQ=="
  no_reservations="65Ox66Gd65CcIOyYiOyVveydtCDsl4bsirXri4jri6Qu"
  start="7Iuc7J6R"
  end="7KKF66OM"
  user="7IKs7Jqp7J6Q"
  purpose="66qp7KCB"
  add_res="7JiI7JW9IOy2lOqwgA=="
  date_format="64Kg7KecIO2YleyLnTogeXl5eS1NTS1kZCBISDptbQ=="
  start_time_prompt="7Iuc7J6RIOyLnOqwhCwg7Leo7IaM7ZWY66Ck66m0IEVudGVy"
  end_time_prompt="7KKF66OMIOyLnOqwhA=="
  end_after_start="7KKF66OMIOyLnOqwhOydgCDsi5zsnpEg7Iuc6rCE67O064ukIOuSpOyXrOyVvCDtlanri4jri6Qu"
  purpose_prompt="66qp7KCBIFvshKDtg51d"
  conflict="7JiI7JW9IOyLnOqwhOydtCDqsrnsuanri4jri6Qu"
  res_added="7JiI7JW97J2EIOuTseuhne2WiOyKteuLiOuLpC4="
  no_my_res="7Zmc7ISxIOyYiOyVveydtCDsl4bsirXri4jri6Qu"
  cancel_choice="7Leo7IaM7ZWgIOyYiOyVvSDrsojtmLjrpbwg7ISg7YOd7ZWY7IS47JqULiDrj4zslYTqsIDroKTrqbQgRW50ZXI="
  bad_choice="7J6Y66q765CcIOyEoO2DneyeheuLiOuLpC4="
  res_cancelled="7JiI7JW97J2EIOy3qOyGjO2WiOyKteuLiOuLpC4="
  sessions="7ZiE7J6sIOyLpO2WiSDshLjshZg="
  no_sessions="7ZiE7J6sIOyLpO2WiSDspJHsnbgg7IS47IWY7J20IOyXhuyKteuLiOuLpC4="
  running="7Iuk7ZaJ7KSR"
  stale="64GK6rmA7J2Y7Ius"
  pc="UEM="
  last_seen="66eI7KeA66eJ7Iug7Zi4"
  age_min="6rK96rO867aE"
  overlap_msg="7ZiE7J6sIOyLnOqwhOydtCDri6Trpbgg7IKs7Jqp7J6Q7J2YIOyYiOyVvSDsi5zqsITqs7wg6rK57Lmp64uI64ukLg=="
  reserved_by="7JiI7JW97J6Q"
  res_time="7JiI7JW9IOyLnOqwhA=="
  run_anyway="6re4656Y64+EIOyLpO2Wie2VmOyLnOqyoOyKteuLiOq5jD8="
  res_notice="UnVuQm9hcmQg7JiI7JW9IOyVjOumvA=="
  run_cancelled="7IKs7Jqp7J6Q6rCAIOyLpO2WieydhCDst6jshoztlojsirXri4jri6Qu"
  running_target="7ZSE66Gc6re4656o7J2EIOyLpO2Wie2VqeuLiOuLpDog"
  reservation_starts="64uk66W4IOyCrOyaqeyekOydmCDsmIjslb0g7Iuc6rCE7J20IHswfeu2hCDsnbTrgrTsl5Ag7Iuc7J6R65Cp64uI64ukLg=="
  reservation_started="64uk66W4IOyCrOyaqeyekOydmCDsmIjslb0g7Iuc6rCE7J20IOyLnOyekeuQmOyXiOyKteuLiOuLpC4="
  wrap_up="6rCA64ql7ZWY66m0IOyekeyXheydhCDsoJXrpqztlbQg7KO87IS47JqULg=="
  res_started_title="UnVuQm9hcmQg7JiI7JW9IOyLnOyekQ=="
  closed="7ZSE66Gc6re4656o7J20IOyiheujjOuQmOyXiOyKteuLiOuLpC4g7KKF66OMIOy9lOuTnDog"
  menu_res="MS4g7JiI7JW9"
  menu_run="Mi4g7KaJ7IucIOyLpO2WiQ=="
  menu_exit="My4g7KKF66OM"
  select="7ISg7YOd"
  res_menu_add="MS4g7JiI7JW9IOy2lOqwgA=="
  res_menu_cancel="Mi4g64K0IOyYiOyVvSDst6jshow="
  res_menu_show="My4g7JiI7JW9IOuqqeuhnSDrs7TquLA="
  res_menu_back="NC4g65Kk66Gc"
  continue_enter="6rOE7IaN7ZWY66Ck66m0IEVudGVy"
  exit_enter="7KKF66OM7ZWY66Ck66m0IEVudGVy"
  header_user="7IKs7Jqp7J6QICAgICA6IA=="
  header_pc="UEMgICAgICAgICA6IA=="
  header_target="7Iuk7ZaJIO2MjOydvCAgOiA="
  header_root="7KCA7J6lIOqyveuhnCAgOiA="
  next_res="64uk7J2MIOuLpOuluCDsgqzsmqnsnpAg7JiI7JW9"
  continue_yn="6rOE7IaN7ZWY7Iuc6rKg7Iq164uI6rmMPyAoWS9OKQ=="
}
function T($k, $a = $null) { $s = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($M[$k])); if ($null -ne $a) { return [string]::Format($s, $a) }; return $s }
function BaseDir { if ($PSScriptRoot) { return $PSScriptRoot }; Split-Path -Parent $MyInvocation.MyCommand.Path }
function SafeId([string]$Text) { $s=($Text -replace '[^a-zA-Z0-9_-]','-'); $s=($s -replace '-+','-').Trim('-'); if([string]::IsNullOrWhiteSpace($s)){"app"}else{$s.ToLowerInvariant()} }
function ExpandPath([string]$Path) { if([string]::IsNullOrWhiteSpace($Path)){return $Path}; $p=[Environment]::ExpandEnvironmentVariables($Path); if([IO.Path]::IsPathRooted($p)){return $p}; Join-Path (BaseDir) $p }
function Info($m){Write-Host $m -ForegroundColor Cyan}; function Warn($m){Write-Host $m -ForegroundColor Yellow}; function Bad($m){Write-Host $m -ForegroundColor Red}
function Popup($title,$msg,[bool]$question){try{Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop|Out-Null; if($question){return [System.Windows.Forms.MessageBox]::Show($msg,$title,[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)}; return [System.Windows.Forms.MessageBox]::Show($msg,$title,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)}catch{Warn "[$title] $msg"; if($question){$a=Read-Host (T "continue_yn"); if($a -match '^[Yy]'){"Yes"}else{"No"}}else{"OK"}}}
function CurrentUser { if([string]::IsNullOrWhiteSpace($env:USERDOMAIN)){$env:USERNAME}else{"$env:USERDOMAIN\$env:USERNAME"} }
function ConfigFile { if(-not [string]::IsNullOrWhiteSpace($ConfigPath)){return $ConfigPath}; Join-Path (BaseDir) "runboard.config.json" }
function LoadConfig { $file=ConfigFile; if(Test-Path $file -PathType Leaf){$c=Get-Content -Raw -Path $file -Encoding UTF8|ConvertFrom-Json; if(-not $c.appId){$c|Add-Member appId (SafeId $c.appName)}; if(-not $c.heartbeatIntervalSeconds){$c|Add-Member heartbeatIntervalSeconds 30}; if(-not $c.reservationWarningMinutes){$c|Add-Member reservationWarningMinutes @(15,5,0)}; return $c}; Info (T "config_missing"); do{$target=ExpandPath (Read-Host (T "target_prompt")); if(-not(Test-Path $target -PathType Leaf)){Bad ((T "target_not_found")+$target)}}while(-not(Test-Path $target -PathType Leaf)); $default=[IO.Path]::GetFileNameWithoutExtension($target); $name=Read-Host ((T "app_name_prompt")+" [$default]"); if([string]::IsNullOrWhiteSpace($name)){$name=$default}; $args=Read-Host (T "args_prompt"); $work=Read-Host (T "work_prompt"); if([string]::IsNullOrWhiteSpace($work)){$work=Split-Path -Parent $target}; do{$root=ExpandPath (Read-Host (T "root_prompt")); if([string]::IsNullOrWhiteSpace($root)){Bad (T "root_required")}}while([string]::IsNullOrWhiteSpace($root)); $c=[ordered]@{appId=SafeId $name; appName=$name; targetPath=$target; targetArgs=$args; workingDirectory=$work; controlRoot=$root; heartbeatIntervalSeconds=30; reservationWarningMinutes=@(15,5,0); preventOverlappingReservations=$true}; $dir=Split-Path -Parent $file; if($dir){New-Item -ItemType Directory -Force -Path $dir|Out-Null}; $c|ConvertTo-Json -Depth 10|Set-Content -Path $file -Encoding UTF8; Info ((T "config_created")+$file); [pscustomobject]$c }
function Paths($c){$root=ExpandPath $c.controlRoot; [pscustomobject]@{root=$root;reservationDir=Join-Path $root "reservations";reservationFile=Join-Path $root "reservations\reservations.json";lockFile=Join-Path $root "reservations\reservations.lock";runningDir=Join-Path $root "sessions\running";closedDir=Join-Path $root "sessions\closed";heartbeatDir=Join-Path $root "heartbeats";logDir=Join-Path $root "logs"}}
function InitStore($p){@($p.reservationDir,$p.runningDir,$p.closedDir,$p.heartbeatDir,$p.logDir)|%{New-Item -ItemType Directory -Force -Path $_|Out-Null}; if(-not(Test-Path $p.reservationFile)){"[]"|Set-Content -Path $p.reservationFile -Encoding UTF8}}
function WithLock($p,[scriptblock]$block){$start=Get-Date;$stream=$null;while(((Get-Date)-$start).TotalSeconds -lt 15){try{$stream=[IO.File]::Open($p.lockFile,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None);$r=&$block;return $r}catch{Start-Sleep -Milliseconds 300}finally{if($stream){$stream.Dispose();$stream=$null;Remove-Item $p.lockFile -Force -ErrorAction SilentlyContinue}}};throw (T "lock_fail")}
function Reservations($p){$raw=Get-Content -Raw -Path $p.reservationFile -Encoding UTF8;if([string]::IsNullOrWhiteSpace($raw)){return @()};$x=$raw|ConvertFrom-Json;if($null -eq $x){return @()};if($x -is [array]){@($x)}else{@($x)}}
function SaveReservations($p,[array]$items){$items|ConvertTo-Json -Depth 10|Set-Content -Path $p.reservationFile -Encoding UTF8}
function FTime($v){if($null -eq $v){return ""};([datetime]$v).ToString("yyyy-MM-dd HH:mm")}
function ShowReservations($p){$now=Get-Date;$list=Reservations $p|?{$_.status -eq "reserved" -and ([datetime]$_.endTime) -ge $now.Date}|sort{[datetime]$_.startTime};Write-Host "";Info (T "reservations");if($list.Count -eq 0){Write-Host (T "no_reservations");return};$list|Select @{n=(T "start");e={FTime $_.startTime}},@{n=(T "end");e={FTime $_.endTime}},@{n=(T "user");e={$_.user}},@{n=(T "purpose");e={$_.purpose}}|ft -AutoSize}
function AddReservation($p){Write-Host "";Info (T "add_res");Write-Host (T "date_format");$st=Read-Host (T "start_time_prompt");if([string]::IsNullOrWhiteSpace($st)){return};$et=Read-Host (T "end_time_prompt");$s=[datetime]::Parse($st);$e=[datetime]::Parse($et);if($e -le $s){Bad (T "end_after_start");return};$purpose=Read-Host (T "purpose_prompt");$user=CurrentUser;WithLock $p {$items=@(Reservations $p);$conflict=@($items|?{$_.status -eq "reserved" -and $s -lt ([datetime]$_.endTime) -and $e -gt ([datetime]$_.startTime)});if($conflict.Count -gt 0){Bad (T "conflict");$conflict|Select @{n=(T "start");e={FTime $_.startTime}},@{n=(T "end");e={FTime $_.endTime}},@{n=(T "user");e={$_.user}},@{n=(T "purpose");e={$_.purpose}}|ft -AutoSize;return};$id="{0}-{1}-{2}" -f $s.ToString("yyyyMMdd-HHmmss"),(SafeId $user),([guid]::NewGuid().ToString("N").Substring(0,8));$new=[pscustomobject][ordered]@{reservationId=$id;user=$user;computer=$env:COMPUTERNAME;startTime=$s.ToString("s");endTime=$e.ToString("s");purpose=$purpose;status="reserved";createdAt=(Get-Date).ToString("s")};SaveReservations $p (@($items)+$new);Info (T "res_added")}}
function CancelMine($p){$user=CurrentUser;$now=Get-Date;WithLock $p {$items=@(Reservations $p);$mine=@($items|?{$_.status -eq "reserved" -and $_.user -ieq $user -and ([datetime]$_.endTime) -ge $now}|sort{[datetime]$_.startTime});if($mine.Count -eq 0){Write-Host (T "no_my_res");return};for($i=0;$i -lt $mine.Count;$i++){Write-Host ("{0}. {1} ~ {2} | {3}" -f ($i+1),(FTime $mine[$i].startTime),(FTime $mine[$i].endTime),$mine[$i].purpose)};$choice=Read-Host (T "cancel_choice");if([string]::IsNullOrWhiteSpace($choice)){return};$idx=[int]$choice-1;if($idx -lt 0 -or $idx -ge $mine.Count){Bad (T "bad_choice");return};$id=$mine[$idx].reservationId;foreach($r in $items){if($r.reservationId -eq $id){$r.status="cancelled"}};SaveReservations $p $items;Info (T "res_cancelled")}}
function CurrentOtherReservations($p){$now=Get-Date;$user=CurrentUser;@(Reservations $p|?{$_.status -eq "reserved" -and $_.user -ine $user -and $now -ge ([datetime]$_.startTime) -and $now -lt ([datetime]$_.endTime)})}
function NextOtherReservation($p){$now=Get-Date;$user=CurrentUser;@(Reservations $p|?{$_.status -eq "reserved" -and $_.user -ine $user -and ([datetime]$_.startTime) -gt $now}|sort{[datetime]$_.startTime}|select -First 1)}
function ShowSessions($p){Write-Host "";Info (T "sessions");$files=@(gci $p.runningDir -Filter "*.json" -ea SilentlyContinue);if($files.Count -eq 0){Write-Host (T "no_sessions");return};$now=Get-Date;$rows=foreach($f in $files){try{$s=gc -Raw $f.FullName -Encoding UTF8|ConvertFrom-Json;$age=[math]::Round(($now-([datetime]$s.lastSeen)).TotalMinutes,1);[pscustomobject]@{상태=$(if($age -le 5){T "running"}else{T "stale"});사용자=$s.user;PC=$s.computer;시작=FTime $s.startTime;마지막신호=FTime $s.lastSeen;경과분=$age}}catch{}};$rows|ft -AutoSize}
function RunNow($c,$p){$target=ExpandPath $c.targetPath;if(-not(Test-Path $target -PathType Leaf)){Bad ((T "target_not_found")+$target);return};$work=ExpandPath $c.workingDirectory;if(-not(Test-Path $work -PathType Container)){$work=Split-Path -Parent $target};ShowSessions $p;$others=@(CurrentOtherReservations $p);if($others.Count -gt 0){$r=$others[0];$msg=(T "overlap_msg")+"`r`n`r`n"+(T "reserved_by")+": $($r.user)`r`n"+(T "res_time")+": $(FTime $r.startTime) ~ $(FTime $r.endTime)`r`n"+(T "purpose")+": $($r.purpose)`r`n`r`n"+(T "run_anyway");if((Popup (T "res_notice") $msg $true) -ne "Yes"){Warn (T "run_cancelled");return}};$now=Get-Date;$sid="{0}-{1}-{2}-{3}" -f $c.appId,$now.ToString("yyyyMMdd-HHmmss"),(SafeId $env:COMPUTERNAME),(SafeId $env:USERNAME);$sessionFile=Join-Path $p.runningDir "$sid.json";$closedFile=Join-Path $p.closedDir "$sid.json";$heartbeatFile=Join-Path $p.heartbeatDir "$sid.hb";$si=@{FilePath=$target;WorkingDirectory=$work;PassThru=$true};if(-not [string]::IsNullOrWhiteSpace($c.targetArgs)){$si.ArgumentList=$c.targetArgs};Info ((T "running_target")+$target);$proc=Start-Process @si;$session=[ordered]@{sessionId=$sid;appId=$c.appId;appName=$c.appName;user=(CurrentUser);computer=$env:COMPUTERNAME;pid=$proc.Id;targetPath=$target;startTime=$now.ToString("s");lastSeen=$now.ToString("s");endTime=$null;status="running";exitCode=$null;warningsShown=@();overlappedReservations=@()};$session|ConvertTo-Json -Depth 10|sc $sessionFile -Encoding UTF8;$now.ToString("s")|sc $heartbeatFile -Encoding ASCII;$shown=@{};$warnMinutes=@($c.reservationWarningMinutes);while(-not $proc.HasExited){Start-Sleep -Seconds ([int]$c.heartbeatIntervalSeconds);$tick=Get-Date;$session.lastSeen=$tick.ToString("s");try{$session|ConvertTo-Json -Depth 10|sc $sessionFile -Encoding UTF8;$tick.ToString("s")|sc $heartbeatFile -Encoding ASCII}catch{};$next=NextOtherReservation $p;if($next){foreach($m in $warnMinutes|?{[int]$_ -gt 0}){$left=(([datetime]$next.startTime)-$tick).TotalMinutes;$key="$($next.reservationId)-before-$m";if($left -gt 0 -and $left -le [int]$m -and -not $shown.ContainsKey($key)){$shown[$key]=$true;Popup (T "res_notice") ((T "reservation_starts" $m)+"`r`n`r`n"+(T "reserved_by")+": $($next.user)`r`n"+(T "res_time")+": $(FTime $next.startTime) ~ $(FTime $next.endTime)`r`n"+(T "purpose")+": $($next.purpose)") $false|Out-Null}}};foreach($r in @(CurrentOtherReservations $p)){$key="$($r.reservationId)-started";if(-not $shown.ContainsKey($key)){$shown[$key]=$true;Popup (T "res_started_title") ((T "reservation_started")+"`r`n`r`n"+(T "reserved_by")+": $($r.user)`r`n"+(T "res_time")+": $(FTime $r.startTime) ~ $(FTime $r.endTime)`r`n"+(T "purpose")+": $($r.purpose)`r`n`r`n"+(T "wrap_up")) $false|Out-Null}}};$end=Get-Date;$session.status="closed";$session.endTime=$end.ToString("s");$session.lastSeen=$end.ToString("s");$session.exitCode=$proc.ExitCode;$session|ConvertTo-Json -Depth 10|sc $closedFile -Encoding UTF8;rm $sessionFile -Force -ea SilentlyContinue;rm $heartbeatFile -Force -ea SilentlyContinue;Info ((T "closed")+$proc.ExitCode)}
function ReservationMenu($p){while($true){Write-Host "";Write-Host (T "res_menu_add");Write-Host (T "res_menu_cancel");Write-Host (T "res_menu_show");Write-Host (T "res_menu_back");switch(Read-Host (T "select")){"1"{AddReservation $p}"2"{CancelMine $p}"3"{ShowReservations $p}"4"{return}default{Warn (T "bad_choice")}}}}
function Header($c){Clear-Host;Write-Host "========================================";Write-Host " RunBoard - $($c.appName)";Write-Host "========================================";Write-Host ((T "header_user")+(CurrentUser));Write-Host ((T "header_pc")+$env:COMPUTERNAME);Write-Host ((T "header_target")+(ExpandPath $c.targetPath));Write-Host ((T "header_root")+(ExpandPath $c.controlRoot))}
try{$config=LoadConfig;$paths=Paths $config;InitStore $paths;while($true){Header $config;ShowSessions $paths;$next=NextOtherReservation $paths;if($next){Info ((T "next_res")+": $(FTime $next.startTime) ~ $(FTime $next.endTime) | $($next.user) | $($next.purpose)")};Write-Host "";Write-Host (T "menu_res");Write-Host (T "menu_run");Write-Host (T "menu_exit");switch(Read-Host (T "select")){"1"{ReservationMenu $paths}"2"{RunNow $config $paths;Read-Host (T "continue_enter")|Out-Null}"3"{return}default{Warn (T "bad_choice");Start-Sleep 1}}}}catch{Bad $_.Exception.Message;Bad $_.ScriptStackTrace;Read-Host (T "exit_enter")|Out-Null;exit 1}
