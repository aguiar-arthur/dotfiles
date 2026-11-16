param(
    [switch]$Deep,
    [int]$Days = 30
)

$ErrorActionPreference = 'Continue'
$minSupportedBuild = 26200
$since = (Get-Date).AddDays(-$Days)
$stamp = Get-Date -Format 'yyyyMMdd_HHmm'
$documents = [Environment]::GetFolderPath('MyDocuments')
if (-not $documents) { $documents = Join-Path $env:USERPROFILE 'Documents' }
$base = Join-Path $documents 'diagnostics'
$results = New-Object System.Collections.Generic.List[object]
$colors = @{ OK = 'Green'; INFO = 'Cyan'; WARN = 'Yellow'; FAIL = 'Red'; SKIP = 'DarkGray' }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host 'Windows health check (read-only, nothing is changed)' -ForegroundColor White
if (-not $isAdmin) {
    Write-Host 'WARNING: not running as Administrator. Checks that need it are skipped.' -ForegroundColor Yellow
}

function Add-Result($status, $detail) {
    $results.Add([pscustomobject]@{ Index = $results.Count; Status = $status; Area = $area; Check = $check; Detail = $detail })
    Write-Host ('  [{0}] {1}: {2}' -f $status, $check, $detail) -ForegroundColor $colors[$status]
}

function Start-Area($name) {
    $script:area = $name
    Write-Host "`n$name" -ForegroundColor White
}

function Test-Check($check, [scriptblock]$block, [switch]$Admin) {
    if ($Admin -and -not $isAdmin) { Add-Result 'SKIP' 'needs PowerShell as Administrator'; return }
    try { & $block } catch { Add-Result 'SKIP' "could not check: $($_.Exception.Message)" }
}

function Get-RegValue($path, $name) {
    $key = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($key) { $key.GetValue($name) }
}

function Get-EventCount($filter) {
    try { @(Get-WinEvent -FilterHashtable $filter -ErrorAction Stop).Count } catch { 0 }
}

function Add-Count($count, $what, $failAt) {
    if ($count -eq 0) { Add-Result 'OK' "no $what in the last $Days days" }
    elseif ($count -lt $failAt) { Add-Result 'WARN' "$count $what in the last $Days days" }
    else { Add-Result 'FAIL' "$count $what in the last $Days days" }
}

