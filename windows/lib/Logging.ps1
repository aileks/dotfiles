function Log-Info    { Write-Host "`e[34m[INFO]`e[0m $args" }
function Log-Success { Write-Host "`e[32m[OK]`e[0m $args" }
function Log-Warn    { Write-Host "`e[33m[WARN]`e[0m $args" }
function Log-Error   { Write-Host "`e[31m[ERROR]`e[0m $args" }

function Record-Error {
    param([string]$Message)
    Log-Error $Message
    $script:SetupErrors += $Message
}
