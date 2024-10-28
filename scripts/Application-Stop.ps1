# Application-Stop.ps1
# Stop IIS site and application pool safely
try {
    Import-Module WebAdministration
    
    $siteName = "Default Web Site"
    $appPoolName = "DefaultAppPool"
    
    # Check if the site exists before attempting to stop it
    if (Test-Path "IIS:\Sites\$siteName") {
        Write-Output "Stopping IIS Site: $siteName"
        Stop-Website -Name $siteName
    } else {
        Write-Output "Site $siteName not found - might be first deployment"
    }
    
    # Check if the app pool exists before attempting to stop it
    if (Test-Path "IIS:\AppPools\$appPoolName") {
        Write-Output "Stopping Application Pool: $appPoolName"
        if ((Get-WebAppPoolState $appPoolName).Value -ne "Stopped") {
            Stop-WebAppPool -Name $appPoolName
        }
    } else {
        Write-Output "AppPool $appPoolName not found - might be first deployment"
    }
    
    Write-Output "Application Stop script completed successfully"
} catch {
    Write-Output "Error in Application-Stop.ps1: $_"
    throw $_
}
