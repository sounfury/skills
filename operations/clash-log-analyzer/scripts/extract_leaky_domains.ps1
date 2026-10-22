param(
    [string]$LogPath = "",
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

if ([string]::IsNullOrEmpty($LogPath)) {
    $LogPath = "C:\Users\Administrator\AppData\Roaming\mihomo-party\logs\core-$Date.log"
}

if (-not (Test-Path $LogPath)) {
    Write-Error "Log file not found: $LogPath"
    exit 1
}

Write-Host "Reading log: $LogPath" -ForegroundColor Cyan

$lines = Get-Content -Path $LogPath -Encoding UTF8

$domains = $lines | Where-Object {
    $_ -match [regex]::Escape("match Match using") -and $_ -match "\u6f0f\u7f51\u4e4b\u9c7c"
} | ForEach-Object {
    if ($_ -match '-->\s+([^\s:]+):\d+\s+match Match') {
        $Matches[1]
    }
} | Where-Object {
    # IP
    $_ -ne $null -and $_ -notmatch '^\d+\.\d+\.\d+\.\d+$'
} | Sort-Object -Unique

Write-Host ""
Write-Host "Found $($domains.Count) unique domains:" -ForegroundColor Green
Write-Host ""
$domains | ForEach-Object { Write-Host "  $_" }

$domains -join "`n" | Set-Clipboard
Write-Host ""
Write-Host "Result copied to clipboard." -ForegroundColor Yellow
