# Windows

Two standalone PowerShell scripts to debug the health of a Windows 11 PC (sudden shutdowns,
blue screens, crashes, broken settings). They are the one thing here that is not for macOS:
nothing installs, links or tests them, and no other context depends on them.

## Language

- **check**: one line of `check-health.ps1`'s verdict, with a status: `OK`, `INFO` (worth
  knowing, not a problem), `WARN`, `FAIL`, or `SKIP` (could not check, usually no admin).
- **collection**: the raw data `collect-diagnostics.ps1` saves for reading later or sharing.

## Files

| Path | Holds |
|---|---|
| `windows/check-health.ps1` | the verdict: about 70 read-only checks with a status each, in under a minute |
| `windows/collect-diagnostics.ps1` | the raw data: collector, monitor and the optional repair |

Start with `check-health.ps1`; when it finds blue screens or shutdowns, `collect-diagnostics.ps1`
gathers the dumps and logs to read, and is the one that repairs.

## Requirements

Both scripts run on a stock Windows 11 with nothing installed: everything they call ships with
Windows (Windows PowerShell 5.1 and its built-in modules Storage, PnpDevice, Dism, Defender,
NetSecurity, DnsClient, Appx and SecureBoot, plus `pnputil`, `driverquery`, `powercfg`,
`winmgmt`, `sfc`, `chkdsk` and `DISM`). What is missing only turns a check into `SKIP` or skips
one step; nothing else breaks. For the complete result:

| Need | For | How to get it | Without it |
|---|---|---|---|
| Administrator | DISM, WMI, Secure Boot, TPM, .NET 3.5, minidumps, WER reports, the repair | Start > right-click > Terminal (Admin) | those checks are `SKIP`, the dumps are not copied |
| Scripts allowed to run | running a `.ps1` at all | `-ExecutionPolicy Bypass` on each command, as below; nothing to change system-wide | Windows refuses to run the script |
| WinDbg | `collect-diagnostics.ps1` naming the driver behind each blue screen (`34_dump_analysis.csv`) | `winget install Microsoft.WinDbg` (no admin needed); winget comes with App Installer from the Microsoft Store | dumps are copied but not analyzed |
| Internet | debug symbols (`msdl.microsoft.com`), the DISM repair, the Windows Update driver search, the DNS check | | dump analysis names fewer modules, the repair fails, those two checks are `SKIP` / `WARN` |
| Crash dumps on, a page file, Storage Sense not deleting dumps | minidumps to exist at all | System > About > Advanced system settings > Startup and Recovery: "Small memory dump"; Settings > System > Storage > Storage Sense: leave system error dump files alone | nothing to analyze; `check-health.ps1` warns about all three |
| Windows Update service | the driver update search | it is on by default (`wuauserv`, Manual) | `Driver updates` is `SKIP` |
| NVIDIA driver (`nvidia-smi`) | GPU temperature and power in `-Monitor` | comes with the NVIDIA driver | the GPU column stays empty; Intel and AMD GPUs have no equivalent |

Once per machine, in any PowerShell:

```powershell
winget install Microsoft.WinDbg
```

