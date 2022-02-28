:: //***************************************************************************
:: //
:: // File:      datacopySYSTEM.cmd
:: //
:: // Additional files required:  Robocopy.exe.  Script creates required elevate.cmd and 
:: //                             elevate.vbs in %Temp% when run.
:: //
:: // Purpose:   CMD script that will self elevate and allow copying a source to destination sans
:: //            commonly unnecessary folders. Uses robocopy
:: // 
:: // Usage:     datacopy.cmd
:: //
:: // Version:   0.8
:: //
:: // History:
:: // ::Change Log
:: // v0.8 (16.10.12) - First Github release, no other changes.
:: // v0.7.2 (16.07.08) - Added $RECYCLE.BIN to folder exclusions, added .ost to file exclusions
:: // v0.7.1 (16.05.20) - Added OLDHD to folder exclusions, set MT:64, on a 64bit system this can dramatically speed up a copy. Removed ZB parameter from robocopy. Removed -d parameter from psexec.
:: // v0.7 (16.04.13) - Created a SYSTEM version of the script that utilizes psexec in the same path as the script to run as SYSTEM, modified the save location of the script also.
:: // v0.6.1 (14.08.19) - Added $hf_mig$, Temp, ServicePackFiles, Microsoft.Net, ie8updates, ie7updates, assembly to folder exclusions and MFT.exe to file exclusions
:: // v0.6 (14.07.17) - Added time to log file to allow multiple runs and to allow resuming without overwriting log files.
:: //                   Added XP version check, some xp systems has robocopy but lack whoami and the elevation script then fails, skip elevation if system is XP, but may still fail if missing robocopy.
:: // v0.5 (14.04.28) - Added winsxs and SoftwareDistribution to directory exclusions as it is quite large and entirely useless.
:: // v0.4 (14.02.04) - Added /NP parameter to the script as including progress percentage was wasting log space. Also added version identifier to the log and made sure the log was defaulting to append.

:: //
:: // ***** End Header *****
:: //***************************************************************************

@echo off
setlocal enabledelayedexpansion

set CmdDir=%~dp0
set CmdDir=%CmdDir:~0,-1%


:: ////////////////////////////////////////////////////////////////////////////
:: Check whether running elevated
:: ////////////////////////////////////////////////////////////////////////////
call :CREATE_ELEVATE_SCRIPTS

::VERSION Check
ver | find "2003" > nul
if %ERRORLEVEL% == 0 goto xpera
ver | find "XP" > nul
if %ERRORLEVEL% == 0 goto xpera
ver | find "2000" > nul
if %ERRORLEVEL% == 0 goto xpera
ver | find "NT" > nul
if %ERRORLEVEL% == 0 goto xpera

:: Check for Mandatory Label\High Mandatory Level
whoami /groups | find "S-1-16-12288" > nul
if "%errorlevel%"=="0" (
    echo Running as elevated user.  Continuing script.
) else (
    echo Not running as elevated user.
    echo Relaunching Elevated: "%~dpnx0" %*

    if exist "%Temp%\elevate.cmd" (
        set ELEVATE_COMMAND="%Temp%\elevate.cmd"
    ) else (
        set ELEVATE_COMMAND=elevate.cmd
    )

    set CARET=^^
    !ELEVATE_COMMAND! cmd /k cd /d "%~dp0" !CARET!^& call "%~dpnx0" %*
    goto :EOF
)
:: Skips elevation if XP era system found
:xpera

if exist %ELEVATE_CMD% del %ELEVATE_CMD%
if exist %ELEVATE_VBS% del %ELEVATE_VBS%


:: ////////////////////////////////////////////////////////////////////////////
:: Main script code starts here
:: ////////////////////////////////////////////////////////////////////////////
echo Arguments passed: %*
@ECHO OFF

ECHO Wscript.Echo Msgbox("Datacopy Script v0.8 (16.10.12)")>%TEMP%\~input.vbs
cscript //nologo %TEMP%\~input.vbs
DEL %TEMP%\~input.vbs

::Input Source
ECHO Wscript.Echo Inputbox("Enter Source without trailing slash (Eg: D:):")>%TEMP%\~input.vbs
FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set src=%%G
DEL %TEMP%\~input.vbs

::Input Destination
ECHO Wscript.Echo Inputbox("Enter Destination without trailing slash(Eg: C:\OLDHD):")>%TEMP%\~input.vbs
FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set dest=%%G
DEL %TEMP%\~input.vbs

IF "%dest%" == "" goto ERROR
IF "%src%" == "" goto ERROR

::Remove Trailing Slash
IF %dest:~-1%==\ SET dest=%dest:~0,-1%
IF %src:~-1%==\ SET src=%src:~0,-1%

IF "%dest%" == "A:" goto ERROR
IF "%dest%" == "B:" goto ERROR
IF "%dest%" == "C:" goto ERROR
IF "%dest%" == "D:" goto ERROR
IF "%dest%" == "E:" goto ERROR
IF "%dest%" == "F:" goto ERROR
IF "%dest%" == "G:" goto ERROR
IF "%dest%" == "H:" goto ERROR
IF "%dest%" == "I:" goto ERROR
IF "%dest%" == "J:" goto ERROR
IF "%dest%" == "K:" goto ERROR
IF "%dest%" == "L:" goto ERROR
IF "%dest%" == "M:" goto ERROR
IF "%dest%" == "N:" goto ERROR
IF "%dest%" == "O:" goto ERROR
IF "%dest%" == "P:" goto ERROR
IF "%dest%" == "Q:" goto ERROR
IF "%dest%" == "R:" goto ERROR
IF "%dest%" == "S:" goto ERROR
IF "%dest%" == "T:" goto ERROR
IF "%dest%" == "U:" goto ERROR
IF "%dest%" == "V:" goto ERROR
IF "%dest%" == "W:" goto ERROR
IF "%dest%" == "X:" goto ERROR
IF "%dest%" == "Y:" goto ERROR
IF "%dest%" == "Z:" goto ERROR

