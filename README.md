# RDP Wrapper & OpenSSH Management Tool

A comprehensive PowerShell utility for installing, configuring, and managing RDP Wrapper and OpenSSH Server on Windows systems.

## Overview

This tool provides a user-friendly interface to manage RDP Wrapper (which enables concurrent RDP sessions on Windows) and OpenSSH Server functionality on Windows 11 systems. It handles installation, configuration, uninstallation, and cleanup tasks with a simple menu-driven approach.

## Features

- **RDP Wrapper Management**
  - Installation and configuration
  - Automatic download of the latest compatible rdpwrap.ini
  - Firewall rule creation
  - Antivirus exclusion setup
  - Clean uninstallation

- **OpenSSH Server Management**
  - Installation using Windows Capability
  - Firewall configuration
  - Service configuration
  - Clean uninstallation

- **System Maintenance**
  - Status checking for both components
  - Forced cleanup of leftover files and registry entries
  - System restart management when required

## Requirements

- Windows 10/11
- PowerShell 5.1 or higher
- Administrative privileges
- Internet connection (for downloading RDP Wrapper)

## Installation & Running

### Online Installation (Recommended)

Run the script directly from GitHub using PowerShell (Run as Administrator):

```powershell
irm https://github.com/Munirg2003/my-scripts/raw/refs/heads/main/install.ps1 | iex
```

This will download and execute the script in a single command.

### Manual Installation

1. Download the `RDPWrapper-OpenSSH-Manager.ps1` script
2. Right-click the script and select "Run with PowerShell"
3. If prompted about execution policy, you may need to allow script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

## Usage

### Running the Script

1. Use the online installation method above, or run the downloaded script as administrator
2. A menu will appear with the following options:

```
===== RDP Wrapper & OpenSSH Management Tool =====
Select an option:
[1] Install/Update RDP Wrapper
[2] Install/Update OpenSSH
[3] Uninstall RDP Wrapper
[4] Uninstall OpenSSH
[5] Forced Cleanup of Leftovers
[6] Show Installed Status
[7] Exit
```

3. Select the desired option by entering the corresponding number

### Option Details

#### 1. Install/Update RDP Wrapper
- Downloads and installs RDP Wrapper
- Configures with latest rdpwrap.ini
- Sets up necessary firewall rules
- Configures antivirus exclusions

#### 2. Install/Update OpenSSH
- Installs the OpenSSH Server Windows capability
- Configures firewall rules for SSH (port 22)
- Sets up the SSH service to start automatically

#### 3. Uninstall RDP Wrapper
- Removes all RDP Wrapper files
- Cleans up registry entries
- Removes firewall rules

#### 4. Uninstall OpenSSH
- Removes the OpenSSH Server Windows capability
- Cleans up related services
- Removes associated firewall rules

#### 5. Forced Cleanup of Leftovers
- Performs a deep cleanup of any remaining files or registry entries
- Useful if standard uninstallation doesn't work completely

#### 6. Show Installed Status
- Displays the current installation status of both components

## Technical Details

### RDP Wrapper
- Default installation path: `C:\Program Files\RDP Wrapper`
- Uses RDP Wrapper version v1.6.2
- Downloads up-to-date rdpwrap.ini from sebastaxakerhtc GitHub repository
- Configures Windows Terminal Services

### OpenSSH Server
- Installed as a Windows Capability
- Configures port 22 for SSH access
- Sets service to automatic startup

## Troubleshooting

### Common Issues

1. **Script fails to run with permission errors**
   - Ensure you're running PowerShell as Administrator
   - Check your execution policy with `Get-ExecutionPolicy`

2. **RDP Wrapper installation fails**
   - Check your internet connection
   - Verify Windows version compatibility
   - Manually download RDP Wrapper if automatic download fails

3. **OpenSSH installation issues**
   - Ensure your Windows version supports OpenSSH Server capability
   - Check for existing SSH software that might conflict

### Logs and Debugging

The script displays detailed information about each operation as it runs. If you need to troubleshoot:
- Look for error messages in red text
- Check Windows Event Viewer for service-related issues
- Verify that Windows Firewall is properly configured

## Security Considerations

- This tool modifies system settings and should only be used on systems you control
- The RDP Wrapper component modifies Windows Terminal Services behavior
- Always ensure your systems are properly secured when enabling remote access
- Set strong passwords for all user accounts
- Consider additional security measures like IP restrictions

## License

This script is provided as-is under the MIT License.

## Credits

- RDP Wrapper project: [stascorp/rdpwrap](https://github.com/stascorp/rdpwrap)
- Updated rdpwrap.ini: [sebaxakerhtc/rdpwrap.ini](https://github.com/sebaxakerhtc/rdpwrap.ini)
