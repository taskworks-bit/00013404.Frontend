# Scripts/Application-Stop.ps1
$ErrorActionPreference = "Stop"
Import-Module WebAdministration

# Stop website if it exists
if (Test-Path "IIS:\Sites\mvcapp") {
    Stop-Website -Name "mvcapp" -ErrorAction SilentlyContinue
}

# Stop app pool
if (Test-Path "IIS:\AppPools\DefaultAppPool") {
    Stop-WebAppPool -Name "DefaultAppPool" -ErrorAction SilentlyContinue
}

# Stop IIS
Stop-Service -Name W3SVC -Force -ErrorAction SilentlyContinue
