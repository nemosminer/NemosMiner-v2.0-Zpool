@echo off
mode con cols=50 lines=10
cls
:begin
FOR /L %%A IN (60,-1,0) DO (
  cls
  echo Timeout [92;1m%%A[0m seconds...
  timeout /t 1 >nul
)
:start
cls
:measure
for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage0=%%p
for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage1=%%p
for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage2=%%p
for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage3=%%p
for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage4=%%p
for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage5=%%p
for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage6=%%p
set /a total=%gpu_usage0%+%gpu_usage1%+%gpu_usage2%+%gpu_usage3%+%gpu_usage4%+%gpu_usage5%+%gpu_usage6%
set /a gpu_average=%total%/7

:end_for
cls
echo Average Usage of *7 GPUs usage is %gpu_average%%%
if %gpu_average% GTR 40 (
   echo [92;1mMining is working[0m
   echo [102;92;1mMining is working[0m
   timeout /t 120 >nul
   goto :start
)

set log_file=mining_problems_log.txt
set ping_time=900
FOR /F "skip=8 tokens=10" %%G in ('ping -n 3 google.com') DO set ping_time=%%G
if %ping_time% GTR 0 (
   
   echo Control checking of GPUs usage, timeout 120 sec...
   timeout /t 120 >nul
   goto:recheck
   :endrecheck
   if %gpu_average% GTR 40 (
      echo ------------------- %date% %time% reboot warning>> %log_file%
      goto :start
   )
   echo.
   echo Average Usage of *7 GPUs usage is [93m%gpu_average%%%[0m
   echo.
   
   echo ping is [92m%ping_time%[0m - OK, not internet problem
   timeout /t 120 >nul
   goto :endif
)
:else
   cls
   echo      %date% %time% No internet connection>> %log_file%
   echo No internet connection, keep working...
   timeout /t 120 >nul
   goto :begin
:endif

SET mypath=%~dp0
SET scrpath=%mypath%Scr
if not exist "%scrpath%" mkdir "%scrpath%"

rem "%mypath%nircmd.exe" savescreenshot "%scrpath%\%TIME:~0,-9%-%TIME:~3,2%-%TIME:~6,2%.png"
echo "%scrpath%%DATE:~6,4%.%DATE:~3,2%.%DATE:~0,2% %TIME:~0,-9%-%TIME:~3,2%-%TIME:~6,2%.png"

echo.>> %log_file%
echo ---------------------------------------------------------------------------------------------------->> %log_file%
echo.>> %log_file%
echo PC was restarted at %date% %time%>> %log_file%, mining issue. GPUs usage is %gpu_average%%%
"nvidia-smi">> %log_file%
echo.>> %log_file%
echo ---------------------------------------------------------------------------------------------------->> %log_file%
echo.>> %log_file%

echo [101;93mMining is NOT working, rebooting in 10 seconds...[0m
timeout /t 30 >nul
shutdown.exe /r /t 00
goto :end



:recheck
   for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage0=%%p
   for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage1=%%p
   for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage2=%%p
   for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage3=%%p
   for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage4=%%p
   for /F %%p in ('"nvidia-smi" --id^=1 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage5=%%p
   for /F %%p in ('"nvidia-smi" --id^=0 --query-gpu^=utilization.gpu --format^=csv^,noheader^,nounits') do set gpu_usage6=%%p
      set /a total=%gpu_usage0%+%gpu_usage1%+%gpu_usage2%+%gpu_usage3%+%gpu_usage4%+%gpu_usage5%+%gpu_usage6%
   set /a gpu_average=%total%/7
goto :endrecheck
:end
