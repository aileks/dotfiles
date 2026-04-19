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
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey(
            $Path -replace '^HKCU:\\','',
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [System.Security.AccessControl.RegistryRights]::TakeOwnership
        )
        $acl = $key.GetAccessControl()
        $acl.SetOwner([System.Security.Principal.WindowsIdentity]::GetCurrent().User)
        $key.SetAccessControl($acl)
        $key.Close()

        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
            $Path -replace '^HKCU:\\','',
            $true
        )
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
            [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
            'FullControl', 'Allow'
        )
        $acl = $key.GetAccessControl()
        $acl.AddAccessRule($rule)
        $key.SetAccessControl($acl)
        $key.Close()

        Set-ItemProperty $Path -Name $Name -Value $Value
    }
}

function Hide-Taskbar {
    Log-Info "Auto-hiding taskbar..."
    try {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        if (Test-Path $path) {
            $settings = (Get-ItemProperty $path).Settings
            $settings[8] = 3
            Set-ItemProperty $path -Name Settings -Value $settings
        }
        $advPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-RegistryValue $advPath TaskbarDa 0
        Set-RegistryValue $advPath TaskbarMn 0
        Set-RegistryValue $advPath ShowCopilotButton 0
        Log-Success "Taskbar hidden, widgets/copilot disabled"
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
