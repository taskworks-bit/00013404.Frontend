# Stop the IIS website and app pool
Import-Module WebAdministration
Stop-Website -Name "mvcapp"
Stop-WebAppPool -Name "DefaultAppPool"

# Stop the IIS service
Stop-Service -Name 'w3svc' -Force
