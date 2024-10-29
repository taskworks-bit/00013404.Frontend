Write-Host "Preparing for installation..."

# Stop Default Web Site if it's running
Import-Module WebAdministration
if((Get-Website -Name 'Default Web Site').State -eq 'Started') {
    Stop-Website -Name 'Default Web Site'
}

# Remove existing application pool if it exists
if(Test-Path IIS:\AppPools\Coursework.Frontend) {
    Remove-WebAppPool -Name "Coursework.Frontend"
}

# Remove existing website if it exists
if(Test-Path IIS:\Sites\Coursework.Frontend) {
    Remove-Website -Name "Coursework.Frontend"
}

# Create new application pool
New-WebAppPool -Name "Coursework.Frontend"
Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "managedRuntimeVersion" -value "v4.0"
Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "startMode" -value "AlwaysRunning"

Write-Host "Installation preparation completed."