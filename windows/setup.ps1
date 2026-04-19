#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 dotfiles setup - komorebi + whkd + yasb
.DESCRIPTION
    Automated setup for a tiling WM environment on Windows 11.
    Installs packages via winget and scoop, configures system tweaks,
    symlinks dotfiles, sets up autostart, and installs Arch Linux on WSL2.
.EXAMPLE
    .\windows\setup.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$script:SetupErrors = [System.Collections.Generic.List[string]]::new()

# PS5 on older Win11 builds defaults to TLS 1.0/1.1; pin 1.2 for Invoke-*
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ScriptDir = $PSScriptRoot
$DotfilesDir = if ($ScriptDir -match '\\windows$') { Split-Path $ScriptDir } else { $ScriptDir }

# -- Dot-source libraries -------------------------------------
. "$ScriptDir\lib\Logging.ps1"
. "$ScriptDir\lib\Utils.ps1"
. "$ScriptDir\lib\PackageManager.ps1"
. "$ScriptDir\lib\Tweaks.ps1"

# -- Phase 0: Prerequisites ------------------------------------

function Test-Windows11 {
    # Detect LTSC
    $product = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
    if ($product -match 'LTSC|EnterpriseS') {
        Log-Warn "LTSC edition detected ($product) - winget may need manual installation"
    }
}

# -- Phase 2: Package Installation -----------------------------

function Install-AllPackages {
    $packagesFile = Join-Path -Path $ScriptDir -ChildPath 'packages.psd1'
    $packages = Import-PowerShellDataFile $packagesFile

    foreach ($name in $packages.Keys) {
        Install-WingetPackage -Name $name -Id $packages[$name]
    }

    # Scoop-only packages
    Install-ScoopPackage -Name 'uutils-coreutils' -Package 'uutils-coreutils'
}

# -- Phase 4: Config Symlinks ----------------------------------

