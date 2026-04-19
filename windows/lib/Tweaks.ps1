function Enable-LongPaths {
    Log-Info "Enabling long path support..."
    try {
        Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
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

function Hide-Taskbar {
    Log-Info "Auto-hiding taskbar..."
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        if (Test-Path $path) {
            $settings = (Get-ItemProperty $path).Settings
            $settings[8] = 3  # Enable auto-hide
            Set-ItemProperty $path -Name Settings -Value $settings
        }
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name TaskbarDa -Value 0
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name TaskbarMn -Value 0
        Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ShowCopilotButton -Value 0
        Log-Success "Taskbar hidden, widgets/cocopilot disabled"
    } catch {
        Record-Error "Failed to hide taskbar: $_"
    }
}

function Disable-WinLock {
    if (-not (Confirm-Prompt "Disable Win+L lock screen? (Needed for whkd Win key bindings)" "N")) {
        return
    }
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty $path -Name DisabledHotkeys -Value 'L'
        Log-Success "Win+L disabled (requires logoff/logon)"
    } catch {
        Record-Error "Failed to disable Win+L: $_"
    }
}

function Apply-AllTweaks {
    Enable-LongPaths
    Disable-Animations
    Set-DarkMode
    Set-ExplorerTweaks
    Hide-Taskbar
    Disable-WinLock
}