::Time 
for /f "Tokens=1-4 Delims=/ " %%i in ('date /t') do  set dt=%%i-%%j-%%k-%%l
for /f "Tokens=1" %%i in ('time /t') do set tm=-%%i
set tm=%tm::=-%
set dtt=%dt%%tm%

::Version Identifier
ECHO "Version 0.8 (16.10.12)" > "%userprofile%\%username%.%computername%.%dtt%.log"
IF NOT EXIST "%dest%" MKDIR "%dest%"
start /b /wait "" psexec -accepteula -i -s robocopy "%src%" "%dest%" /MT:64 /E /NP /XD $RECYCLE.BIN "Temporary Internet Files" Temp OLDHD Microsoft.Net $hf_mig$ ie8updates ie7updates ServicePackFiles assembly SoftwareDistribution winsxs /XJ /XF MRT.exe pagefile.sys hiberfil.sys *.ost /R:2 /W:5 /LOG+:"%userprofile%\%username%.%computername%.%dtt%.log"
copy /Y "%username%.%computername%.%dtt%.log" "%dest%\%username%.%computername%.%dtt%.log"
attrib -s -h -r "%dest%"
start notepad "%userprofile%\%username%.%computername%.%dtt%.log"
GOTO :EOF

:ERROR
ECHO Don't use the root folder as your destination!
GOTO :EOF


:: ////////////////////////////////////////////////////////////////////////////
:: End of main script code here
:: ////////////////////////////////////////////////////////////////////////////
goto :EOF


:: ////////////////////////////////////////////////////////////////////////////
:: Subroutines
:: ////////////////////////////////////////////////////////////////////////////

:CREATE_ELEVATE_SCRIPTS

    set ELEVATE_CMD="%Temp%\elevate.cmd"

    echo @setlocal>%ELEVATE_CMD%
    echo @echo off>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo :: Pass raw command line agruments and first argument to Elevate.vbs>>%ELEVATE_CMD%
    echo :: through environment variables.>>%ELEVATE_CMD%
    echo set ELEVATE_CMDLINE=%%*>>%ELEVATE_CMD%
    echo set ELEVATE_APP=%%1>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo start wscript //nologo "%%~dpn0.vbs" %%*>>%ELEVATE_CMD%


    set ELEVATE_VBS="%Temp%\elevate.vbs"

    echo Set objShell ^= CreateObject^("Shell.Application"^)>%ELEVATE_VBS% 
    echo Set objWshShell ^= WScript.CreateObject^("WScript.Shell"^)>>%ELEVATE_VBS%
    echo Set objWshProcessEnv ^= objWshShell.Environment^("PROCESS"^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo ' Get raw command line agruments and first argument from Elevate.cmd passed>>%ELEVATE_VBS%
    echo ' in through environment variables.>>%ELEVATE_VBS%
    echo strCommandLine ^= objWshProcessEnv^("ELEVATE_CMDLINE"^)>>%ELEVATE_VBS%
    echo strApplication ^= objWshProcessEnv^("ELEVATE_APP"^)>>%ELEVATE_VBS%
    echo strArguments ^= Right^(strCommandLine, ^(Len^(strCommandLine^) - Len^(strApplication^)^)^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo If ^(WScript.Arguments.Count ^>^= 1^) Then>>%ELEVATE_VBS%
    echo     strFlag ^= WScript.Arguments^(0^)>>%ELEVATE_VBS%
    echo     If ^(strFlag ^= "") OR (strFlag="help") OR (strFlag="/h") OR (strFlag="\h") OR (strFlag="-h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "\?") OR (strFlag = "/?") OR (strFlag = "-?") OR (strFlag="h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "?"^) Then>>%ELEVATE_VBS%
    echo         DisplayUsage>>%ELEVATE_VBS%
    echo         WScript.Quit>>%ELEVATE_VBS%
    echo     Else>>%ELEVATE_VBS%
    echo         objShell.ShellExecute strApplication, strArguments, "", "runas">>%ELEVATE_VBS%
    echo     End If>>%ELEVATE_VBS%
    echo Else>>%ELEVATE_VBS%
    echo     DisplayUsage>>%ELEVATE_VBS%
    echo     WScript.Quit>>%ELEVATE_VBS%
    echo End If>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo Sub DisplayUsage>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo     WScript.Echo "Elevate - Elevation Command Line Tool for Windows Vista" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Purpose:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "--------" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "To launch applications that prompt for elevation (i.e. Run as Administrator)" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "from the command line, a script, or the Run box." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage:   " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate application <arguments>" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate notepad ""C:\Windows\win.ini""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate cmd /k cd ""C:\Program Files""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command Set-Location 'C:\Windows'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage with scripts: When using the elevate command with scripts such as" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Windows Script Host or Windows PowerShell scripts, you should specify" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "the script host executable (i.e., wscript, cscript, powershell) as the " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "application." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage with scripts:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate wscript ""C:\windows\system32\slmgr.vbs"" –dli" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command & 'C:\Temp\Test.ps1'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "The elevate command consists of the following files:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.cmd" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.vbs" ^& vbCrLf>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo End Sub>>%ELEVATE_VBS%

goto :EOF

