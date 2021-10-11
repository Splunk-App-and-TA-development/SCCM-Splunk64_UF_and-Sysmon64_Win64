# **SCCM Install Splunk-UF 8.2.1 and Sysmon64 v13.02 on Windows Client and Servers**
SCCM Installation and Upgrade procedure for Splunk Universalforwarder version 8.2.1 and Sysmon64 12.03 containing the symon.config file to deploy on each Client.

## **How this package works**
How to upgrade **Splunk UniversalForwarder v8.2.1 (64Bit)** and **Sysmon v13.02 (64Bit)** Windows 64bit Clients and Servers.
This procedure installs the Splunk-UF 64Bit version 8.2.1 and Sysmon 64Bit version 13.02.

In the package folder you'll find a **batch file** called `Installation-win_script_sccm.cmd` where the correct procedure of this upgrade was already tested.
If you are using **Powershell** to deploy then use the file called `Installation-win_script_sccm.ps1` instead of. Please adapt the Powershell commands before!!

The Upgrade of the UniversalForwarder must be performed **as Administrator** or with **Administrator rights** on Windows 64bit Clients and Servers.
Therefore, execute the batch or powershell script **as Administrator** to upgrade Splunk and Sysmon automatically via SCCM.

### Installation process in detail
The steps shown below explains the Upgrade procedure in detail.

1.	Upgrade The Universal Forwarder to Version 7.3.6:
	`msiexec /i "splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi" AGREETOLICENSE=yes /quiet`

2.	Stop the Universal Forwarder:
	`net stop SplunkForwarder`
	
3.	Delete deploymentclient.conf under C:\Program Files\SplunkUniversalForwarder\etc\system\local:
	`del /f "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"`
	
4.	Copy additional App folder under C:\Program Files\SplunkUniversalForwarder\etc\apps:
	`xcopy "TA_deploymentclient-DEP1" "C:\Program Files\SplunkUniversalForwarder\etc\apps" /h /i /c /e /y`
	
5.	Uninstall old Sysmon. Execute booth commands:
	`Sysmon64.exe -u force`
	`Sysmon.exe -u force`
	
6.	Intall new Sysmon 32Bit v10.31 with specific Configuration file:
	`Sysmon.exe /accepteula -i SysmonConfig_windows_systems-v6.0.xml`

7.	Start Splunk Universal Forwarder
	`net start SplunkForwarder`
	
	
  NOTE:		ADAPT THE SCRIPT ACCORDING TO YOUR SOFTWARE DEPLOYMENT TOOL IF NEEDED!
			Windows7 (32bit) and lower Windows Client 32bit versions are not compatible!
			WindowsXP ist not more compatible!


## **Download the Packages**

### **Download the Package from Github**
Fist of all. you need to download the package from github.com. Therefore just execute the following command:
`git clone https://github.com/Splunk-App-and-TA-development/SCCM-Splunk64_UF_and-Sysmon64_Win64.git`

### **Download the Splunk Universal Forwarder**
Download the Splunk-UF version 8.2.1 and the MD5 checksum file from https://www.splunk.com/en_us/download/universal-forwarder.html.
You can download your preferred version instead. Just adapt then the parameters (eg. _PkgSplunkVersion64_) on the scripts explained few steps below.

**Copy booth files** to the previous downloaded **folder from Github**.
- `splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi`
- `splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi.md5`

## **Execute automated scripts in SCCM**
You need to understand how the SCCM process is working before you add this to a deployment job.
Often you need to work with other teams in your company because of the fact that the SCCM deployment is not in your hands.

## **Adapt your Splunk Deployment Server**
To avoid issues from the begining, adapt your ***Splunk Deployment Server*** before every other step:

1. Upload the **TA-deploymentclient-DEP1** to the `/opt/splunk/etc/deployment-apps` folder of your Splunk Deployment Server.

2. Modify the `TA-deploymentclient-DEP1/local/deploymentclient.conf` file by adding your **targetUri**.
```
[target-broker:deploymentServer]
targetUri = <your deployment server ip or hostname>:8089
```

3. Create a **Server Class** with the name `00_All-Client-Default` that includes the **TA-deploymentclient-DEP1** in your deployment server.

4. Ensure to set the parameters `Enable App, Restart Splunkd` on the **TA-deploymentclient-DEP1**
Example of the **serverclass.conf** 
```
[serverClass:00_All-Client-Default:app:TA-deploymentclient-DEP1]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled
```


  NOTE:	YOU NEED TO FIRST ADAPT THE targetUri TO ENSURE THAT THE CLIENT CONNECTS TO THE DEPLOYMENTSERVER.
		PAY ATTENTION, DO NOT FORGET THIS STEP !!!!





## **Execute automated scripts manually**
You can execute the windows batch files _as Administrator_ to manually install the Splunk UniversalForwarder and Sysmon version inside.
There are two scripts to execute the installation. Choose the best for your environment.

1.- Run `Installation-win_script_sccm.cmd` as Administrator from a DOS Shell in the folder where you cloned from Github.
	I prefeer to use this because it always works.
