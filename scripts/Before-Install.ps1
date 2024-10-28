# Before-Install.ps1
$ErrorActionPreference = "Stop"

try {
    # Create directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path C:\inetpub\wwwroot\mvcapp -ErrorAction SilentlyContinue

    # Remove contents if they exist
    Get-ChildItem -Path C:\inetpub\wwwroot\mvcapp -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    Write-Host "Before-Install.ps1 completed successfully"
    exit 0
} catch {
    Write-Error "Error in Before-Install.ps1: $_"
    exit 1
}