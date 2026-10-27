Set-Location $PSScriptRoot
Write-Host "Starting ParilGPT Backend Server..." -ForegroundColor Cyan
& ".\.venv\Scripts\python.exe" main.py
