@echo off
REM CMD / PowerShell wrapper for scripts/home-doctor on Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0home-doctor.ps1" %*
exit /b %ERRORLEVEL%
