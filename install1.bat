@echo off

:: Title and User Information
::TITLE Install & Configure RDP Wrapper & OpenSSH on Windows 11

:: Check for Administrative Privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Please run this script as an administrator.
    PAUSE
    EXIT /B
)

:: Define Variables
SET RDPWRAP_BASE_URL=https://github.com/stascorp/rdpwrap/releases/download
SET RDPWRAP_VERSION=v1.6.2
SET RDPWRAP_URL=%RDPWRAP_BASE_URL%/%RDPWRAP_VERSION%/RDPWrap-%RDPWRAP_VERSION%.zip
SET RDPWRAP_INI_URL=https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini
SET INSTALL_FOLDER="C:\Program Files\RDP Wrapper"
SET TEMP_FOLDER=%TEMP%\RDPWrapInstaller
SET OPENSSH_FEATURE_NAME="OpenSSH.Server"

:: Prompt for Installation or Uninstallation Options
:SelectionMenu
ECHO Select an option:
ECHO [1] Install/Update RDP Wrapper
ECHO [2] Install/Update OpenSSH
ECHO [3] Uninstall RDP Wrapper
ECHO [4] Uninstall OpenSSH
ECHO [5] Forced Cleanup of Leftovers
ECHO [6] Show Installed Status
ECHO [7] Exit
SET /P OPTION=Enter your choice (1/2/3/4/5/6/7):
IF "%OPTION%"=="1" GOTO InstallRDPWrapper
IF "%OPTION%"=="2" GOTO InstallOpenSSH
IF "%OPTION%"=="3" GOTO UninstallRDPWrapper
IF "%OPTION%"=="4" GOTO UninstallOpenSSH
IF "%OPTION%"=="5" GOTO CleanupLeftovers
IF "%OPTION%"=="6" GOTO ShowStatus
IF "%OPTION%"=="7" GOTO Exit
ECHO Invalid option. Returning to selection menu.
PAUSE
GOTO SelectionMenu

:ShowStatus
ECHO Checking installation status...
SET RDP_STATUS=Not Installed
IF EXIST "%INSTALL_FOLDER%" (
    SET RDP_STATUS=Installed
)
ECHO RDP Wrapper is %RDP_STATUS%.
SET OPENSSH_STATUS=Not Installed
POWERSHELL -Command "Get-WindowsCapability -Online | Where-Object { $_.Name -like '*OpenSSH.Server*' } | ForEach-Object { Write-Host 'Installed' }" >NUL 2>&1 && SET OPENSSH_STATUS=Installed
ECHO OpenSSH is %OPENSSH_STATUS%.
GOTO SelectionMenu

:InstallRDPWrapper
:: Step 1: Create Temporary Folder
ECHO Creating temporary folder...
IF EXIST %TEMP_FOLDER% RMDIR /S /Q %TEMP_FOLDER%
MKDIR %TEMP_FOLDER%

:: Step 2: Download and Extract RDP Wrapper
ECHO Downloading RDP Wrapper from %RDPWRAP_URL%...
CALL :ShowAnimation
POWERSHELL -Command "Invoke-WebRequest -Uri '%RDPWRAP_URL%' -OutFile '%TEMP_FOLDER%\RDPWrap.zip'"
IF NOT EXIST "%TEMP_FOLDER%\RDPWrap.zip" (
    ECHO Download failed. Exiting.
    EXIT /B
)
ECHO Extracting RDP Wrapper files...
CALL :ShowAnimation
POWERSHELL -Command "Expand-Archive -Path '%TEMP_FOLDER%\RDPWrap.zip' -DestinationPath '%TEMP_FOLDER%'"

:: Step 3: Run install.bat
ECHO Running install.bat...
CALL :ShowAnimation
CD /D %TEMP_FOLDER%
IF EXIST install.bat (
    CALL install.bat
) ELSE (
    ECHO install.bat not found. Exiting.
    EXIT /B
)

:: Step 4: Update rdpwrap.ini
ECHO Updating rdpwrap.ini...
POWERSHELL -Command "Invoke-WebRequest -Uri '%RDPWRAP_INI_URL%' -OutFile '%TEMP_FOLDER%\rdpwrap.ini'"
IF EXIST "%INSTALL_FOLDER%\rdpwrap.ini" (
    REN "%INSTALL_FOLDER%\rdpwrap.ini" rdpwrap.ini.bkp
)
COPY "%TEMP_FOLDER%\rdpwrap.ini" "%INSTALL_FOLDER%"

