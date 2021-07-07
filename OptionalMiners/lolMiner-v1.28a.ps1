using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\lolminer.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.28/lolMiner_v1.28a_Win64.zip"
$DeviceEnumerator = "Bus"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
#    [PSCustomObject]@{ Algorithm = "Beam";          Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo BEAM-I" } # Algo is dead, needs pers
#    [PSCustomObject]@{ Algorithm = "BeamV2";        Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo BEAM-II" } # Algo is dead
    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 0);   Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "AMD"; Fee = 0.01;  MinMemGB = 7.8; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algo C29D" } # TeamRed-v0.8.3 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algo C31" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(0, 30);  Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(20, 35); Arguments = " --coin AUTO144_5" } # GMiner-v2.59 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --coin AUTO192_7" } # GMiner-v2.59 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v5.6d is faster
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.007; MinMemGB = 5.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.6d is faster
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.6d is faster

#    [PSCustomObject]@{ Algorithm = "Beam";          Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algo BEAM-I" } # Algo is dead, needs pers
#    [PSCustomObject]@{ Algorithm = "BeamV2";        Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algo BEAM-II" } # Algo is dead
    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 1; WarmupTimes = @(0, 0);   Arguments = " --algo BEAM-III" } # NBMiner-v38.1 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 8.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algo C29D" } # GMiner-v2.59 is fastest
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(0, 30);  Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(20, 35); Arguments = " --coin AUTO144_5" } # MiniZ-v1.8y2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --coin AUTO192_7" } # MiniZ-v1.8y2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --coin ZEL" } # MiniZ-v1.8y2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "NVIDIA"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v5.6d is faster
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "NVIDIA"; Fee = 0.007; MinMemGB = 5.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.6d is faster
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "NVIDIA"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(60, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.6d is faster
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($_.Algorithm -match "^EtcHash$|^Ethash$" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { $Arguments += " --ethstratum ETHV1" }
                If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $MinMemGB += 1 }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo", "coin") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).pass)"

                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Arguments += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = $_.Type
                        Path            = $Path
                        Arguments       = ("$Arguments$(If ($Pools.($_.Algorithm).SSL) { " --tls on" } Else { " --tls off" } ) --log off --apiport $MinerAPIPort --devicesbypcie --shortstats=1 --longstats=30 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0}:0' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "lolMiner"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee
                        WarmupTimes     = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
