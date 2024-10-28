# Before-Install.ps1
try {
    $deployPath = "C:\inetpub\wwwroot\mvcapp"
    
    if (Test-Path $deployPath) {
        Write-Output "Cleaning existing files from $deployPath"
        Get-ChildItem -Path $deployPath -Recurse | Remove-Item -Force -Recurse
    } else {
        Write-Output "Creating directory $deployPath"
        New-Item -ItemType Directory -Path $deployPath -Force
    }
    
    Write-Output "Before Install script completed successfully"
} catch {
    Write-Output "Error in Before-Install.ps1: $_"
    Write-Output "Exception details: $($_.Exception.Message)"
    Write-Output "Stack trace: $($_.Exception.StackTrace)"
    throw $_
}