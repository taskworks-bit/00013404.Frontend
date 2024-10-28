$ErrorActionPreference = "Stop"
Import-Module WebAdministration

New-Item -ItemType Directory -Force -Path C:\inetpub\wwwroot\mvcapp

# Remove any old files from the deployment directory
if (Test-Path C:\inetpub\wwwroot\mvcapp\*) {
    Remove-Item -Recurse -Force C:\inetpub\wwwroot\mvcapp\*
}
