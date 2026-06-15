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

## Files

```text
RunBoard.ps1                  # English/ASCII UI
RunBoard.ko.ps1               # Korean UI
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

Korean UI:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoard.ko.ps1
```

The Korean UI script stores user-facing Korean text as UTF-8 Base64 strings and decodes it at runtime. This avoids common script-file encoding issues on Windows PowerShell 5.1.

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

Korean UI:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\RunBoard.ko.ps1 -ConfigPath .\configs\starccm.json
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
  "preventOverlappingReservations": true
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

## Notes

No administrator feature is included. Users can cancel only their own future reservations.
