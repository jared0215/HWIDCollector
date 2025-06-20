param(
    [string]$Org = "YourOrg"  # Change this or pass as param later if needed
)

# Prompt for Org if not supplied
if (-not $Org) {
    $Org = Read-Host "Enter Org Name (no spaces or special characters)"
    $Org = $Org -replace '[^a-zA-Z0-9_-]', ''
}

# Get key system info
$Serial = (Get-CimInstance Win32_BIOS).SerialNumber
$ProductID = (Get-CimInstance Win32_OperatingSystem).ProductID
$ComputerName = $env:COMPUTERNAME
$Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer
$Model = (Get-CimInstance Win32_ComputerSystem).Model
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Output filename
$outputName = "HWID-$Org-$Serial-$Timestamp.csv"

# Try saving to first available removable drive
$savePath = $null
$removableDrives = @()
foreach ($drv in Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^[D-Z]:\\" }) {
    try {
        if ((Get-Volume -DriveLetter $drv.Root.Substring(0, 1)).DriveType -eq 'Removable') {
            $removableDrives += $drv
        }
    }
    catch {}
}

foreach ($drive in $removableDrives) {
    $testPath = Join-Path $drive.Root $outputName
    try {
        $savePath = $testPath
        break
    }
    catch {}
}

# Fallback to desktop if USB not found
if (-not $savePath) {
    $savePath = "$env:USERPROFILE\Desktop\$outputName"
}

# Collect HWID using official script
Install-Script -Name Get-WindowsAutoPilotInfo -Force -Scope CurrentUser -AllowClobber
$null = & Get-WindowsAutoPilotInfo -OutputFile $savePath -Partner -Force

# Append more fields manually (if needed)
Add-Content -Path $savePath "`n# Extra Info"
Add-Content -Path $savePath "Org Name: $Org"
Add-Content -Path $savePath "Device Name: $ComputerName"
Add-Content -Path $savePath "Product ID: $ProductID"
Add-Content -Path $savePath "Manufacturer: $Manufacturer"
Add-Content -Path $savePath "Model: $Model"

Write-Host "`n[✓] Autopilot HWID collected and saved to: $savePath" -ForegroundColor Green
