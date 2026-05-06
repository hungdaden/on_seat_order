@echo off
setlocal
set CMD=%~1

if "%CMD%"=="opensv" goto :start_server
if "%CMD%"=="closesv" goto :stop_server

:: Neu khong go lenh, huong dan su dung
echo Cu phap su dung:
echo   sv.bat opensv   - De mo may chu
echo   sv.bat closesv - De dong may chu
echo.
pause
exit /b

:start_server
title Pho Cam Pha - Server (DANG CHAY)
echo ---------------------------------------------------
echo       PHO CAM PHA - DANG MO SERVER
echo ---------------------------------------------------
:: Tim IP
powershell -NoProfile -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.InterfaceAlias -notlike '*Virtual*' -and $_.InterfaceAlias -notlike '*VMware*' -and $_.InterfaceAlias -notlike '*Radmin*' } | Select-Object -ExpandProperty IPAddress | Select-Object -First 1; Write-Host 'Dia chi IP may chu: ' -NoNewline; Write-Host $ip -ForegroundColor Cyan"
echo.
dart run server/bin/server.dart
pause
exit /b

:stop_server
echo [He thong] Dang tim va dong server tren cong 8080...
:: Tim PID cua tien trinh dang dung cong 8080 va tat no
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080') do (
    taskkill /F /PID %%a >nul 2>&1
    echo [OK] Da tat tien trinh PID: %%a
)
echo ---------------------------------------------------
echo [Ket qua] Da dong toan bo server Pho Cam Pha.
echo ---------------------------------------------------
pause
exit /b
