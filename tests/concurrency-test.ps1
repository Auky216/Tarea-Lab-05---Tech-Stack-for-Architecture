# Concurrency Test
param(
    [string]$baseUrl = "http://localhost:8080",
    [int]$concurrentRequests = 50
)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "      CONCURRENCY TEST" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "This test will attempt to buy the same ticket with $concurrentRequests concurrent requests" -ForegroundColor Yellow
Write-Host "Expected: Only 1 should succeed, others should fail (409 Conflict)`n" -ForegroundColor Yellow

# Get available tickets
$tickets = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method GET
if ($tickets.tickets.Count -eq 0) {
    Write-Host "[ERROR] No tickets available for testing!" -ForegroundColor Red
    exit
}

$targetTicket = $tickets.tickets[0]

Write-Host "Target ticket: $($targetTicket.event) - Seat $($targetTicket.seat)" -ForegroundColor Cyan
Write-Host "Starting $concurrentRequests concurrent purchase attempts...`n" -ForegroundColor Yellow

# Create jobs for concurrent requests
$jobs = @()

for ($i = 1; $i -le $concurrentRequests; $i++) {
    $job = Start-Job -ScriptBlock {
        param($url, $ticketId, $index)
        
        $body = @{
            ticketId = $ticketId
            customerName = "Concurrent User $index"
            customerEmail = "user$index@test.com"
        } | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri "$url/api/orders" `
                -Method POST `
                -ContentType "application/json" `
                -Body $body `
                -ErrorAction Stop
            
            return @{
                Index = $index
                Status = "SUCCESS"
                StatusCode = 201
            }
        }
        catch {
            $statusCode = 0
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode.value__
            }
            return @{
                Index = $index
                Status = "FAILED"
                StatusCode = $statusCode
            }
        }
    } -ArgumentList $baseUrl, $targetTicket.id, $i
    
    $jobs += $job
}

Write-Host "[INFO] Waiting for all requests to complete..." -ForegroundColor Gray

# Wait for all jobs and collect results
$results = $jobs | Wait-Job | Receive-Job

# Clean up jobs
$jobs | Remove-Job

# Analyze results
$successes = ($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
$conflicts = ($results | Where-Object { $_.StatusCode -eq 409 }).Count
$otherFailures = ($results | Where-Object { $_.Status -eq "FAILED" -and $_.StatusCode -ne 409 }).Count

Write-Host "`n[CONCURRENCY TEST RESULTS]" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Gray
Write-Host "Total Requests: $concurrentRequests" -ForegroundColor White
Write-Host "Successful Purchases: $successes" -ForegroundColor $(if ($successes -eq 1) { "Green" } else { "Red" })
Write-Host "Conflicts (409): $conflicts" -ForegroundColor Yellow
Write-Host "Other Failures: $otherFailures" -ForegroundColor $(if ($otherFailures -gt 0) { "Red" } else { "Gray" })

Write-Host "`n[TEST VERDICT]" -ForegroundColor Cyan

if ($successes -eq 1 -and $conflicts -eq ($concurrentRequests - 1)) {
    Write-Host "[PASSED] Exactly 1 purchase succeeded, no double-booking!" -ForegroundColor Green
} elseif ($successes -gt 1) {
    Write-Host "[FAILED] Multiple purchases succeeded (DOUBLE-BOOKING DETECTED!)" -ForegroundColor Red
} else {
    Write-Host "[INCONCLUSIVE] Unexpected result pattern" -ForegroundColor Yellow
}

# Create results directory if it doesn't exist
if (!(Test-Path "tests/results")) {
    New-Item -ItemType Directory -Path "tests/results" -Force | Out-Null
}

# Save results
$testResult = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    concurrentRequests = $concurrentRequests
    targetTicket = $targetTicket
    results = @{
        successes = $successes
        conflicts = $conflicts
        otherFailures = $otherFailures
    }
    verdict = if ($successes -eq 1) { "PASSED" } else { "FAILED" }
}

$testResult | ConvertTo-Json | Out-File "tests/results/concurrency-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
Write-Host "`n[INFO] Results saved to tests/results/" -ForegroundColor Gray