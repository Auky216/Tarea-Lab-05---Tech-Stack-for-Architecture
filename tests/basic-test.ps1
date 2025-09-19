# Run All Tests - Master Test Runner

Write-Host "`n=============================================================" -ForegroundColor Cyan
Write-Host "     TICKET SYSTEM - COMPLETE TEST SUITE" -ForegroundColor Cyan
Write-Host "=============================================================`n" -ForegroundColor Cyan

# Create results directory if it doesn't exist
if (!(Test-Path "tests/results")) {
    New-Item -ItemType Directory -Path "tests/results" | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = "tests/results/complete-test-$timestamp.log"

function Write-Log {
    param([string]$message, [string]$color = "White")
    
    $logMessage = "[$(Get-Date -Format 'HH:mm:ss')] $message"
    Write-Host $logMessage -ForegroundColor $color
    $logMessage | Out-File -Append $logFile
}

# Test 1: Basic Functionality
Write-Log "`n=== TEST 1: BASIC FUNCTIONALITY ===" "Yellow"
& "$PSScriptRoot/basic-test.ps1"
Start-Sleep -Seconds 2

# Test 2: Load Balancing
Write-Log "`n=== TEST 2: LOAD BALANCING ===" "Yellow"
& "$PSScriptRoot/load-balancing-test.ps1" -requests 50
Start-Sleep -Seconds 2

# Test 3: Concurrency
Write-Log "`n=== TEST 3: CONCURRENCY (DOUBLE-BOOKING) ===" "Yellow"
& "$PSScriptRoot/concurrency-test.ps1" -concurrentRequests 20
Start-Sleep -Seconds 2

# Test 4: Stress Test (optional)
Write-Log "`n=== TEST 4: STRESS TEST ===" "Yellow"
Write-Host "[WARNING] Stress test will take ~5 minutes. Run it? (y/n)" -ForegroundColor Yellow
$runStress = Read-Host
if ($runStress -eq "y") {
    & "$PSScriptRoot/stress-test.ps1"
}

# Generate Summary Report
Write-Log "`n=== GENERATING SUMMARY REPORT ===" "Yellow"

$summaryFile = "tests/results/SUMMARY-$timestamp.md"

$summary = @"
# Test Suite Summary - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Tests Executed

1. [OK] Basic Functionality Test
2. [OK] Load Balancing Test  
3. [OK] Concurrency Test (Double-booking prevention)
4. $(if ($runStress -eq "y") { "[OK]" } else { "[SKIP]" }) Stress Test

## Results Location

All test results are saved in: tests/results/

## Quick Summary

- **Basic Tests**: Check individual test files in results/
- **Load Balancing**: Verify distribution is ~50-50
- **Concurrency**: Should show exactly 1 success, rest conflicts
- **Stress Test**: Check Artillery HTML report

## Next Steps

1. Review detailed results in JSON files
2. Check HTML reports (if generated)
3. Analyze any failures
4. Document findings in RESULTADOS-POC.md

---
Generated at: $(Get-Date)
"@

$summary | Out-File $summaryFile

Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "                ALL TESTS COMPLETED!" -ForegroundColor Green
Write-Host "=============================================================`n" -ForegroundColor Green

Write-Host "[INFO] Results saved to tests/results/" -ForegroundColor Cyan
Write-Host "[INFO] Summary: $summaryFile" -ForegroundColor Cyan
Write-Host "[INFO] Full log: $logFile" -ForegroundColor Cyan