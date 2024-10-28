# SetPermissions.ps1
Write-Host "Setting permissions for application directory..."
$path = "C:\inetpub\wwwroot\Coursework.Frontend"
icacls $path /grant "IIS_IUSRS:(OI)(CI)RX"
Write-Host "Permissions set successfully."
