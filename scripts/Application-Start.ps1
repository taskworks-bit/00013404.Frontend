Write-Host "Starting IIS Site..."
Import-Module WebAdministration

$appPoolName = "Coursework.Frontend"
if(!(Test-Path IIS:\AppPools\$appPoolName)) {
    New-WebAppPool -Name $appPoolName
}

Set-ItemProperty IIS:\AppPools\$appPoolName -name "managedRuntimeVersion" -value ""  # Empty string for No Managed Code
Set-ItemProperty IIS:\AppPools\$appPoolName -name "startMode" -value "AlwaysRunning"
Set-ItemProperty IIS:\AppPools\$appPoolName -name "processModel.identityType" -value "ApplicationPoolIdentity"

if(!(Test-Path IIS:\Sites\$appPoolName)) {
    New-Website -Name $appPoolName `
                -PhysicalPath "C:\inetpub\wwwroot\Coursework.Frontend" `
                -ApplicationPool $appPoolName `
                -Port 80
}

Set-WebBinding -Name $appPoolName -BindingInformation "*:80:" -PropertyName "Port" -Value 80

Start-WebSite -Name $appPoolName
Write-Host "IIS Site started successfully."