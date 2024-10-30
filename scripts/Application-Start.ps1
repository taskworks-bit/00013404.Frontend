# Enable verbose logging
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

Write-Host "Starting IIS Site configuration..."

# Define variables
$appPoolName = "Coursework.Frontend"
$siteName = "Coursework.Frontend"
$physicalPath = "C:\inetpub\wwwroot\Coursework.Frontend"

# Function to write detailed logs
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

try {
    Write-DetailedLog "Starting deployment process..."
    
    # Verify IIS Service
    $iisService = Get-Service -Name W3SVC -ErrorAction Stop
    Write-DetailedLog "IIS Service Status: $($iisService.Status)"
    
    if ($iisService.Status -ne 'Running') {
        Write-DetailedLog "Starting IIS Service..."
        Start-Service -Name W3SVC -ErrorAction Stop
        Start-Sleep -Seconds 5
    }
    
    # Import WebAdministration module
    Write-DetailedLog "Importing WebAdministration module..."
    Remove-Module WebAdministration -ErrorAction SilentlyContinue
    Import-Module WebAdministration -Force -ErrorAction Stop
    
    # Verify module is loaded
    $module = Get-Module WebAdministration
    Write-DetailedLog "WebAdministration Module Version: $($module.Version)"
    
    # List existing app pools for verification
    Write-DetailedLog "Current App Pools:"
    Get-ChildItem IIS:\AppPools | ForEach-Object { Write-DetailedLog "- $($_.Name)" }

    # Check and remove existing website
    try {
        $existingSite = Get-Website -Name $siteName -ErrorAction SilentlyContinue
        if ($existingSite) {
            Write-DetailedLog "Found existing website. Stopping and removing..."
            if ($existingSite.State -eq 'Started') {
                Stop-Website -Name $siteName -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
            Remove-Website -Name $siteName -ErrorAction Stop
        }
    } catch {
        Write-DetailedLog "Warning during website removal: $_"
    }

    # Check and remove existing app pool
    try {
        $existingPool = Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -eq $appPoolName }
        if ($existingPool) {
            Write-DetailedLog "Found existing app pool. Stopping and removing..."
            if ($existingPool.State -eq 'Started') {
                Stop-WebAppPool -Name $appPoolName -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
            Remove-WebAppPool -Name $appPoolName -ErrorAction Stop
        }
    } catch {
        Write-DetailedLog "Warning during app pool removal: $_"
    }

    # Ensure physical path exists
    if (-not (Test-Path $physicalPath)) {
        Write-DetailedLog "Creating physical path: $physicalPath"
        New-Item -ItemType Directory -Path $physicalPath -Force -ErrorAction Stop
    }

    # Create new app pool
    Write-DetailedLog "Creating new application pool: $appPoolName"
    $newPool = New-WebAppPool -Name $appPoolName -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    # Configure app pool
    Write-DetailedLog "Configuring application pool settings..."
    $pool = Get-ChildItem IIS:\AppPools | Where-Object { $_.Name -eq $appPoolName }
    
    if ($pool) {
        Set-ItemProperty IIS:\AppPools\$appPoolName -name "managedRuntimeVersion" -value "v4.0"
        Set-ItemProperty IIS:\AppPools\$appPoolName -name "startMode" -value "AlwaysRunning"
        Set-ItemProperty IIS:\AppPools\$appPoolName -name "processModel.identityType" -value "ApplicationPoolIdentity"
        Write-DetailedLog "App pool configured successfully"
    } else {
        throw "App pool was not created successfully"
    }

    # Create website
    Write-DetailedLog "Creating website: $siteName"
    $newSite = New-Website -Name $siteName `
                          -PhysicalPath $physicalPath `
                          -ApplicationPool $appPoolName `
                          -Port 80 `
                          -Force `
                          -ErrorAction Stop
    
    Start-Sleep -Seconds 2

    # Set permissions
    Write-DetailedLog "Setting permissions for: $physicalPath"
    $acl = Get-Acl $physicalPath
    $identity = "IIS AppPool\$appPoolName"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $physicalPath $acl -ErrorAction Stop

    # Verify website creation
    $site = Get-Website -Name $siteName
    if (-not $site) {
        throw "Website was not created successfully"
    }

    # Start the website
    Write-DetailedLog "Starting website: $siteName"
    Start-Website -Name $siteName -ErrorAction Stop
    Start-Sleep -Seconds 2

    # Final verification
    $site = Get-Website -Name $siteName
    $pool = Get-WebAppPool -Name $appPoolName
    
    Write-DetailedLog "Final Status:"
    Write-DetailedLog "Website State: $($site.State)"
    Write-DetailedLog "App Pool State: $($pool.State)"
    
    # Verify site is actually responding
    try {
        $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -ErrorAction Stop
        Write-DetailedLog "Website is responding with status code: $($response.StatusCode)"
    } catch {
        Write-DetailedLog "Warning: Could not verify website response: $_"
    }

    Write-DetailedLog "IIS Site configuration completed successfully."
} catch {
    Write-DetailedLog "Critical error occurred during deployment: $_"
    Write-DetailedLog "Stack Trace: $($_.Exception.StackTrace)"
    throw
}