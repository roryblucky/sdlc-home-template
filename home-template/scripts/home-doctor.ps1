# PowerShell wrapper for scripts/home-doctor on Windows.
# Finds Git for Windows' bundled bash.exe (not WSL bash) and runs ./scripts/home-doctor.
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$GitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $GitCmd) {
    Write-Error "git not found in PATH. Please install Git for Windows."
    exit 2
}

$GitRoot = Split-Path -Parent (Split-Path -Parent $GitCmd.Source)
$Candidates = @(
    (Join-Path $GitRoot "bin\bash.exe"),
    (Join-Path $GitRoot "usr\bin\bash.exe"),
    "C:\Program Files\Git\bin\bash.exe"
)

$BashExe = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $BashExe) {
    $BashExe = "bash"
}

& $BashExe "./scripts/home-doctor" @args
exit $LASTEXITCODE
