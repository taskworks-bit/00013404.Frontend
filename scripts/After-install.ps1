$ErrorActionPreference = "Stop"
Import-Module WebAdministration

# Create IIS website if it doesn't exist
if (!(Test-Path "IIS:\Sites\mvcapp")) {
    New-Website -Name "mvcapp" -PhysicalPath "C:\inetpub\wwwroot\mvcapp" -Port 80 -Force
}

# Set application pool to No Managed Code if it's a self-contained deployment
Set-ItemProperty -Path "IIS:\AppPools\DefaultAppPool" -Name "managedRuntimeVersion" -Value ""

# Ensure proper permissions
$acl = Get-Acl "C:\inetpub\wwwroot\mvcapp"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl "C:\inetpub\wwwroot\mvcapp" $acl
