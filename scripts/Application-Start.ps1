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

function Test-ModuleLoaded {
    param ([string]$moduleName)
    
    Write-DetailedLog "Checking if module $moduleName is loaded..."
    if (-not (Get-Module -Name $moduleName)) {
        Write-DetailedLog "Module $moduleName is not loaded. Attempting to import..."
        try {
            Import-Module $moduleName -Force -ErrorAction Stop
            Write-DetailedLog "Successfully imported $moduleName module"
            return $true
        } catch {
            Write-DetailedLog "Failed to import $moduleName module: $_"
            return $false
        }
    }
    return $true
}

try {
    Write-DetailedLog "Starting deployment process..."
    
    # Check IIS Service
    $iisService = Get-Service -Name W3SVC -ErrorAction Stop
    Write-DetailedLog "IIS Service Status: $($iisService.Status)"
    
    if ($iisService.Status -ne 'Running') {
        Write-DetailedLog "Starting IIS Service..."
        Start-Service -Name W3SVC -ErrorAction Stop
        Start-Sleep -Seconds 5
    }

    # Ensure WebAdministration module is loaded
    if (-not (Test-ModuleLoaded -moduleName "WebAdministration")) {
        throw "Failed to load WebAdministration module"
    }

    # Alternative way to check and remove website
    Write-DetailedLog "Checking existing website..."
    if (Test-Path "IIS:\Sites\$siteName") {
        Write-DetailedLog "Found existing website. Stopping and removing..."
        Stop-Website -Name $siteName -ErrorAction SilentlyContinue
        Remove-Website -Name $siteName -ErrorAction Stop
    }

    # Alternative way to check and remove app pool
    Write-DetailedLog "Checking existing app pool..."
    if (Test-Path "IIS:\AppPools\$appPoolName") {
        Write-DetailedLog "Found existing app pool. Stopping and removing..."
        $pool = Get-Item "IIS:\AppPools\$appPoolName"
        if ($pool.State -eq "Started") {
            $pool.Stop()
        }
        Remove-Item "IIS:\AppPools\$appPoolName" -Force -Recurse
    }

    # Ensure physical path exists
    if (-not (Test-Path $physicalPath)) {
        Write-DetailedLog "Creating physical path: $physicalPath"
        New-Item -ItemType Directory -Path $physicalPath -Force -ErrorAction Stop
    }

    # Create new app pool using alternative method
    Write-DetailedLog "Creating new application pool: $appPoolName"
    $newPool = New-WebAppPool -Name $appPoolName -ErrorAction Stop
    
    # Configure app pool using direct path
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -name "managedRuntimeVersion" -value "v4.0"
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -name "startMode" -value "AlwaysRunning"
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -name "processModel.identityType" -value "ApplicationPoolIdentity"
    Write-DetailedLog "App pool configured successfully"

    # Create website
    Write-DetailedLog "Creating website: $siteName"
    $newSite = New-Website -Name $siteName `
                          -PhysicalPath $physicalPath `
                          -ApplicationPool $appPoolName `
                          -Port 8080 `
                          -Force `
                          -ErrorAction Stop
    
    # Set permissions
    Write-DetailedLog "Setting permissions for: $physicalPath"
    $acl = Get-Acl $physicalPath
    $identity = "IIS AppPool\$appPoolName"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $physicalPath $acl -ErrorAction Stop

    # Start the website
    Write-DetailedLog "Starting website: $siteName"
    Start-Website -Name $siteName -ErrorAction Stop
    Start-Sleep -Seconds 2

    # Final verification using alternative methods
    Write-DetailedLog "Final Status:"
    $site = Get-Item "IIS:\Sites\$siteName"
    $pool = Get-Item "IIS:\AppPools\$appPoolName"
    
    Write-DetailedLog "Website State: $($site.State)"
    Write-DetailedLog "App Pool State: $($pool.State)"

    Write-DetailedLog "IIS Site configuration completed successfully."
} catch {
    Write-DetailedLog "Critical error occurred during deployment: $_"
    throw
}