# Stress Test Runner
param(
    [int]$duration = 300,
    [int]$rps = 50
)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "         STRESS TEST" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "[WARNING] This will run a stress test for $duration seconds" -ForegroundColor Yellow
Write-Host "Target: $rps requests/second`n" -ForegroundColor Yellow

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Test cancelled" -ForegroundColor Gray
    exit
}

Write-Host "`n[INFO] Starting stress test...`n" -ForegroundColor Green

# Check if Artillery is installed
try {
    npx artillery -V | Out-Null
} catch {
    Write-Host "[ERROR] Artillery not found. Installing..." -ForegroundColor Red
    npm install --save-dev artillery
}

# Run Artillery test
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportFile = "tests/results/stress-test-$timestamp.json"

npx artillery run tests/stress-test.yml --output $reportFile

Write-Host "`n[INFO] Generating HTML report..." -ForegroundColor Cyan
npx artillery report $reportFile --output "tests/results/stress-test-$timestamp.html"

Write-Host "`n[SUCCESS] Test completed!" -ForegroundColor Green
Write-Host "[INFO] Results saved to:" -ForegroundColor White
Write-Host "   - JSON: $reportFile" -ForegroundColor Gray
Write-Host "   - HTML: tests/results/stress-test-$timestamp.html" -ForegroundColor Gray

# Open HTML report
$htmlReport = "tests/results/stress-test-$timestamp.html"
if (Test-Path $htmlReport) {
    Write-Host "`n[INFO] Opening report in browser..." -ForegroundColor Cyan
    Start-Process $htmlReport
}