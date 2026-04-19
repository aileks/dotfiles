function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Confirm-Prompt {
    param(
        [string]$Prompt,
        [string]$Default = 'N'
    )
    $defaultLabel = if ($Default -eq 'Y') { 'Y/n' } else { 'y/N' }
    $reply = Read-Host "$Prompt [$defaultLabel]"
    if (-not $reply) { $reply = $Default }
    return $reply -match '^[Yy]$'
}

function Backup-File {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupDir = "$HOME\.config-backup.$timestamp"

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $dest = Join-Path -Path $backupDir -ChildPath (Split-Path $Path -Leaf)
    Move-Item -Path $Path -Destination $dest -Force
    Log-Info "Backed up $Path -> $dest"
}

function New-Symlink {
    param(
        [string]$Source,
        [string]$Target
    )

    if (-not (Test-Path $Source)) {
        Record-Error "Source missing: $Source"
        return
    }

    if ((Test-Path $Target) -and (Get-Item $Target).Target -eq $Source) {
        Log-Success "Already linked: $Target"
        return
    }

    if (Test-Path $Target) {
        Backup-File $Target
    }

    $targetDir = Split-Path $Target -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    try {
        if (Test-Path $Source -PathType Container) {
            New-Item -ItemType Junction -Path $Target -Target $Source -Force | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        }
        Log-Success "Linked: $Target"
    } catch {
        Record-Error "Failed to link $Target -> $Source : $_"
    }
}
