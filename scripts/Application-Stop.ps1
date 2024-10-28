# Application-Stop.ps1
$ErrorActionPreference = "Stop"

try {
    # Import IIS Module
    Import-Module WebAdministration -ErrorAction Stop

    # Stop website if it exists
    $siteName = "mvcapp"
    $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
    if ($site) {
        Write-Host "Stopping website $siteName..."
        Stop-Website -Name $siteName -ErrorAction SilentlyContinue
    } else {
        Write-Host "Website $siteName not found, continuing..."
    }

    # Stop app pool
    $poolName = "DefaultAppPool"
    $pool = Get-WebAppPool -Name $poolName -ErrorAction SilentlyContinue
    if ($pool) {
        Write-Host "Stopping application pool $poolName..."
        Stop-WebAppPool -Name $poolName -ErrorAction SilentlyContinue
    } else {
        Write-Host "Application pool $poolName not found, continuing..."
    }

    # Stop IIS
    Write-Host "Stopping IIS service..."
    Stop-Service -Name W3SVC -Force -ErrorAction SilentlyContinue

    Write-Host "Application-Stop.ps1 completed successfully"
    exit 0
} catch {
    Write-Error "Error in Application-Stop.ps1: $_"
    exit 1
}