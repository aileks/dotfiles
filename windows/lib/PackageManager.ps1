function Install-WingetIfNeeded {
    if (Test-Command winget) {
        Log-Success "winget already available"
        return $true
    }

    Log-Info "winget not found. Installing via asheroto/winget-install..."

    try {
        Invoke-RestMethod https://github.com/asheroto/winget-install/raw/main/winget-install.ps1 |
            Invoke-Expression
    } catch {
        Record-Error "winget-install script failed: $_"
        return $false
    }

    if (Test-Command winget) {
        Log-Success "winget installed"
        return $true
    }

    Record-Error "winget still not available after install attempt"
    return $false
}

function Update-WingetIfNeeded {
    Log-Info "Checking winget version..."
    try {
        winget source reset --force --accept-source-agreements 2>$null
        $null = winget upgrade --id Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements 2>$null
        Log-Success "winget up to date"
    } catch {
        Log-Warn "Could not update winget: $_"
    }
}

function Install-Scoop {
    if (Test-Command scoop) {
        Log-Success "scoop already installed"
        return
    }

    Log-Info "Installing scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression

    if (Test-Command scoop) {
        scoop bucket add extras
        Log-Success "scoop installed with extras bucket"
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
        $result = winget install --id $WingetId --accept-source-agreements --accept-package-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Success "$Name installed via winget"
            return
        }
        Log-Warn "winget install failed for $Name (exit $LASTEXITCODE)"
    }

    if ($ScoopName) {
        Log-Info "Trying $Name via scoop ($ScoopName)..."
        scoop install $ScoopName 2>$null
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
