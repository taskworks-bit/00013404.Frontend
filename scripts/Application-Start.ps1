# Application-Start.ps1
try {
    Import-Module WebAdministration
    
    $siteName = "Default Web Site"
    $appPoolName = "DefaultAppPool"
    $deployPath = "C:\inetpub\wwwroot\mvcapp"
    
    # Ensure IIS is installed
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        Write-Output "Installing IIS WebAdministration module..."
        Install-WindowsFeature Web-Server, Web-Mgmt-Tools
    }
    
    # Create and configure application pool if it doesn't exist
    if (-not (Test-Path "IIS:\AppPools\$appPoolName")) {
        Write-Output "Creating Application Pool: $appPoolName"
        New-WebAppPool -Name $appPoolName
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedRuntimeVersion -Value "v4.0"
        Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedPipelineMode -Value "Integrated"
    }
    
    # Create and configure website if it doesn't exist
    if (-not (Test-Path "IIS:\Sites\$siteName")) {
        Write-Output "Creating Website: $siteName"
        New-Website -Name $siteName -PhysicalPath $deployPath -ApplicationPool $appPoolName -Force
    } else {
        Set-ItemProperty "IIS:\Sites\$siteName" -Name physicalPath -Value $deployPath
        Set-ItemProperty "IIS:\Sites\$siteName" -Name applicationPool -Value $appPoolName
    }
    
    # Start application pool
    Write-Output "Starting Application Pool: $appPoolName"
    Start-WebAppPool -Name $appPoolName
    
    # Start website
    Write-Output "Starting Website: $siteName"
    Start-Website -Name $siteName
    
    Write-Output "Application Start script completed successfully"
} catch {
    Write-Output "Error in Application-Start.ps1: $_"
    throw $_
}
