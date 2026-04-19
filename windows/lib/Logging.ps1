$ESC = [char]27

function Log-Info    { Write-Host "$ESC[34m[INFO]$ESC[0m $args" }
function Log-Success { Write-Host "$ESC[32m[OK]$ESC[0m $args" }
function Log-Warn    { Write-Host "$ESC[33m[WARN]$ESC[0m $args" }
function Log-Error   { Write-Host "$ESC[31m[ERROR]$ESC[0m $args" }

function Record-Error {
    param([string]$Message)
    Log-Error $Message
    $script:SetupErrors += $Message
}
