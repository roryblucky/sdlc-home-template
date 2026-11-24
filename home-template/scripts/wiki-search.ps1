$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'wiki-search'
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    & python3 $scriptPath @args
    exit $LASTEXITCODE
} else {
    & python $scriptPath @args
    exit $LASTEXITCODE
}
