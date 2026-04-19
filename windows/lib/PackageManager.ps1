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

function Install-GitIfNeeded {
    if (Test-Command git) {
        Log-Success "git already available"
        return $true
    }

    Log-Info "Installing git via winget..."
    winget install --id Git.Git -e --source winget --silent --disable-interactivity `
                   --accept-source-agreements --accept-package-agreements | Out-Null
    if ($LASTEXITCODE -eq 0 -and (Test-Command git)) {
        Log-Success "git installed via winget"
        return $true
    }

    Log-Warn "winget install failed, downloading Git for Windows installer..."
    $url = 'https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.3/Git-2.53.0.3-64-bit.exe'
    $installer = Join-Path -Path $env:TEMP -ChildPath 'Git-2.53.0.3-64-bit.exe'

    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS' -Wait
        Remove-Item $installer -Force -ErrorAction SilentlyContinue
    } catch {
        Record-Error "Failed to install git: $_"
        return $false
    }

    if (Test-Command git) {
        Log-Success "git installed"
        return $true
    }

    Record-Error "git still not available after install attempt"
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
        Log-Success "scoop installed with extras bucket"
    } else {
        Record-Error "Failed to install scoop"
    }
}

function Install-WingetPackage {
    param(
        [string]$Name,
        [string]$Id
    )

    winget list --id $Id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$Name already installed"
        return
    }

    Log-Info "Installing $Name via winget ($Id)..."
    winget install --id $Id --exact --silent --disable-interactivity `
                   --accept-source-agreements --accept-package-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$Name installed"
    } else {
        Record-Error "Failed to install $Name via winget (exit $LASTEXITCODE)"
    }
}

function Install-ScoopPackage {
    param(
        [string]$Name,
        [string]$Package
    )

    $installed = scoop list $Package 2>$null
    if ($installed -match $Package) {
        Log-Success "$Name already installed"
        return
    }

    Log-Info "Installing $Name via scoop ($Package)..."
    scoop install $Package | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$Name installed"
    } else {
        Record-Error "Failed to install $Name via scoop (exit $LASTEXITCODE)"
    }
}
