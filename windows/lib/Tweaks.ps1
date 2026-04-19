function Enable-LongPaths {
    Log-Info "Enabling long path support..."
    try {
        New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
                         -Name 'LongPathsEnabled' -Value 1 -PropertyType DWord -Force | Out-Null
        Log-Success "Long paths enabled"
    } catch {
        Record-Error "Failed to enable long paths: $_"
    }
}

function Disable-Animations {
    Log-Info "Disabling unnecessary animations..."
    try {
        Set-ItemProperty 'HKCU:\Control Panel\Accessibility' -Name 'MessageDuration' -Value 1
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -Value 3
        Log-Success "Animations disabled"
    } catch {
        Record-Error "Failed to disable animations: $_"
    }
}

function Set-DarkMode {
    Log-Info "Setting dark mode..."
    try {
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 0
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 0
        Log-Success "Dark mode enabled"
    } catch {
        Record-Error "Failed to set dark mode: $_"
    }
}

function Set-ExplorerTweaks {
    Log-Info "Applying Explorer tweaks..."
    try {
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1
        Log-Success "File extensions shown, hidden files visible"
    } catch {
        Record-Error "Failed to apply Explorer tweaks: $_"
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value
    )
    try {
        Set-ItemProperty $Path -Name $Name -Value $Value -ErrorAction Stop
    } catch [System.UnauthorizedAccessException] {
        # Fallback to reg.exe which works as admin regardless of key ownership
        $hive = if ($Path -match '^HKLM:') { 'HKLM' } else { 'HKCU' }
        $subKey = $Path -replace '^HK[LC]U:\\',''
        reg.exe add "$hive\$subKey" /v $Name /t REG_DWORD /d $Value /f 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    }
}

function Hide-Taskbar {
    Log-Info "Configuring taskbar..."

    # Auto-hide taskbar via StuckRects3
    $stuckPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    if (Test-Path $stuckPath) {
        try {
            $settings = (Get-ItemProperty $stuckPath).Settings
            $settings[8] = 3
            Set-ItemProperty $stuckPath -Name Settings -Value $settings -ErrorAction Stop
        } catch {
            Log-Warn "Could not set taskbar auto-hide: $_"
        }
    }

    # Disable Chat and Task View buttons
    $advPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    try {
        Set-ItemProperty $advPath -Name TaskbarMn -Value 0 -ErrorAction Stop
    } catch {
        Log-Warn "Could not disable Chat button: $_"
    }
    try {
        Set-ItemProperty $advPath -Name ShowTaskViewButton -Value 0 -ErrorAction Stop
    } catch {
        Log-Warn "Could not disable Task View button: $_"
    }

    # Remove Widgets and Copilot via AppxPackage (avoids SYSTEM-owned registry keys)
    Get-Process *Widget* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-AppxPackage Microsoft.WidgetsPlatformRuntime -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxPackage MicrosoftWindows.Client.WebExperience -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers *Copilot* -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    Log-Success "Taskbar configured, widgets/copilot removed"
}

function Disable-WinLock {
    if (-not (Confirm-Prompt "Disable Win+L lock screen? Needed for whkd Win key bindings" "N")) {
        return
    }
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty $path -Name DisabledHotkeys -Value 'L'
        Log-Success "Win+L disabled; requires logoff/logon"
    } catch {
        Record-Error "Failed to disable Win+L: $_"
    }
}

function Enable-DeveloperMode {
    Log-Info "Enabling Developer Mode..."
    try {
        $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        New-ItemProperty -Path $path -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 `
                         -PropertyType DWord -Force | Out-Null
        Log-Success "Developer Mode enabled"
    } catch {
        Record-Error "Failed to enable Developer Mode: $_"
    }
}

function Apply-AllTweaks {
    Enable-LongPaths
    Enable-DeveloperMode
    Disable-Animations
    Set-DarkMode
    Set-ExplorerTweaks
    Hide-Taskbar
    Disable-WinLock
}