function Resolve-CommandPath($line) {
    if (-not $line) { return $null }
    $s = [Environment]::ExpandEnvironmentVariables([string]$line).Trim()
    if ($s.StartsWith('"')) {
        $end = $s.IndexOf('"', 1)
        if ($end -lt 0) { return $null }
        $s = $s.Substring(1, $end - 1)
    } else {
        $m = [regex]::Match($s, '^(.+?\.(exe|dll|sys|com|bat|cmd|scr))(?=\s|,|$)', 'IgnoreCase')
        if (-not $m.Success) { return $null }
        $s = $m.Groups[1].Value
    }
    $s = $s -replace '^\\\?\?\\', ''
    $s = $s -replace '(?i)^\\SystemRoot\\', ($env:SystemRoot + '\')
    $s = $s -replace '(?i)^System32\\', ($env:SystemRoot + '\System32\')
    if ($s -notmatch '^[A-Za-z]:\\') { return $null }
    $s
}

function Test-Missing($line) {
    $p = Resolve-CommandPath $line
    $p -and -not (Test-Path -LiteralPath $p)
}

function Add-Missing($what, $items) {
    $items = @($items | Where-Object { $_ } | Sort-Object -Unique)
    if ($items.Count -eq 0) { Add-Result 'OK' "no $what point to missing files" }
    else { Add-Result 'WARN' ('{0} {1} point to missing files: {2}' -f $items.Count, $what, (($items | Select-Object -First 8) -join '; ')) }
}

Start-Area 'System'
$cv = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
Test-Check 'Windows version' {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $text = '{0} {1} build {2}.{3}' -f $os.Caption, (Get-RegValue $cv 'DisplayVersion'), $os.BuildNumber, (Get-RegValue $cv 'UBR')
    if ([int]$os.BuildNumber -lt $minSupportedBuild) { Add-Result 'WARN' "$text is older than 25H2 and may be out of support" }
    else { Add-Result 'OK' $text }
}
Test-Check 'Activation' {
    $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop |
        Select-Object -First 1
    if ($lic -and $lic.LicenseStatus -eq 1) { Add-Result 'OK' 'Windows is activated' } else { Add-Result 'WARN' 'Windows is not activated' }
}
Test-Check 'Pending restart' {
    $pending = @()
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $pending += 'servicing' }
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $pending += 'Windows Update' }
    $renames = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' 'PendingFileRenameOperations'
    if ($pending) { Add-Result 'WARN' ('restart pending ({0}); restart before trusting the other results' -f ($pending -join ', ')) }
    elseif ($renames) { Add-Result 'INFO' 'files waiting to be replaced at the next restart' }
    else { Add-Result 'OK' 'no restart pending' }
}
Test-Check 'Uptime' {
    $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    if ($up.TotalDays -gt 14) { Add-Result 'WARN' ('up for {0:N0} days; restart to finish updates' -f $up.TotalDays) }
    else { Add-Result 'OK' ('up for {0:N1} days' -f $up.TotalDays) }
}
Test-Check 'Fast Startup' {
    if ((Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled') -eq 1) {
        Add-Result 'INFO' 'on: shutting down does not restart Windows or reload drivers; use Restart when debugging'
    } else { Add-Result 'OK' 'off' }
}
Test-Check 'Last update' {
    $last = Get-HotFix -ErrorAction Stop | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if (-not $last) { Add-Result 'WARN' 'no installed updates found' }
    elseif ($last.InstalledOn -lt (Get-Date).AddDays(-60)) { Add-Result 'WARN' ('{0} on {1:yyyy-MM-dd}, over 60 days ago' -f $last.HotFixID, $last.InstalledOn) }
    else { Add-Result 'OK' ('{0} on {1:yyyy-MM-dd}' -f $last.HotFixID, $last.InstalledOn) }
}
Test-Check 'Failed updates' {
    $failed = @()
    try { $failed = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WindowsUpdateClient'; Id = 20; StartTime = $since } -ErrorAction Stop) } catch {}
    $store = @($failed | Where-Object { "$($_.Properties[1].Value)" -match '^9[A-Z0-9]{11}-' })
    Add-Count ($failed.Count - $store.Count) 'failed Windows updates' 3
    if ($store.Count) {
        $apps = $store | ForEach-Object { "$($_.Properties[1].Value)" -replace '^9[A-Z0-9]{11}-', '' } | Sort-Object -Unique
        Add-Result 'INFO' ('{0} Store app updates failed, usually because the app was open: {1}' -f $store.Count, ($apps -join ', '))
    }
}
Test-Check 'Stability index' {
    $m = Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction Stop | Sort-Object TimeGenerated -Descending | Select-Object -First 1
    if (-not $m) { Add-Result 'INFO' 'no data (Reliability Monitor may be off)' }
    elseif ($m.SystemStabilityIndex -lt 5) { Add-Result 'WARN' ('{0:N1} of 10; open Reliability Monitor (perfmon /rel) to see why' -f $m.SystemStabilityIndex) }
    else { Add-Result 'OK' ('{0:N1} of 10' -f $m.SystemStabilityIndex) }
}

Start-Area 'Integrity'
Test-Check 'Component store (DISM)' {
    $state = "$((Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop).ImageHealthState)"
    if ($state -eq 'Healthy') { Add-Result 'OK' 'healthy' }
    else { Add-Result 'FAIL' "$state; run collect-diagnostics.ps1 and answer y to repair" }
} -Admin
Test-Check 'WMI repository' {
    $null = winmgmt /verifyrepository
    if ($LASTEXITCODE -eq 0) { Add-Result 'OK' 'consistent' } else { Add-Result 'FAIL' "inconsistent (winmgmt exit $LASTEXITCODE)" }
} -Admin
if ($Deep) {
    Test-Check 'System files (sfc /verifyonly)' {
        $started = (Get-Date).AddSeconds(-5)
        Write-Host '  running sfc /verifyonly (several minutes)...'
        cmd /c 'sfc /verifyonly >nul 2>&1'
        $bad = @(Select-String -Path "$env:SystemRoot\Logs\CBS\CBS.log" -Pattern '\[SR\].*(corrupt|Cannot|damaged|do not match)' -ErrorAction Stop |
            Where-Object { $_.Line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})' -and [datetime]$Matches[1] -ge $started })
        if ($bad.Count) { Add-Result 'FAIL' "$($bad.Count) integrity problems in CBS.log; run collect-diagnostics.ps1 and answer y to repair" }
        else { Add-Result 'OK' 'no integrity violations' }
    } -Admin
    Test-Check 'File system (chkdsk /scan)' {
        Write-Host '  running chkdsk /scan (several minutes)...'
        $null = chkdsk $env:SystemDrive /scan
        if ($LASTEXITCODE -eq 0) { Add-Result 'OK' "$env:SystemDrive has no errors" }
        else { Add-Result 'WARN' "chkdsk found problems on $env:SystemDrive (exit $LASTEXITCODE)" }
    } -Admin
}

Start-Area 'Hardware and compatibility'
Test-Check '64-bit' {
    if ([Environment]::Is64BitOperatingSystem) { Add-Result 'OK' '64-bit Windows' } else { Add-Result 'FAIL' '32-bit Windows; Windows 11 needs 64-bit' }
}
Test-Check 'Firmware' {
    if ($env:firmware_type -eq 'UEFI') { Add-Result 'OK' 'UEFI' } else { Add-Result 'WARN' "$env:firmware_type; Windows 11 needs UEFI" }
}
Test-Check 'Secure Boot' {
    try { $on = Confirm-SecureBootUEFI -ErrorAction Stop } catch { Add-Result 'WARN' 'not supported (legacy BIOS)'; return }
    if ($on) { Add-Result 'OK' 'on' } else { Add-Result 'WARN' 'off; turn it on in the UEFI setup' }
} -Admin
Test-Check 'TPM' {
    $tpm = Get-CimInstance -Namespace root/cimv2/security/microsofttpm -ClassName Win32_Tpm -ErrorAction Stop
    if (-not $tpm) { Add-Result 'FAIL' 'no TPM found; turn on fTPM or PTT in the UEFI setup'; return }
    $ver = ($tpm.SpecVersion -split ',')[0].Trim()
    if (-not $tpm.IsEnabled_InitialValue) { Add-Result 'WARN' "TPM $ver is disabled" }
    elseif ([double]$ver -lt 2) { Add-Result 'FAIL' "TPM $ver; Windows 11 needs 2.0" }
    else { Add-Result 'OK' "TPM $ver" }
} -Admin
Test-Check 'Memory' {
    $gb = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB, 1)
    if ($gb -lt 4) { Add-Result 'FAIL' "$gb GB; Windows 11 needs 4 GB" }
    elseif ($gb -lt 8) { Add-Result 'WARN' "$gb GB; 8 GB or more is comfortable" }
    else { Add-Result 'OK' "$gb GB" }
}
Test-Check 'Memory modules' {
    $mods = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop)
    $slots = (Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction Stop | Measure-Object MemoryDevices -Sum).Sum
    $parts = @($mods | ForEach-Object { "$($_.PartNumber)".Trim() } | Sort-Object -Unique)
    $text = '{0} of {1} slots: {2}' -f $mods.Count, $slots, (($mods | ForEach-Object { '{0} {1} GB {2}/{3} MT/s' -f $_.DeviceLocator, [math]::Round($_.Capacity / 1GB), $_.ConfiguredClockSpeed, $_.Speed }) -join '; ')
    if ($parts.Count -gt 1) { Add-Result 'WARN' "$text; mixed modules ($($parts -join ', ')) are a common cause of instability" }
    elseif ($mods.Count -eq 1 -and $slots -gt 1) { Add-Result 'INFO' "$text; one module runs single channel, which is slower but stable" }
    else { Add-Result 'OK' $text }
}
Test-Check 'BIOS' {
    $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
    $board = Get-CimInstance Win32_BaseBoard -ErrorAction Stop
    $text = '{0} {1}, BIOS {2} from {3:yyyy-MM-dd}' -f $board.Manufacturer, $board.Product, $bios.SMBIOSBIOSVersion, $bios.ReleaseDate
    if ($bios.ReleaseDate -lt (Get-Date).AddYears(-1)) { Add-Result 'WARN' "$text, over a year old; newer ones often fix memory and CPU stability" }
    else { Add-Result 'OK' $text }
}

