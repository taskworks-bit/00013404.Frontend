Write-Host "Setting permissions for application directory..."
$path = "C:\inetpub\wwwroot\Coursework.Frontend"

if(!(Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force
}

$acl = Get-Acl $path
$acl.SetAccessRuleProtection($false, $true)

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IUSR", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\Coursework.Frontend", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)

Set-Acl $path $acl

Write-Host "Permissions set successfully."