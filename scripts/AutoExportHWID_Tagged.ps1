# AutoExportHWID.ps1 - WinPE Compatible Version
Set-ExecutionPolicy Bypass -Scope Process -Force

# Prompt for Org name
$org = Read-Host "Enter Org Name (no spaces or special characters)"
# Sanitize org name for file use
$org = $org -replace '[^a-zA-Z0-9_-]', ''

# Try multiple methods to get serial number (WinPE compatible)
try {
    $serial = (Get-WmiObject Win32_BIOS -ErrorAction Stop).SerialNumber
    if ([string]::IsNullOrEmpty($serial)) {
        throw "Serial number is empty"
    }
} catch {
    try {
        # Fallback method using WMIC
        $serial = (wmic bios get serialnumber /value | Where-Object {$_ -like "SerialNumber=*"}).Split('=')[1].Trim()
        if ([string]::IsNullOrEmpty($serial)) {
            throw "Serial number is empty"
        }
    } catch {
        Write-Warning "Could not retrieve serial number, using 'UNKNOWN'"
        $serial = "UNKNOWN"
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$output = "$PSScriptRoot\HWID-$org-$serial-$timestamp.csv"

# Check for required script
if (-not (Test-Path ".\Get-WindowsAutopilotInfo.ps1")) {
    Write-Error "`nERROR: Get-WindowsAutopilotInfo.ps1 not found in the same folder as this script.`n"
    Read-Host "Press Enter to exit"
    exit 1
}

# Run export with WinPE compatibility
Write-Host ""
Write-Host "Generating HWID for Org '$org' and Serial '$serial'..."

try {
    # Force Partner mode for WinPE compatibility (doesn't require hardware hash)
    Write-Host "Using Partner mode for WinPE compatibility..." -ForegroundColor Yellow
    .\Get-WindowsAutopilotInfo.ps1 -OutputFile $output -Partner -Force -Verbose
    
    if (Test-Path $output) {
        Write-Host "SUCCESS: HWID saved as: $output" -ForegroundColor Green
        
        # Display the contents
        Write-Host "`nGenerated HWID file contents:" -ForegroundColor Cyan
        Get-Content $output | ForEach-Object { Write-Host $_ -ForegroundColor White }
    } else {
        throw "Output file was not created"
    }
} catch {
    Write-Error "Partner mode failed: $($_.Exception.Message)"
    Write-Host "Trying manual collection..." -ForegroundColor Yellow
    
    # Manual collection as fallback
    try {
        $computerSystem = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-WmiObject Win32_BIOS -ErrorAction Stop
        
        Write-Host "Computer: $($computerSystem.Manufacturer) $($computerSystem.Model)"
        Write-Host "Serial: $($bios.SerialNumber)"
        
        # Create manual CSV file
        $manualOutput = "$PSScriptRoot\HWID-MANUAL-$org-$serial-$timestamp.csv"
        $csvContent = @"
Device Serial Number,Windows Product ID,Hardware Hash,Manufacturer name,Device model
$($bios.SerialNumber),,$($computerSystem.Manufacturer),$($computerSystem.Model)
"@
        
        $csvContent | Out-File -FilePath $manualOutput -Encoding UTF8
        Write-Host "Manual HWID file created: $manualOutput" -ForegroundColor Green
        
        # Display the contents
        Write-Host "`nManual HWID file contents:" -ForegroundColor Cyan
        Get-Content $manualOutput | ForEach-Object { Write-Host $_ -ForegroundColor White }
        
    } catch {
        Write-Error "Manual collection also failed: $($_.Exception.Message)"
        Write-Host "WinPE may be missing required WMI components" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Press Enter to exit"