Write-Host "Starting IIS Site..."
Import-Module WebAdministration

# Remove existing site and app pool if they exist
$appPoolName = "Coursework.Frontend"
$siteName = "Coursework.Frontend"

if(Test-Path IIS:\Sites\$siteName) {
    Remove-Website -Name $siteName
}

if(Test-Path IIS:\AppPools\$appPoolName) {
    Remove-WebAppPool -Name $appPoolName
}

# Create new app pool
New-WebAppPool -Name $appPoolName
Set-ItemProperty IIS:\AppPools\$appPoolName -name "managedRuntimeVersion" -value ""
Set-ItemProperty IIS:\AppPools\$appPoolName -name "startMode" -value "AlwaysRunning"
Set-ItemProperty IIS:\AppPools\$appPoolName -name "processModel.identityType" -value "ApplicationPoolIdentity"

# Create website
New-Website -Name $siteName `
            -PhysicalPath "C:\inetpub\wwwroot\Coursework.Frontend" `
            -ApplicationPool $appPoolName `
            -Port 80 `
            -Force

# Set permissions
$path = "C:\inetpub\wwwroot\Coursework.Frontend"
$acl = Get-Acl $path
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$appPoolName", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $path $acl

# Start the website
Start-WebSite -Name $siteName
Write-Host "IIS Site started successfully."

# Create logs directory if it doesn't exist
$logsPath = "C:\inetpub\wwwroot\Coursework.Frontend\logs"
if(!(Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath
}

# Set permissions for logs
$acl = Get-Acl $logsPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\$appPoolName", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $logsPath $acl