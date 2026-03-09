@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0brain-verify.ps1" %*
exit /b %errorlevel%
