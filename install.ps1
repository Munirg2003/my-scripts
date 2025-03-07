# Title and Description: Install & Configure RDP Wrapper & OpenSSH on Windows 11
# Requires administrator privileges

# Check for Administrative Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as an administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Define Variables
$RDPWRAP_BASE_URL = "https://github.com/stascorp/rdpwrap/releases/download"
$RDPWRAP_VERSION = "v1.6.2"
$RDPWRAP_URL = "$RDPWRAP_BASE_URL/$RDPWRAP_VERSION/RDPWrap-$RDPWRAP_VERSION.zip"
$RDPWRAP_INI_URL = "https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini"
$INSTALL_FOLDER = "C:\Program Files\RDP Wrapper"
$TEMP_FOLDER = "$env:TEMP\RDPWrapInstaller"
$OPENSSH_FEATURE_NAME = "OpenSSH.Server"

# Function for Animation
function Show-Animation {
    $spinner = @('|', '/', '-', '\')
    foreach ($i in 0..3) {
        foreach ($char in $spinner) {
            Write-Host "`r$char" -NoNewline
            Start-Sleep -Milliseconds 250
            Write-Host "`r " -NoNewline
        }
    }
    Write-Host "`r" -NoNewline
}

# Function to Check Restart Required
function Check-RestartRequired {
    $restartRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    if ($restartRequired) {
        $restart = Read-Host "A system restart is required. Do you want to restart now? (Y/N)"
        if ($restart -eq "Y" -or $restart -eq "y") {
            Restart-Computer -Force
        } else {
            Write-Host "Please restart the system manually for changes to take effect." -ForegroundColor Yellow
        }
    }
}

# Function to Show Status
function Show-InstallationStatus {
    Write-Host "Checking installation status..." -ForegroundColor Cyan
    $rdpStatus = "Not Installed"
    if (Test-Path $INSTALL_FOLDER) {
        $rdpStatus = "Installed"
    }
    Write-Host "RDP Wrapper is $rdpStatus." -ForegroundColor Yellow

    $opensshStatus = "Not Installed"
    $opensshFeature = Get-WindowsCapability -Online | Where-Object { $_.Name -like '*OpenSSH.Server*' }
    if ($opensshFeature.State -eq "Installed") {
        $opensshStatus = "Installed"
    }
    Write-Host "OpenSSH is $opensshStatus." -ForegroundColor Yellow
}

# Function to Install RDP Wrapper
function Install-RDPWrapper {
    # Step 1: Create Temporary Folder
    Write-Host "Creating temporary folder..." -ForegroundColor Cyan
    if (Test-Path $TEMP_FOLDER) {
        Remove-Item -Path $TEMP_FOLDER -Recurse -Force
    }
    New-Item -Path $TEMP_FOLDER -ItemType Directory -Force | Out-Null

    # Step 2: Download and Extract RDP Wrapper
    Write-Host "Downloading RDP Wrapper from $RDPWRAP_URL..." -ForegroundColor Cyan
    Show-Animation
    try {
        Invoke-WebRequest -Uri $RDPWRAP_URL -OutFile "$TEMP_FOLDER\RDPWrap.zip" -ErrorAction Stop
    } catch {
        Write-Host "Download failed. Exiting." -ForegroundColor Red
        return
    }
    
    Write-Host "Extracting RDP Wrapper files..." -ForegroundColor Cyan
    Show-Animation
    Expand-Archive -Path "$TEMP_FOLDER\RDPWrap.zip" -DestinationPath $TEMP_FOLDER -Force

    # Step 3: Run install.bat (using batch since the original install.bat might contain logic that's hard to convert)
    Write-Host "Running install.bat..." -ForegroundColor Cyan
    Show-Animation
    Set-Location -Path $TEMP_FOLDER
    if (Test-Path "$TEMP_FOLDER\install.bat") {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $TEMP_FOLDER\install.bat" -Wait -NoNewWindow
    } else {
        Write-Host "install.bat not found. Exiting." -ForegroundColor Red
        return
    }

    # Step 4: Update rdpwrap.ini
    Write-Host "Updating rdpwrap.ini..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $RDPWRAP_INI_URL -OutFile "$TEMP_FOLDER\rdpwrap.ini" -ErrorAction Stop
        if (Test-Path "$INSTALL_FOLDER\rdpwrap.ini") {
            Rename-Item -Path "$INSTALL_FOLDER\rdpwrap.ini" -NewName "rdpwrap.ini.bkp" -Force
        }
        Copy-Item -Path "$TEMP_FOLDER\rdpwrap.ini" -Destination $INSTALL_FOLDER -Force
    } catch {
        Write-Host "Failed to update rdpwrap.ini." -ForegroundColor Red
    }

    # Step 5: Configure Firewall and Antivirus
    Write-Host "Configuring firewall and antivirus exclusions..." -ForegroundColor Cyan
    try {
        Add-MpPreference -ExclusionPath $INSTALL_FOLDER -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName "Open RDP Port" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Host "Failed to configure firewall rules. You may need to do this manually." -ForegroundColor Yellow
    }

    # Step 6: Start Relevant Services
    Write-Host "Starting relevant services..." -ForegroundColor Cyan
    try {
        Start-Service -Name TermService -ErrorAction SilentlyContinue
        Start-Service -Name RpcSs -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Failed to start services. You may need to do this manually." -ForegroundColor Yellow
    }
    
    Write-Host "RDP Wrapper installed/updated successfully." -ForegroundColor Green
    Check-RestartRequired
}

