# StartApp.ps1
Write-Host "Starting IIS Site..."
Import-Module WebAdministration
Start-WebSite -Name "Coursework.Frontend"
Write-Host "IIS Site started successfully."
