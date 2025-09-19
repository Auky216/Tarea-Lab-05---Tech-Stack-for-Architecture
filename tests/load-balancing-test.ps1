# Load Balancing Verification Test
param(
    [string]$baseUrl = "http://localhost:8080",
    [int]$requests = 100
)

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "      LOAD BALANCING TEST" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "Sending $requests requests to test distribution...`n" -ForegroundColor Yellow

$serverCounts = @{}
$responseTimes = @()

for ($i = 1; $i -le $requests; $i++) {
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/tickets" -Method GET
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        $responseTimes += $duration
        
        $server = $response.server
        
        if ($serverCounts.ContainsKey($server)) {
            $serverCounts[$server]++
        } else {
            $serverCounts[$server] = 1
        }
        
        # Progress indicator
        if ($i % 10 -eq 0) {
            Write-Host "Progress: $i/$requests requests completed..." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[ERROR] Request $i failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n[DISTRIBUTION RESULTS]" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Gray

$total = ($serverCounts.Values | Measure-Object -Sum).Sum

foreach ($server in $serverCounts.Keys | Sort-Object) {
    $count = $serverCounts[$server]
    $percentage = [math]::Round(($count / $total) * 100, 2)
    $barLength = [math]::Floor($percentage / 2)
    $bar = "=" * $barLength
    
    Write-Host "$server : $count requests ($percentage%)" -ForegroundColor White
    Write-Host "  $bar" -ForegroundColor Green
}

Write-Host "`n[PERFORMANCE METRICS]" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Gray

$avgTime = ($responseTimes | Measure-Object -Average).Average
$minTime = ($responseTimes | Measure-Object -Minimum).Minimum
$maxTime = ($responseTimes | Measure-Object -Maximum).Maximum

Write-Host "Average Response Time: $([math]::Round($avgTime, 2))ms" -ForegroundColor White
Write-Host "Min Response Time: $([math]::Round($minTime, 2))ms" -ForegroundColor Green
Write-Host "Max Response Time: $([math]::Round($maxTime, 2))ms" -ForegroundColor Yellow

# Check if distribution is balanced
$expectedPercentage = 100.0 / $serverCounts.Count
$isBalanced = $true

foreach ($count in $serverCounts.Values) {
    $percentage = ($count / $total) * 100
    $deviation = [math]::Abs($percentage - $expectedPercentage)
    
    if ($deviation -gt 15) {
        $isBalanced = $false
        break
    }
}

Write-Host "`n[LOAD BALANCING STATUS]" -ForegroundColor Cyan
if ($isBalanced) {
    Write-Host "[OK] Load is well balanced (deviation < 15%)" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Load distribution has significant deviation" -ForegroundColor Yellow
}

# Create results directory if it doesn't exist
if (!(Test-Path "tests/results")) {
    New-Item -ItemType Directory -Path "tests/results" -Force | Out-Null
}

# Save results
$results = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalRequests = $requests
    distribution = $serverCounts
    performance = @{
        averageMs = [math]::Round($avgTime, 2)
        minMs = [math]::Round($minTime, 2)
        maxMs = [math]::Round($maxTime, 2)
    }
    isBalanced = $isBalanced
}

$results | ConvertTo-Json | Out-File "tests/results/load-balancing-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
Write-Host "`n[INFO] Results saved to tests/results/" -ForegroundColor Gray