# Function to Install OpenSSH
function Install-OpenSSHServer {
    # Step 1: Install OpenSSH
    Write-Host "Installing OpenSSH Server..." -ForegroundColor Cyan
    Show-Animation
    
    try {
        $opensshFeature = Get-WindowsCapability -Online | Where-Object { $_.Name -like '*OpenSSH.Server*' }
        if ($opensshFeature) {
            Add-WindowsCapability -Online -Name $opensshFeature.Name
            
            # Configure firewall
            New-NetFirewallRule -DisplayName "Open OpenSSH Port" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue | Out-Null
            
            # Start and configure the service
            Start-Service sshd
            Set-Service -Name sshd -StartupType 'Automatic'
            
            Write-Host "OpenSSH installed/updated successfully." -ForegroundColor Green
        } else {
            Write-Host "OpenSSH Server feature not found on this system." -ForegroundColor Red
        }
    } catch {
        Write-Host "Failed to install OpenSSH: $_" -ForegroundColor Red
    }
    
    Check-RestartRequired
}

# Function to Uninstall RDP Wrapper
function Uninstall-RDPWrapper {
    # Step 1: Uninstall RDP Wrapper
    Write-Host "Uninstalling RDP Wrapper..." -ForegroundColor Cyan
    Show-Animation
    
    if (Test-Path $INSTALL_FOLDER) {
        Remove-Item -Path $INSTALL_FOLDER -Recurse -Force
        Write-Host "RDP Wrapper files removed successfully." -ForegroundColor Green
    } else {
        Write-Host "RDP Wrapper is not installed." -ForegroundColor Yellow
    }
    
    # Remove Firewall Rules and Registry Entries
    try {
        Remove-NetFirewallRule -DisplayName "Open RDP Port" -ErrorAction SilentlyContinue
        Remove-Item -Path "HKLM:\Software\RDPWrapper" -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Failed to remove some firewall rules or registry entries." -ForegroundColor Yellow
    }
    
    Write-Host "RDP Wrapper uninstallation completed." -ForegroundColor Green
    Check-RestartRequired
}

# Function to Uninstall OpenSSH
function Uninstall-OpenSSHServer {
    # Step 1: Uninstall OpenSSH
    Write-Host "Uninstalling OpenSSH Server..." -ForegroundColor Cyan
    Show-Animation
    
    try {
        # Stop service
        Stop-Service -Name sshd -ErrorAction SilentlyContinue
        
        # Remove the OpenSSH capability
        Get-WindowsCapability -Online | Where-Object { $_.Name -like '*OpenSSH.Server*' } | Remove-WindowsCapability -Online
        
        # Remove firewall rule
        Remove-NetFirewallRule -DisplayName "Open OpenSSH Port" -ErrorAction SilentlyContinue
        
        # Clean registry entries
        Remove-Item -Path "HKLM:\Software\OpenSSH" -Force -ErrorAction SilentlyContinue
        
        Write-Host "OpenSSH uninstallation completed." -ForegroundColor Green
    } catch {
        Write-Host "Failed to uninstall OpenSSH: $_" -ForegroundColor Red
    }
    
    Check-RestartRequired
}

# Function for Forced Cleanup
function Perform-ForcedCleanup {
    # Cleanup leftover files and registry entries
    Write-Host "Performing forced cleanup of leftovers..." -ForegroundColor Cyan
    Show-Animation
    
    if (Test-Path $INSTALL_FOLDER) {
        Remove-Item -Path $INSTALL_FOLDER -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed leftover files from $INSTALL_FOLDER." -ForegroundColor Green
    }
    
    # Remove registry entries
    Remove-Item -Path "HKLM:\Software\RDPWrapper" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\OpenSSH" -Force -ErrorAction SilentlyContinue
    
    Write-Host "Cleanup of leftover registry entries completed." -ForegroundColor Green
    Check-RestartRequired
}

# Main Menu Function
function Show-MainMenu {
    while ($true) {
        Write-Host "`n===== RDP Wrapper & OpenSSH Management Tool =====" -ForegroundColor Cyan
        Write-Host "Select an option:" -ForegroundColor Green
        Write-Host "[1] Install/Update RDP Wrapper" -ForegroundColor White
        Write-Host "[2] Install/Update OpenSSH" -ForegroundColor White
        Write-Host "[3] Uninstall RDP Wrapper" -ForegroundColor White
        Write-Host "[4] Uninstall OpenSSH" -ForegroundColor White
        Write-Host "[5] Forced Cleanup of Leftovers" -ForegroundColor White
        Write-Host "[6] Show Installed Status" -ForegroundColor White
        Write-Host "[7] Exit" -ForegroundColor White
        
        $option = Read-Host "Enter your choice (1/2/3/4/5/6/7)"
        
        switch ($option) {
            "1" { Install-RDPWrapper }
            "2" { Install-OpenSSHServer }
            "3" { Uninstall-RDPWrapper }
            "4" { Uninstall-OpenSSHServer }
            "5" { Perform-ForcedCleanup }
            "6" { Show-InstallationStatus }
            "7" { 
                Write-Host "Exiting program. Goodbye!" -ForegroundColor Cyan
                exit 
            }
            default { Write-Host "Invalid option. Please try again." -ForegroundColor Red }
        }
    }
}

# Start the main menu
Show-MainMenu
