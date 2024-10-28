# Application-Start.ps1
$ErrorActionPreference = "Stop"

try {
    # Import IIS Module
    Import-Module WebAdministration -ErrorAction Stop

    # Ensure IIS is installed
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        Write-Host "Installing IIS components..."
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
        Install-WindowsFeature -Name Web-Scripting-Tools
    }

    # Create website if it doesn't exist
    if (-not (Get-Website -Name "mvcapp")) {
        New-Website -Name "mvcapp" -PhysicalPath "C:\inetpub\wwwroot\mvcapp" -Port 80 -Force
    }

    # Start IIS
    Start-Service -Name W3SVC

    # Start app pool
    Start-WebAppPool -Name "DefaultAppPool" -ErrorAction SilentlyContinue

    # Start website
    Start-Website -Name "mvcapp" -ErrorAction SilentlyContinue

    Write-Host "Application-Start.ps1 completed successfully"
    exit 0
} catch {
    Write-Error "Error in Application-Start.ps1: $_"
    exit 1
}

