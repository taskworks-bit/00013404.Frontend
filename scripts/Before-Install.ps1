Write-Host "Starting installation preparation..."
Import-Module WebAdministration

# Function to write detailed logs
function Write-DetailedLog {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
    Add-Content -Path "C:\CodeDeploy\deployment.log" -Value "[$timestamp] $message"
}

try {
    # Stop Default Website if running
    if((Get-Website -Name 'Default Web Site').State -eq 'Started') {
        Write-DetailedLog "Stopping Default Web Site..."
        Stop-Website -Name 'Default Web Site'
    }

    # Clean up existing app pool and website
    if(Test-Path IIS:\AppPools\Coursework.Frontend) {
        Write-DetailedLog "Removing existing app pool..."
        Remove-WebAppPool -Name "Coursework.Frontend"
    }

    if(Test-Path IIS:\Sites\Coursework.Frontend) {
        Write-DetailedLog "Removing existing website..."
        Remove-Website -Name "Coursework.Frontend"
    }

    # Install .NET Core Hosting Bundle
    Write-DetailedLog "Downloading .NET Core Hosting Bundle..."
    $hostingBundleDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/1c068829-6e5c-471f-a7c5-7cae80368c26/0ce2dc53c54534a3845f700ddfbe0ac7/dotnet-hosting-7.0.14-win.exe"
    $hostingBundleInstaller = "C:\Windows\Temp\dotnet-hosting-bundle.exe"

    # Download with retry logic
    $maxRetries = 3
    $retryCount = 0
    $downloadSuccess = $false

    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
    Remove-Item $hostingBundleInstaller -Force
    
    # Verify installation by checking dotnet command
    try {
        $dotnetVersion = & dotnet --version
        Write-DetailedLog "Installed .NET version: $dotnetVersion"
    }
    catch {
        Write-DetailedLog "Warning: Unable to verify dotnet installation: $_"
    }

    # Create new app pool with correct settings
    Write-DetailedLog "Creating new application pool..."
    New-WebAppPool -Name "Coursework.Frontend"
    Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "managedRuntimeVersion" -value "No Managed Code"
    Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "startMode" -value "AlwaysRunning"

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