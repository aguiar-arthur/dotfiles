param(
    [switch]$Deep,
    [switch]$Monitor,
    [int]$Minutes = 30,
    [int]$Days = 30
)

$ErrorActionPreference = 'Continue'
$base = Join-Path $env:USERPROFILE 'Documents\diagnostics'
$stamp = Get-Date -Format 'yyyyMMdd_HHmm'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'WARNING: not running as Administrator. Some data (minidumps, WER, DISM) may be missing.' -ForegroundColor Yellow
}

if ($Monitor) {
    New-Item -ItemType Directory -Force $base | Out-Null
    $csv = Join-Path $base "monitor_$stamp.csv"
    'time,cpu_pct,ram_free_mb,ram_used_pct,thermal_zone_c,gpu_nvidia,top_cpu_process,top_cpu_process_pct' | Set-Content $csv -Encoding UTF8
    $end = (Get-Date).AddMinutes($Minutes)
    $nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    Write-Host "Monitoring for $Minutes min. File: $csv" -ForegroundColor Cyan
    Write-Host 'Open the program or file that causes the problem now. Ctrl+C to stop.'
    while ((Get-Date) -lt $end) {
        try {
            $time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
            $os = Get-CimInstance Win32_OperatingSystem
            $free = [math]::Round($os.FreePhysicalMemory / 1024)
            $used = [math]::Round(100 * (1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize), 1)
            $temp = ''
            try {
                $tz = Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop
                $temp = ($tz | ForEach-Object { [math]::Round($_.Temperature - 273.15, 1) }) -join '|'
            } catch {}
            $gpu = ''
            if ($nvidia) {
                $gpu = (& nvidia-smi --query-gpu=temperature.gpu,power.draw,utilization.gpu --format=csv,noheader 2>$null) -join ';'
                $gpu = $gpu -replace ',', ';'
            }
            $top = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process |
                Where-Object { $_.Name -ne '_Total' -and $_.Name -ne 'Idle' } |
                Sort-Object PercentProcessorTime -Descending | Select-Object -First 1
            $line = '{0},{1},{2},{3},{4},{5},{6},{7}' -f $time, $cpu, $free, $used, $temp, $gpu, $top.Name, $top.PercentProcessorTime
            Add-Content -Path $csv -Value $line -Encoding UTF8
        } catch {}
        Start-Sleep -Seconds 5
    }
    Write-Host "Monitoring done: $csv" -ForegroundColor Green
    return
}

$out = Join-Path $base "collection_$stamp"
New-Item -ItemType Directory -Force $out | Out-Null
$start = Get-Date
Write-Host "Saving to: $out" -ForegroundColor Cyan

$Error.Clear()
$exitFailures = [System.Collections.Generic.List[string]]::new()

function Save-Exit($what) {
    if ($LASTEXITCODE) { $exitFailures.Add("${what}: exit code $LASTEXITCODE") }
}

function Save-Csv($data, $name) {
    try {
        if ($null -eq $data -or @($data).Count -eq 0) { "(no data)" | Out-File (Join-Path $out "$name.txt") -Encoding UTF8; return }
        @($data) | Export-Csv (Join-Path $out "$name.csv") -NoTypeInformation -Encoding UTF8
    } catch { "error: $_" | Out-File (Join-Path $out "$name.error.txt") -Encoding UTF8 }
}

function Get-Ev($filter, $name) {
    Write-Host "  events: $name"
    try {
        $ev = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, LogName,
                @{n='Message'; e={ ($_.Message -replace '\s+', ' ') }}
        Save-Csv $ev $name
    } catch {
        "no events found (or error): $($_.Exception.Message)" | Out-File (Join-Path $out "$name.txt") -Encoding UTF8
    }
}

$since = (Get-Date).AddDays(-$Days)

Write-Host '[1/10] Hardware and system'
$summary = [ordered]@{}
try {
    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $bb = Get-CimInstance Win32_BaseBoard
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor
    $summary['Computer'] = $cs.Name
    $summary['Manufacturer/Model'] = "$($cs.Manufacturer) / $($cs.Model)"
    $summary['Motherboard'] = "$($bb.Manufacturer) $($bb.Product)"
    $summary['BIOS'] = "$($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate))"
    $summary['Windows'] = "$($os.Caption) build $($os.BuildNumber) / installed $($os.InstallDate)"
    $summary['Last boot'] = $os.LastBootUpTime
    $summary['CPU'] = ($cpu | ForEach-Object { "$($_.Name) | $($_.NumberOfCores) cores | current clock $($_.CurrentClockSpeed) MHz / max $($_.MaxClockSpeed) MHz" }) -join ' ; '
    $summary['Total RAM (GB)'] = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
} catch {}
$summary.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $_.Value } | Out-File (Join-Path $out '01_system_summary.txt') -Encoding UTF8

