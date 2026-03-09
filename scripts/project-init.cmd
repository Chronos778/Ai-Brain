@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0project-init.ps1" %*
exit /b %errorlevel%