# Application-Stop.ps1
try {
    # Ensure IIS PowerShell snap-in is registered and loaded
    Write-Output "Initializing IIS PowerShell environment..."
    $env:PSModulePath = $env:PSModulePath + ";C:\Windows\System32\WindowsPowerShell\v1.0\Modules\"
    Import-Module WebAdministration -Force -Verbose
    
    Start-Sleep -Seconds 5  # Give the module time to load properly
    
    $siteName = "Default Web Site"
    $appPoolName = "DefaultAppPool"
    
    # Stop website if it exists
    if (Get-Website -Name $siteName) {
        Write-Output "Stopping IIS Site: $siteName"
        $website = Get-Item "IIS:\Sites\$siteName"
        if ($website.State -eq "Started") {
            $website.Stop()
        }
    } else {
        Write-Output "Site $siteName not found - might be first deployment"
    }
    
    # Stop application pool if it exists
    if (Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -eq $appPoolName }) {
        Write-Output "Stopping Application Pool: $appPoolName"
        $appPool = Get-Item "IIS:\AppPools\$appPoolName"
        if ($appPool.State -eq "Started") {
            $appPool.Stop()
        }
    } else {
        Write-Output "AppPool $appPoolName not found - might be first deployment"
    }
    
    Write-Output "Application Stop script completed successfully"
} catch {
    Write-Output "Error in Application-Stop.ps1: $_"
    Write-Output "Exception details: $($_.Exception.Message)"
    Write-Output "Stack trace: $($_.Exception.StackTrace)"
    throw $_
}