Then check that the debugger is there (the scripts look for `cdb.exe` in the WinDbg package and
in the Windows SDK's `Windows Kits\10\Debuggers\x64`):

```powershell
Get-ChildItem (Get-AppxPackage Microsoft.WinDbg).InstallLocation -Recurse -Filter cdb.exe
```

## How it works

Run both in PowerShell as Administrator; without it, the checks and data that need it are
skipped (DISM, WMI, Secure Boot, TPM, .NET 3.5, minidumps, WER reports).

### check-health.ps1

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\check-health.ps1
```

| Parameter | Does |
|---|---|
| none | every check below, events of the last `-Days` days (default 30) |
| `-Deep` | also `sfc /verifyonly` and `chkdsk /scan` (several minutes) |

| Area | Checks |
|---|---|
| System | version and support, activation, pending restart, uptime, Fast Startup, last update, failed updates, stability index |
| Integrity | component store (`Repair-WindowsImage -CheckHealth`), WMI repository; `-Deep`: SFC, chkdsk |
| Hardware and compatibility | 64-bit, UEFI, Secure Boot, TPM 2.0, memory, memory modules (mixed kits, single channel, speed against rated), BIOS age |
| Drivers | Device Manager problem codes, unsigned drivers, missing or old graphics driver, running third-party kernel drivers (known troublemakers, older than three years), services and drivers that fail to start, ghost devices, driver updates Windows Update offers, Driver Verifier left on |
| Disks | health, wear and temperature, free space, dirty bit, page file, crash dumps on |
| Registry | `.exe` / `.bat` / `.lnk` associations, Winlogon shell, IFEO debugger redirections, AppInit DLLs, policies blocking Task Manager / regedit / cmd / Defender / updates, Run, App Paths, uninstall, service, ServiceDll and driver entries pointing to missing files, user folders |
| Defaults | core services present and enabled, system programs, PATH, TEMP, .NET 4.8 and 3.5, Visual C++ runtime, DirectX 9 extras, WebView2, winget, Store |
| Security and network | antivirus, memory integrity (HVCI) and the vulnerable driver blocklist, unsigned code blocked from loading into other programs, firewall, UAC, hosts file, proxy, DNS |
| Problems | blue screens, Kernel-Power 41, WHEA, disk and NTFS errors, graphics driver resets, app crashes, new minidumps and the ones that were deleted |

It prints each check, then a summary with the `FAIL` and `WARN` lines, and saves the same,
worst first, to `Documents\diagnostics\health_<stamp>.txt`. It changes nothing.

### collect-diagnostics.ps1

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\collect-diagnostics.ps1
```

| Parameter | Does |
|---|---|
| none | read-only collection of the last `-Days` days (default 30) |
| `-Deep` | also `sfc /verifyonly` and `chkdsk /scan` (several minutes) |
| `-Monitor -Minutes N` | only logs CPU, RAM, temperature, NVIDIA GPU and the busiest process every 5 s to `Documents\diagnostics\monitor_<stamp>.csv` for N minutes (default 30); if the PC dies, the last rows show what was happening |

The collection writes numbered files (`01_system_summary.txt`, `22_unexpected_shutdowns.csv`,
`dumps\`, ...) to `Documents\diagnostics\collection_<stamp>\` and zips it:
system and hardware summary, RAM sticks, video, disks and SMART counters, drivers (PnP list,
`driverquery`, third-party kernel drivers with company, version and signer, the driver store,
devices with problems, ghost devices, the tail of `setupapi.dev.log`), event logs (critical and
error, unexpected shutdowns such as Kernel-Power 41, WHEA, thermal, Office, service and driver
start failures, Kernel-PnP device problems, Code Integrity blocks), Reliability Monitor,
minidumps and WER reports, power settings, installed software, updates, startup items, and
`DISM /CheckHealth`; every event query stops at `-Days`. `errors.txt` lists what could not be
read: every error PowerShell recorded (`$Error`, including a missing `Memory.dmp` or an unknown
thermal class) and every native command that exited non-zero, except `sfc` and `chkdsk`, whose
exit code is a finding (corrupt files, disk errors) and goes at the end of their own file
instead; event logs and providers with nothing to report, and the checks marked
`-ErrorAction Ignore`, are left out.

With WinDbg installed (`winget install Microsoft.WinDbg`), it runs `cdb -z <dump> -c "!analyze -v"`
on each copied minidump, saves the full output in `dump_analysis\`, and sums them up in
`34_dump_analysis.csv`: bug check, faulting module and image (the driver to blame), process and
failure bucket. Without WinDbg, `34_dump_analysis.txt` says how to install it; the first run
downloads symbols to `%TEMP%\symbols`, and each dump has five minutes.

The ten steps are numbered `[n/10]`. At the end it asks `y`/`n` before running the only step
that changes the system: `DISM /RestoreHealth` plus `sfc /scannow` (admin only, 20 to 50 minutes,
needs internet), with the SFC lines of `CBS.log`.

## Pitfalls

- `Documents` is the folder Windows reports (`[Environment]::GetFolderPath('MyDocuments')`), not
  `%USERPROFILE%\Documents`: with OneDrive backing it up, the Documents a user opens is
  `OneDrive\Documents`, and the report landed in a folder they never saw.
- `Read-Host` returns nothing, or fails, without a console (a remote session, a management tool);
  the repair question then counts as `n`, since the loop that asks again never ended, and
  `70_repair_skipped.txt` says why.
- A `try` / `catch` sees neither a native command that fails (it only sets `$LASTEXITCODE`,
  read by `Save-Exit`) nor a cmdlet error under `$ErrorActionPreference = 'Continue'`, so
  `errors.txt` is built from `$Error` and those exit codes, not from the `catch` blocks.
- The ZIP holds computer and user names, hardware serial numbers, event messages (which can
  quote paths and accounts), installed programs, and minidumps and WER reports, whose memory
  fragments can hold anything the crashed program had open. The script says so at the end;
  read it before sharing.
- Windows text is localized, so `check-health.ps1` never parses command output: it reads
  objects (`Repair-WindowsImage`, CIM), exit codes (`winmgmt`, `chkdsk`) or `CBS.log`, which
  is always English.
- `sfc` and `DISM` write UTF-16 with NUL bytes when redirected; `collect-diagnostics.ps1` runs
  them through `cmd /c` and strips the NULs so the logs read as text.
- `$minSupportedBuild` in `check-health.ps1` (26200, 25H2) goes stale; raise it when a release
  leaves support.
- Windows Update event 20 also logs Microsoft Store app updates, which fail harmlessly when
  the app is open (`0x80073D02`); their titles start with a Store ID (`9NMPJ99VJBWV-...`), so
  `Failed updates` counts only the rest and lists the Store ones as `INFO`.
- Fast Startup keeps the kernel across a shutdown, so uptime and driver state only reset on
  Restart; the check says so.
- WMI (`Win32_Service`, `Win32_SystemDriver`) leaves out services whose file is gone, so the
  missing-file check reads `HKLM\SYSTEM\CurrentControlSet\Services` itself; it first missed a
  `PRI-Driver` that failed to start 260 times.
- Event properties are positional and differ per event: in Kernel-PnP 219 the driver is
  property 4, in Code Integrity 3033 the blocked file is 1 and the process 3. Check with
  `$ev.Properties` before reading a new one.
- Third-party means neither the company is Microsoft nor the signer is `CN=Microsoft Windows`
  (Windows' own files, some with no company); WHQL drivers from other makers are signed by
  "Microsoft Windows Hardware Compatibility Publisher" and stay in.
- `Blocked code` ignores a program blocking its own files (Chrome blocks DLLs from its own
  folder all the time); what is left is one program injecting into others, such as Warsaw.
- `Start failures` ignores `dam` (Desktop Activity Moderator), which never loads on desktops.
- The minidump check is admin-only and fails as `SKIP` when it cannot read the folder, so an
  unreadable folder never looks like "no dumps"; blue screens whose dump file is gone mean
  Storage Sense or Disk Cleanup deleted it.
- Registry checks that find files missing are warnings, not proof: an uninstalled program often
  leaves a Run or uninstall entry behind, which is harmless clutter.
- No comments here either, so usage lives in this doc, not in a `<# #>` help block.

## Checks

None in `tests/` (macOS runs them); check by hand on Windows: parse both with
`[System.Management.Automation.Language.Parser]::ParseFile`, run `check-health.ps1` with and
without admin, and run `collect-diagnostics.ps1` as admin with WinDbg installed and a minidump
present, answer `n`, and open `34_dump_analysis.csv`, `errors.txt` and the ZIP.

## Changing it

- A new check in `check-health.ps1` is a `Test-Check 'Name' { ... }` in its area that calls
  `Add-Result` with a status and one line (`Add-Count` for event counts, `Add-Missing` for
  lists of broken entries); add `-Admin` when it needs it, and a row above.
- A driver known to cause blue screens is a pattern on its file name and a label in `$suspects`
  of `check-health.ps1`.
- A new collection step is a `Save-Csv` or `Get-Ev` line in the numbered section of
  `collect-diagnostics.ps1` it belongs to.
- Both stay read-only; anything that changes the system goes behind the final `y`/`n` of
  `collect-diagnostics.ps1`.
