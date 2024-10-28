# Before-Install.ps1
try {
    # Ensure the destination directory exists and is empty
    $deployPath = "C:\inetpub\wwwroot\mvcapp"
    
    if (Test-Path $deployPath) {
        Write-Output "Cleaning existing files from $deployPath"
        Remove-Item -Path "$deployPath\*" -Recurse -Force
    } else {
        Write-Output "Creating directory $deployPath"
        New-Item -ItemType Directory -Path $deployPath -Force
    }
    
    Write-Output "Before Install script completed successfully"
} catch {
    Write-Output "Error in Before-Install.ps1: $_"
    throw $_
}
