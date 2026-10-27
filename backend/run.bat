@echo off
cd /d "%~dp0"
echo Starting ParilGPT Backend Server...
.\.venv\Scripts\python.exe main.py
pause
