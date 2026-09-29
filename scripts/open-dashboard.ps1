$ErrorActionPreference = 'Stop'
$dashboard = Join-Path (Split-Path -Parent $PSScriptRoot) 'dashboard.html'
if (-not (Test-Path -LiteralPath $dashboard -PathType Leaf)) { throw "Dashboard file not found: $dashboard" }
Start-Process -FilePath $dashboard