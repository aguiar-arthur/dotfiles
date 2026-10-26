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

The collection writes numbered files (`01_system_summary.txt`, `22_unexpected_shutdowns_all.csv`,
`dumps\`, ...) to `%USERPROFILE%\Documents\diagnostics\collection_<stamp>\` and zips it:
system and hardware summary, RAM sticks, video, disks and SMART counters, drivers, event logs
(critical and error, unexpected shutdowns such as Kernel-Power 41, WHEA, thermal, Office),
Reliability Monitor, minidumps and WER reports, power settings, installed software, updates,
startup items, and `DISM /CheckHealth`. At the end it asks `y`/`n` before running the only step
that changes the system: `DISM /RestoreHealth` plus `sfc /scannow` (admin only, 20 to 50 minutes,
needs internet), with the SFC lines of `CBS.log`.

## Pitfalls

- `sfc` and `DISM` write UTF-16 with NUL bytes when redirected; the script runs them through
  `cmd /c` and strips the NULs so the logs read as text.
- The output holds the computer and user names (no passwords); look before sharing the ZIP.
- No comments here either, so usage lives in this doc, not in a `<# #>` help block.

## Checks

None in `tests/` (macOS runs them); check by hand on Windows: run it without parameters, answer
`n`, and open the ZIP.

## Changing it

Keep it one read-only script: a new collection step is a `Save-Csv` or `Get-Ev` line in the
numbered section it belongs to; anything that changes the system goes behind the final `y`/`n`.