Start-Area 'Drivers'
$codes = @{ 1 = 'not configured'; 3 = 'driver corrupted or out of memory'; 10 = 'cannot start'; 12 = 'not enough resources'; 14 = 'needs a restart';
    18 = 'reinstall the driver'; 19 = 'registry entry corrupted'; 21 = 'being removed'; 24 = 'not present or not working'; 28 = 'driver not installed';
    31 = 'not working properly'; 32 = 'driver start disabled'; 37 = 'driver failed to start'; 39 = 'driver missing or corrupted';
    41 = 'driver loaded but device not found'; 43 = 'stopped after reporting problems'; 48 = 'driver blocked'; 52 = 'driver not signed' }
$suspects = [ordered]@{
    '^wsdd' = 'Warsaw (bank security module)'
    '^(AsIO|AsUpIO|GLCKIO)' = 'ASUS hardware access (AI Suite, Armoury Crate)'
    '^(WinRing0|RTCore|NTIOLib|cpuz|HWiNFO|gdrv)' = 'hardware monitor or overclocking tool'
    '^(ene|EneIo|MsIo|LgCoreTemp)' = 'RGB lighting tool'
}
Test-Check 'Devices with problems' {
    $devices = @(Get-CimInstance Win32_PnPEntity -ErrorAction Stop | Where-Object { $_.ConfigManagerErrorCode })
    $bad = @($devices | Where-Object { $_.ConfigManagerErrorCode -notin 22, 45 })
    $off = @($devices | Where-Object { $_.ConfigManagerErrorCode -eq 22 })
    if ($bad.Count) {
        $list = $bad | Select-Object -First 8 | ForEach-Object {
            $name = if ($_.Name) { $_.Name } else { $_.DeviceID }
            '{0} (code {1}: {2})' -f $name, $_.ConfigManagerErrorCode, $codes[[int]$_.ConfigManagerErrorCode]
        }
        Add-Result 'FAIL' ('{0} in Device Manager: {1}' -f $bad.Count, ($list -join '; '))
    } else { Add-Result 'OK' 'every device works' }
    if ($off.Count) { Add-Result 'INFO' ('{0} disabled: {1}' -f $off.Count, (($off | Select-Object -First 8 | ForEach-Object { $_.Name }) -join '; ')) }
}
Test-Check 'Unsigned drivers' {
    $unsigned = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop | Where-Object { $_.DeviceName -and $_.IsSigned -eq $false } | ForEach-Object { $_.DeviceName })
    if ($unsigned.Count) { Add-Result 'WARN' ('{0}: {1}' -f $unsigned.Count, (($unsigned | Select-Object -First 8) -join '; ')) }
    else { Add-Result 'OK' 'every driver is signed' }
}
Test-Check 'Graphics driver' {
    foreach ($v in Get-CimInstance Win32_VideoController -ErrorAction Stop) {
        if ($v.InfFilename -eq 'display.inf' -or $v.Name -match 'Basic Display|Basic Render') { Add-Result 'FAIL' "$($v.Name): no graphics driver; install the one from the GPU maker" }
        elseif ($v.DriverDate -and $v.DriverDate -lt (Get-Date).AddYears(-2)) { Add-Result 'WARN' ('{0} driver {1} from {2:yyyy-MM-dd}, over two years old' -f $v.Name, $v.DriverVersion, $v.DriverDate) }
        else { Add-Result 'OK' "$($v.Name) driver $($v.DriverVersion)" }
    }
}
Test-Check 'Third-party kernel drivers' {
    $list = foreach ($d in Get-CimInstance Win32_SystemDriver -Filter "State='Running'" -ErrorAction Stop) {
        $p = Resolve-CommandPath $d.PathName
        if (-not $p -or -not (Test-Path -LiteralPath $p)) { continue }
        $item = Get-Item -LiteralPath $p
        $company = "$($item.VersionInfo.CompanyName)".Trim()
        if ($company -match 'Microsoft') { continue }
        if (-not $company -and "$((Get-AuthenticodeSignature -LiteralPath $p).SignerCertificate.Subject)" -match '^CN=Microsoft Windows,') { continue }
        [pscustomobject]@{ File = $item.Name; Company = $company; Date = $item.LastWriteTime }
    }
    $list = @($list | Sort-Object Company, File)
    Add-Result 'INFO' ('{0} running: {1}' -f $list.Count, (($list | ForEach-Object { '{0} ({1}, {2:yyyy-MM})' -f $_.File, $_.Company, $_.Date }) -join '; '))
    foreach ($pattern in $suspects.Keys) {
        $hits = @($list | Where-Object { $_.File -match $pattern } | ForEach-Object { $_.File })
        if ($hits.Count) { Add-Result 'WARN' ('{0}: {1}; a common cause of blue screens, uninstall it if you do not need it' -f $suspects[$pattern], ($hits -join ', ')) }
    }
    $old = @($list | Where-Object { $_.Date -lt (Get-Date).AddYears(-3) } | ForEach-Object { '{0} ({1:yyyy-MM-dd})' -f $_.File, $_.Date })
    if ($old.Count) { Add-Result 'WARN' ('older than three years: {0}' -f ($old -join '; ')) }
}
Test-Check 'Start failures' {
    $ev = @()
    try { $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 7000, 7026, 219; StartTime = $since } -ErrorAction Stop) } catch {}
    $names = @($ev | ForEach-Object {
        if ($_.Id -eq 219) { "$($_.Properties[4].Value)" -replace '^\\Driver\\', '' }
        else { "$($_.Properties[0].Value)" -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
    } | Where-Object { $_ -ne 'dam' })
    if (-not $names.Count) { Add-Result 'OK' "no services or drivers failed to start in the last $Days days"; return }
    $top = $names | Group-Object | Sort-Object Count -Descending | Select-Object -First 6 | ForEach-Object { "$($_.Name) x$($_.Count)" }
    Add-Result 'WARN' ('{0} failed starts: {1}' -f $names.Count, ($top -join ', '))
}
Test-Check 'Ghost devices' {
    $ghosts = @(Get-PnpDevice -ErrorAction Stop | Where-Object { -not $_.Present })
    if ($ghosts.Count) { Add-Result 'INFO' "$($ghosts.Count) devices no longer connected keep their drivers; harmless, remove them in Device Manager > View > Show hidden devices" }
    else { Add-Result 'OK' 'none' }
}
Test-Check 'Driver updates' {
    $found = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0 and Type='Driver'").Updates
    if ($found.Count) { Add-Result 'INFO' ('{0} offered by Windows Update: {1}' -f $found.Count, (($found | ForEach-Object { $_.Title }) -join '; ')) }
    else { Add-Result 'OK' 'Windows Update offers none' }
}
Test-Check 'Driver Verifier' {
    $verify = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'VerifyDrivers'
    if ($verify) { Add-Result 'WARN' "on for $verify; it causes blue screens on purpose, turn it off with verifier /reset" }
    else { Add-Result 'OK' 'off' }
}

