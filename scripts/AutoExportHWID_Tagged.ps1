param(
    [switch]$PauseAtEnd = $false
)
# AutoExportHWID.ps1 - WinPE Compatible Version
# The following line temporarily sets the execution policy to Bypass for this process only,
# allowing the script to run in environments (like WinPE) where the default policy may block script execution.

# Prompt for Org name and validate input
do {
    $org = Read-Host "Enter Org Name (no spaces or special characters)"
    # Sanitize org name for file use
    $org = $org -replace '[^a-zA-Z0-9_-]', ''
    if ([string]::IsNullOrWhiteSpace($org)) {
        Write-Host "Invalid Org Name. Please enter a value with at least one letter, number, underscore, or hyphen." -ForegroundColor Red
    }
} while ([string]::IsNullOrWhiteSpace($org))

# Try multiple methods to get serial number (WinPE compatible)
$serial = $null
try {
    $serial = (Get-WmiObject Win32_BIOS -ErrorAction Stop).SerialNumber
}
catch {}
if ([string]::IsNullOrEmpty($serial)) {
    try {
        $wmicOutput = wmic bios get serialnumber /value | Where-Object { $_ -like "SerialNumber=*" }
        if ($wmicOutput -and $wmicOutput -match "=") {
            $splitOutput = $wmicOutput.Split('=')
            if ($splitOutput.Count -ge 2) {
                $serial = $splitOutput[1].Trim()
            }
        }
    }
    catch {}
}
if ([string]::IsNullOrEmpty($serial)) {
    $serial = "UNKNOWN"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$output = "$PSScriptRoot\HWID-$org-$serial-$timestamp.csv"

# Check for required script
if (-not (Test-Path ".\Get-WindowsAutopilotInfo.ps1")) {
    Write-Error "`nERROR: Get-WindowsAutopilotInfo.ps1 not found in the same folder as this script.`n"
    if ($PauseAtEnd) { Read-Host "Press Enter to exit" }
    exit 1
}

# Run export with WinPE compatibility
Write-Host ""
Write-Host "Generating HWID for Org '$org' and Serial '$serial'..."

try {
    $errorOutput = $null
    $exitCode = $null
    $errorOutput = & .\Get-WindowsAutopilotInfo.ps1 -OutputFile $output -Partner -Force -Verbose 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0 -and (Test-Path $output)) {
        Write-Host "SUCCESS: HWID saved as: $output" -ForegroundColor Green
        # Display the contents
        Write-Host "`nGenerated HWID file contents:" -ForegroundColor Cyan
        Get-Content $output | ForEach-Object { Write-Host $_ -ForegroundColor White }
    }
    else {
        Write-Error "Get-WindowsAutopilotInfo.ps1 failed with exit code $exitCode. Error: $errorOutput"
        throw "Output file was not created or script failed"
    }
}
catch {
    Write-Error "Partner mode failed: $($_.Exception.Message)"
    Write-Host "Trying manual collection..." -ForegroundColor Yellow
    # Gather fallback info
    try {
        $bios = Get-WmiObject Win32_BIOS -ErrorAction SilentlyContinue
        $computerSystem = Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue
        $manualOutput = "$PSScriptRoot\HWID-MANUAL-$org-$serial-$timestamp.csv"
        $csvContent = @"
Org Name,Device Serial Number,Windows Product ID,Hardware Hash,Manufacturer name,Device model
$org,$($bios.SerialNumber),,,${($computerSystem.Manufacturer)},${($computerSystem.Model)}
"@
        $csvContent | Out-File -FilePath $manualOutput -Encoding UTF8
        Write-Host "Manual HWID file created: $manualOutput" -ForegroundColor Green
        # Display the contents
        Write-Host "`nManual HWID file contents:" -ForegroundColor Cyan
        Get-Content $manualOutput | ForEach-Object { Write-Host $_ -ForegroundColor White }
    }
    catch {
        Write-Error "Manual collection also failed: $($_.Exception.Message)"
        Write-Host "WinPE may be missing required WMI components" -ForegroundColor Red
    }
}
Write-Host ""
if ($PauseAtEnd) {
    Read-Host "Press Enter to exit"
}