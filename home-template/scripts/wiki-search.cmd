@echo off
setlocal
where python3 >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  python3 "%~dp0wiki-search" %*
  exit /b %ERRORLEVEL%
)
python "%~dp0wiki-search" %*
exit /b %ERRORLEVEL%