Start-Area 'Disks'
Test-Check 'Physical disks' {
    foreach ($d in Get-PhysicalDisk -ErrorAction Stop) {
        $r = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
        $text = "$($d.FriendlyName): $($d.HealthStatus)"
        if ($r -and $r.Wear) { $text += ", wear $($r.Wear)%" }
        if ($r -and $r.Temperature) { $text += ", $($r.Temperature) C" }
        if ("$($d.HealthStatus)" -ne 'Healthy') { Add-Result 'FAIL' "$text; back up now" }
        elseif ($r -and ($r.Wear -ge 80 -or $r.Temperature -ge 60)) { Add-Result 'WARN' $text }
        else { Add-Result 'OK' $text }
    }
}
Test-Check 'Free space' {
    foreach ($v in Get-CimInstance Win32_Volume -Filter 'DriveType=3' -ErrorAction Stop | Where-Object { $_.DriveLetter -and $_.Capacity }) {
        $pct = 100 * $v.FreeSpace / $v.Capacity
        $text = '{0} {1:N1} GB free of {2:N0} GB ({3:N0}%)' -f $v.DriveLetter, ($v.FreeSpace / 1GB), ($v.Capacity / 1GB), $pct
        if ($pct -lt 5) { Add-Result 'FAIL' $text } elseif ($pct -lt 10) { Add-Result 'WARN' $text } else { Add-Result 'OK' $text }
        if ($v.DirtyBitSet) { Add-Result 'FAIL' "$($v.DriveLetter) is marked dirty; Windows runs chkdsk at the next start" }
    }
}
Test-Check 'Page file' {
    $auto = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).AutomaticManagedPagefile
    $files = @(Get-CimInstance Win32_PageFileUsage -ErrorAction Stop)
    if ($auto) { Add-Result 'OK' 'managed by Windows' }
    elseif ($files.Count) { Add-Result 'OK' (($files | ForEach-Object { "$($_.Name) $($_.AllocatedBaseSize) MB" }) -join '; ') }
    else { Add-Result 'WARN' 'no page file; programs run out of memory and blue screens leave no dump' }
}
Test-Check 'Crash dumps' {
    if ((Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' 'CrashDumpEnabled') -eq 0) { Add-Result 'WARN' 'off; blue screens leave no dump to read' }
    else { Add-Result 'OK' 'on' }
}

Start-Area 'Registry'
Test-Check 'File associations' {
    $broken = @()
    $expected = [ordered]@{ '.exe' = 'exefile'; '.com' = 'comfile'; '.bat' = 'batfile'; '.cmd' = 'cmdfile'; '.lnk' = 'lnkfile'; '.reg' = 'regfile'; '.msi' = 'Msi.Package' }
    foreach ($ext in $expected.Keys) {
        $value = Get-RegValue "HKLM:\SOFTWARE\Classes\$ext" ''
        if ($value -ne $expected[$ext]) { $broken += "$ext is '$value', not '$($expected[$ext])'" }
    }
    foreach ($ext in '.exe', '.com', '.bat', '.cmd', '.lnk') {
        if (Get-RegValue "HKCU:\Software\Classes\$ext" '') { $broken += "$ext is overridden for this user" }
    }
    foreach ($cls in 'exefile', 'comfile', 'batfile', 'cmdfile') {
        $cmd = Get-RegValue "HKLM:\SOFTWARE\Classes\$cls\shell\open\command" ''
        if ($cmd -ne '"%1" %*') { $broken += "$cls opens with '$cmd'" }
    }
    $lnk = Get-Item -LiteralPath 'HKLM:\SOFTWARE\Classes\lnkfile' -ErrorAction SilentlyContinue
    if (-not $lnk -or $lnk.GetValueNames() -notcontains 'IsShortcut') { $broken += 'lnkfile lost IsShortcut (shortcut arrows and opening break)' }
    if ($broken) { Add-Result 'FAIL' ($broken -join '; ') } else { Add-Result 'OK' 'programs, scripts and shortcuts open normally' }
}
Test-Check 'Logon shell' {
    $wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $broken = @()
    $shell = Get-RegValue $wl 'Shell'
    $userinit = Get-RegValue $wl 'Userinit'
    if ($shell -ne 'explorer.exe') { $broken += "Shell is '$shell'" }
    if ($userinit -notmatch '^[A-Za-z]:\\Windows\\system32\\userinit\.exe,?$') { $broken += "Userinit is '$userinit'" }
    $userShell = Get-RegValue 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' 'Shell'
    if ($userShell) { $broken += "this user's Shell is '$userShell'" }
    if ($broken) { Add-Result 'FAIL' ($broken -join '; ') } else { Add-Result 'OK' 'explorer.exe and userinit.exe' }
}
Test-Check 'Program redirections (IFEO)' {
    $hits = foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options') {
        Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue | Where-Object { $_.GetValue('Debugger') } |
            ForEach-Object { "$($_.PSChildName) -> $($_.GetValue('Debugger'))" }
    }
    $hits = @($hits)
    if ($hits.Count) { Add-Result 'WARN' ('programs started through another program: {0}' -f ($hits -join '; ')) }
    else { Add-Result 'OK' 'none' }
}
Test-Check 'AppInit DLLs' {
    $hits = foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows') {
        $dlls = Get-RegValue $k 'AppInit_DLLs'
        if ($dlls -and (Get-RegValue $k 'LoadAppInit_DLLs') -eq 1) { $dlls }
    }
    $hits = @($hits)
    if ($hits.Count) { Add-Result 'WARN' ('loaded into every program: {0}' -f ($hits -join '; ')) } else { Add-Result 'OK' 'none' }
}
Test-Check 'Policy restrictions' {
    $rules = @()
    foreach ($root in 'HKCU:', 'HKLM:') {
        $rules += , @("$root\Software\Microsoft\Windows\CurrentVersion\Policies\System", 'DisableTaskMgr', "Task Manager ($root)")
        $rules += , @("$root\Software\Microsoft\Windows\CurrentVersion\Policies\System", 'DisableRegistryTools', "Registry Editor ($root)")
        $rules += , @("$root\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer", 'NoControlPanel', "Control Panel and Settings ($root)")
        $rules += , @("$root\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer", 'NoRun', "Run dialog ($root)")
        $rules += , @("$root\Software\Policies\Microsoft\Windows\System", 'DisableCMD', "Command Prompt ($root)")
    }
    $rules += , @('HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender', 'DisableAntiSpyware', 'Microsoft Defender')
    $rules += , @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU', 'NoAutoUpdate', 'automatic updates')
    $blocked = @($rules | Where-Object { Get-RegValue $_[0] $_[1] } | ForEach-Object { $_[2] })
    if ($blocked.Count) { Add-Result 'WARN' ('blocked by policy: {0}' -f ($blocked -join '; ')) } else { Add-Result 'OK' 'nothing blocked' }
}
Test-Check 'Startup entries' {
    $missing = foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce') {
        $key = Get-Item -LiteralPath $k -ErrorAction SilentlyContinue
        if ($key) { foreach ($n in $key.GetValueNames()) { if (Test-Missing $key.GetValue($n)) { $n } } }
    }
    Add-Missing 'startup entries' $missing
}
Test-Check 'App Paths' {
    $missing = foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths') {
        Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue | Where-Object { Test-Missing $_.GetValue('') } | ForEach-Object { $_.PSChildName }
    }
    Add-Missing 'App Paths entries' $missing
}
Test-Check 'Uninstall entries' {
    $missing = foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall') {
        Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue |
            Where-Object { $_.GetValue('DisplayName') -and (Test-Missing $_.GetValue('UninstallString')) } | ForEach-Object { $_.GetValue('DisplayName') }
    }
    Add-Missing 'installed programs' $missing
}
Test-Check 'Services and drivers' {
    $missing = foreach ($k in Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop) {
        if ($null -eq $k.GetValue('Type') -or $k.GetValue('Start') -eq 4) { continue }
        if (Test-Missing $k.GetValue('ImagePath')) { $k.PSChildName; continue }
        $dll = Get-RegValue "$($k.PSPath)\Parameters" 'ServiceDll'
        if ($dll -and -not (Test-Path -LiteralPath $dll)) { "$($k.PSChildName) (ServiceDll)" }
    }
    Add-Missing 'services and drivers' $missing
}
Test-Check 'User folders' {
    $key = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
    $missing = foreach ($n in 'Desktop', 'Personal', '{374DE290-123F-4565-9164-39C4925E467B}', 'My Pictures', 'My Music', 'My Video', 'AppData', 'Local AppData') {
        $p = $key.GetValue($n)
        if ($p -and -not (Test-Path -LiteralPath $p)) { "$n ($p)" }
    }
    $missing = @($missing)
    if ($missing.Count) { Add-Result 'FAIL' ('point to missing folders: {0}' -f ($missing -join '; ')) } else { Add-Result 'OK' 'Desktop, Documents, Downloads and the rest exist' }
}