2.- Run `Installation-win_script_sccm.ps1` as Administrator from a Powershell in the folder where you cloned from Github.


## **Install and Update Process via Batch script**
The Batch installation process performs first a MD5 Check of the Splunk Universalforwarder file before it starts with the installation.
```bash
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
echo       Please contact with SwissTXT Security - security@swisstxt.ch
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
```

### Parameters to adapt
If you want to adapt the script to install another Splunk-UF version, then first download the binary and MD5-file from splunk.com,
copy it to the folder where the script is stored and adapt then the following parameters:

- **PkgSplunkVersion64** = The Splunk-UF version you want to install. In our case `splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi`.
- **PkgSysmonCfg** = The name of the Sysmon config file. In our case `SysmonConfig_windows_systems-v6.0.xml`
- **PkgDeploymentOldConf`** = The full path where the `deploymentclient.conf` is stored you want to change with the TA in **PkgDeploymentApp** . Usually in `%ProgramFiles%\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf`
- **PkgDeploymentApp** = This is a specific TA to provide the `deploymentclient.conf` file. So you can later manage it via your deployment server. The folder is called `TA-deploymentclient-DEP1`.
- **TargetAppLocation** = Usually in `%ProgramFiles%\SplunkUniversalForwarder\etc\apps\` and don't need to be changed in 99% of the cases.

### Purpose of the _TA-deploymentclient-DEP1_
When you install the Splunk-UF from scratch, you usually need to refeer where the agent can find the **Deployment Server**.
One of the main problems here is that the `deploymentclient.conf`, where the information is stored how the client can find the Deployment Server, is automatic stored in `%ProgramFiles%\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf`.
If you want, for some reasons, change the deployment server to another IP or hostname, then you end in a problem.

Therefore I created the **TA-deploymentclient-DEP1** where the `deploymentclient.conf` is stored and later on managed by your deployment server.


## **Install and Update Process via Powershell script**
The Upgrade using the Powershell script is more straight forward, but needs to be adapted before!.
If you want to change the Version of Splunk-UF of the Sysmon Config file, then you need to do it inside of the script.
Don't forget to upload the new Splunk-UF Software with the MD5-file as well as the new Sysmon config file!

```bash
###################################################
####  Sysmon 64 Bit Upgrade to version 13.02:  ####
###################################################

## ---> Remove previous Sysmon - Uninstall old Sysmon and remove old Active Setup <---
if (Test-Path "${Env:windir}\sysmon64.exe") {Execute-Process -Path "${Env:windir}\sysmon64.exe" -Parameters "-u"} else {}
if (Test-Path "${Env:windir}\sysmon64.exe") {Remove-File -Path "${Env:windir}\sysmon64.exe" -ContinueOnError $true} else {}
Remove-Folder -Path "$envProgramFilesX86\Sysmon" -ContinueOnError $true

