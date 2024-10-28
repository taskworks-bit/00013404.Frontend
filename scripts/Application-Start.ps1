# Restart the IIS service
Stop-Service -Name 'w3svc' -Force
Start-Service -Name 'w3svc'

# Ensure the app pool and site are running
Import-Module WebAdministration

# Start the IIS website
Start-WebAppPool -Name "DefaultAppPool"
Start-Website -Name "mvcapp"
