# Enable detailed logging and strict error handling
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

Write-Host "Starting IIS Site configuration..."

$appPoolName = "Coursework.Frontend"
$siteName = "Coursework.Frontend"
$physicalPath = "C:\inetpub\wwwroot\Coursework.Frontend"

function Write-DetailedLog {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
    
    $logPath = "C:\CodeDeploy"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    Add-Content -Path "C:\CodeDeploy\deployment.log" -Value "[$timestamp] $message"
}

function Repair-IISInstallation {
    Write-DetailedLog "Repairing IIS Installation..."
    
    try {
        # Reset IIS
        Write-DetailedLog "Stopping IIS services..."
        Stop-Service -Name W3SVC -Force -ErrorAction SilentlyContinue
        Stop-Service -Name WAS -Force -ErrorAction SilentlyContinue
        
        # Register IIS PowerShell Assembly
        Write-DetailedLog "Registering Microsoft.Web.Administration..."
        $env:systemroot = [Environment]::GetEnvironmentVariable("SystemRoot")
        $assembly = Join-Path $env:systemroot "System32\inetsrv\Microsoft.Web.Administration.dll"
        if (Test-Path $assembly) {
            & regsvr32 /s $assembly
        }
        
        # Re-register IIS components
        Write-DetailedLog "Re-registering IIS components..."
        Start-Process "dism.exe" -ArgumentList "/online /enable-feature /featurename:IIS-WebServerRole /all" -Wait -NoNewWindow
        Start-Process "dism.exe" -ArgumentList "/online /enable-feature /featurename:IIS-WebServerManagementTools /all" -Wait -NoNewWindow
        Start-Process "dism.exe" -ArgumentList "/online /enable-feature /featurename:IIS-ManagementScriptingTools /all" -Wait -NoNewWindow
        
        # Restart IIS services
        Write-DetailedLog "Starting IIS services..."
        Start-Service -Name WAS
        Start-Service -Name W3SVC
        
        # Reset IIS
        Write-DetailedLog "Resetting IIS..."
        & iisreset /restart
        
        return $true
    }
    catch {
        Write-DetailedLog "Error repairing IIS: $_"
        return $false
    }
}

function Test-IISComponents {
    Write-DetailedLog "Testing IIS components..."
    
    $requiredFeatures = @(
        "IIS-WebServerRole",
        "IIS-WebServer",
        "IIS-CommonHttpFeatures",
        "IIS-ManagementConsole",
        "IIS-ManagementScriptingTools"
    )
    
    foreach ($feature in $requiredFeatures) {
        $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if ($featureState.State -ne "Enabled") {
            Write-DetailedLog "Installing missing IIS feature: $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
        }
    }
}

try {
    Write-DetailedLog "Starting deployment process..."
    
    # Verify and repair IIS installation
    Test-IISComponents
    
    # Check if IIS provider is available
    if (-not (Get-PSProvider -PSProvider WebAdministration -ErrorAction SilentlyContinue)) {
        Write-DetailedLog "WebAdministration provider not found. Attempting repair..."
        if (-not (Repair-IISInstallation)) {
            throw "Failed to repair IIS installation"
        }
    }
    
    # Import WebAdministration module with retry
    $maxRetries = 3
    $retryCount = 0
    $moduleLoaded = $false
    
    while (-not $moduleLoaded -and $retryCount -lt $maxRetries) {
        try {
            Remove-Module WebAdministration -ErrorAction SilentlyContinue
            Import-Module WebAdministration -Force
            $moduleLoaded = $true
            Write-DetailedLog "Successfully loaded WebAdministration module"
        }
        catch {
            $retryCount++
            Write-DetailedLog "Attempt $retryCount to load WebAdministration module failed. Retrying..."
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $moduleLoaded) {
        throw "Failed to load WebAdministration module after $maxRetries attempts"
    }
    
    # Create website using direct AppCmd calls if PowerShell commands fail
    Write-DetailedLog "Creating application pool and website using AppCmd..."
    $appcmd = "$env:SystemRoot\System32\inetsrv\appcmd.exe"
    
    # Delete existing app pool and site
    & $appcmd delete apppool "$appPoolName" 2>&1 | Out-Null
    & $appcmd delete site "$siteName" 2>&1 | Out-Null
    
    # Create new app pool
    & $appcmd add apppool /name:"$appPoolName" /managedRuntimeVersion:"v4.0" /managedPipelineMode:"Integrated"
    & $appcmd set apppool "$appPoolName" /autoStart:true
    
    # Create website
    & $appcmd add site /name:"$siteName" /physicalPath:"$physicalPath" /bindings:http/172.31.45.240:8080:
    & $appcmd set site "$siteName" /applicationDefaults.applicationPool:"$appPoolName"
    
    # Set permissions
    Write-DetailedLog "Setting permissions for: $physicalPath"
    if (-not (Test-Path $physicalPath)) {
        New-Item -ItemType Directory -Path $physicalPath -Force
    }
    $acl = Get-Acl $physicalPath
    $identity = "IIS AppPool\$appPoolName"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $physicalPath $acl
    
    # Start the website
    & $appcmd start site "$siteName"
    
    Write-DetailedLog "IIS Site configuration completed successfully."
}
catch {
    Write-DetailedLog "Critical error occurred during deployment: $_"
    throw
}