param($InputIP)

# Tim IP neu dung tu khoa currentip
if ($InputIP -eq "currentip") {
    Write-Host "[Info] Dang tu dong tim IP Wi-Fi/Ethernet..." -ForegroundColor Cyan
    # Chi lay cac card mang dang co Gateway (dang vao duoc mang) va loai bo cac adapter ao
    $Config = Get-NetIPConfiguration | Where-Object { 
        $_.IPv4DefaultGateway -ne $null -and 
        $_.InterfaceAlias -notlike '*Virtual*' -and 
        $_.InterfaceAlias -notlike '*VMware*' -and 
        $_.InterfaceAlias -notlike '*Radmin*' 
    } | Select-Object -First 1
    
    if ($Config) {
        $InputIP = $Config.IPv4Address.IPAddress
    }
}

if (-not $InputIP) {
    Write-Host "`n[LOI] Khong tim thay dia chi IP. Vui long nhap thu cong." -ForegroundColor Red
    Write-Host "Cu phap: .\genqr.bat 192.168.1.10"
    exit
}

# Chuan hoa URL
$HostUrl = if ($InputIP -like "http*") { $InputIP } else { "http://$($InputIP):8080" }

Write-Host "`n[Pho Cam Pha] Dang tao lai ma QR cho dia chi: $HostUrl" -ForegroundColor Green
Write-Host "--------------------------------------------------------"

# Chay lenh Dart
dart run server/bin/generate_qr.dart $HostUrl

Write-Host "`n[OK] Da xong! Ma QR moi nam trong: server/qr_codes" -ForegroundColor Yellow
Write-Host "Nhan phim bat ky de thoat..."
$null = [Console]::ReadKey()
