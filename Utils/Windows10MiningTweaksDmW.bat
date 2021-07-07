rem ========== Pre ==========

rem Don't echo to standard output
@echo off
rem Set version info
set V=5.3.6
rem Change colors
color 1F
rem Set title
title Windows 10 Mining Tweaks (x64) Version %V% by: DeadManWalking

rem ========== Start ==========

cls
echo ###############################################################################
echo #                                                                             #
echo #  Windows10MiningTweaksDmW Version %V%                                     #
echo #                                                                             #
echo #  Microsoft Windows 10  --  Build 10240 (x64) or later                       #
echo #                                                                             #
echo #  AUTHOR: DeadManWalking  (DeadManWalkingTO-GitHub)                          #
echo #                                                                             #
echo #                                                                             #
echo #  Features                                                                   #
echo #                                                                             #
echo #  1. System BackUp                                                           #
echo #  1.1. Registry BackUp                                                       #
echo #  1.2. Services BackUp                                                       #
echo #                                                                             #
echo #  2. System Tweak                                                            #
echo #  2.1. Registry Tweaks                                                       #
echo #  2.2. Removing Services                                                     #
echo #  2.3. Removing Scheduled Tasks                                              #
echo #  2.4. Removing Windows Default Apps                                         #
echo #  2.5. Disable / Remove OneDrive                                             #
echo #  2.6. Blocking Telemetry Servers                                            #
echo #  2.7. Blocking More Windows Servers                                         #
echo #  2.8. Disable Windows Error Recovery on Startup                             #
echo #  2.9. Internet Explorer 11 Tweaks                                           #
echo #  2.10. Libraries Tweaks                                                     #
echo #  2.11. Windows Update Tweaks                                                #
echo #  2.12. Windows Defender Tweaks                                              #
echo #                                                                             #
echo ###############################################################################
echo.
timeout /T 1 /NOBREAK > nul

rem ========== Automatically Check & Get Admin Rights ==========

:init
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>nul 2>nul
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
echo.
echo ###############################################################################
echo #  Invoking UAC for Privilege Escalation                                      #
echo ###############################################################################

echo Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
echo args = "ELEV " >> "%vbsGetPrivileges%"
echo For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
echo args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
echo Next >> "%vbsGetPrivileges%"
echo UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

rem ========== Initializing ==========

setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsServicesBackup=%temp%\DmwServicesBackup_%batchName%.vbs"
setlocal EnableDelayedExpansion

set "DmwLine= rem By DeadManWalking"
echo !DmwLine! > %vbsServicesBackup%
set "DmwLine=Option Explicit"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=If WScript.Arguments.length = 0 Then"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Dim objShell : Set objShell = CreateObject("Shell.Application")"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   objShell.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & " uac", "", "runas", 1"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=Else"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Dim WshShell, objFSO, strNow, intServiceType, intStartupType, strDisplayName, iSvcCnt"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Dim sREGFile, sBATFile, r, b, strComputer, objWMIService, colListOfServices, objService"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set WshShell = CreateObject("Wscript.Shell")"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set objFSO = Wscript.CreateObject("Scripting.FilesystemObject")"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   strNow = Year(Date) & Right("0" & Month(Date), 2) & Right("0" & Day(Date), 2)"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Dim objFile: Set objFile = objFSO.GetFile(WScript.ScriptFullName)"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   sREGFile = "C:\DmWBackup-Services-" & strNow & ".reg""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   sBATFile = "C:\DmWBackup-Services-" & strNow & ".bat""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set r = objFSO.CreateTextFile (sREGFile, True)"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   r.WriteLine "Windows Registry Editor Version 5.00""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   r.WriteBlankLines 1"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   r.WriteLine ";Services Startup Configuration Backup " & Now"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   r.WriteBlankLines 1"
echo !DmwLine! >> %vbsServicesBackup% 
set "DmwLine=   Set b = objFSO.CreateTextFile (sBATFile, True)"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   b.WriteLine "@echo Restore Service Startup State saved at " & Now"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   b.WriteBlankLines 1"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   strComputer = ".""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   iSvcCnt=0"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Dim sStartState, sSvcName, sSkippedSvc"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set colListOfServices = objWMIService.ExecQuery ("Select * from Win32_Service")"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   For Each objService In colListOfServices"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      iSvcCnt=iSvcCnt + 1"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      r.WriteLine "[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\" & trim(objService.Name) & "]""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      sStartState = lcase(objService.StartMode)"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      sSvcName = objService.Name"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      Select Case sStartState"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "boot""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000000""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         b.WriteLine "sc.exe config " & sSvcName & " start= boot""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "system""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000001""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         b.WriteLine "sc.exe config " & sSvcName & " start= system""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "auto""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000002""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         If objService.DelayedAutoStart = True Then"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=            r.WriteLine chr(34) & "DelayedAutostart" & Chr(34) & "=dword:00000001""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=            b.WriteLine "sc.exe config " & sSvcName & " start= delayed-auto""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Else"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=            r.WriteLine chr(34) & "DelayedAutostart" & Chr(34) & "=-""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=            b.WriteLine "sc.exe config " & sSvcName & " start= auto""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         End If"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "manual""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000003""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         b.WriteLine "sc.exe config " & sSvcName & " start= demand""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "disabled""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000004""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         b.WriteLine "sc.exe config " & sSvcName & " start= disabled""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=         Case "unknown"	sSkippedSvc = sSkippedSvc & ", " & sSvcName"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      End Select"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      r.WriteBlankLines 1"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Next"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   If trim(sSkippedSvc) <> "" Then"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      WScript.Echo iSvcCnt & " Services found. The services " & sSkippedSvc & " could not be backed up.""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Else"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=      WScript.Echo iSvcCnt & " Services found and their startup configuration backed up.""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   End If"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   r.Close"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   b.WriteLine "@pause""
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   b.Close"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set objFSO = Nothing"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=   Set WshShell = Nothing"
echo !DmwLine! >> %vbsServicesBackup%
set "DmwLine=End If"
echo !DmwLine! >> %vbsServicesBackup%

