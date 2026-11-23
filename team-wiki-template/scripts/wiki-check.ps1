# PowerShell wrapper for scripts/wiki-check on Windows
$ErrorActionPreference = "Stop"
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 "$PSScriptRoot\wiki-check" @args
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python "$PSScriptRoot\wiki-check" @args
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 "$PSScriptRoot\wiki-check" @args
} else {
    Write-Error "Python 3 not found in PATH."
    exit 2
}
exit $LASTEXITCODE
