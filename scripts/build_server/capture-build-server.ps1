<#
.SYNOPSIS
  Read-only capture of the Windows Server 2016 GitLab build server before the 2025 reinstall.

.DESCRIPTION
  Run as Administrator on the OLD server. It changes nothing on the machine.
  Output goes to D:\migration_capture\<timestamp> because D: survives the reinstall.
  Copy that folder somewhere safe as well (it is also your rollback reference).

  WARNING: env_variables.csv, runner_profile\* and config files may contain secrets
  (npm/NuGet tokens, passwords in env vars). Tokens in config.toml are redacted;
  the rest is NOT. Do not commit this folder to Git.
#>
param(
    [string]$OutDir = "D:\migration_capture\$(Get-Date -Format yyyyMMdd_HHmm)"
)

$ErrorActionPreference = 'Continue'

# Read-only guarantee: the only external programs run are version/list queries
# (vswhere, dotnet --list-*, perl -v / module list, git config --list, gitlab-runner --version).
# These env vars apply to THIS PowerShell process only; they stop the dotnet CLI from
# writing its first-run/telemetry files into the profile of the admin running the script.
$env:DOTNET_NOLOGO = '1'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
function Save($name, $obj) { $obj | Export-Csv "$OutDir\$name.csv" -NoTypeInformation -Encoding UTF8 }
function DriveOf($p) { if ($p -match '^\s*"?([A-Za-z]):') { $Matches[1].ToUpper() } else { '?' } }

Write-Host "Capturing to $OutDir"

# 1. Installed software (64 + 32 bit) and the drive it lives on.
#    Drive '?' = MSI without InstallLocation; check the Location/Name manually.
$keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$software = Get-ItemProperty $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
    ForEach-Object {
        $loc = if ($_.InstallLocation) { $_.InstallLocation } else { $_.UninstallString -replace '^"?([^"]+?\.exe).*', '$1' }
        [pscustomobject]@{
            Name        = $_.DisplayName
            Version     = $_.DisplayVersion
            Publisher   = $_.Publisher
            Drive       = DriveOf $loc
            Location    = $loc
            InstallDate = $_.InstallDate
        }
    } | Sort-Object Name -Unique
Save 'installed_software' $software

# 2. Machine PATH, one entry per row, with drive and whether it still exists.
$path = [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ } |
    ForEach-Object {
        $e = [Environment]::ExpandEnvironmentVariables($_)
        [pscustomobject]@{ Drive = DriveOf $e; Entry = $_; Exists = (Test-Path $e) }
    }
Save 'machine_path' $path

# 3. Other machine environment variables (may contain secrets!).
$envVars = [Environment]::GetEnvironmentVariables('Machine').GetEnumerator() |
    Where-Object { $_.Key -ne 'Path' } | Sort-Object Key |
    ForEach-Object { [pscustomobject]@{ Name = $_.Key; Value = $_.Value; Drive = DriveOf $_.Value } }
Save 'env_variables' $envVars

# 4. Build tools on PATH: where each one resolves to (C: or D:) and its version.
$tools = 'git','dotnet','msbuild','nuget','perl','cpan','cpanm','sqlpackage','sqlcmd','bcp',
         'uipcli','uipath','node','npm','java','mvn','python','pip','pwsh','7z','curl'
$toolchain = foreach ($t in $tools) {
    $c = Get-Command $t -ErrorAction SilentlyContinue | Select-Object -First 1
    [pscustomobject]@{
        Tool    = $t
        Found   = [bool]$c
        Drive   = if ($c) { DriveOf $c.Source } else { '' }
        Source  = if ($c) { $c.Source } else { '' }
        Version = if ($c) { "$($c.Version)" } else { '' }
    }
}
Save 'toolchain' $toolchain

# 5. Toolchain details: Visual Studio / Build Tools, .NET SDKs, Perl modules.
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) { & $vswhere -all -products * -format json | Out-File "$OutDir\visual_studio.json" -Encoding UTF8 }
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    & dotnet --list-sdks     | Out-File "$OutDir\dotnet_sdks.txt" -Encoding UTF8
    & dotnet --list-runtimes | Out-File "$OutDir\dotnet_runtimes.txt" -Encoding UTF8
}
if (Get-Command perl -ErrorAction SilentlyContinue) {
    & perl -v | Out-File "$OutDir\perl_version.txt" -Encoding UTF8
    & perl -MExtUtils::Installed -e "print join qq(\n), ExtUtils::Installed->new->modules" |
        Out-File "$OutDir\perl_modules.txt" -Encoding UTF8
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    & git config --system --list 2>$null | Out-File "$OutDir\git_system_config.txt" -Encoding UTF8
}