function New-ConfigLinks {
    Log-Info "Creating config symlinks..."

    $links = @(
        @{ Src = 'komorebi\komorebi.json';           Tgt = "$HOME\komorebi.json" }
        @{ Src = 'komorebi\applications.json';        Tgt = "$HOME\applications.json" }
        @{ Src = 'whkd\whkdrc';                       Tgt = "$HOME\.config\whkdrc" }
        @{ Src = 'yasb\config.yaml';                  Tgt = "$HOME\.config\yasb\config.yaml" }
        @{ Src = 'yasb\styles.css';                   Tgt = "$HOME\.config\yasb\styles.css" }
        @{ Src = 'profiles\Microsoft.PowerShell_profile.ps1'; Tgt = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" }
        @{ Src = 'wezterm\wezterm.lua';               Tgt = "$HOME\.config\wezterm\wezterm.lua" }
        @{ Src = 'fastfetch\config.jsonc';            Tgt = "$HOME\.config\fastfetch\config.jsonc" }
        @{ Src = 'bat\config';                        Tgt = "$HOME\.config\bat\config" }
    )

    # Shared ashen.lua from repo root
    $ashenSrc = Join-Path -Path $DotfilesDir -ChildPath 'wezterm\ashen.lua'
    if (Test-Path $ashenSrc) {
        $links += @{ Src = ''; Tgt = "$HOME\.config\wezterm\ashen.lua"; AbsoluteSrc = $ashenSrc }
    }

    foreach ($link in $links) {
        $src = if ($link.AbsoluteSrc) { $link.AbsoluteSrc } else { Join-Path -Path $ScriptDir -ChildPath $link.Src }
        New-Symlink -Source $src -Target $link.Tgt
    }
}

# -- Phase 5: Autostart ----------------------------------------

function Register-Autostart {
    Log-Info "Setting up autostart..."

    $startupDir = [System.Environment]::GetFolderPath('Startup')
    $startupScript = Join-Path -Path $startupDir -ChildPath 'komorebi-startup.ps1'

    $content = @'
# Komorebi + whkd + yasb autostart
komorebic start --whkd --bar
Start-Process yasb -WindowStyle Hidden
'@

    Set-Content -Path $startupScript -Value $content -Encoding UTF8

    $shell = if (Test-Command pwsh) { 'pwsh.exe' } else { 'powershell.exe' }

    $ws = New-Object -ComObject WScript.Shell
    $shortcut = $ws.CreateShortcut((Join-Path -Path $startupDir -ChildPath 'komorebi.lnk'))
    $shortcut.TargetPath = $shell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startupScript`""
    $shortcut.WorkingDirectory = $HOME
    $shortcut.Save()

    Log-Success "Autostart shortcut created"
}

# -- Phase 6: WSL + Arch Linux ---------------------------------

function Install-WSLArch {
    Log-Info "Setting up WSL..."

    # Check if WSL is already enabled
    $wslEnabled = $false
    try {
        $null = wsl --status 2>$null
        $wslEnabled = $true
    } catch {}

    if (-not $wslEnabled) {
        Log-Info "Enabling WSL..."
        try {
            wsl --install --no-distribution 2>$null
            if ($LASTEXITCODE -ne 0) {
                dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>$null
                dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>$null
            }
            Log-Success "WSL features enabled (reboot may be required)"
        } catch {
            Record-Error "Failed to enable WSL: $_"
            return
        }
    } else {
        Log-Success "WSL already enabled"
    }

    wsl --set-default-version 2 2>$null

    # Check if Arch is already installed
    $distributions = wsl --list --quiet 2>$null
    if ($distributions -match 'Arch') {
        Log-Success "Arch WSL already installed"
        return
    }

    Log-Info "Installing Arch Linux..."
    try {
        wsl --install -d Arch 2>$null
        if ($LASTEXITCODE -eq 0) {
            Log-Success "Arch WSL installed"
        } else {
            # Fallback for LTSC / no Store: manual import
            Log-Warn "Store install failed, trying manual import..."
            $tmpDir = "$env:TEMP\arch-wsl"
            New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

            $url = 'https://geo.mirror.pkgbuild.com/iso/latest/archlinux-wsl-x86_64.tar.zst'
            $tarball = Join-Path -Path $tmpDir -ChildPath 'arch-rootfs.tar.zst'

            Log-Info "Downloading Arch rootfs..."
            Invoke-WebRequest -Uri $url -OutFile $tarball -UseBasicParsing

            $installDir = "$HOME\WSL\Arch"
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
            wsl --import Arch $installDir $tarball 2>$null

            if ($LASTEXITCODE -eq 0) {
                Log-Success "Arch WSL imported manually"
            } else {
                Record-Error "Failed to import Arch WSL"
            }

            Remove-Item $tmpDir -Recurse -Force 2>$null
        }
    } catch {
        Record-Error "Arch WSL installation failed: $_"
    }

    # Basic Arch setup
    $setupScript = @'
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm
pacman -S --noconfirm --needed base-devel sudo
'@

    Log-Info "Running initial Arch setup..."
    try {
        wsl -d Arch -- bash -c $setupScript 2>$null
        Log-Success "Arch base system configured"
    } catch {
        Log-Warn "Could not run Arch setup (may need reboot first): $_"
    }

    # Prompt for username
    $username = Read-Host "Enter username for Arch WSL (or press Enter to skip user creation)"
    if ($username) {
        $userScript = @"
useradd -m -G wheel -s /bin/bash $username
echo '$username ALL=(ALL:ALL) ALL' >> /etc/sudoers.d/$username
"@
        wsl -d Arch -- bash -c $userScript 2>$null

        # Set password
        Log-Info "Setting password for $username..."
        wsl -d Arch -- bash -c "passwd $username" 2>$null

        # Create wsl.conf
        $wslConf = @"
[user]
default=$username

[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=true
"@
        $wslConf | wsl -d Arch -- bash -c 'cat > /etc/wsl.conf'
        wsl --terminate Arch 2>$null

        Log-Success "Arch user '$username' created and set as default"
    }
}

# -- Phase 7: Finalization -------------------------------------

function Show-Summary {
    Write-Host ""
    Log-Success "========================================"
    Log-Success "    Installation finished!"
    Log-Success "========================================"
    Write-Host ""

    if ($script:SetupErrors.Count -gt 0) {
        Log-Error "Errors during installation:"
        foreach ($err in $script:SetupErrors) {
            Write-Host "  - $err"
        }
        Log-Warn "Review the errors; manual intervention may be needed."
        Write-Host ""
    }

    if (Confirm-Prompt "Reboot now to apply all changes?" "Y") {
        Restart-Computer -Force
    }
}

# -- Main -------------------------------------------------------

function Main {
    Test-Windows11

    Write-Host "================================================================"
    Write-Host "      WARNING: DESTRUCTION AHEAD!"
    Write-Host "================================================================"
    Write-Host "This will install packages, apply system tweaks,"
    Write-Host "and overwrite your dotfile symlinks."
    Write-Host ""

    if (-not (Confirm-Prompt "Proceed?" "N")) {
        Log-Info "Aborted by user."
        return
    }

    Write-Host ""
    Log-Info "Starting full installation pipeline..."

    # Phase 0: winget
    Install-WingetIfNeeded

    # Phase 1: git
    Install-GitIfNeeded

    # Phase 2: scoop (for scoop-only packages)
    Install-Scoop

    # Phase 3: packages
    Install-AllPackages

    # Phase 4: system tweaks
    Apply-AllTweaks

    # Phase 5: symlinks
    New-ConfigLinks

    # Phase 6: autostart
    Register-Autostart

    # Phase 7: WSL + Arch
    if (Confirm-Prompt "Install Arch Linux on WSL2?" "Y") {
        Install-WSLArch
    }

    # Phase 8: summary
    Show-Summary
}

Main
