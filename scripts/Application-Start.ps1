Write-Host "Starting IIS Site..."
Import-Module WebAdministration

# Create the website if it doesn't exist
if(!(Test-Path IIS:\Sites\Coursework.Frontend)) {
    New-Website -Name "Coursework.Frontend" `
                -PhysicalPath "C:\inetpub\wwwroot\Coursework.Frontend" `
                -ApplicationPool "Coursework.Frontend" `
                -Port 443
}

# Start the website
Start-WebSite -Name "Coursework.Frontend"
Write-Host "IIS Site started successfully."