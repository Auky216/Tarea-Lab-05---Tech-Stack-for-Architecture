Write-Host "🚀 Iniciando servicios localmente..." -ForegroundColor Green

# Iniciar Sales Service - 2 instancias
Start-Process powershell -ArgumentList "-NoExit", "-Command", "`$env:PORT=3001; node services/sales-service/index.js"
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "`$env:PORT=3011; node services/sales-service/index.js"

# Iniciar Accounting Service - 2 instancias  
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "`$env:PORT=3002; node services/accounting-service/index.js"
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "`$env:PORT=3012; node services/accounting-service/index.js"

Write-Host "✅ Servicios iniciados:" -ForegroundColor Green
Write-Host "   Sales: http://localhost:3001 y http://localhost:3011" -ForegroundColor Cyan
Write-Host "   Accounting: http://localhost:3002 y http://localhost:3012" -ForegroundColor Cyan
Write-Host ""
Write-Host "Presiona Ctrl+C para detener este script (los servicios seguirán corriendo)" -ForegroundColor Yellow