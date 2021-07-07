REM This file will run for neoscrypt algo
REM This file and nvidia inspector is disabled by default to Enable them, rename this file from neoscrpyt-example.bat to neoscrypt.bat
REM Below is a example for a 6 GPU setup

SET PL=61
SET MEMORY=-500
SET CORE=25
SET TEMP=90

SET GPU0=-setBaseClockOffset:0,0,%CORE% -setMemoryClockOffset:0,0,%MEMORY% -setPowerTarget:0,%PL% -setTempTarget:0,0,%TEMP%
SET GPU1=-setBaseClockOffset:1,0,%CORE% -setMemoryClockOffset:1,0,%MEMORY% -setPowerTarget:1,%PL% -setTempTarget:1,0,%TEMP% 
SET GPU2=-setBaseClockOffset:2,0,%CORE% -setMemoryClockOffset:2,0,%MEMORY% -setPowerTarget:2,%PL% -setTempTarget:2,0,%TEMP% 
SET GPU3=-setBaseClockOffset:3,0,%CORE% -setMemoryClockOffset:3,0,%MEMORY% -setPowerTarget:3,%PL% -setTempTarget:3,0,%TEMP% 
SET GPU4=-setBaseClockOffset:4,0,%CORE% -setMemoryClockOffset:4,0,%MEMORY% -setPowerTarget:4,%PL% -setTempTarget:4,0,%TEMP% 
SET GPU5=-setBaseClockOffset:5,0,%CORE% -setMemoryClockOffset:5,0,%MEMORY% -setPowerTarget:5,%PL% -setTempTarget:5,0,%TEMP%

nvidiaInspector.exe %GPU0% %GPU1% %GPU2% %GPU3% %GPU4% %GPU5%
