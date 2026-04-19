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
        Log-Warn "LTSC edition detected - winget may need manual installation"
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
        @{ Src = 'fastfetch\config.jsonc';            Tgt = "$HOME\.config\fastfetch\config.jsonc" }
        @{ Src = 'bat\config';                        Tgt = "$HOME\.config\bat\config" }
        @{ Src = 'starship\starship.toml';             Tgt = "$HOME\.config\starship.toml" }
    )

    foreach ($link in $links) {
        $src = if ($link.AbsoluteSrc) { $link.AbsoluteSrc } else { Join-Path -Path $ScriptDir -ChildPath $link.Src }
        New-Symlink -Source $src -Target $link.Tgt
    }
}

# -- Phase 5: Autostart ----------------------------------------

function Register-Autostart {
    Log-Info "Setting up komorebi autostart..."
    try {
        komorebic enable-autostart --whkd
        Log-Success "Komorebi autostart enabled"
    } catch {
        Record-Error "Failed to enable komorebi autostart: $_"
    }
}

# -- Phase 6: WSL ---------------------------------

function Enable-WSL {
    Log-Info "Enabling WSL..."

    $wslEnabled = $false
    try {
        $null = wsl --status 2>$null
        $wslEnabled = $true
    } catch {}

    if ($wslEnabled) {
        Log-Success "WSL already enabled"
        return
    }

    try {
        wsl --install --no-distribution 2>$null
        if ($LASTEXITCODE -ne 0) {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>$null
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>$null
        }
        wsl --set-default-version 2 2>$null
        Log-Success "WSL features enabled; reboot may be required"
    } catch {
        Record-Error "Failed to enable WSL: $_"
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

    # Phase 7: WSL
    Enable-WSL

    # Phase 8: summary
    Show-Summary
}

Main
