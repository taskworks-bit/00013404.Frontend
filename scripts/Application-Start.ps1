# Enable verbose logging
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

Write-Host "Starting IIS Site configuration..."

# Verify IIS Installation
try {
    Write-Host "Verifying IIS installation..."
    $iisInstalled = Get-Service W3SVC -ErrorAction SilentlyContinue
    if (-not $iisInstalled) {
        throw "IIS Service (W3SVC) not found. Please ensure IIS is properly installed."
    }

    # Verify WebAdministration module
    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        throw "WebAdministration module not found. Please install IIS Management Tools."
    }

    # Import module with explicit error handling
    Import-Module WebAdministration -ErrorAction Stop
} catch {
    Write-Host "Error during IIS verification: $_"
    throw
}

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
    
    # Verify IIS:\Sites path exists
    if (-not (Test-Path "IIS:\Sites")) {
        Write-DetailedLog "IIS:\Sites path not found. Attempting to load IIS provider..."
        Push-Location
        Import-Module WebAdministration
        Pop-Location
    }

    # Check for existing website using Get-Website instead of Test-Path
    $existingSite = Get-Website -Name $siteName -ErrorAction SilentlyContinue
    if ($existingSite) {
        Write-DetailedLog "Removing existing website: $siteName"
        Remove-Website -Name $siteName -ErrorAction Stop
    }

    # Check for existing app pool using Get-WebAppPool
    $existingPool = Get-WebAppPool -Name $appPoolName -ErrorAction SilentlyContinue
    if ($existingPool) {
        Write-DetailedLog "Removing existing app pool: $appPoolName"
        Remove-WebAppPool -Name $appPoolName -ErrorAction Stop
    }

    # Create new app pool with specific settings
    Write-DetailedLog "Creating new application pool: $appPoolName"
    New-WebAppPool -Name $appPoolName -ErrorAction Stop
    
    # Configure app pool settings
    Write-DetailedLog "Configuring application pool settings..."
    Set-ItemProperty IIS:\AppPools\$appPoolName -name "managedRuntimeVersion" -value "v4.0" -ErrorAction Stop
    Set-ItemProperty IIS:\AppPools\$appPoolName -name "startMode" -value "AlwaysRunning" -ErrorAction Stop
    Set-ItemProperty IIS:\AppPools\$appPoolName -name "processModel.identityType" -value "ApplicationPoolIdentity" -ErrorAction Stop
    
    # Ensure the physical path exists
    if (-not (Test-Path $physicalPath)) {
        Write-DetailedLog "Creating physical path: $physicalPath"
        New-Item -ItemType Directory -Path $physicalPath -Force -ErrorAction Stop
    }

    # Create website
    Write-DetailedLog "Creating website: $siteName"
    New-Website -Name $siteName `
                -PhysicalPath $physicalPath `
                -ApplicationPool $appPoolName `
                -Port 80 `
                -Force `
                -ErrorAction Stop

    # Set permissions
    Write-DetailedLog "Setting permissions for: $physicalPath"
    $acl = Get-Acl $physicalPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$appPoolName", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $physicalPath $acl -ErrorAction Stop

    # Start the website
    Write-DetailedLog "Starting website: $siteName"
    Start-WebSite -Name $siteName -ErrorAction Stop

    # Verify website and app pool status
    $site = Get-Website -Name $siteName
    $pool = Get-WebAppPool -Name $appPoolName
    
    Write-DetailedLog "Website Status: $($site.State)"
    Write-DetailedLog "App Pool Status: $($pool.State)"
    
    # Create and set permissions for logs directory
    $logsPath = Join-Path $physicalPath "logs"
    if (-not (Test-Path $logsPath)) {
        Write-DetailedLog "Creating logs directory: $logsPath"
        New-Item -ItemType Directory -Path $logsPath -Force -ErrorAction Stop
    }

    $acl = Get-Acl $logsPath
    $acl.AddAccessRule($rule)
    Set-Acl $logsPath $acl -ErrorAction Stop

    Write-DetailedLog "IIS Site configuration completed successfully."
} catch {
    Write-DetailedLog "Error occurred during deployment: $_"
    Write-DetailedLog "Stack Trace: $($_.Exception.StackTrace)"
    throw
}