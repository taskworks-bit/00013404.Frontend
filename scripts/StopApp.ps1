# StopApp.ps1
Write-Host "Stopping IIS Site..."
Import-Module WebAdministration
Stop-WebSite -Name "Coursework.Frontend"
Write-Host "IIS Site stopped successfully."
