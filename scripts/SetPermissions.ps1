Write-Host "Setting permissions for application directory..."
$path = "C:\inetpub\wwwroot\Coursework.Frontend"

# Ensure directory exists
if(!(Test-Path $path)) {
    New-Item -ItemType Directory -Path $path -Force
}

# Reset permissions
icacls $path /reset
icacls $path /grant "IIS_IUSRS:(OI)(CI)(RX)"
icacls $path /grant "IUSR:(OI)(CI)(RX)"
icacls $path /grant "NT SERVICE\TrustedInstaller:(OI)(CI)(F)"
icacls $path /grant "NT AUTHORITY\SYSTEM:(OI)(CI)(F)"
icacls $path /grant "BUILTIN\Administrators:(OI)(CI)(F)"
icacls $path /grant "BUILTIN\Users:(OI)(CI)(RX)"

# Set permissions for web.config if it exists
$webConfig = Join-Path $path "web.config"
if(Test-Path $webConfig) {
    icacls $webConfig /grant "IIS_IUSRS:(M)"
}

Write-Host "Permissions set successfully."