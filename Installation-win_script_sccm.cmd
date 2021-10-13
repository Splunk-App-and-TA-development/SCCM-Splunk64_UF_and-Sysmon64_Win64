:: ####################################################################
:: ##  Upgrade Splunk UF v.8.2.1 (64Bit) and Sysmon v.13.02 (64Bit)  ##
:: ## -------------------------------------------------------------- ##
:: ##  Installation and Upgrade of Splunk UF and Sysmon on all       ##
:: ##  Windows 64Bit Clients and Servers.                            ##
:: ## -------------------------------------------------------------- ##
:: ##  This software is a part of the SIEM/SOC environment !         ##
:: ####################################################################
:: # Description:			Install Splunk UniversalForwarder and Deploy Sysmon Software with Sysmon Config
:: # Destination:			Windows Clients (Windows7/32, Windows7/64 and Windows10/64) and Windows Servers (Win2016/Win2019)
:: Author:					Patrick Vanreck, SwissTXT
:: Author Contact:			yoyonet-info@gmx.net
:: Date:					21.05.2021
:: Script Version:			4.0

:: Splunk Deployer:			<Your Deployment Server Hostname>
:: Version Splunk:			8.2.1
:: Architecture Splunk:		64 Bit

:: Version Sysmon:			13.02
:: Architecture Sysmon:		64 Bit
:: Sysmon Manual:			https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon
:: Sysmon MITRE ATT&CK		https://github.com/olafhartong/sysmon-modular/tree/v13.02
:: Version Sysmon config:	SysmonConfig_windows_systems-v6.0.xml

echo off
:: ---> The static Packages Definitions <---
SET PkgSource=%~dp0

:: ---> The changing Packages Definitions <---
:: ---> Upload the new "Splunkforwarder" software versions and the "sysmon-config.xml" filename in the package folder and rename the variable in the "PkgSysmonCfg" before!! <---
SET PkgSplunkVersion64=splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi
SET PkgSysmonCfg=SysmonConfig_windows_systems-v6.0.xml
SET PkgDeploymentOldConf=%ProgramFiles%\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf
SET PkgDeploymentApp=TA-deploymentclient-DEP1
SET TargetAppLocation=%ProgramFiles%\SplunkUniversalForwarder\etc\apps\
SET DeploymentTAInstallState=false
SET md5caller=md5.bat

:: *** 64bit Installation of SplunkUniversalForwarder-8.2.1 and Sysmon-13.01 ***
echo.
echo --------------------------------------------------------------------
echo Installation Procedure of for Splunk UniversalForwarder and Sysmon64
echo --------------------------------------------------------------------
echo.
echo.
echo ----------
echo - STEP-1 -
echo ---------- 
echo Check first MD5 Checksum of the Installation File.
echo The Correct result must be: 74892c7aa3a36c579aedefcdc2177030
echo.
call "%PkgSource%%md5caller%" "%PkgSource%%PkgSplunkVersion64%" md5
if "%md5%" equ "74892c7aa3a36c579aedefcdc2177030" (
	  echo --------------------------------------
      echo MD5 check OK - Checksum are identical!
	  echo MD5: %md5%
	  echo --------------------------------------
	  echo.
	  echo.
	  echo ----------
	  echo - STEP-2 - 
	  echo ----------
	  echo Install the Splunkforwarder version 8.2.1
	  echo.
	  :: Installation of Splunk in quiet mode.
	  msiexec /i "%PkgSource%%PkgSplunkVersion64%" AGREETOLICENSE=yes /quiet
	  echo Stop the Splunkforwarder Service for the next steps
	  echo.
	  net stop SplunkForwarder
	  timeout 5
	  echo.
	  echo Delete the old deploymentclient.conf file under %PkgDeploymentOldConf%.
	  :: Old deploymentclient.conf file is not more needed and will be deleted here if available.
	  del /f "%PkgDeploymentOldConf%"
	  timeout 1
	  GOTO UPLOAD_DEPLOYMENT_TA
) else (
	  echo --------------------
      echo MD5 does not match !
	  echo --------------------
	  GOTO ERROR_END
)

:: Procedure to Upload the TA-SRG_deploymentclient-DEP2 to the UniversalForwarder Apps folder if needed.
:UPLOAD_DEPLOYMENT_TA
echo.
echo.
echo ----------
echo - STEP-3 -
echo ----------
echo Upload the %PkgDeploymentApp% to %TargetAppLocation% if not exists in target folder.
echo.
if exist "%TargetAppLocation%\%PkgDeploymentApp%" SET DeploymentTAInstallState=true
if "DeploymentTAInstallState"=="true" (
    :: Inform that the TA is already uploaded and go direct to the Sysmon Installation..
	echo TA-SRG_deploymentclient-DEP2 already installed in this UniversalForwarder!
	GOTO INSTALL_SYSMON
) else (
    :: Upload the TA to C:\Program Files\SplunkUniversalForwarder\etc\apps\etc\apps
	echo Folder does not exist in the %TargetAppLocation%.
	echo Upload %PkgDeploymentApp% to %TargetAppLocation%.
	echo ------------------------------------------------------------------------------------
	md "%TargetAppLocation%%PkgDeploymentApp%"
	XCOPY /E /I /F /R /Y "%PkgSource%%PkgDeploymentApp%" "%TargetAppLocation%%PkgDeploymentApp%"
	GOTO INSTALL_SYSMON
)

:: Procedure to Uninstall and Install Sysmon in 64bit version with the last config file.
:INSTALL_SYSMON
echo.
echo.
echo ----------
echo - STEP-4 - 
echo ----------
echo Installation step for the Sysmon64 Version 13.02 with the last config file.
echo.
echo Uninstall first the Old Sysmon32 Bit!
echo -------------------------------------
"%PkgSource%Sysmon.exe" -u
echo.
echo Uninstall first the Old Sysmon64 Bit!
echo -------------------------------------
"%PkgSource%Sysmon64.exe" -u
timeout 3
echo.
echo Install the new Sysmon64 to version 13.02 with the config: %PkgSysmonCfg%
echo -------------------------------------------------------------------------------------------------------
:: Install Sysmon64 with the specific config file defined in the variables.
"%PkgSource%Sysmon64.exe" /accepteula -i "%PkgSource%%PkgSysmonCfg%"
GOTO FINAL_TASKS

:FINAL_TASKS
:: restart service after install
echo.
echo.
echo ----------
echo - STEP-5 - 
echo ----------
echo Restart The Splunk UniversalForwarder and finish the Installation
timeout 5
net start SplunkForwarder
GOTO SUCCESS_END

:ERROR_END
echo.
echo. 
echo -----------------------------------------------------------------------------
echo                        !! A T T E N T I O N  !!
echo -----------------------------------------------------------------------------
echo The Splunk Software you try to install does not match with the MD5 Checksum !
echo                  Please contact your Splunk Administrator
echo -----------------------------------------------------------------------------

:SUCCESS_END
echo.
echo.
echo -----------------------------------------------------------------------------
echo               S U C C E S S F U L   I N S T A L L A T I O N
echo -----------------------------------------------------------------------------
echo The installation of SplunkUniversalForwarder to version 8.2.1 was successful.
echo Also the Upgrade of Sysmon to the version 13.02 was successful.
echo -----------------------------------------------------------------------------
