REM This file will run for any algo if AlgoName.bat does not exist
REM This file and nvidia inspector is disabled by default to Enable them, rename this file from default-example.bat to default.bat
REM Below is a example for a 6 GPU setup

SET PL=61
SET MEMORY=225
SET CORE=25
SET TEMP=90

SET GPU0=-setBaseClockOffset:0,0,%CORE% -setMemoryClockOffset:0,0,%MEMORY% -setPowerTarget:0,%PL% -setTempTarget:0,0,%TEMP%
SET GPU1=-setBaseClockOffset:1,0,%CORE% -setMemoryClockOffset:1,0,%MEMORY% -setPowerTarget:1,%PL% -setTempTarget:1,0,%TEMP% 
SET GPU2=-setBaseClockOffset:2,0,%CORE% -setMemoryClockOffset:2,0,%MEMORY% -setPowerTarget:2,%PL% -setTempTarget:2,0,%TEMP% 
SET GPU3=-setBaseClockOffset:3,0,%CORE% -setMemoryClockOffset:3,0,%MEMORY% -setPowerTarget:3,%PL% -setTempTarget:3,0,%TEMP% 
SET GPU4=-setBaseClockOffset:4,0,%CORE% -setMemoryClockOffset:4,0,%MEMORY% -setPowerTarget:4,%PL% -setTempTarget:4,0,%TEMP% 
SET GPU5=-setBaseClockOffset:5,0,%CORE% -setMemoryClockOffset:5,0,%MEMORY% -setPowerTarget:5,%PL% -setTempTarget:5,0,%TEMP%
SET GPU6=-setBaseClockOffset:6,0,%CORE% -setMemoryClockOffset:6,0,%MEMORY% -setPowerTarget:6,%PL% -setTempTarget:6,0,%TEMP%
SET GPU7=-setBaseClockOffset:7,0,%CORE% -setMemoryClockOffset:7,0,%MEMORY% -setPowerTarget:7,%PL% -setTempTarget:7,0,%TEMP%
SET GPU8=-setBaseClockOffset:8,0,%CORE% -setMemoryClockOffset:8,0,%MEMORY% -setPowerTarget:8,%PL% -setTempTarget:8,0,%TEMP%

nvidiaInspector.exe %GPU0% %GPU1% %GPU2% %GPU3% %GPU4% %GPU5% %GPU6% %GPU7% %GPU8%
