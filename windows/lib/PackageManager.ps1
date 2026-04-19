function Install-WingetIfNeeded {
    if (Test-Command winget) {
        Log-Success "winget already available"
        return $true
    }

    Log-Info "Installing winget via asheroto/winget-install (PSGallery)..."
    try {
        $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 `
                                        -Force -Scope CurrentUser -ErrorAction Stop
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Install-Script -Name winget-install -Force -Scope CurrentUser -ErrorAction Stop

        $scriptsDir = "$env:USERPROFILE\Documents\WindowsPowerShell\Scripts"
        if ($env:PATH -notlike "*$scriptsDir*") {
            $env:PATH = "$scriptsDir;$env:PATH"
        }

        & winget-install -Force
    } catch {
        Record-Error "winget-install failed: $_"
        return $false
    }

    if (Test-Command winget) {
        Log-Success "winget installed"
        return $true
    }

    Record-Error "winget still not available after install attempt"
    return $false
}

function Install-Scoop {
    if (Test-Command scoop) {
        Log-Success "scoop already installed"
        return
    }

    Log-Info "Installing scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    # -RunAsAdmin: scoop discourages this, but this setup script requires admin,
    # so it's the only way to keep a single-process install.
    Invoke-Expression "& { $(Invoke-RestMethod get.scoop.sh) } -RunAsAdmin"

    if (Test-Command scoop) {
        scoop bucket add extras | Out-Null
        scoop bucket add nerd-fonts | Out-Null
        Log-Success "scoop installed with extras and nerd-fonts buckets"
    } else {
        Record-Error "Failed to install scoop"
    }
}

function Install-Package {
    param(
        [string]$Name,
        [string]$WingetId,
        [string]$ScoopName
    )

    if ($WingetId) {
        Log-Info "Installing $Name via winget ($WingetId)..."
        winget install --id $WingetId --exact --silent --disable-interactivity `
                       --accept-source-agreements --accept-package-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Log-Success "$Name installed via winget"
            return
        }
        Log-Warn "winget install failed for $Name (exit $LASTEXITCODE)"
    }

    if ($ScoopName) {
        Log-Info "Trying $Name via scoop ($ScoopName)..."
        scoop install $ScoopName | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Log-Success "$Name installed via scoop"
            return
        }
        Record-Error "Failed to install $Name (tried winget and scoop)"
        return
    }

    if (-not $ScoopName -and -not $WingetId) {
        Record-Error "No package source defined for $Name"
    } elseif (-not $ScoopName) {
        Record-Error "Failed to install $Name via winget, no scoop fallback defined"
    }
}
