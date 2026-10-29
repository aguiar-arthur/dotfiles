# Windows

A standalone PowerShell script to debug the health of a Windows 11 PC (sudden shutdowns, blue
screens, crashes). It is the one thing here that is not for macOS: nothing installs, links or
tests it, and no other context depends on it.

## Files

| Path | Holds |
|---|---|
| `windows/collect-diagnostics.ps1` | the collector, monitor and optional repair |

## How it works

Run it in PowerShell as Administrator (without it, minidumps, WER reports and DISM may be
missing):

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\collect-diagnostics.ps1
```

| Parameter | Does |
|---|---|
| none | read-only collection of the last `-Days` days (default 30) |
| `-Deep` | also `sfc /verifyonly` and `chkdsk /scan` (several minutes) |
| `-Monitor -Minutes N` | only logs CPU, RAM, temperature, NVIDIA GPU and the busiest process every 5 s to `Documents\diagnostics\monitor_<stamp>.csv` for N minutes (default 30); if the PC dies, the last rows show what was happening |

The collection writes numbered files (`01_system_summary.txt`, `22_unexpected_shutdowns.csv`,
`dumps\`, ...) to `%USERPROFILE%\Documents\diagnostics\collection_<stamp>\` and zips it:
system and hardware summary, RAM sticks, video, disks and SMART counters, drivers, event logs
(critical and error, unexpected shutdowns such as Kernel-Power 41, WHEA, thermal, Office),
Reliability Monitor, minidumps and WER reports, power settings, installed software, updates,
startup items, and `DISM /CheckHealth`; every event query stops at `-Days`. `errors.txt` lists what
could not be read: every error PowerShell recorded (`$Error`, including a missing `Memory.dmp` or
an unknown thermal class) and every native command that exited non-zero, except `sfc` and
`chkdsk`, whose exit code is a finding (corrupt files, disk errors) and goes at the end of their
own file instead; event logs and
providers with nothing to report, and the checks marked `-ErrorAction Ignore`, are left out.
The ten steps are numbered `[n/10]`. At the end it asks `y`/`n` before running the only step
that changes the system: `DISM /RestoreHealth` plus `sfc /scannow` (admin only, 20 to 50 minutes,
needs internet), with the SFC lines of `CBS.log`.

## Pitfalls

- A `try` / `catch` sees neither a native command that fails (it only sets `$LASTEXITCODE`,
  read by `Save-Exit`) nor a cmdlet error under `$ErrorActionPreference = 'Continue'`, so
  `errors.txt` is built from `$Error` and those exit codes, not from the `catch` blocks.
- `sfc` and `DISM` write UTF-16 with NUL bytes when redirected; the script runs them through
  `cmd /c` and strips the NULs so the logs read as text.
- The ZIP holds computer and user names, hardware serial numbers, event messages (which can
  quote paths and accounts), installed programs, and minidumps and WER reports, whose memory
  fragments can hold anything the crashed program had open. The script says so at the end;
  read it before sharing.
- No comments here either, so usage lives in this doc, not in a `<# #>` help block.

## Checks

None in `tests/` (macOS runs them); check by hand on Windows: run it, answer `n`, and open the ZIP
and `errors.txt`.

## Changing it

Keep it one read-only script: a new collection step is a `Save-Csv` or `Get-Ev` line in the
numbered section it belongs to; anything that changes the system goes behind the final `y`/`n`.
