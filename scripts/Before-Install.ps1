Write-Host "Preparing for installation..."

Import-Module WebAdministration
if((Get-Website -Name 'Default Web Site').State -eq 'Started') {
    Stop-Website -Name 'Default Web Site'
}

if(Test-Path IIS:\AppPools\Coursework.Frontend) {
    Remove-WebAppPool -Name "Coursework.Frontend"
}

if(Test-Path IIS:\Sites\Coursework.Frontend) {
    Remove-Website -Name "Coursework.Frontend"
}

New-WebAppPool -Name "Coursework.Frontend"
Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "managedRuntimeVersion" -value "v4.0"
Set-ItemProperty IIS:\AppPools\Coursework.Frontend -name "startMode" -value "AlwaysRunning"

Write-Host "Installation preparation completed."

Write-Host "Installing .NET Core Hosting Bundle..."

$hostingBundleDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/1c068829-6e5c-471f-a7c5-7cae80368c26/0ce2dc53c54534a3845f700ddfbe0ac7/dotnet-hosting-7.0.14-win.exe"
$hostingBundleInstaller = "C:\Windows\Temp\dotnet-hosting-bundle.exe"
Invoke-WebRequest -Uri $hostingBundleDownloadUrl -OutFile $hostingBundleInstaller

Start-Process -FilePath $hostingBundleInstaller -ArgumentList '/install', '/quiet', '/norestart' -NoNewWindow -Wait

Remove-Item $hostingBundleInstaller

iisreset /restart

Write-Host ".NET Core Hosting Bundle installed successfully."