# 6. GitLab runner service: exe path, config path, and the account it runs as.
$runners = Get-CimInstance Win32_Service |
    Where-Object { $_.Name -like '*runner*' -or $_.PathName -like '*gitlab-runner*' } |
    Select-Object Name, State, StartMode, StartName, PathName
Save 'runner_services' $runners

# 7. Runner config.toml with tokens/passwords redacted.
foreach ($s in $runners) {
    $exe = $s.PathName -replace '^"?([^"]+?\.exe).*', '$1'
    $cfg = if ($s.PathName -match '--config\s+"?([^"]+?\.toml)') { $Matches[1] } else { Join-Path (Split-Path $exe) 'config.toml' }
    if (Test-Path $cfg) {
        Get-Content $cfg | ForEach-Object {
            $_ -replace '^(\s*(token|password|\w*secret\w*|access_key|secret_key)\s*=\s*).*$', '$1"***REDACTED***"'
        } | Out-File "$OutDir\config_$($s.Name).toml.redacted" -Encoding UTF8
        & $exe --version 2>$null | Out-File "$OutDir\runner_version_$($s.Name).txt" -Encoding UTF8
    } else {
        "config.toml not found at $cfg" | Out-File "$OutDir\config_$($s.Name).missing.txt"
    }
}

# 8. Config files in the runner account's profile (on C: -> lost on reinstall).
$acct = ($runners | Select-Object -First 1).StartName
if ($acct) {
    $profileDir = if ($acct -eq 'LocalSystem') { "$env:windir\System32\config\systemprofile" }
                  else { $u = $acct.Split('\')[-1]; Get-ChildItem C:\Users -Directory | Where-Object Name -like "$u*" | Select-Object -First 1 -ExpandProperty FullName }
    if ($profileDir) {
        $dest = New-Item -ItemType Directory -Path "$OutDir\runner_profile" -Force
        '.gitconfig','.npmrc','.m2\settings.xml','AppData\Roaming\NuGet\NuGet.Config','AppData\Roaming\pip\pip.ini','pip\pip.ini' |
            ForEach-Object {
                $f = Join-Path $profileDir $_
                if (Test-Path $f) { Copy-Item $f (Join-Path $dest.FullName ($_ -replace '[\\/]', '_')) }
            }
        "Runner account: $acct`r`nProfile: $profileDir" | Out-File "$OutDir\runner_profile\README.txt"
    }
}

# 9. Non-Windows services (SQL Server, agents, anything running from D:).
$services = Get-CimInstance Win32_Service |
    Where-Object { $_.PathName -and $_.PathName -notmatch '\\Windows\\' } |
    Select-Object Name, DisplayName, State, StartMode, StartName, @{n='Drive';e={DriveOf $_.PathName}}, PathName
Save 'services_non_windows' $services

# 10. Non-Microsoft scheduled tasks.
$tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' } |
    Select-Object TaskPath, TaskName, State,
        @{n='RunAs';  e={ $_.Principal.UserId }},
        @{n='Command';e={ ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join '; ' }}
Save 'scheduled_tasks' $tasks

# 11. Windows features, certificates, disks, top-level D: folders.
Save 'windows_features' (Get-WindowsFeature | Where-Object Installed | Select-Object Name, DisplayName)
Save 'certificates' (Get-ChildItem Cert:\LocalMachine\My, Cert:\LocalMachine\Root, Cert:\LocalMachine\CA |
    Select-Object @{n='Store';e={ Split-Path $_.PSParentPath -Leaf }}, Subject, Issuer, Thumbprint, NotAfter)
Save 'disks' (Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, DriveType, VolumeName, Size, FreeSpace)
Save 'd_drive_folders' (Get-ChildItem D:\ -Directory -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime)

Write-Host ""
Write-Host "Done. Quick view - software and tools on C: (these must be reinstalled by Ansible):"
$software  | Where-Object Drive -eq 'C' | Format-Table Name, Version -AutoSize
$toolchain | Where-Object Found | Format-Table Tool, Drive, Source -AutoSize
$runners   | Format-List Name, StartName, PathName
