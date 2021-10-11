####################################################################
##  Upgrade Splunk UF v.8.2.1 (64Bit) and Sysmon v.13.02 (64Bit)  ##
## -------------------------------------------------------------- ##
##  Installation and Upgrade of Splunk UF and Sysmon on all       ##
##  Windows 64Bit Clients and Servers.                            ##
## -------------------------------------------------------------- ##
##  This software is a part of the SIEM/SOC environment !         ##
####################################################################
# Description:				Install Splunk UniversalForwarder and Deploy Sysmon Software with Sysmon Config
# Destination:				Windows Clients (Windows7/32, Windows7/64 and Windows10/64) and Windows Servers (Win2016/Win2019)
# Author:					Patrick Vanreck, SwissTXT
# Author Contact:			yoyonet-info@gmx.net
# Date:						21.05.2021
# Script Version:			4.0

# Splunk Deployer:			<Your Deployment Server Hostname>
# Version Splunk:			8.2.1
# Architecture Splunk:		64 Bit

# Version Sysmon:			13.02
# Architecture Sysmon:		64 Bit
# Sysmon Manual:			https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon
# Sysmon MITRE ATT&CK		https://github.com/olafhartong/sysmon-modular/tree/v13.02
# Version Sysmon config:	SysmonConfig_windows_systems-v6.0.xml

###################################################
####  Sysmon 64 Bit Upgrade to version 13.02:  ####
###################################################

## ---> Remove previous Sysmon - Uninstall old Sysmon and remove old Active Setup <---
if (Test-Path "${Env:windir}\sysmon64.exe") {Execute-Process -Path "${Env:windir}\sysmon64.exe" -Parameters "-u"} else {}
if (Test-Path "${Env:windir}\sysmon64.exe") {Remove-File -Path "${Env:windir}\sysmon64.exe" -ContinueOnError $true} else {}
Remove-Folder -Path "$envProgramFilesX86\Sysmon" -ContinueOnError $true

## ---> Remove previous Sysmon Registry Key's - (Version's:  8.0.2, 10.41 and 10.42) <---
## ---> Registry Entries created by SCCM. This part can be ignored if deployment is not SCCM (clarify with your SCCM Team) <---
Remove-RegistryKey -Key 'hklm:\SOFTWARE\Microsoft\Active Setup\Installed Components\MarkRussinovich_Sysmon_8.0.2_X64_MUI_001' -ContinueOnError $true
Remove-Folder -Path "$envWinDir\cache\MarkRussinovich_Sysmon_8.0.2_X64_MUI_001" -ContinueOnError:$true
Remove-RegistryKey -Key 'hklm:\SOFTWARE\Microsoft\Active Setup\Installed Components\MarkRussinovich_Sysmon_10.41_X64_MUI_001' -ContinueOnError $true
Remove-Folder -Path "$envWinDir\cache\MarkRussinovich_Sysmon_10.41_X64_MUI_001" -ContinueOnError:$true
Remove-RegistryKey -Key 'hklm:\SOFTWARE\Microsoft\Active Setup\Installed Components\MarkRussinovich_Sysmon_10.42_X64_MUI_001' -ContinueOnError $true
Remove-Folder -Path "$envWinDir\cache\MarkRussinovich_Sysmon_10.42_X64_MUI_001" -ContinueOnError:$true

## ---> Install Sysmon_13.02 - Create Folder with source (If in C:\Windows\Cache, install is failed) and Install command <---
New-Folder -Path "$envProgramFiles\Sysmon" -ContinueOnError $true
Copy-File -Path "$dirFiles\*.*" -Destination "$envProgramFiles\Sysmon" -ContinueOnError $true
Execute-Process -Path "$envProgramFiles\Sysmon\Sysmon64.exe" "-i `"$envProgramFiles\Sysmon\SysmonConfig_windows_systems-v6.0.xml`" -accepteula" 


#####################################################################
####  Splunk Universal Forwarder Upgrade to version 8.2.1 64Bit  ####
#####################################################################

## ---> Install splunkforwarder-8.2.1 64 Bit version <---
Execute-MSI -Action 'Install' -Path "$DirFiles\splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi" -Parameters '/qn AGREETOLICENSE=yes'
    
## ---> Stop Service SplunkForwarder <---
Stop-ServiceAndDependencies -Name 'SplunkForwarder'

## ---> Delete deploymentclient.conf under C:\Program Files\SplunkUniversalForwarder\etc\system\local: <---
Remove-File -Path "$envProgramFiles\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf" -ContinueOnError $true

## ---> Copy additional App folder under C:\Program Files\SplunkUniversalForwarder\etc\apps: <---
Copy-File -Path "$DirFiles\TA-deploymentclient-DEP1*" -Destination "$envProgramFiles\SplunkUniversalForwarder\etc\apps" -recurse
       
## ---> Start Service SplunkForwarder <---
Start-ServiceAndDependencies -Name 'SplunkForwarder'