:: Step 5: Configure Firewall and Antivirus
ECHO Configuring firewall and antivirus exclusions...
POWERSHELL -Command "Add-MpPreference -ExclusionPath '%INSTALL_FOLDER%'"
NETSH advfirewall firewall add rule name="Open RDP Port" protocol=TCP dir=in localport=3389 action=allow >nul 2>&1 || ECHO Failed to add firewall rule for RDP Port.

:: Step 6: Start Relevant Services
ECHO Starting relevant services...
NET START TermService >nul 2>&1 || ECHO Failed to start TermService.
NET START RpcSs >nul 2>&1 || ECHO Failed to start RpcSs.
ECHO RDP Wrapper installed/updated successfully.
CALL :CheckRestart
GOTO SelectionMenu

:InstallOpenSSH
:: Step 1: Install OpenSSH
ECHO Installing OpenSSH Server...
CALL :ShowAnimation
POWERSHELL -Command "Get-WindowsCapability -Online | Where-Object { $_.Name -like '*OpenSSH.Server*' } | ForEach-Object { Add-WindowsCapability -Online -Name $_.Name }"
NETSH advfirewall firewall add rule name="Open OpenSSH Port" protocol=TCP dir=in localport=22 action=allow >nul 2>&1 || ECHO Failed to add firewall rule for OpenSSH Port.
NET START sshd >nul 2>&1 || ECHO Failed to start sshd.
ECHO OpenSSH installed/updated successfully.
CALL :CheckRestart
GOTO SelectionMenu

:UninstallRDPWrapper
:: Step 1: Uninstall RDP Wrapper
ECHO Uninstalling RDP Wrapper...
CALL :ShowAnimation
IF EXIST "%INSTALL_FOLDER%" (
    RMDIR /S /Q "%INSTALL_FOLDER%"
    ECHO RDP Wrapper uninstalled successfully.
) ELSE (
    ECHO RDP Wrapper is not installed.
)
:: Remove Firewall Rules and Registry Entries
NETSH advfirewall firewall delete rule name="Open RDP Port" >nul 2>&1 || ECHO No matching firewall rule found for RDP Port.
REG DELETE HKLM\Software\RDPWrapper /f >nul 2>&1
ECHO RDP Wrapper uninstallation completed.
CALL :CheckRestart
GOTO SelectionMenu

:UninstallOpenSSH
:: Step 1: Uninstall OpenSSH
ECHO Uninstalling OpenSSH Server...
CALL :ShowAnimation
NET STOP sshd >nul 2>&1 || ECHO Failed to stop sshd.
POWERSHELL -Command "Remove-WindowsCapability -Online -Name 'OpenSSH.Server'"
:: Remove Firewall Rules and Registry Entries
NETSH advfirewall firewall delete rule name="Open OpenSSH Port" >nul 2>&1 || ECHO No matching firewall rule found for OpenSSH Port.
REG DELETE HKLM\Software\OpenSSH /f >nul 2>&1
ECHO OpenSSH uninstallation completed.
CALL :CheckRestart
GOTO SelectionMenu

:CleanupLeftovers
:: Cleanup leftover files and registry entries
ECHO Performing forced cleanup of leftovers...
CALL :ShowAnimation
IF EXIST "%INSTALL_FOLDER%" (
    RMDIR /S /Q "%INSTALL_FOLDER%"
    ECHO Removed leftover files from %INSTALL_FOLDER%.
)
REG DELETE HKLM\Software\RDPWrapper /f >nul 2>&1
REG DELETE HKLM\Software\OpenSSH /f >nul 2>&1
ECHO Cleanup of leftover registry entries completed.
CALL :CheckRestart
GOTO SelectionMenu

:: Define Function for Animation
:ShowAnimation
SETLOCAL ENABLEDELAYEDEXPANSION
FOR /L %%G IN (0,1,3) DO (
    FOR %%A IN (^|,/,-,\) DO (
        <NUL SET /P=%%A
        TIMEOUT /T 1 >NUL
        <NUL SET /P=
    )
)
ENDLOCAL
EXIT /B

:: Check Pending Restart
:CheckRestart
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >NUL 2>&1
IF %ERRORLEVEL% EQU 0 (
    ECHO A system restart is required. Do you want to restart now? (Y/N)
    SET /P RESTART=
    IF /I "%RESTART%"=="Y" (
        SHUTDOWN /R /T 0
    ) ELSE (
        ECHO Please restart the system manually for changes to take effect.
    )
)

:Exit
ECHO Exiting program. Goodbye!
EXIT /B
