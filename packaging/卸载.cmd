@echo off
chcp 65001 >nul
title SpektraLab 卸载程序
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
pause
