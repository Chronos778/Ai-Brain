@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0brain-learn.ps1" %*
exit /b %errorlevel%
