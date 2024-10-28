# Scripts/Application-Start.ps1
$ErrorActionPreference = "Stop"
Import-Module WebAdministration

# Start IIS services
Start-Service -Name W3SVC

# Start app pool and website
if((Get-WebAppPoolState -Name "DefaultAppPool").Value -ne "Started") {
    Start-WebAppPool -Name "DefaultAppPool"
}
if((Get-WebsiteState -Name "mvcapp").Value -ne "Started") {
    Start-Website -Name "mvcapp"
}
