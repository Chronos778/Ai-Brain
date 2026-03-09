@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0brain-adapt.ps1" %*
exit /b %errorlevel%
