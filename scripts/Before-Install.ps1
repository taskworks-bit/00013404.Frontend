Write-Host "Starting installation preparation..."

# Create log directory first
$logPath = "C:\CodeDeploy"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force
}

# Function to write detailed logs
function Write-DetailedLog {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
    Add-Content -Path "C:\CodeDeploy\deployment.log" -Value "[$timestamp] $message" -Force
}

try {
    # Import required modules
    Write-DetailedLog "Importing required modules..."
    Import-Module ServerManager -ErrorAction SilentlyContinue
    Import-Module WebAdministration -ErrorAction SilentlyContinue

    # Install IIS features using Add-WindowsFeature
    Write-DetailedLog "Installing IIS and Management Tools..."
    $features = @(
        "Web-Server",
        "Web-WebServer",
        "Web-Common-Http",
        "Web-Default-Doc",
        "Web-Dir-Browsing",
        "Web-Http-Errors",
        "Web-Static-Content",
        "Web-Health",
        "Web-Http-Logging",
        "Web-Performance",
        "Web-Security",
        "Web-Filtering",
        "Web-App-Dev",
        "Web-Net-Ext45",
        "Web-Asp-Net45",
        "Web-ISAPI-Ext",
        "Web-ISAPI-Filter",
        "Web-Mgmt-Tools",
        "Web-Mgmt-Console"
    )

    foreach ($feature in $features) {
        Write-DetailedLog "Installing feature: $feature"
        try {
            Install-WindowsFeature -Name $feature -ErrorAction SilentlyContinue
        }
        catch {
            Write-DetailedLog "Warning: Could not install feature $feature : $_"
        }
    }

    # Stop Default Website if running (with error handling)
    Write-DetailedLog "Checking Default Web Site status..."
    try {
        $defaultSite = Get-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
        if ($defaultSite -and $defaultSite.State -eq 'Started') {
            Write-DetailedLog "Stopping Default Web Site..."
            Stop-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-DetailedLog "Warning: Could not check Default Web Site status: $_"
    }

    # Create website directory if it doesn't exist
    $websitePath = "C:\inetpub\wwwroot\Coursework.Frontend"
    if (-not (Test-Path $websitePath)) {
        New-Item -ItemType Directory -Path $websitePath -Force
    }

    # Clean up existing app pool and website (with error handling)
    Write-DetailedLog "Cleaning up existing resources..."
    try {
        if(Test-Path IIS:\AppPools\Coursework.Frontend) {
            Remove-WebAppPool -Name "Coursework.Frontend" -ErrorAction SilentlyContinue
        }

        if(Test-Path IIS:\Sites\Coursework.Frontend) {
            Remove-Website -Name "Coursework.Frontend" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-DetailedLog "Warning: Error during cleanup: $_"
    }

    # Restart IIS to apply changes
    Write-DetailedLog "Restarting IIS..."
    iisreset /restart

    Write-DetailedLog "Installation preparation completed successfully."
}
catch {
    Write-DetailedLog "Error during installation preparation: $_"
    Write-DetailedLog "Stack Trace: $($_.Exception.StackTrace)"
    throw
}