Save-Csv (Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, DeviceLocator, Manufacturer, PartNumber, SerialNumber,
    @{n='CapacityGB'; e={ [math]::Round($_.Capacity / 1GB, 1) }}, Speed, ConfiguredClockSpeed, ConfiguredVoltage, MinVoltage, MaxVoltage, SMBIOSMemoryType) '02_ram_modules'
Save-Csv (Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, DriverDate, AdapterRAM, VideoProcessor, Status) '03_video'
Save-Csv (Get-CimInstance Win32_DiskDrive | Select-Object Model, InterfaceType, @{n='SizeGB'; e={ [math]::Round($_.Size / 1GB) }}, Status, FirmwareRevision) '04_disks'
Save-Csv (Get-CimInstance Win32_Battery -ErrorAction Ignore) '05_battery_ups'
Save-Csv (Get-CimInstance Win32_Fan -ErrorAction Ignore) '06_fans_wmi'
try {
    Save-Csv (Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop |
        Select-Object Name, @{n='TempC'; e={ [math]::Round($_.Temperature - 273.15, 1) }}) '07_thermal_zone_temperature'
} catch {}

Write-Host '[2/10] Disk health'
try {
    Save-Csv (Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus, @{n='SizeGB'; e={ [math]::Round($_.Size / 1GB) }}) '08_disk_health'
    $rel = Get-PhysicalDisk | ForEach-Object {
        $r = $_ | Get-StorageReliabilityCounter -ErrorAction Ignore
        if ($r) { [pscustomobject]@{ Disk = $_.FriendlyName; TempC = $r.Temperature; TempMaxC = $r.TemperatureMax; Wear = $r.Wear; PowerOnHours = $r.PowerOnHours; ReadErrors = $r.ReadErrorsTotal; WriteErrors = $r.WriteErrorsTotal } }
    }
    Save-Csv $rel '09_disk_smart_basic'
} catch {}
Save-Csv (Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus, @{n='FreeGB'; e={ [math]::Round($_.SizeRemaining / 1GB, 1) }}, @{n='TotalGB'; e={ [math]::Round($_.Size / 1GB, 1) }}) '10_volumes'

Write-Host '[3/10] Drivers'
Save-Csv (Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName } |
    Select-Object DeviceName, DeviceClass, Manufacturer, DriverVersion, DriverDate, InfName, IsSigned | Sort-Object DeviceClass, DeviceName) '11_drivers_pnp'
try { driverquery /v /fo csv | Out-File (Join-Path $out '12_driverquery.csv') -Encoding UTF8; Save-Exit 'driverquery' } catch {}

Write-Host '[4/10] Event logs'
Get-Ev @{ LogName = 'System'; Level = 1, 2; StartTime = $since } '20_system_critical_errors'
Get-Ev @{ LogName = 'System'; Level = 3; StartTime = $since } '21_system_warnings'
Get-Ev @{ LogName = 'System'; Id = 41, 1001, 6005, 6006, 6008, 6009, 1074, 1076; StartTime = $since } '22_unexpected_shutdowns'
Get-Ev @{ LogName = 'Application'; Level = 1, 2; StartTime = $since } '23_application_critical_errors'
Get-Ev @{ LogName = 'Application'; Id = 1000, 1001, 1002; StartTime = $since } '24_application_crashes_wer'
Get-Ev @{ LogName = 'Microsoft-Windows-WHEA-Logger/Operational'; StartTime = $since } '25_whea_hardware_operational'
Get-Ev @{ LogName = 'Microsoft-Windows-Kernel-Power/Thermal-Operational'; StartTime = $since } '26_kernel_power_thermal'

$providers = 'Microsoft-Windows-WHEA-Logger', 'disk', 'Ntfs', 'storahci', 'stornvme', 'nvlddmkm', 'amdkmdag', 'amdwddmg', 'igfx', 'Display',
    'volmgr', 'Microsoft-Windows-Kernel-Processor-Power', 'Microsoft-Windows-Kernel-PnP', 'Microsoft-Windows-Kernel-Power',
    'Microsoft-Windows-MemoryDiagnostics-Results', 'Microsoft-Windows-WER-SystemErrorReporting', 'BugCheck', 'Microsoft-Windows-Hyper-V-Hypervisor',
    'Microsoft-Windows-DriverFrameworks-UserMode', 'Microsoft-Windows-Kernel-Boot', 'Microsoft-Windows-Kernel-General'
$all = @()
foreach ($p in $providers) {
    try {
        $all += Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $p; StartTime = $since } -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, LogName, @{n='Message'; e={ ($_.Message -replace '\s+', ' ') }}
    } catch {}
}
Save-Csv ($all | Sort-Object TimeCreated -Descending) '27_system_relevant_providers'

