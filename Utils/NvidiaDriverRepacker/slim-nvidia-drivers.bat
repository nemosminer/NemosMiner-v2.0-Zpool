@echo off

rem --------------------------------------------------
rem A Windows batch file to slim down NVIDIA drivers.
rem Author: XhmikosR
rem Licensed under the MIT License
rem See help for more info
rem --------------------------------------------------


:start
setlocal

set "FOLDERS_TO_KEEP_MINIMAL=Display.Driver NVI2"
set "FOLDERS_TO_KEEP_SLIM=Display.Driver HDAudio NVI2 PhysX PPC"
set "FILES_TO_KEEP_MINIMAL=EULA.txt ListDevices.txt setup.cfg setup.exe"
set "FILES_TO_KEEP_SLIM=%FILES_TO_KEEP_MINIMAL%"

set "BATCH_FILENAME=%~nx0"
set "ARG1=%~1"
set "FULL_PATH=%ARG1%"
set "FILENAME=%~n1"
set "WORK_FOLDER=%FILENAME%"
set "SCRIPT_VERSION=0.5"

title %BATCH_FILENAME% %FILENAME%

rem Check if any argument is passed; if not show the help screen
if "%ARG1%" == "" goto help
if "%ARG1%" == "--help" goto help
if "%ARG1%" == "-help" goto help
if "%ARG1%" == "/help" goto help

rem Try to detect 7-Zip or 7za.exe; if none is found, show a message and exit
call :detect_sevenzip_path

if not exist "%SEVENZIP%" (
  echo 7-Zip or 7za.exe wasn't found!
  echo You can install 7-Zip, or place 7za.exe in your %%PATH%%, or in the same folder as this script.
  goto exit
)

rem Switch to the batch file's directory
cd /d %~dp0

rem If the file doesn't exist show a message and exit
if not exist "%FULL_PATH%" (
  echo "%FULL_PATH%" wasn't found! & goto exit
)

rem Remove the old folder if it exists
if exist "%WORK_FOLDER%" rd /q /s "%WORK_FOLDER%"

rem Extract the driver
"%SEVENZIP%" x "%FULL_PATH%" -o"%WORK_FOLDER%"
if %ERRORLEVEL% neq 0 (
  echo. & echo *** [ERROR] Extracting "%FULL_PATH%" failed! & echo.
  goto exit
)

rem Switch to the drivers folder
pushd "%WORK_FOLDER%"

rem Minimal
call :copy "minimal"
if ERRORLEVEL 1 goto exit
call :modify_setup_cfg
if ERRORLEVEL 1 goto exit
call :create_archive "minimal"
if ERRORLEVEL 1 goto exit

rem Slim
call :copy "slim"
if ERRORLEVEL 1 goto exit
call :modify_setup_cfg
if ERRORLEVEL 1 goto exit
call :create_archive "slim"
if ERRORLEVEL 1 goto exit

popd

rem Remove the drivers folder
rd /q /s "%WORK_FOLDER%"


:exit
endlocal
echo. & echo Press any key to close this window...
pause >nul
exit /b


rem Subroutines
:help
echo --------------------------------------------------
echo %BATCH_FILENAME% v%SCRIPT_VERSION%
echo A Windows batch file to slim down NVIDIA drivers.
echo Author: XhmikosR
echo Licensed under the MIT License
echo.
echo Requirements:
echo   * a) 7-Zip installed or b) 7za.exe in your %%PATH%%, or in the same folder as this script
echo   * A recent Windows version; the script is only tested on Windows 10
echo   * The NVIDIA driver already downloaded somewhere on your computer :)
echo.
echo Usage: %BATCH_FILENAME% NVIDIA_DRIVER_FILE.exe
echo.
echo This will create two 7z archives, minimal and slim:
echo   * "minimal" includes only the driver
echo   * "slim" includes the driver, HDAudio, PhysX and USB-C HDMI Driver
echo --------------------------------------------------
goto exit


:copy
set "TYPE=%~1"
set "TEMP_DIR=_temp_%TYPE%"

rem Create a temporary folder
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

rem Copy all the things
call :copy_folders "%TYPE%"
if ERRORLEVEL 1 exit /b %ERRORLEVEL%
call :copy_files "%TYPE%"
if ERRORLEVEL 1 exit /b %ERRORLEVEL%

exit /b 0


