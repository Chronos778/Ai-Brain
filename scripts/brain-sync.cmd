@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0brain-sync.ps1" %*
exit /b %errorlevel%