$office = @()
foreach ($p in 'Excel', 'Microsoft Office*', 'Office*', 'Outlook', 'Microsoft Office Alerts') {
    try {
        $office += Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = $p; StartTime = $since } -ErrorAction Stop |
            Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{n='Message'; e={ ($_.Message -replace '\s+', ' ') }}
    } catch {}
}
Save-Csv $office '28_office_excel_events'

Write-Host '[5/10] Reliability history'
try {
    Save-Csv (Get-CimInstance Win32_ReliabilityRecords | Where-Object { $_.TimeGenerated -gt $since } |
        Select-Object TimeGenerated, SourceName, EventIdentifier, ProductName, @{n='Message'; e={ ($_.Message -replace '\s+', ' ') }} |
        Sort-Object TimeGenerated -Descending) '30_reliability_monitor'
} catch {}

Write-Host '[6/10] Crash dumps'
$dumpDir = Join-Path $out 'dumps'
New-Item -ItemType Directory -Force $dumpDir | Out-Null
try { Copy-Item "$env:SystemRoot\Minidump\*.dmp" $dumpDir -ErrorAction Stop } catch { "no minidumps (or no permission)" | Out-File (Join-Path $dumpDir 'README.txt') }
try {
    Get-ChildItem "$env:SystemRoot\Memory.dmp" -ErrorAction Stop | Select-Object FullName, Length, LastWriteTime | Export-Csv (Join-Path $out '31_memory_dmp_info.csv') -NoTypeInformation -Encoding UTF8
} catch {}
try {
    Get-ChildItem "$env:SystemRoot\LiveKernelReports" -Recurse -ErrorAction Stop -File |
        Select-Object FullName, Length, LastWriteTime | Export-Csv (Join-Path $out '32_livekernelreports.csv') -NoTypeInformation -Encoding UTF8
} catch {}
try {
    foreach ($d in "$env:ProgramData\Microsoft\Windows\WER\ReportArchive", "$env:ProgramData\Microsoft\Windows\WER\ReportQueue") {
        if (Test-Path $d) {
            Get-ChildItem $d -Recurse -Filter Report.wer -ErrorAction Ignore | Where-Object { $_.LastWriteTime -gt $since } | ForEach-Object {
                $dest = Join-Path $dumpDir ("WER_" + $_.Directory.Name + ".wer")
                Copy-Item $_.FullName $dest -ErrorAction Ignore
            }
        }
    }
} catch {}
try {
    Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' | Select-Object * -ExcludeProperty PS* |
        Out-File (Join-Path $out '33_crashcontrol_dump_settings.txt') -Encoding UTF8
} catch {}

Write-Host '[7/10] Power'
try { powercfg /a | Out-File (Join-Path $out '40_powercfg_states.txt') -Encoding UTF8; Save-Exit 'powercfg /a' } catch {}
try { powercfg /getactivescheme | Out-File (Join-Path $out '41_powercfg_active_scheme.txt') -Encoding UTF8; Save-Exit 'powercfg /getactivescheme' } catch {}
try { powercfg /requests | Out-File (Join-Path $out '42_powercfg_requests.txt') -Encoding UTF8; Save-Exit 'powercfg /requests' } catch {}
try { powercfg /lastwake | Out-File (Join-Path $out '43_powercfg_lastwake.txt') -Encoding UTF8; Save-Exit 'powercfg /lastwake' } catch {}
try { powercfg /query SCHEME_CURRENT SUB_PROCESSOR | Out-File (Join-Path $out '44_powercfg_cpu.txt') -Encoding UTF8; Save-Exit 'powercfg /query' } catch {}

Write-Host '[8/10] Installed software and updates'
try {
    $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    Save-Csv (Get-ItemProperty $keys -ErrorAction Ignore | Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName) '50_installed_programs'
} catch {}
Save-Csv (Get-HotFix | Select-Object HotFixID, Description, InstalledOn | Sort-Object InstalledOn -Descending) '51_windows_updates'
Save-Csv (Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User) '52_startup_programs'
Save-Csv (Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | Select-Object Name, DisplayName, State, StartMode, PathName) '53_auto_services_stopped'
try {
    Save-Csv (Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 25 Name, Id, @{n='RAM_MB'; e={ [math]::Round($_.WorkingSet64 / 1MB) }}, CPU) '54_top_ram_processes'
} catch {}