:copy_folders
if "%TYPE%" == "minimal" (
  set "TEMP_FOLDERS_TO_KEEP=%FOLDERS_TO_KEEP_MINIMAL%"
) else (
  set "TEMP_FOLDERS_TO_KEEP=%FOLDERS_TO_KEEP_SLIM%"
)

rem Copy the folders we want to keep into the temporary folder
for /d %%G in (%TEMP_FOLDERS_TO_KEEP%) do (
  if not exist "%%G" (
    echo. & echo *** [ERROR] "%%G" doesn't exist in the drivers file! & echo.
    exit /b 1
  )

  xcopy "%%G" "%TEMP_DIR%\%%G" /i /s /h /e /k /q /r /y /v
  if %ERRORLEVEL% neq 0 (
    echo. & echo *** [ERROR] Copying folders failed! & echo.
    exit /b 1
  )
)

exit /b 0


:copy_files
if "%TYPE%" == "minimal" (
  set "TEMP_FILES_TO_KEEP=%FILES_TO_KEEP_MINIMAL%"
) else (
  set "TEMP_FILES_TO_KEEP=%FILES_TO_KEEP_SLIM%"
)

rem Copy the files we want to keep into the temporary folder
for %%G in (%TEMP_FILES_TO_KEEP%) do (
  if not exist "%%G" (
    echo. & echo *** [ERROR] "%%G" doesn't exist in the drivers file! & echo.
    exit /b 1
  )

  copy /y /v "%%G" "%TEMP_DIR%\"
  if %ERRORLEVEL% neq 0 (
    echo. & echo *** [ERROR] Copying files failed! & echo.
    exit /b 1
  )
)

exit /b 0


:modify_setup_cfg
rem Remove the files required after 397.93, but are not needed
type "%TEMP_DIR%\setup.cfg" | findstr /v "EulaHtmlFile FunctionalConsentFile PrivacyPolicyFile">"%TEMP_DIR%\setup2.cfg"
if ERRORLEVEL 1 exit /b %ERRORLEVEL%

rem Overwrite the origin setup.cfg file
move /y "%TEMP_DIR%\setup2.cfg" "%TEMP_DIR%\setup.cfg"
if ERRORLEVEL 1 exit /b %ERRORLEVEL%

exit /b 0


:create_archive
rem Rename the temporary directory
set "TEMP_ARCHIVE_DIR=%FILENAME%_%TYPE%"
rename "%TEMP_DIR%" "%TEMP_ARCHIVE_DIR%"

rem Just in case NUMBER_OF_PROCESSORS isn't defined
if not defined NUMBER_OF_PROCESSORS set NUMBER_OF_PROCESSORS=4

rem Create the new archive
start "7-Zip" /b /wait "%SEVENZIP%" a -t7z ""%TEMP_ARCHIVE_DIR%.7z"" ""%TEMP_ARCHIVE_DIR%\*"" -mmt=%NUMBER_OF_PROCESSORS% -m0=LZMA2 -mx9

if %ERRORLEVEL% neq 0 (
  echo. & echo *** [ERROR] Creating 7z archive! & echo.
  exit /b 1
)

move /y "%TEMP_ARCHIVE_DIR%.7z" ".."

rem Remove the temporary folders
if exist "%TEMP_DIR%" rd /q /s "%TEMP_DIR%"
if exist "%TEMP_ARCHIVE_DIR%" rd /q /s "%TEMP_ARCHIVE_DIR%"

exit /b 0


:detect_sevenzip_path
if exist 7za.exe (set "SEVENZIP=7za.exe" & exit /b)

for %%G in (7z.exe) do (set "SEVENZIP_PATH=%%~$PATH:G")
if exist "%SEVENZIP_PATH%" (set "SEVENZIP=%SEVENZIP_PATH%" & exit /b)

for %%G in (7za.exe) do (set "SEVENZIP_PATH=%%~$PATH:G")
if exist "%SEVENZIP_PATH%" (set "SEVENZIP=%SEVENZIP_PATH%" & exit /b)

for /f "tokens=2*" %%A in (
  'reg QUERY "HKLM\SOFTWARE\7-Zip" /v "Path" 2^>nul ^| find "REG_SZ" ^|^|
   reg QUERY "HKLM\SOFTWARE\Wow6432Node\7-Zip" /v "Path" 2^>nul ^| find "REG_SZ"') do set "SEVENZIP=%%B\7z.exe"
exit /b 0