set "DmwBackupFilename=C:\DmWBackup"
set DmwDate=%date:~10,4%%date:~7,2%%date:~4,2%

set PMax=0
set PRun=0
set PAct=0

rem ========== 1. System BackUp ==========

echo.
echo ###############################################################################
echo #  1. System BackUp  --  Start                                                #
echo ###############################################################################
echo.

rem ========== 1.1. Registry BackUp ==========

echo.
echo ###############################################################################
echo #  1.1. Registry BackUp  --  Start                                            #
echo ###############################################################################
echo.

:500
set /A Pline=500
set PMax=5
set PRun=0
rem set PAct=0
echo Registry BackUp in C:\ (%PMax%).
set /p Pselect="Continue? y/n/a: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+2
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:501
set myMSG=BackUp HKCR (HKEY_CLASSES_ROOT)
echo %myMSG%
set myMSG=Describes file type, file extension, and OLE information.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:502
reg EXPORT HKCR %DmwBackupFilename%-Reg-HKCR-%DmwDate%.reg /y
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:503
set myMSG=BackUp HKCU (HKEY_CURRENT_USER)
echo %myMSG%
set myMSG=Contains user who is currently logged into Windows and their settings.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:504
reg EXPORT HKCU %DmwBackupFilename%-Reg-HKCU-%DmwDate%.reg /y
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:505
set myMSG=BackUp HKLM (HKEY_LOCAL_MACHINE)
echo %myMSG%
set myMSG=Contains computer-specific information about the hardware installed, software settings, and other information. The information is used for all users who log on to that computer and is one of the more commonly accessed areas in the registry.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:506
reg EXPORT HKLM %DmwBackupFilename%-Reg-HKLM-%DmwDate%.reg /y
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:507
set myMSG=BackUp HKU (HKEY_USERS)
echo %myMSG%
set myMSG=Contains information about all the users who log on to the computer, including both generic and user-specific information.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:508
reg EXPORT HKU %DmwBackupFilename%-Reg-HKU-%DmwDate%.reg /y
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:509
set myMSG=BackUp HKCC (HKEY_CURRENT_CONFIG)
echo %myMSG%
set myMSG=The details about the current configuration of hardware attached to the computer.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:510
reg EXPORT HKCC %DmwBackupFilename%-Reg-HKCC-%DmwDate%.reg /y
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:511
:512

:599
echo.
echo ###############################################################################
echo #  1.1. Registry BackUp  --  End                                              #
echo ###############################################################################
echo.

rem ========== 1.2. Services BackUp ==========

echo.
echo ###############################################################################
echo #  1.2. Services BackUp  --  Start                                            #
echo ###############################################################################
echo.

:600
set /A Pline=600
set PMax=1
set PRun=0
rem set PAct=0
echo Registry BackUp in C:\ (%PMax%).
set /p Pselect="Continue? y/n/a: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+2
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:601
set myMSG=Queries the list of Windows services and their startup type configuration.
echo %myMSG%
set myMSG=The results are written to .reg and .bat files for later restoration. The two files are created in the C:\ folder.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:602
WScript.exe %vbsServicesBackup%
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry BackUp. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:603
:604

:649
echo.
echo ###############################################################################
echo #  1.2. Services BackUp  --  End                                              #
echo ###############################################################################
echo.

rem ========== 2. System BackUp ==========

echo.
echo ###############################################################################
echo #  2. System Tweaks  --  Start                                                #
echo ###############################################################################
echo.

rem ========== 2.1. Registry Tweaks ==========

echo.
echo ###############################################################################
echo #  2.1. Registry Tweaks  --  Start                                            #
echo ###############################################################################
echo.