## ---> Remove previous Sysmon Registry Key's - (Version's:  8.0.2, 10.41 and 10.42) <---
## ---> Registry Entries created by SCCM. This part can be ignored if deployment is not SCCM (clarify with SwissTXT Workplace Team) <---
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
```



## **Package Content**
Inside the folder you'll find the following files to perform the Installation of the Splunk UniversalForwarder and Sysmon.

### Sysmon bianries and config file
- **SysmonConfig_windows_systems-v6.0.xml** - Sysmon Configuration file to deploy on the clients/servers. This config is already integrated to the MITRE ATT@CK detection vectors.
- **Sysmon64.exe** - Sysmon 13.02 64Bit version (preferred to used in all 64bit systems)
- **Sysmon.exe** - Sysmon 13.02 32Bit version

### Install Splunk-UF and Sysmon with predefined sysmon.xml config file
- **Installation-win_script_sccm.cmd** - Windows Batch file to install the `splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi` and `Sysmon64.exe` with the `SysmonConfig_windows_systems-v6.0.xml`.
- **Installation-win_script_sccm.ps1** - Windows Powershell file to install the `splunkforwarder-8.2.1-ddff1c41e5cf-x64-release.msi` and `Sysmon64.exe` with the `SysmonConfig_windows_systems-v6.0.xml`.
- **md5.bat** - MD5 Checksum procedure for the Splunk-UF installationspackage.

### Spunk TA with deploymentclient.conf
- **TA-deploymentclient-DEP1** - Splunk TA containig the deploymentclient.conf file.
This TA must be also uploaded to the `/opt/splunk/etc/deployment-apps` folder of your deployment server !





## **Sysinternals Software License Terms - by Microsoft (R)**
These license terms are an agreement between Sysinternals (a wholly owned subsidiary of Microsoft Corporation) and you. Please read them. They apply to the software you are downloading from technet.microsoft.com/sysinternals, which includes the media on which you received it, if any. The terms also apply to any Sysinternals
* updates,
* supplements,
* Internet-based services,
* and support services

 for this software, unless other terms accompany those items. If so, those terms apply.
 BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS. IF YOU DO NOT ACCEPT THEM, DO NOT USE THE SOFTWARE.
 If you comply with these license terms, you have the rights below.

#### Installation and User Rights
You may install and use any number of copies of the software on your devices.

#### Scope of License
The software is licensed, not sold. This agreement only gives you some rights to use the software. Sysinternals reserves all other rights. Unless applicable law gives you more rights despite this limitation, you may use the software only as expressly permitted in this agreement. In doing so, you must comply with any technical limitations in the software that only allow you to use it in certain ways. You may not
* work around any technical limitations in the software;
* reverse engineer, decompile or disassemble the software, except and only to the extent that applicable law expressly permits, despite this limitation;
* make more copies of the software than specified in this agreement or allowed by applicable law, despite this limitation;
* publish the software for others to copy;
* rent, lease or lend the software;
* transfer the software or this agreement to any third party; or
* use the software for commercial software hosting services.

#### Sensitive Information
Please be aware that, similar to other debug tools that capture “process state” information, files saved by Sysinternals tools may include personally identifiable or other sensitive information (such as usernames, passwords, paths to files accessed, and paths to registry accessed). By using this software, you acknowledge that you are aware of this and take sole responsibility for any personally identifiable or other sensitive information provided to Microsoft or any other party through your use of the software.

#### Documentation
Any person that has valid access to your computer or internal network may copy and use the documentation for your internal, reference purposes.

#### Export Restrictions
The software is subject to United States export laws and regulations. You must comply with all domestic and international export laws and regulations that apply to the software. These laws include restrictions on destinations, end users and end use. For additional information, see www.microsoft.com/exporting .

#### Entire Agreement
This agreement, and the terms for supplements, updates, Internet-based services and support services that you use, are the entire agreement for the software and support services.

#### Applicable Law
United States . If you acquired the software in the United States , Washington state law governs the interpretation of this agreement and applies to claims for breach of it, regardless of conflict of laws principles. The laws of the state where you live govern all other claims, including claims under state consumer protection laws, unfair competition laws, and in tort.
Outside the United States . If you acquired the software in any other country, the laws of that country apply.

#### Legal Effect
This agreement describes certain legal rights. You may have other rights under the laws of your country. You may also have rights with respect to the party from whom you acquired the software. This agreement does not change your rights under the laws of your country if the laws of your country do not permit it to do so.

### Disclaimer of Warranty
The software is licensed "as-is." You bear the risk of using it. Sysinternals gives no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this agreement cannot change. To the extent permitted under your local laws, sysinternals excludes the implied warranties of merchantability, fitness for a particular purpose and non-infringement.

#### Limitation on and Exclusion of Remedies and Damages
You can recover from sysinternals and its suppliers only direct damages up to U.S. $5.00. You cannot recover any other damages, including consequential, lost profits, special, indirect or incidental damages.
This limitation applies to
* anything related to the software, services, content (including code) on third party Internet sites, or third party programs; and
* claims for breach of contract, breach of warranty, guarantee or condition, strict liability, negligence, or other tort to the extent permitted by applicable law.

It also applies even if Sysinternals knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your country may not allow the exclusion or limitation of incidental, consequential or other damages.
Please note: As this software is distributed in Quebec , Canada , some of the clauses in this agreement are provided below in French.
Remarque : Ce logiciel étant distribué au Québec, Canada, certaines des clauses dans ce contrat sont fournies ci-dessous en français.
EXONÉRATION DE GARANTIE. Le logiciel visé par une licence est offert « tel quel ». Toute utilisation de ce logiciel est à votre seule risque et péril. Sysinternals n'accorde aucune autre garantie expresse. Vous pouvez bénéficier de droits additionnels en vertu du droit local sur la protection dues consommateurs, que ce contrat ne peut modifier. La ou elles sont permises par le droit locale, les garanties implicites de qualité marchande, d'adéquation à un usage particulier et d'absence de contrefaçon sont exclues.
LIMITATION DES DOMMAGES-INTÉRÊTS ET EXCLUSION DE RESPONSABILITÉ POUR LES DOMMAGES. Vous pouvez obtenir de Sysinternals et de ses fournisseurs une indemnisation en cas de dommages directs uniquement à hauteur de 5,00 $ US. Vous ne pouvez prétendre à aucune indemnisation pour les autres dommages, y compris les dommages spéciaux, indirects ou accessoires et pertes de bénéfices.






### **Support**
Please use Github to place incidents. 
This app is supported by SwissTXT/Patrick Vanreck. Contact us under: **[yoyonet-info@gmx.net](mailto:yoyonet-info@gmx.net)**.


#### Credits
Security SwissTXT Splunk App Development

- Find us under **[SECLAB Splunk App & TA Development](https://github.com/Splunk-App-and-TA-development "SECLAB Splunk App & TA Development")**
- Send requests or questions to  _[yoyonet-info@gmx.net](mailto:yoyonet-info@gmx.net)_
- Developped by **Patrick Vanreck**


#### Software License
See attached **LICENSE** file ...


#### Copyrights
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),<br>
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,<br>
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.


<div class="footer">
    Copyright &copy; 2017-2021 by SwissTXT Security
</div>