Start-Area 'Defaults'
Test-Check 'Core services' {
    $required = 'RpcSs', 'DcomLaunch', 'EventLog', 'Winmgmt', 'PlugPlay', 'Power', 'ProfSvc', 'SamSs', 'Schedule', 'CryptSvc', 'BITS', 'wuauserv',
        'UsoSvc', 'TrustedInstaller', 'msiserver', 'AppXSvc', 'Dhcp', 'Dnscache', 'nsi', 'LanmanWorkstation', 'BFE', 'mpssvc', 'WinDefend', 'wscsvc',
        'Audiosrv', 'AudioEndpointBuilder', 'Themes', 'DPS', 'W32Time'
    $missing = @()
    $disabled = @()
    foreach ($n in $required) {
        $s = Get-Service -Name $n -ErrorAction SilentlyContinue
        if (-not $s) { $missing += $n } elseif ("$($s.StartType)" -eq 'Disabled') { $disabled += $n }
    }
    if ($missing) { Add-Result 'FAIL' ('missing: {0}' -f ($missing -join ', ')) }
    if ($disabled) { Add-Result 'WARN' ('disabled: {0}' -f ($disabled -join ', ')) }
    if (-not $missing -and -not $disabled) { Add-Result 'OK' "all $($required.Count) present and enabled" }
}
Test-Check 'System programs' {
    $s32 = "$env:SystemRoot\System32"
    $files = "$env:SystemRoot\explorer.exe", "$env:SystemRoot\regedit.exe", "$s32\cmd.exe", "$s32\WindowsPowerShell\v1.0\powershell.exe", "$s32\taskmgr.exe",
        "$s32\mmc.exe", "$s32\msiexec.exe", "$s32\control.exe", "$s32\rundll32.exe", "$s32\svchost.exe", "$s32\sfc.exe", "$s32\Dism.exe"
    $missing = @($files | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count) { Add-Result 'FAIL' ('missing: {0}' -f ($missing -join ', ')) } else { Add-Result 'OK' "all $($files.Count) present" }
}
Test-Check 'PATH' {
    $split = { param($scope) @([Environment]::GetEnvironmentVariable('Path', $scope) -split ';' | Where-Object { $_ } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }) }
    $machine = & $split 'Machine'
    $user = & $split 'User'
    $needed = "$env:SystemRoot\System32", $env:SystemRoot, "$env:SystemRoot\System32\Wbem", "$env:SystemRoot\System32\WindowsPowerShell\v1.0"
    $lost = @($needed | Where-Object { $machine -notcontains $_ })
    $gone = @($machine + $user | Where-Object { -not (Test-Path -LiteralPath $_) } | Select-Object -Unique)
    if ($lost.Count) { Add-Result 'FAIL' ('system PATH lacks {0}' -f ($lost -join ', ')) }
    if ($gone.Count) { Add-Result 'WARN' ('PATH folders that no longer exist: {0}' -f ($gone -join '; ')) }
    if (-not $lost.Count -and -not $gone.Count) { Add-Result 'OK' 'system folders present, no dead entries' }
}
Test-Check 'Temp folder' {
    if (Test-Path -LiteralPath $env:TEMP) { Add-Result 'OK' $env:TEMP } else { Add-Result 'FAIL' "$env:TEMP does not exist; installers will fail" }
}
Test-Check '.NET Framework 4.8' {
    $release = Get-RegValue 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' 'Release'
    if ($release -ge 528040) { Add-Result 'OK' "release $release" } else { Add-Result 'WARN' "release $release; 4.8 or newer is expected" }
}
Test-Check '.NET Framework 3.5' {
    if ("$((Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop).State)" -eq 'Enabled') { Add-Result 'OK' 'on' }
    else { Add-Result 'INFO' 'off; older programs ask for it (Windows Features)' }
} -Admin
Test-Check 'Visual C++ runtime' {
    $need = "$env:SystemRoot\System32\vcruntime140.dll", "$env:SystemRoot\System32\vcruntime140_1.dll", "$env:SystemRoot\System32\msvcp140.dll",
        "$env:SystemRoot\SysWOW64\vcruntime140.dll", "$env:SystemRoot\SysWOW64\msvcp140.dll"
    $missing = @($need | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count) { Add-Result 'WARN' ('missing {0}; install the latest Visual C++ Redistributable, x64 and x86' -f ($missing -join ', ')) }
    else { Add-Result 'OK' 'x64 and x86 present' }
}
Test-Check 'DirectX 9 extras' {
    if (Test-Path -LiteralPath "$env:SystemRoot\System32\d3dx9_43.dll") { Add-Result 'OK' 'present' }
    else { Add-Result 'INFO' 'missing; older games need the DirectX End-User Runtime' }
}
Test-Check 'WebView2 runtime' {
    $id = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    $pv = Get-RegValue "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$id" 'pv'
    if (-not $pv) { $pv = Get-RegValue "HKCU:\Software\Microsoft\EdgeUpdate\Clients\$id" 'pv' }
    if ($pv -and $pv -ne '0.0.0.0') { Add-Result 'OK' $pv } else { Add-Result 'WARN' 'missing; many apps (Teams, Office add-ins) need it' }
}
Test-Check 'winget' {
    if (Get-Command winget -ErrorAction SilentlyContinue) { Add-Result 'OK' 'present' } else { Add-Result 'WARN' 'missing; install App Installer from the Microsoft Store' }
}
Test-Check 'Microsoft Store' {
    if (Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction Stop) { Add-Result 'OK' 'present' } else { Add-Result 'WARN' 'missing for this user' }
}

