# Master Bootstrapper for Autopilot HWID Collection
# This script ensures both required scripts are present and runs the main collection script.

$ErrorActionPreference = 'Stop'

# Define script names
$autopilotScript = 'Get-WindowsAutopilotInfo.ps1'
$mainScript = 'AutoExportHWID_Tagged.ps1'

# Check for Get-WindowsAutopilotInfo.ps1
if (-not (Test-Path ".\$autopilotScript")) {
    Write-Host "ERROR: $autopilotScript not found in the current directory!" -ForegroundColor Red
    Write-Host "Please copy $autopilotScript to this folder before running this tool." -ForegroundColor Yellow
    exit 1
}

# Check for AutoExportHWID_Tagged.ps1
if (-not (Test-Path ".\$mainScript")) {
    Write-Host "ERROR: $mainScript not found in the current directory!" -ForegroundColor Red
    Write-Host "Please copy $mainScript to this folder before running this tool." -ForegroundColor Yellow
    exit 1
}

# Run the main script
Write-Host "Running $mainScript..." -ForegroundColor Cyan
& .\$mainScript
