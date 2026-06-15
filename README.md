# RunBoard

RunBoard is a small PowerShell launcher for shared Windows programs.

It records who runs a program, keeps a heartbeat while the program is running, stores closed session logs, and provides a simple reservation board. Reservations are advisory only: RunBoard does not block execution. If a user runs during another user's reservation, it shows a warning popup.

## Features

- First-run setup when no config file exists
- Target executable path and control/log root path configuration
- Menu-driven usage
  - `1. Reservation`
  - `2. Run now`
  - `3. Exit`
- Reservation add/cancel/show
- Reservation overlap prevention
- Immediate execution without hard blocking
- Popup warning when current time overlaps another user's reservation
- Heartbeat file while the target program is running
- Running and closed session JSON logs
- Detached watcher mode
- Stale session cleanup
- English/ASCII UI only, to avoid Windows PowerShell encoding issues

## Files

```text
RunBoard.ps1                  # English/ASCII UI, launches detached watcher and exits
RunBoardDetached.ps1          # English/ASCII UI, launches detached watcher and exits
RunBoardWatcher.ps1           # Background watcher used by detached mode
runboard.config.json          # created automatically on first run
runboard.sample.config.json   # example config
```

Control root structure is created automatically:

```text
<controlRoot>\
  reservations\
    reservations.json
    reservations.lock
  sessions\
    running\
    closed\
  heartbeats\
  logs\
```

## Quick start

Run PowerShell and execute:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoard.ps1
```

Detached watcher mode:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoardDetached.ps1
```

In detached mode, RunBoard shows current sessions and upcoming reservations, starts the target program, launches `RunBoardWatcher.ps1` in the background, and then exits. The watcher keeps updating heartbeat/session data until the target process exits. After the target process exits, the watcher writes the closed session log, removes the running session and heartbeat files, then exits.

On first run, RunBoard asks for:

1. Target exe path
2. App display name
3. Target arguments
4. Working directory
5. Log/reservation root path

Example control root:

```text
\\fileserver\app_control\sample-app
```

After setup, RunBoard creates `runboard.config.json` next to the script.

## Use a custom config path

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoard.ps1 -ConfigPath .\configs\starccm.json
```

Detached watcher mode:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoardDetached.ps1 -ConfigPath .\configs\starccm.json
```

This allows one RunBoard script to wrap multiple programs.

## Sample config

```json
{
  "appId": "sample-app",
  "appName": "Sample App",
  "targetPath": "C:\\Apps\\Sample\\sample.exe",
  "targetArgs": "",
  "workingDirectory": "C:\\Apps\\Sample",
  "controlRoot": "\\\\fileserver\\app_control\\sample-app",
  "heartbeatIntervalSeconds": 30,
  "reservationWarningMinutes": [15, 5, 0],
  "preventOverlappingReservations": true,
  "staleMinutes": 10,
  "staleCleanupMinutesSameComputer": 30,
  "staleCleanupHoursOtherComputer": 24
}
```

## Behavior

### Reservation

Reservations are stored in:

```text
<controlRoot>\reservations\reservations.json
```

A reservation contains:

- reservation ID
- user
- computer
- start time
- end time
- purpose
- status
- created time

Reservation conflicts are blocked using this rule:

```text
newStart < existingEnd AND newEnd > existingStart
```

### Run now

RunBoard always allows the user to run the target program unless the user cancels at the warning prompt.

If the current time overlaps another user's reservation, RunBoard shows a popup:

```text
Current time overlaps another user's reservation.
Run anyway?
```

While running, RunBoard writes heartbeat data to:

```text
<controlRoot>\heartbeats\<sessionId>.hb
```

Running session JSON is stored in:

```text
<controlRoot>\sessions\running\<sessionId>.json
```

When the target program exits, the session is moved to:

```text
<controlRoot>\sessions\closed\<sessionId>.json
```

### Stale session cleanup

RunBoard runs stale cleanup on startup and before showing the dashboard.

Default policy:

```text
staleMinutes = 10
  -> Current sessions shows stale when lastSeen is older than 10 minutes.

staleCleanupMinutesSameComputer = 30
  -> If the stale session is from the current computer and its PID no longer exists, move it to closed after 30 minutes.

staleCleanupHoursOtherComputer = 24
  -> If the stale session is from another computer, move it to closed after 24 hours.
```

Cleanup does not delete the record. It moves the JSON file from `sessions\running` to `sessions\closed` and marks it:

```json
{
  "status": "stale_closed",
  "closedBy": "stale_cleanup"
}
```

### Detached watcher lifecycle

```text
RunBoardDetached.ps1
  -> shows current sessions and reservations
  -> starts target exe
  -> creates running session and heartbeat
  -> starts RunBoardWatcher.ps1 hidden
  -> exits

RunBoardWatcher.ps1
  -> updates heartbeat while target PID exists
  -> shows reservation warning popups when possible
  -> when target PID disappears, writes closed session
  -> removes running session and heartbeat
  -> exits
```

The watcher exits shortly after the target program exits. The delay is up to `heartbeatIntervalSeconds`.

### Exit behavior in detached mode

When the user selects `3. Exit`, RunBoard stops only target processes that match all of these conditions:

- same `appId`
- same user
- same computer
- PID exists in `sessions\running`

RunBoard first tries `CloseMainWindow()`, waits 5 seconds, then uses `Stop-Process -Force` if the process is still alive.

## Notes

No administrator feature is included. Users can cancel only their own future reservations.
