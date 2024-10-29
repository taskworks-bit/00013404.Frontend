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
    # Install IIS and necessary features if not already installed
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
        Install-WindowsFeature -Name $feature -ErrorAction SilentlyContinue
    }

    # Force reload IIS PowerShell module
    Write-DetailedLog "Reloading WebAdministration module..."
    Remove-Module WebAdministration -ErrorAction SilentlyContinue
    Import-Module WebAdministration -Force

    # Wait for IIS to be ready
    Start-Sleep -Seconds 10

    # Install .NET Core Hosting Bundle
    Write-DetailedLog "Downloading .NET Core Hosting Bundle..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $hostingBundleDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/1c068829-6e5c-471f-a7c5-7cae80368c26/0ce2dc53c54534a3845f700ddfbe0ac7/dotnet-hosting-7.0.14-win.exe"
    $hostingBundleInstaller = "C:\Windows\Temp\dotnet-hosting-bundle.exe"

    # Download with retry logic
    $maxRetries = 3
    $retryCount = 0
    $downloadSuccess = $false

    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            Invoke-WebRequest -Uri $hostingBundleDownloadUrl -OutFile $hostingBundleInstaller -ErrorAction Stop
            $downloadSuccess = $true
            Write-DetailedLog "Download completed successfully."
        }
        catch {
            $retryCount++
            Write-DetailedLog "Download attempt $retryCount failed: $_"
            Start-Sleep -Seconds 10
        }
    }

    if (-not $downloadSuccess) {
        throw "Failed to download .NET Core Hosting Bundle after $maxRetries attempts."
    }

    # Install Hosting Bundle
    Write-DetailedLog "Installing .NET Core Hosting Bundle..."
    $process = Start-Process -FilePath $hostingBundleInstaller -ArgumentList '/install', '/quiet', '/norestart' -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -ne 0) {
        throw "Hosting Bundle installation failed with exit code: $($process.ExitCode)"
    }

    Write-DetailedLog ".NET Core Hosting Bundle installed successfully."

    # Clean up installer
    Remove-Item $hostingBundleInstaller -Force -ErrorAction SilentlyContinue

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