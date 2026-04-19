$ESC = [char]27

function Log-Info    { param([string]$Message) Write-Host "$ESC[34m[INFO]$ESC[0m $Message" }
function Log-Success { param([string]$Message) Write-Host "$ESC[32m[OK]$ESC[0m $Message" }
function Log-Warn    { param([string]$Message) Write-Host "$ESC[33m[WARN]$ESC[0m $Message" }
function Log-Error   { param([string]$Message) Write-Host "$ESC[31m[ERROR]$ESC[0m $Message" }

function Record-Error {
    param([string]$Message)
    Log-Error $Message
    $script:SetupErrors += $Message
}
