# Application-Stop.ps1
$ErrorActionPreference = "Continue"

try {
    # Check if IIS is installed before trying to load the module
    if ((Get-WindowsFeature Web-Server).Installed) {
        Import-Module WebAdministration
    } else {
        Write-Host "IIS is not installed yet, skipping stop operations"
        exit 0
    }

    # Try to stop IIS service if it exists
    $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
    if ($iisService) {
        Write-Host "Stopping IIS service..."
        Stop-Service -Name W3SVC -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "IIS service not found, skipping..."
    }

    Write-Host "Application-Stop.ps1 completed successfully"
    exit 0
} catch {
    Write-Host "Error in Application-Stop.ps1: $_"
    # Exit with success anyway since this is just the stop script
    exit 0
}