Start-Area 'Security and network'
Test-Check 'Antivirus' {
    $mp = $null
    try { $mp = Get-MpComputerStatus -ErrorAction Stop } catch {}
    if ($mp -and $mp.AntivirusEnabled) {
        if (-not $mp.RealTimeProtectionEnabled) { Add-Result 'WARN' 'Microsoft Defender real-time protection is off' }
        elseif ($mp.AntivirusSignatureAge -gt 7) { Add-Result 'WARN' "Defender signatures are $($mp.AntivirusSignatureAge) days old" }
        else { Add-Result 'OK' 'Microsoft Defender on and up to date' }
        return
    }
    $av = @(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | ForEach-Object { $_.displayName })
    if ($av.Count) { Add-Result 'INFO' ('Defender off, using {0}' -f ($av -join ', ')) } else { Add-Result 'FAIL' 'no antivirus is on' }
}
Test-Check 'Memory integrity' {
    $dg = Get-CimInstance -Namespace root/Microsoft/Windows/DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
    if ($dg.SecurityServicesRunning -contains 2) { Add-Result 'OK' 'on; drivers that break it cannot load' }
    else { Add-Result 'INFO' 'off; Windows Security > Device security > Core isolation lists the drivers that keep it off' }
    if ((Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config' 'VulnerableDriverBlocklistEnable') -eq 0) {
        Add-Result 'WARN' 'the vulnerable driver blocklist is off'
    }
}
Test-Check 'Blocked code' {
    $ev = @()
    try { $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-CodeIntegrity/Operational'; Id = 3033, 3063; StartTime = $since } -ErrorAction Stop) } catch {}
    $foreign = @($ev | Where-Object {
        $file = "$($_.Properties[1].Value)"
        $proc = "$($_.Properties[3].Value)"
        -not $file.StartsWith((Split-Path $proc -Parent), [StringComparison]::OrdinalIgnoreCase)
    } | ForEach-Object { '{0} into {1}' -f (Split-Path "$($_.Properties[1].Value)" -Leaf), (Split-Path "$($_.Properties[3].Value)" -Leaf) })
    if (-not $foreign.Count) { Add-Result 'OK' "no code blocked from loading into other programs in the last $Days days"; return }
    $top = $foreign | Group-Object | Sort-Object Count -Descending | Select-Object -First 6 | ForEach-Object { "$($_.Name) x$($_.Count)" }
    Add-Result 'WARN' ('{0} unsigned loads blocked, a program injecting into others: {1}' -f $foreign.Count, ($top -join '; '))
}
Test-Check 'Firewall' {
    $off = @(Get-NetFirewallProfile -ErrorAction Stop | Where-Object { "$($_.Enabled)" -ne 'True' } | ForEach-Object { $_.Name })
    if ($off.Count) { Add-Result 'WARN' ('off for {0}' -f ($off -join ', ')) } else { Add-Result 'OK' 'on for every profile' }
}
Test-Check 'UAC' {
    if ((Get-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'EnableLUA') -eq 0) { Add-Result 'FAIL' 'off; the Store and many apps break without it' }
    else { Add-Result 'OK' 'on' }
}
Test-Check 'Hosts file' {
    $hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (-not (Test-Path -LiteralPath $hosts)) { Add-Result 'INFO' 'no hosts file'; return }
    $entries = @(Get-Content -LiteralPath $hosts -ErrorAction Stop | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -notmatch '\slocalhost$' })
    if ($entries.Count) { Add-Result 'WARN' ('custom entries ({0}): {1}' -f $entries.Count, (($entries | Select-Object -First 5) -join '; ')) }
    else { Add-Result 'OK' 'no custom entries' }
}
Test-Check 'Proxy' {
    $is = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $pac = Get-RegValue $is 'AutoConfigURL'
    if ((Get-RegValue $is 'ProxyEnable') -eq 1) { Add-Result 'INFO' "proxy $(Get-RegValue $is 'ProxyServer')" }
    elseif ($pac) { Add-Result 'INFO' "proxy script $pac" }
    else { Add-Result 'OK' 'no proxy' }
}
Test-Check 'DNS' {
    try {
        Resolve-DnsName -Name www.microsoft.com -QuickTimeout -ErrorAction Stop | Out-Null
        Add-Result 'OK' 'names resolve'
    } catch { Add-Result 'WARN' 'cannot resolve www.microsoft.com: no internet or broken DNS' }
}

Start-Area "Problems in the last $Days days"
Test-Check 'Blue screens' {
    Add-Count (Get-EventCount @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = $since }) 'blue screens' 1
}
Test-Check 'Unexpected shutdowns' {
    Add-Count (Get-EventCount @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41; StartTime = $since }) 'unexpected shutdowns (Kernel-Power 41)' 3
}
Test-Check 'Hardware errors (WHEA)' {
    Add-Count (Get-EventCount @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WHEA-Logger'; StartTime = $since }) 'WHEA hardware errors' 10
}
Test-Check 'Disk errors' {
    $n = (Get-EventCount @{ LogName = 'System'; ProviderName = 'disk'; Id = 7, 51, 153; StartTime = $since }) +
        (Get-EventCount @{ LogName = 'System'; ProviderName = 'Ntfs'; Id = 55, 98; StartTime = $since })
    Add-Count $n 'disk or file system errors' 1
}
Test-Check 'Graphics driver resets' {
    Add-Count (Get-EventCount @{ LogName = 'System'; ProviderName = 'Display'; Id = 4101; StartTime = $since }) 'graphics driver resets' 3
}
Test-Check 'App crashes' {
    try { $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Application Error'; Id = 1000; StartTime = $since } -ErrorAction Stop) }
    catch { Add-Result 'OK' "no app crashes in the last $Days days"; return }
    $top = $ev | Group-Object { $_.Properties[0].Value } | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object { "$($_.Name) x$($_.Count)" }
    $status = if ($ev.Count -ge 10) { 'WARN' } else { 'INFO' }
    Add-Result $status ('{0} crashes, most: {1}' -f $ev.Count, ($top -join ', '))
}
Test-Check 'Crash dump files' {
    $dir = "$env:SystemRoot\Minidump"
    $dumps = @()
    if (Test-Path -LiteralPath $dir) { $dumps = @(Get-ChildItem -LiteralPath $dir -Filter *.dmp -ErrorAction Stop | Where-Object { $_.LastWriteTime -gt $since }) }
    $named = @()
    try {
        $named = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = $since } -ErrorAction Stop |
            ForEach-Object { if ($_.Message -match '([A-Za-z]:\\\S+\.dmp)') { $Matches[1].TrimEnd('.') } })
    } catch {}
    $gone = @($named | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($gone.Count) { Add-Result 'WARN' "$($gone.Count) dumps named by blue screens were deleted (Storage Sense or Disk Cleanup removes them): $($gone -join ', ')" }
    if ($dumps.Count) { Add-Result 'INFO' "$($dumps.Count) minidumps in $dir; collect-diagnostics.ps1 copies and analyzes them" }
    elseif (-not $gone.Count) { Add-Result 'OK' 'no new minidumps' }
} -Admin

New-Item -ItemType Directory -Force $base | Out-Null
$report = Join-Path $base "health_$stamp.txt"
$order = @{ FAIL = 0; WARN = 1; INFO = 2; SKIP = 3; OK = 4 }
$sorted = $results | Sort-Object { $order[$_.Status] }, Index
$sorted | ForEach-Object { '[{0}] {1} / {2}: {3}' -f $_.Status, $_.Area, $_.Check, $_.Detail } | Set-Content -LiteralPath $report -Encoding UTF8

$counts = foreach ($s in 'FAIL', 'WARN', 'INFO', 'SKIP', 'OK') { '{0} {1}' -f @($results | Where-Object { $_.Status -eq $s }).Count, $s }
Write-Host "`nSummary: $($counts -join ', ')" -ForegroundColor White
foreach ($r in $sorted | Where-Object { $_.Status -eq 'FAIL' -or $_.Status -eq 'WARN' }) {
    Write-Host ('  [{0}] {1} / {2}: {3}' -f $r.Status, $r.Area, $r.Check, $r.Detail) -ForegroundColor $colors[$r.Status]
}
Write-Host "Report: $report"
Write-Host 'Nothing was changed. For a full data dump and the DISM / SFC repair, run collect-diagnostics.ps1.'
