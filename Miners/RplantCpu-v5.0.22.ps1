using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-sse42.exe"
$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.22/cpuminer-opt-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Balloon";       MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo balloon" }
    [PSCustomObject]@{ Algorithm = "Circcash";      MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo circcash" }
    [PSCustomObject]@{ Algorithm = "CpuPower";      MinerSet = 0; WarmupTimes = @(45, 45);  Arguments = " --algo cpupower" }
#    [PSCustomObject]@{ Algorithm = "CurveHash";     MinerSet = 0; WarmupTimes = @(0, 75); Arguments = " --algo curvehash" } # reported hash rates too high (https://github.com/rplant8/cpuminer-opt-rplant/issues/21)
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo heavyhash" }
    [PSCustomObject]@{ Algorithm = "Hodl";          MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo hodl" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";    MinerSet = 0; WarmupTimes = @(0, 75); Arguments = " --algo gr" }
    [PSCustomObject]@{ Algorithm = "Phi5";          MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo phi5" }
    [PSCustomObject]@{ Algorithm = "Qureno";        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo qureno" }
    [PSCustomObject]@{ Algorithm = "X33";           MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "X22";           MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo x22" } 
    [PSCustomObject]@{ Algorithm = "Yescrypt";      MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --algo yescryptr16" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8";    MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --algo yescryptr8" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8g";   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yescryptr8g" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Yespower";      MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";    MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo power2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo power2b" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";    MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerIC" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerIOTS" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerITC" }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerLITB" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerLTNCG" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";   MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerRes";   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerRes" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerSugar" }
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerTIDE" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo yespowerURX" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 

            If ($Miner_Devices.CpuFeatures -match "avx512")   { $Path = ".\Bin\$($Name)\cpuminer-Avx512.exe" }
            ElseIf ($Miner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
            ElseIf ($Miner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
            ElseIf ($Miner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
            ElseIf ($Miner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
            Else { Return }

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | ForEach-Object {

                # Get arguments for active miner devices
                # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+tcps" } Else { $Protocol = "stratum+tcp" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $Miner_Devices.Name
                    Type        = "CPU"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --rig-id $($Config.WorkerName) --cpu-affinity AAAA --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                }
            }
        }
    }
}