:1000
set /A Pline=1000
set PMax=37
set PRun=0
rem set PAct=0
echo Apply Registry tweaks (%PMax%).
set /p Pselect="Continue? y/n/a: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+2
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:1001
set myMSG=Show computer shortcut on desktop.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1002
rem 0 = show icon, 1 = don't show icon
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1003
set myMSG=Show Network shortcut on desktop.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1004
rem 0 = show icon, 1 = don't show icon
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1005
set myMSG=Classic vertical icon spacing.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1006
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "IconVerticalSpacing" /t REG_SZ /d "-1150" /f > nul 2>&1set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1007
set myMSG=Lock the Taskbar.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1008
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarSizeMove" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1009
set myMSG=Always show all icons on the taskbar (next to clock).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1010
rem 0 = Show all icons
rem 1 = Hide icons on the taskbar
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "EnableAutoTray" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1011
set myMSG=Delay taskbar thumbnail pop-ups to 10 seconds.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1012
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t REG_DWORD /d "10000" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1013
set myMSG=Enable classic control panel view.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1014
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ForceClassicControlPanel" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1015
set myMSG=Turn OFF Sticky Keys when SHIFT is pressed 5 times.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1016
rem 506 = Off, 510 = On (default)
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1017
set myMSG=Turn OFF Filter Keys when SHIFT is pressed for 8 seconds.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1018
rem 122 = Off, 126 = On (default)
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1019
set myMSG=Disable Hibernation.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1020
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1021
set myMSG=Underline keyboard shortcuts and access keys.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1022
reg add "HKCU\Control Panel\Accessibility\Keyboard Preference" /v "On" /t REG_SZ /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1023
set myMSG=Show known file extensions in Explorer.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1024
rem 0 = extensions are visible
rem 1 = extensions are hidden
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1025
set myMSG=Hide indication for compressed NTFS files.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1026
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCompColor" /t RED_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1027
set myMSG=Show Hidden files in Explorer.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1028
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1029
set myMSG=Show Super Hidden System files in Explorer.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1030
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSuperHidden" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1031
set myMSG=Prevent both Windows and Office from creating LNK files in the Recents folder.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1032
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1033
set myMSG=Replace Utilman with CMD.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1034
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe" /v "Debugger" /t REG_SZ /d "cmd.exe" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1035
set myMSG=Add the option "Processor performance core parking min cores".
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1036
rem Option will be added to: Power Options > High Performance > Change Plan Settings > Change advanced power settings > Processor power management
rem Default data is 1 (option hidden)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "Attributes" /t REG_DWORD /d 0 /f  > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1037
set myMSG=Add the option "Disable CPU Core Parking".
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1038
rem Default value is 100 decimal.
rem Basically "Core parking" means that the OS can use less CPU cores when they are not needed, and saving power.
rem This, however, can somewhat hamper performance, so advanced users prefer to disable this feature.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d 0 /f  > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1039
set myMSG=Remove Logon screen wallpaper/background. Will use solid color instead (Accent color).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1040
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableLogonBackgroundImage" /t REG_DWORD /d 1 /f  > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1041
set myMSG=Disable lockscreen.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1042
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreen" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1043
set myMSG=Remove versioning tab from properties.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1044
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v NoPreviousVersionsPage /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1045
set myMSG=Disable jump lists.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1046
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1047
set myMSG=Disable Windows Error Reporting.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1048
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1049
set myMSG=Disable Cortana (Speech Search Assistant, which also sends information to Microsoft).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1050
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1051
set myMSG=Hide the search box from taskbar. You can still search by pressing the Win key and start typing what you're looking for.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1052
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1053
set myMSG=Disable MRU lists (jump lists) of XAML apps in Start Menu.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1054
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1055
set myMSG=Set Windows Explorer to start on This PC instead of Quick Access.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1056
rem 1 = This PC, 2 = Quick access
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1057
set myMSG=Disable Disk Quota tab, which appears as a tab when right-clicking on drive letter - Properties.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1058
rem 1 = This PC, 2 = Quick access
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DiskQuota" /v "Enable" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1059
set myMSG=Disable creation of an Advertising ID.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1060
rem 1 = This PC, 2 = Quick access
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1061
set myMSG=Remove Pin to start (3).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1062
reg delete "HKEY_CLASSES_ROOT\exefile\shellex\ContextMenuHandlers\PintoStartScreen" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\PintoStartScreen" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\mscfile\shellex\ContextMenuHandlers\PintoStartScreen" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+3
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1063
set myMSG=Disable Cortana, Bing Search and Searchbar (4).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1064
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+4
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1065
set myMSG=Turn off the Error Dialog (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1066
reg add "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1067
set myMSG=Disable Administrative shares (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1068
reg add "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters" /v "AutoShareWks" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters" /v "AutoShareServer" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1069
set myMSG=Add "Reboot to Recovery" to right-click menu of "This PC" (4).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1070
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg add "HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\Reboot to Recovery" /v "Icon" /t REG_SZ /d %SystemRoot%\System32\imageres.dll,-110" /f > nul 2>&1
reg add "HKEY_CLASSES_ROOT\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\Reboot to Recovery\command" /ve /d "shutdown.exe -r -o -f -t 00" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+4
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1071
set myMSG=Change Clock and Date formats of current user to: 24H, metric (Sign out required to see changes) (6).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1072
rem Apply to all users by using the key: HKLM\SYSTEM\CurrentControlSet\Control\CommonGlobUserSettings\Control Panel\International
reg add "HKCU\Control Panel\International" /v "iMeasure" /t REG_SZ /d "0" /f > nul 2>&1
reg add "HKCU\Control Panel\International" /v "iNegCurr" /t REG_SZ /d "1" /f > nul 2>&1
reg add "HKCU\Control Panel\International" /v "iTime" /t REG_SZ /d "1" /f > nul 2>&1
reg add "HKCU\Control Panel\International" /v "sShortDate" /t REG_SZ /d "yyyy/MM/dd" /f > nul 2>&1
reg add "HKCU\Control Panel\International" /v "sShortTime" /t REG_SZ /d "HH:mm" /f > nul 2>&1
reg add "HKCU\Control Panel\International" /v "sTimeFormat" /t REG_SZ /d "H:mm:ss" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+6
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1073
set myMSG=Enable Developer Mode (enables you to run XAML apps you develop in Visual Studio which haven't been certified yet) (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1074
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowAllTrustedApps" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1075
set myMSG=Remove telemetry and data collection (14).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:1076
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\COMPONENTS\DerivedData\Components\amd64_microsoft-windows-c..lemetry.lib.cortana_31bf3856ad364e35_10.0.10240.16384_none_40ba2ec3d03bceb0" /v "f!dss-winrt-telemetry.js" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\COMPONENTS\DerivedData\Components\amd64_microsoft-windows-c..lemetry.lib.cortana_31bf3856ad364e35_10.0.10240.16384_none_40ba2ec3d03bceb0" /v "f!proactive-telemetry.js" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\COMPONENTS\DerivedData\Components\amd64_microsoft-windows-c..lemetry.lib.cortana_31bf3856ad364e35_10.0.10240.16384_none_40ba2ec3d03bceb0" /v "f!proactive-telemetry-event_8ac43a41e5030538" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\COMPONENTS\DerivedData\Components\amd64_microsoft-windows-c..lemetry.lib.cortana_31bf3856ad364e35_10.0.10240.16384_none_40ba2ec3d03bceb0" /v "f!proactive-telemetry-inter_58073761d33f144b" /t REG_DWORD /d 0 /f > nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener" /v "Start" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger" /v "Start" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Telemetry" /v "Enabled" /t REG_DWORD /d 0 /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Registry Tweaks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:1077
:1078

:1100
echo.
echo ###############################################################################
echo #  2.1. Registry Tweaks  --  End                                              #
echo ###############################################################################
echo.

rem ========== 2.2. Removing Services ==========

echo.
echo ###############################################################################
echo #  2.2. Removing Services  --  Start                                          #
echo ###############################################################################
echo.

:2000
set /A Pline=2000
set PMax=36
set PRun=0
rem set PAct=0
echo Removing Services (%PMax%).
set /p Pselect="Continue? y/n/a: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+2
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:2001
set myMSG=Disable Connected User Experiences and Telemetry (To turn off Telemetry and Data Collection).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2002
sc config DiagTrack start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2003
set myMSG=Disable Diagnostic Policy Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2004
sc config DPS start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2005
set myMSG=Disable Distributed Link Tracking Client (If your computer is not connected to any network).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2006
sc config TrkWks start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2007
set myMSG=Disable WAP Push Message Routing Service (To turn off Telemetry and Data Collection).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2008
sc config dmwappushservice start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2009
set myMSG=Disable Downloaded Maps Manager (If you don't use Maps app).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2010
sc config MapsBroker start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2011
set myMSG=Disable IP Helper (If you don't use IPv6 connection).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2012
sc config iphlpsvc start= Disabled > nul 2>&1 
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2013
set myMSG=Disable Program Compatibility Assistant Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2014
sc config PcaSvc start= Disabled > nul 2>&1 
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2015
set myMSG=Disable Print Spooler (If you don't have a printer).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2016
sc config Spooler start= Disabled > nul 2>&1 
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2017
set myMSG=Disable Remote Registry (You can set it to DISABLED for Security purposes).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2018
sc config RemoteRegistry start= Disabled > nul 2>&1 
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2019
set myMSG=Disable Secondary Logon.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2020
sc config seclogon start= Disabled > nul 2>&1 	
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2021
set myMSG=Disable Security Center.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2022
sc config wscsvc start= Disabled > nul 2>&1 
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2023
set myMSG=Disable TCP/IP NetBIOS Helper (If you are not in a workgroup network).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2024
sc config lmhosts start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2025
set myMSG=Disable Touch Keyboard and Handwriting Panel Service (If you don't want to use touch keyboard and handwriting features.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2026
sc config TabletInputService start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2027
set myMSG=Disable Windows Error Reporting Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2028
sc config WerSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2029
set myMSG=Disable Windows Image Acquisition (WIA) (If you don't have a scanner).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2030
sc config stisvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2031
set myMSG=Disable Windows Search.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2032
sc config WSearch start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2033
set myMSG=Disable tracking services (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2034
sc config diagnosticshub.standardcollector.service start= Disabled > nul 2>&1
sc config WMPNetworkSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2035
set myMSG=Disable Superfetch.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2036
sc config SysMain start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2037
set myMSG=Disable Xbox Services (5).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2038
rem Xbox Accessory Management Service
sc config XboxGipSvc start= Disabled > nul 2>&1
rem Xbox Game Monitoring
sc config xbgm start= Disabled > nul 2>&1
rem Xbox Live Auth Manager
sc config XblAuthManager start= Disabled > nul 2>&1
rem Xbox Live Game Save
sc config XblGameSave start= Disabled > nul 2>&1
rem Xbox Live Networking Service
sc config XboxNetApiSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+5
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2039
set myMSG=Disable AllJoyn Router Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2040
rem  This service is used for routing the AllJoyn messages for AllJoyn clients.
sc config AJRouter start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2041
set myMSG=Disable Bluetooth Services (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2042
rem Bluetooth Handsfree Service
sc config BthHFSrv start= Disabled > nul 2>&1
rem Bluetooth Support Service
sc config bthserv start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2043
set myMSG=Disable Geolocation Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2044
sc config lfsvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2045
set myMSG=Disable Phone Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2046
sc config PhoneSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2047
set myMSG=Disable Windows Biometric Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2048
sc config WbioSrvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2049
set myMSG=Disable Windows Mobile Hotspot Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2050
sc config icssvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2051
set myMSG=Disable Windows Media Player Network Sharing Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2052
sc config WMPNetworkSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2053
set myMSG=Disable Windows Update Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2054
sc config wuauserv start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2055
set myMSG=Disable Enterprise App Management Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2056
sc config EntAppSvc start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2057
set myMSG=Disable Hyper-V Services (9).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2058
rem HV Host Service
sc config HvHost start= Disabled > nul 2>&1
rem Hyper-V Data Exchange Service
sc config vmickvpexchange start= Disabled > nul 2>&1
rem Hyper-V Guest Service Interface
sc config vmicguestinterface start= Disabled > nul 2>&1
rem Hyper-V Guest Shutdown Service
sc config vmicshutdown start= Disabled > nul 2>&1
rem Hyper-V Heartbeat Service
sc config vmicheartbeat start= Disabled > nul 2>&1
rem Hyper-V PowerShell Direct Service
sc config vmicvmsession start= Disabled > nul 2>&1
rem Hyper-V Remote Desktop Virtualization Service
sc config vmicrdv start= Disabled > nul 2>&1
rem Hyper-V Time Synchronization Service
sc config vmictimesync start= Disabled > nul 2>&1
rem Hyper-V Volume Shadow Copy Requestor
sc config vmicvss start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+9
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2059
set myMSG=Disable HomeGroup Listener.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2060
sc config HomeGroupListener start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2061
set myMSG=Disable HomeGroup Provider.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2062
sc config HomeGroupProvider start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2063
set myMSG=Disable Net.Tcp Port Sharing Service.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2064
sc config NetTcpPortSharing start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2065
set myMSG=Disable Routing and Remote Access.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2066
sc config RemoteAccess start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2067
set myMSG=Disable Internet Connection Sharing (ICS).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2068
sc config RemoteAccess start= Disabled > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2069
set myMSG=Disable Superfetch (A must for SSD drives, but good to do in general)(3).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2070
rem Disabling this service prevents further creation of PF files in C:\Windows\Prefetch.
rem After disabling this service, it is completely safe to delete everything in that folder, except for the ReadyBoot folder.
sc config SysMain start= disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+3
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2071
set myMSG=Disable Action Center & Security Center.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:2072
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "UseActionCenterExperience" /t REG_DWORD /d 0 /f
sc config wscsvc start= disabled
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Services Remove. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:2073
:2074

:2100
echo.
echo ###############################################################################
echo #  2.2. Removing Services  --  End                                            #
echo ###############################################################################
echo.

rem ========== 2.3. Removing Scheduled Tasks ==========

echo.
echo ###############################################################################
echo #  2.3. Removing Scheduled Tasks  --  Start                                   #
echo ###############################################################################
echo.

:3000
set /A Pline=3000
set PMax=1
set PRun=0
rem set PAct=0
echo Removing scheduled tasks (17).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:3001
schtasks /Change /TN "Microsoft\Windows\AppID\SmartScreenSpecific" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Maintenance\WinSAT" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\PI\Sqm-Tasks" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Time Synchronization\ForceSynchronizeTime" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Time Synchronization\SynchronizeTime" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\WindowsUpdate\Automatic App Update" /Disable > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+17
echo Done %PRun% / %PMax% Removing Scheduled Tasks. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:3100
echo.
echo ###############################################################################
echo #  2.3. Removing Scheduled Tasks  --  End                                     #
echo ###############################################################################
echo.

rem ========== 2.4. Removing Windows Default Apps ==========

echo.
echo ###############################################################################
echo #  2.4. Removing Windows Default Apps  --  Start                              #
echo ###############################################################################
echo.

:4000
set /A Pline=4000
set PMax=1
set PRun=0
rem set PAct=0
echo Removing Windows default apps (12).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:4001
powershell "Get-AppxPackage *3d* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *bing* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *zune* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *photo* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *communi* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *solit* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *phone* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *soundrec* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *camera* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *people* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *office* | Remove-AppxPackage" > nul 2>&1
powershell "Get-AppxPackage *xbox* | Remove-AppxPackage" > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+12
echo Done %PRun% / %PMax% Removing Windows Default Apps. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:4100
echo.
echo ###############################################################################
echo #  2.4. Removing Windows Default Apps  --  End                                #
echo ###############################################################################
echo.

rem ========== 2.5. Disable / Remove OneDrive ==========

echo.
echo ###############################################################################
echo #  2.5. Disable / Remove OneDrive  --  Start                                  #
echo ###############################################################################
echo.

:5000
set /A Pline=5000
set PMax=1
set PRun=0
rem set PAct=0
echo Disable OneDrive (7).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:5001
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f > nul 2>&1

reg delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1

:: Detete OneDrive icon on explorer.exe (Only 64 Bits)
reg add "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t reg_DWORD /d 0 /f > nul 2>&1
reg add "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t reg_DWORD /d 0 /f > nul 2>&1

set /A PRun=%PRun%+1
set /A PAct=%PAct%+7
echo Done %PRun% / %PMax% Disable / Remove OneDrive. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:5100
echo.
echo ###############################################################################
echo #  2.5. Disable / Remove OneDrive  --  End                                    #
echo ###############################################################################
echo.

rem ========== 6. Blocking Telemetry Servers ==========

echo.
echo ###############################################################################
echo #  2.6. Blocking Telemetry Servers  --  Start                                 #
echo ###############################################################################
echo.

:6000
set /A Pline=6000
set PMax=1
set PRun=0
rem set PAct=0
echo Blocking Telemetry Servers (25).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:6001
copy "%WINDIR%\system32\drivers\etc\hosts" "%WINDIR%\system32\drivers\etc\hosts.bak" > nul 2>&1
attrib -r "%WINDIR%\system32\drivers\etc\hosts" > nul 2>&1
find /C /I "choice.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 choice.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "choice.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 choice.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "oca.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 oca.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "oca.telemetry.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 oca.telemetry.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "redir.metaservices.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 redir.metaservices.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "reports.wes.df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 reports.wes.df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "services.wes.df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 services.wes.df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "settings-sandbox.data.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 settings-sandbox.data.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "sqm.df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 sqm.df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "sqm.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 sqm.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "sqm.telemetry.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telecommand.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telecommand.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telecommand.telemetry.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telemetry.appex.bing.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telemetry.appex.bing.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telemetry.appex.bing.net:443" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telemetry.appex.bing.net:443>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "telemetry.urs.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 telemetry.urs.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "vortex.data.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 vortex.data.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "vortex-sandbox.data.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 vortex-sandbox.data.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "vortex-win.data.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 vortex-win.data.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.ppe.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.ppe.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.telemetry.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.telemetry.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "wes.df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 wes.df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
attrib +r "%WINDIR%\system32\drivers\etc\hosts" > nul 2>&1

set /A PRun=%PRun%+1
set /A PAct=%PAct%+25
echo Done %PRun% / %PMax% Blocking Telemetry Servers. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:6100
echo.
echo ###############################################################################
echo #  2.6. Blocking Telemetry Servers  --  End                                   #
echo ###############################################################################
echo.

rem ========== 2.7. Blocking More Windows Servers ==========

echo.
echo ###############################################################################
echo #  2.7. Blocking More Windows Servers  --  Start                              #
echo ###############################################################################
echo.

:7000
set /A Pline=7000
set PMax=1
set PRun=0
rem set PAct=0
echo Blocking More Telemetry Servers (109).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:7001
copy "%WINDIR%\system32\drivers\etc\hosts" "%WINDIR%\system32\drivers\etc\hosts.bak" > nul 2>&1
attrib -r "%WINDIR%\system32\drivers\etc\hosts" > nul 2>&1
find /C /I "184-86-53-99.deploy.static.akamaitechnologies.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 184-86-53-99.deploy.static.akamaitechnologies.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a.ads1.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a.ads1.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a.ads2.msads.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a.ads2.msads.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a.ads2.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a.ads2.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a.rad.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a.rad.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0001.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0001.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0002.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0002.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0003.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0003.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0004.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0004.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0005.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0005.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0006.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0006.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0007.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0007.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0008.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0008.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-0009.a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-0009.a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a1621.g.akamai.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a1621.g.akamai.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a1856.g2.akamai.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a1856.g2.akamai.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a1961.g.akamai.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a1961.g.akamai.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a978.i6g1.akamai.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a978.i6g1.akamai.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ac3.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ac3.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ad.doubleclick.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ad.doubleclick.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "adnexus.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 adnexus.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "adnxs.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 adnxs.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ads.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ads.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ads1.msads.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ads1.msads.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ads1.msn.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ads1.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "aidps.atdmt.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 aidps.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "aka-cdn-ns.adtech.de" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 aka-cdn-ns.adtech.de>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a-msedge.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a-msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "any.edge.bing.com" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 any.edge.bing.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "az361816.vo.msecnd.net" %WINDIR%\system32\drivers\etc\hosts	
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 az361816.vo.msecnd.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "az512334.vo.msecnd.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 az512334.vo.msecnd.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "b.ads1.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 b.ads1.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "b.ads2.msads.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 b.ads2.msads.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "b.rad.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 b.rad.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "bingads.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 bingads.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "bs.serving-sys.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 bs.serving-sys.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "c.atdmt.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 c.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "cdn.atdmt.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 cdn.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "cds26.ams9.msecn.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 cds26.ams9.msecn.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "compatexchange.cloudapp.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 compatexchange.cloudapp.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "corp.sts.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 corp.sts.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "corpext.msitadfs.glbdns2.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "cs1.wpc.v0cdn.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 cs1.wpc.v0cdn.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "cy2.vortex.data.microsoft.com.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 cy2.vortex.data.microsoft.com.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "db3aqu.atdmt.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 db3aqu.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "diagnostics.support.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 diagnostics.support.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "e2835.dspb.akamaiedge.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 e2835.dspb.akamaiedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "e7341.g.akamaiedge.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 e7341.g.akamaiedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "e7502.ce.akamaiedge.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 e7502.ce.akamaiedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "e8218.ce.akamaiedge.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 e8218.ce.akamaiedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ec.atdmt.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ec.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "fe2.update.microsoft.com.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 fe2.update.microsoft.com.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "fe2.update.microsoft.com.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 fe2.update.microsoft.com.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "feedback.microsoft-hohm.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 feedback.microsoft-hohm.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "feedback.search.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 feedback.search.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "feedback.windows.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 feedback.windows.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "flex.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 flex.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "g.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 g.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "h1.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 h1.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "h2.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 h2.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "hostedocsp.globalsign.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 hostedocsp.globalsign.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "i1.services.social.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 i1.services.social.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "i1.services.social.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 i1.services.social.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ipv6.msftncsi.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ipv6.msftncsi.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ipv6.msftncsi.com.edgesuite.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ipv6.msftncsi.com.edgesuite.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "lb1.www.ms.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 lb1.www.ms.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "live.rads.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 live.rads.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "m.adnxs.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 m.adnxs.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "m.hotmail.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 m.hotmail.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "msedge.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 msedge.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "msftncsi.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 msftncsi.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "msnbot-65-55-108-23.search.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 msnbot-65-55-108-23.search.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "msntest.serving-sys.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 msntest.serving-sys.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "onesettings-db5.metron.live.nsatc.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 onesettings-db5.metron.live.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "pre.footprintpredict.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 pre.footprintpredict.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "preview.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 preview.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "rad.live.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 rad.live.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "rad.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 rad.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "s0.2mdn.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 s0.2mdn.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "schemas.microsoft.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 schemas.microsoft.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "secure.adnxs.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 secure.adnxs.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "secure.flashtalking.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 secure.flashtalking.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "settings-win.data.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 settings-win.data.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "sls.update.microsoft.com.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 sls.update.microsoft.com.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ssw.live.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ssw.live.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "static.2mdn.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 static.2mdn.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "statsfe1.ws.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 statsfe1.ws.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "statsfe2.update.microsoft.com.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 statsfe2.update.microsoft.com.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "statsfe2.update.microsoft.com.akadns.net," %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 statsfe2.update.microsoft.com.akadns.net,>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "statsfe2.ws.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 statsfe2.ws.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "survey.watson.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 survey.watson.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "survey.watson.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 survey.watson.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "view.atdmt.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 view.atdmt.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "vortex-bn2.metron.live.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 vortex-bn2.metron.live.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "vortex-cy2.metron.live.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 vortex-cy2.metron.live.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.live.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.live.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "watson.telemetry.microsoft.com.nsatc.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 watson.telemetry.microsoft.com.nsatc.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "wes.df.telemetry.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 wes.df.telemetry.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "win10.ipv6.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 win10.ipv6.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "www.bingads.microsoft.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 www.bingads.microsoft.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "www.go.microsoft.akadns.net" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 www.go.microsoft.akadns.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "www.msftncsi.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 www.msftncsi.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "a248.e.akamai.net" %WINDIR%\system32\drivers\etc\hosts
rem skype & itunes issues 
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 a248.e.akamai.net>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "apps.skype.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 apps.skype.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "c.msn.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 c.msn.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "pricelist.skype.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 pricelist.skype.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "s.gateway.messenger.live.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 s.gateway.messenger.live.com>>%WINDIR%\system32\drivers\etc\hosts
find /C /I "ui.skype.com" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% NEQ 0 echo ^0.0.0.0 ui.skype.com>>%WINDIR%\system32\drivers\etc\hosts
attrib +r "%WINDIR%\system32\drivers\etc\hosts" > nul 2>&1

set /A PRun=%PRun%+1
set /A PAct=%PAct%+109
echo Done %PRun% / %PMax% Blocking More Windows Servers. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:7100
echo.
echo ###############################################################################
echo #  2.7. Blocking More Windows Servers  --  End                                #
echo ###############################################################################
echo.

rem ========== 2.8. Disable Windows Error Recovery on Startup ==========

echo.
echo ###############################################################################
echo #  2.8. Disable Windows Error Recovery on Startup   --  Start                 #
echo ###############################################################################
echo.

:8000
set /A Pline=8000
set PMax=1
set PRun=0
rem set PAct=0
echo Disable Windows Error Recovery on Startup (2).
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:8001
bcdedit /set recoveryenabled NO > nul 2>&1
bcdedit /set {current} bootstatuspolicy ignoreallfailures > nul 2>&1

set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax% Disable Windows Error Recovery on Startup. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul

:8100
echo.
echo ###############################################################################
echo #  2.8. Disable Windows Error Recovery on Startup  --  End                    #
echo ###############################################################################
echo.

rem ========== 2.9. Internet Explorer 11 Tweaks ==========

echo.
echo ###############################################################################
echo #  2.9. Internet Explorer 11 Tweaks  --  Start                                #
echo ###############################################################################
echo.

:9000
set /A Pline=9000
set PMax=3
set PRun=0
rem set PAct=0
echo Internet Explorer 11 Tweaks.
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:9001
set myMSG=Internet Explorer 11 Tweaks (Basic)(15).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:9002
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "DoNotTrack" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "http://www.google.com" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Start Page Redirect Cache" /t REG_SZ /d "http://www.google.com" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "RunOnceHasShown" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "RunOnceComplete" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main" /v "RunOnceHasShown" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main" /v "RunOnceComplete" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" /v "RunOnceHasShown" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Internet Explorer\Main" /v "RunOnceComplete" /t REG_DWORD /d 1 /f > nul 2>&1

reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "PlaySounds" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Isolation" /t REG_SZ /d PMEM /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Isolation64Bit" /t REG_DWORD /d 1 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+15
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:9003
set myMSG=Disable IE Suggested Sites & Flip ahead (page prediction which sends browsing history to Microsoft).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:9004
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Suggested Sites" /v "Enabled" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\Suggested Sites" /v "DataStreamEnabledState" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\FlipAhead" /v "FPEnabled" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+3
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:9005
set myMSG=Add Google as search provider for IE11, and make it the default (11).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:9006
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /f  > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "DisplayName" /t REG_SZ /d "Google" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "FaviconURL" /t REG_SZ /d "http://www.google.com/favicon.ico" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "FaviconURLFallback" /t REG_SZ /d "http://www.google.com/favicon.ico" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "OSDFileURL" /t REG_SZ /d "http://www.iegallery.com/en-us/AddOns/DownloadAddOn?resourceId=813" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "ShowSearchSuggestions" /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "SuggestionsURL" /t REG_SZ /d "http://clients5.google.com/complete/search?q={searchTerms}&client=ie8&mw={ie:maxWidth}&sh={ie:sectionHeight}&rh={ie:rowHeight}&inputencoding={inputEncoding}&outputencoding={outputEncoding}" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "SuggestionsURLFallback" /t REG_SZ /d "http://clients5.google.com/complete/search?hl={language}&q={searchTerms}&client=ie8&inputencoding={inputEncoding}&outputencoding={outputEncoding}" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "TopResultURLFallback" /t REG_SZ /d "" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /v "URL" /t REG_SZ /d "http://www.google.com/search?q={searchTerms}&sourceid=ie7&rls=com.microsoft:{language}:{referrer:source}&ie={inputEncoding?}&oe={outputEncoding?}" /f > nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "DefaultScope" /t REG_SZ /d "{89418666-DF74-4CAC-A2BD-B69FB4A0228A}" /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+11
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:9007
:9008

:9100
echo.
echo ###############################################################################
echo #  2.9. Internet Explorer 11 Tweaks  --  End                                  #
echo ###############################################################################
echo.

rem ========== 2.10. Libraries Tweaks ==========

echo.
echo ###############################################################################
echo #   2.10. Libraries Tweaks  --  Start                                         #
echo ###############################################################################
echo.

:10000
set /A Pline=10000
set PMax=8
set PRun=0
rem set PAct=0
echo Libraries Tweaks.
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:10001
set myMSG=Remove Music, Pictures & Videos from Start Menu places (Settings > Personalization > Start > Choose which folders appear on Start)(3).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10002
del "C:\ProgramData\Microsoft\Windows\Start Menu Places\05 - Music.lnk"
del "C:\ProgramData\Microsoft\Windows\Start Menu Places\06 - Pictures.lnk"
del "C:\ProgramData\Microsoft\Windows\Start Menu Places\07 - Videos.lnk"
set /A PRun=%PRun%+1
set /A PAct=%PAct%+3
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10003
set myMSG=Remove Music, Pictures & Videos from Libraries (3).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10004
del "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Music.library-ms"
del "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Pictures.library-ms"
del "%userprofile%\AppData\Roaming\Microsoft\Windows\Libraries\Videos.library-ms"
set /A PRun=%PRun%+1
set /A PAct=%PAct%+3
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10005
set myMSG=Remove Libraries (60).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10006
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\UsersLibraries" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{59BD6DD1-5CEC-4d7e-9AD2-ECC64154418D}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{C4D98F09-6124-4fe0-9942-826416082DA9}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{59BD6DD1-5CEC-4d7e-9AD2-ECC64154418D}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{C4D98F09-6124-4fe0-9942-826416082DA9}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\UsersLibraries" /f
reg delete "HKCU\SOFTWARE\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@C:\Windows\system32\windows.storage.dll,-50691" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Namespace\Windows\UserLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\WindowsSettingHandlers\UserLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.NavPaneShowLibraries" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{c51b83e5-9edd-4250-b45a-da672ee3c70e}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{e9711a2f-350f-4ec1-8ebd-21245a8b9376}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{e9711a2f-350f-4ec1-8ebd-21245a8b9376}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{e9711a2f-350f-4ec1-8ebd-21245a8b9376}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF324EC-F905-4c69-851A-DDC8795F71F2}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{51F649D3-4BFF-42f6-A253-6D878BE1651D}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{896664F7-12E1-490f-8782-C0835AFD98FC}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+60
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10007
set myMSG=Remove "Show Libraries" from Folder Options -> View tab (Advanced Settings).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10008
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\NavPane\ShowLibraries" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10009
set myMSG=Remove Music (appears under This PC in File Explorer)(28).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10010
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Music" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Music" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Music" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\MyMusic" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonMusic" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Music" /f
reg delete "HKEY_USERS\S-1-5-19\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Music" /f
reg delete "HKEY_USERS\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Music" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonMusic" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonMusic" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonMusic" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{3f2a72a7-99fa-4ddb-a5a8-c604edf61d6b}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+28
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10011
set myMSG=Remove Pictures (appears under This PC in File Explorer) (41).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10012
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\MyPictures" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@C:\Windows\System32\Windows.UI.Immersive.dll,-38304" /f
reg delete "HKEY_USERS\S-1-5-19\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /f
reg delete "HKEY_USERS\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Pictures" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonPictures" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\StartMenu\StartPanel\PinnedItems\Pictures" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonPictures" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" /f

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{c1f8339f-f312-4c97-b1c6-ecdf5910c5c0}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{4dcafe13-e6a7-4c28-be02-ca8c2126280d}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{b3690e58-e961-423b-b687-386ebfd83239}" /f

reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{c1f8339f-f312-4c97-b1c6-ecdf5910c5c0}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonPictures" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonPictures" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKLM\SOFTWARE\Wow6432Node\Classes\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+41
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10013
set myMSG=Remove Videos (appears under This PC in File Explorer) (29).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10014
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Video" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonVideo" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Video" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Video" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\MyVideo" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonVideo" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Video" /f
reg delete "HKEY_USERS\S-1-5-19\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Video" /f
reg delete "HKEY_USERS\S-1-5-20\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "My Video" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "CommonVideo" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{51294DA1-D7B1-485b-9E9A-17CFFE33E187}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{ea25fbd7-3bf7-409e-b97f-3352240903f4}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{292108be-88ab-4f33-9a26-7748e62e37ad}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{5fa96407-7e77-483c-ac93-691d05850de8}" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "CommonVideo" /f
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\{51294DA1-D7B1-485b-9E9A-17CFFE33E187}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f

rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+29
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10015
set myMSG=Remove Pictures, Music, Videos from MUIcache (5).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:10016
reg delete "HKCU\SOFTWARE\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@windows.storage.dll,-21790" /f
reg delete "HKCU\SOFTWARE\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@windows.storage.dll,-34584" /f
reg delete "HKCU\SOFTWARE\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@windows.storage.dll,-34595" /f
reg delete "HKCU\SOFTWARE\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@windows.storage.dll,-34620" /f
reg delete "HKEY_USERS\.DEFAULT\Software\Classes\Local Settings\MuiCache\1\52C64B7E" /v "@windows.storage.dll,-21790" /f
set /A PRun=%PRun%+1
set /A PAct=%PAct%+5
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:10017
:10018

:10100
echo.
echo ###############################################################################
echo #  2.10. Libraries Tweaks  --  End                                            #
echo ###############################################################################
echo.


rem ========== 2.11. Windows Update Tweaks ==========

echo.
echo ###############################################################################
echo #  2.11. Windows Update Tweaks --  Start                                      #
echo ###############################################################################
echo.

:11000
set /A Pline=11000
set PMax=4
set PRun=0
rem set PAct=0
echo Windows Update Tweaks.
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:11001
set myMSG=Windows Update - Notify first.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:11002
net stop wuauserv > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f > nul 2>&1
net start wuauserv > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+5
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:11003
set myMSG=Change how Windows Updates are delivered - allow only directly from Microsoft.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:11004
rem 0 = Off (only directly from Microsoft)
rem 1 = Get updates from Microsoft and PCs on your local network
rem 3 = Get updates from Microsoft, PCs on your local network & PCs on the Internet (like how torrents work)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:11005
set myMSG=Disable Windows Update sharing (2).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:11006
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DownloadMode" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+2
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:11007
set myMSG=Disable automatic Windows Updates.
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:11008
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 2 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+1
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:11009
:11010

:11100
echo.
echo ###############################################################################
echo #  2.11. Windows Update Tweaks  --  End                                       #
echo ###############################################################################
echo.


rem ========== 2.12. Windows Defender Tweaks ==========

echo.
echo ###############################################################################
echo #  2.12. Windows Defender Tweaks --  Start                                    #
echo ###############################################################################
echo.

:12000
set /A Pline=12000
set PMax=2
set PRun=0
rem set PAct=0
echo Windows Defender Tweaks.
set /p Pselect="Continue? y/n: "
if '%Pselect%' == 'y' set /A Pline=%Pline%+1
if '%Pselect%' == 'n' set /A Pline=%Pline%+100
goto %Pline%

:12001
set myMSG=Don't allow Windows Defender to submit samples to MAPS (formerly SpyNet) (4).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:12002
rem ext
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet" -ot reg -actn setowner -ownr "n:Administrators" -rec yes
rem %SystemRoot%\System32\setaclx64 -on "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet" -ot reg -actn ace -ace "n:Administrators;p:full" -rec yes
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet" /v "SpyNetReporting" /t REG_DWORD /d 0 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 0 /f > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+4
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:12003
set myMSG=Disable Windows Defender (8).
echo %myMSG%
set /p regTweak="Continue? y/n: "
if '%regTweak%' == 'y' set /A Pline=%Pline%+1
if '%regTweak%' == 'n' set /A Pline=%Pline%+2
goto %Pline%
:12004
sc config WinDefend start= Disabled > nul 2>&1
sc config WdNisSvc start= Disabled > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable > nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable > nul 2>&1
del "C:\ProgramData\Microsoft\Windows Defender\Scans\mpcache*" /s > nul 2>&1
set /A PRun=%PRun%+1
set /A PAct=%PAct%+4
echo Done %PRun% / %PMax%. Total Actions %PAct%.
timeout /T 1 /NOBREAK > nul
set /A Pline=%Pline%+1
if '%Pselect%' == 'a' set /A Pline=%Pline%+1
goto %Pline%

:12005
:12006

:12100
echo.
echo ###############################################################################
echo #  2.12. Windows Defender Tweaks  --  End                                     #
echo ###############################################################################
echo.

rem ========== Finish ==========

:finish
echo.
echo ###############################################################################
echo #                                                                             #
echo #  Windows10MiningTweaksDmW Version %V%                                     #
echo #                                                                             #
echo #  AUTHOR: DeadManWalking  (DeadManWalkingTO-GitHub)                          #
echo #                                                                             #
echo ###############################################################################
echo #  Total Actions %PAct%.
echo ###############################################################################
echo #                                                                             #
echo #  Finish. Ready for mining!                                                  #
echo #                                                                             #
echo #  Press any key to exit.                                                     #
echo #                                                                             #
echo ###############################################################################

pause > nul

rem ========== End ==========

rem ========== EoF ==========