Write-Host '[9/10] System integrity'
try { DISM /Online /Cleanup-Image /CheckHealth | Out-File (Join-Path $out '60_dism_checkhealth.txt') -Encoding UTF8; Save-Exit 'DISM /CheckHealth' } catch {}
if ($Deep) {
    Write-Host '  running sfc /verifyonly (may take a while)...'
    $tmp = Join-Path $out '61_sfc_verifyonly.txt'
    cmd /c "sfc /verifyonly > `"$tmp`" 2>&1"
    $code = $LASTEXITCODE
    try { (Get-Content $tmp -Raw) -replace "`0", '' | Set-Content $tmp -Encoding UTF8 } catch {}
    "exit code: $code" | Add-Content $tmp -Encoding UTF8
    Write-Host '  running chkdsk /scan (read-only)...'
    $chk = Join-Path $out '62_chkdsk_scan.txt'
    try { chkdsk C: /scan | Out-File $chk -Encoding UTF8; "exit code: $LASTEXITCODE" | Add-Content $chk -Encoding UTF8 } catch {}
} else {
    'Skipped. Run again with -Deep to include sfc /verifyonly and chkdsk /scan.' | Out-File (Join-Path $out '61_sfc_skipped.txt') -Encoding UTF8
}

$answer = ''
while ($answer -ne 'y' -and $answer -ne 'n') {
    Write-Host ''
    Write-Host 'Run the Windows repair now? (DISM /RestoreHealth + sfc /scannow)' -ForegroundColor Cyan
    Write-Host 'It can take 20 to 50 minutes and DISM needs internet.'
    $answer = (Read-Host 'Answer y (yes) or n (no)').Trim().ToLower()
}
if ($answer -eq 'n') {
    'Repair declined by the user.' | Out-File (Join-Path $out '70_repair_skipped.txt') -Encoding UTF8
    Write-Host '  Repair skipped.'
} elseif (-not $isAdmin) {
    Write-Host '[10/10] Repair skipped: needs PowerShell as Administrator.' -ForegroundColor Yellow
    'Skipped: no administrator privilege.' | Out-File (Join-Path $out '70_repair_not_admin.txt') -Encoding UTF8
} else {
    Write-Host '[10/10] Repairing Windows: DISM /RestoreHealth (10-30 min, needs internet)...' -ForegroundColor Cyan
    $dismLog = Join-Path $out '70_dism_restorehealth.txt'
    cmd /c "DISM /Online /Cleanup-Image /RestoreHealth > `"$dismLog`" 2>&1"
    Save-Exit 'DISM /RestoreHealth'
    try { (Get-Content $dismLog -Raw) -replace "`0", '' | Set-Content $dismLog -Encoding UTF8 } catch {}

    Write-Host '[10/10] Running sfc /scannow (10-20 min)...' -ForegroundColor Cyan
    $sfcLog = Join-Path $out '71_sfc_scannow.txt'
    cmd /c "sfc /scannow > `"$sfcLog`" 2>&1"
    $code = $LASTEXITCODE
    try { (Get-Content $sfcLog -Raw) -replace "`0", '' | Set-Content $sfcLog -Encoding UTF8 } catch {}
    "exit code: $code" | Add-Content $sfcLog -Encoding UTF8

    try {
        Select-String -Path "$env:SystemRoot\Logs\CBS\CBS.log" -Pattern '\[SR\]' -ErrorAction Stop |
            Select-Object -Last 3000 -ExpandProperty Line |
            Out-File (Join-Path $out '72_cbs_sfc_details.txt') -Encoding UTF8
    } catch {}
    Write-Host '  Repair done. If sfc fixed files, restart the PC.' -ForegroundColor Green
}

$recorded = @($Error | Where-Object { $_.FullyQualifiedErrorId -notmatch '^NoMatching(Events|Providers|Logs)Found' })
[array]::Reverse($recorded)
$failures = @($recorded | ForEach-Object { '{0}: {1}' -f $_.InvocationInfo.MyCommand, $_.Exception.Message }) + @($exitFailures)
if ($failures.Count -gt 0) {
    $failures | Out-File (Join-Path $out 'errors.txt') -Encoding UTF8
    Write-Host "$($failures.Count) problem(s) while collecting: see errors.txt" -ForegroundColor Yellow
}

$zip = "$out.zip"
try {
    Compress-Archive -Path "$out\*" -DestinationPath $zip -Force
    Write-Host "`nDone in $([math]::Round(((Get-Date) - $start).TotalSeconds)) s." -ForegroundColor Green
    Write-Host "Folder: $out"
    Write-Host "ZIP:    $zip"
} catch {
    Write-Host "Collection finished in: $out (could not create the ZIP: $_)" -ForegroundColor Yellow
}
Write-Host 'Note: the files hold computer and user names, hardware serial numbers, event messages, installed programs and crash dumps (which can contain pieces of memory). Read them before you share them.'
