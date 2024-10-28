# Application-Start.ps1
try {
    # Ensure IIS PowerShell snap-in is registered and loaded
    Write-Output "Initializing IIS PowerShell environment..."
    
    # Register IIS PowerShell snap-in if not already registered
    $RegPath = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\WebAdministration"
    if (!(Test-Path $RegPath)) {
        Write-Output "Registering IIS PowerShell snap-in..."
        $IISPath = [System.Environment]::ExpandEnvironmentVariables("%WinDir%\System32\inetsrv\")
        $Assembly = Join-Path $IISPath "Microsoft.Web.Administration.dll"
        $PublicTokens = ([System.Reflection.Assembly]::LoadFrom($Assembly)).FullName.Split("=")[3].Split(",")[0]
        
        New-Item -Path $RegPath -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "ApplicationBase" -Value $IISPath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "AssemblyName" -Value "Microsoft.Web.Administration" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "ModuleName" -Value (Join-Path $IISPath "IISWASDeploymentProvider.dll") -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "PSVersion" -Value "2.0" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "Version" -Value "7.0.0.0" -PropertyType String -Force | Out-Null
    }

    # Import required modules
    Write-Output "Importing WebAdministration module..."
    $env:PSModulePath = $env:PSModulePath + ";C:\Windows\System32\WindowsPowerShell\v1.0\Modules\"
    Import-Module WebAdministration -Force -Verbose

    Start-Sleep -Seconds 5  # Give the module time to load properly
    
    $siteName = "Default Web Site"
    $appPoolName = "DefaultAppPool"
    $deployPath = "C:\inetpub\wwwroot\mvcapp"
    
    # Create and configure application pool
    Write-Output "Configuring application pool..."
    if ((Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -eq $appPoolName }) -eq $null) {
        Write-Output "Creating Application Pool: $appPoolName"
        $appPool = New-WebAppPool -Name $appPoolName -Force
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value "v4.0"
        $appPool | Set-ItemProperty -Name "managedPipelineMode" -Value "Integrated"
    }
    
    # Create and configure website
    Write-Output "Configuring website..."
    if ((Get-ChildItem IIS:\Sites | Where-Object { $_.Name -eq $siteName }) -eq $null) {
        Write-Output "Creating Website: $siteName"
        New-Website -Name $siteName -PhysicalPath $deployPath -ApplicationPool $appPoolName -Force
    } else {
        Write-Output "Updating existing website configuration..."
        Set-ItemProperty "IIS:\Sites\$siteName" -Name "physicalPath" -Value $deployPath
        Set-ItemProperty "IIS:\Sites\$siteName" -Name "applicationPool" -Value $appPoolName
    }
    
    # Start application pool
    Write-Output "Starting Application Pool: $appPoolName"
    $appPool = Get-Item "IIS:\AppPools\$appPoolName"
    if ($appPool.State -ne "Started") {
        $appPool.Start()
    }
    
    # Start website
    Write-Output "Starting Website: $siteName"
    $website = Get-Item "IIS:\Sites\$siteName"
    if ($website.State -ne "Started") {
        $website.Start()
    }
    
    Write-Output "Application Start script completed successfully"
} catch {
    Write-Output "Error in Application-Start.ps1: $_"
    Write-Output "Exception details: $($_.Exception.Message)"
    Write-Output "Stack trace: $($_.Exception.StackTrace)"
    throw $_
}
