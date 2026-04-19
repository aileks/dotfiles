# Environment
$env:EDITOR = 'code'
$env:VISUAL = 'code'
$env:SUDO_EDITOR = 'code'
$env:MANPAGER = 'bat -plman'
$env:SSH_AUTH_SOCK = "$HOME\.bitwarden-ssh-agent.sock"

# PATH additions
$env:PATH += ";$HOME\.local\bin"

# General aliases
Set-Alias -Name c -Value Clear-Host
Set-Alias -Name ff -Value fastfetch

# eza (ls replacement)
function la { eza -al --color=always --icons --group-directories-first @args }
function lt { eza -aT --color=always --icons --group-directories-first @args }
function ls { eza --color=always --icons --group-directories-first @args }

# Git aliases
function ga { git add @args }
function gaa { git add --all @args }
function gb { git branch @args }
function gco { git checkout @args }
function gcb { git checkout -b @args }
function gcmsg { git commit -m @args }
function gd { git diff @args }
function gf { git fetch @args }
function gl { git pull @args }
function gp { git push @args }
function gst { git status @args }
function glog { git log --oneline --decorate --graph @args }
function gsh { git stash @args }
function gsha { git stash apply @args }
function gcl { git clone @args }

# FZF
$env:FZF_DEFAULT_OPTS = @"
  --multi
  --border=top
  --color=fg:#a7a7a7
  --color=fg+:#d5d5d5
  --color=bg:#121212
  --color=bg+:#323232
  --color=hl:#c4693d
  --color=hl+:#e49a44
  --color=info:#a7a7a7
  --color=marker:#c4693d
  --color=prompt:#c4693d
  --color=spinner:#d87c4a
  --color=pointer:#e5a72a
  --color=header:#b14242
  --color=border:#a7a7a7
  --color=query:#d5d5d5
  --color=gutter:#121212
  --highlight-line
  --info=inline-right
  --layout=reverse
  --pointer=[0x2588]
  --scrollbar=[0x258c]
"@

# Starship
Invoke-Expression (&starship init powershell)

# Zoxide
Invoke-Expression (& { $hook = if ($PSVersionTable.PSVersion.Major -ge 6) { 'prompt' } else { 'pwd' }; (zoxide init powershell --hook $hook | Out-String) })

# PSFzf
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsfFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseAcceptance 'Ctrl+r'
}
