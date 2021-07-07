using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.59/gminer_2_59_windows64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    # [PSCustomObject]@{ Algorithm = "BeamV3";        Fee = 0.02;   MinMemGB = 3.0; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo beamhashIII --cuda 0 --opencl 1" } # Algorithm not supported on AMD
    # [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Fee = 0.05;   MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo C30CTX --cuda 0 --opencl 1" } # Algorithm not supported on AMD
    # [PSCustomObject]@{ Algorithm = "Cuckoo29";      Fee = 0.02;   MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo cuckoo29 --cuda 0 --opencl 1" } # Algorithm not supported on AMD
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Fee = 0.02;   MinMemGB = 1.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.28a is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Fee = 0.02;   MinMemGB = 2.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash192_7 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.28a is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Fee = 0.02;   MinMemGB = 2.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash210_9 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.28a is fastest
    [PSCustomObject]@{ Algorithm = "EquihashBTG";   Fee = 0.02;   MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo 144_5 --pers BgoldPoW --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";       Fee = 0.0065; MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo etchash --cuda 0 --opencl 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";        Fee = 0.0065; MinMemGB = 5.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Fee = 0.0065; MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 20); Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = "KawPoW";        Fee = 0.01;   MinMemGB = 4.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 20); Arguments = " --algo kawpow --cuda 0 --opencl 1" } # Algorithm not supported on AMD

    [PSCustomObject]@{ Algorithm = "BeamV3";        Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo beamhashIII --cuda 1 --opencl 0" } # NBMiner-v38.1 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Fee = 0.05;   MinMemGB = 8.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo C30CTX --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Fee = 0.02;   MinMemGB = 4.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo cuckoo29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Equihash1254";  Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash125_4 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y2 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Fee = 0.02;   MinMemGB = 2.1; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y2 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Fee = 0.02;   MinMemGB = 2.8; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo equihash192_7 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y2 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Fee = 0.02;   MinMemGB = 1.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";   Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --algo 144_5 --pers BgoldPoW --cuda 1 --opencl 0" } # MiniZ-v1.8y2 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Fee = 0.0065; MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";        Fee = 0.0065; MinMemGB = 5.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Fee = 0.0065; MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --algo ethash --cuda 1 --opencl 0" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";        Fee = 0.01;   MinMemGB = 4.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo kawpow --cuda 1 --opencl 0" } # XmRig-v6.12.2 is almost as fast but has no fee
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model | Where-Object { $_.Type -ne "AMD" -or $_.OpenCL.ClVersion -ge "OpenCL C 1.2" })) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0 ) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                # Windows 10 requires more memory on some algos
                If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += 1 }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algo", "pers", "proto") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Arguments += " --server $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Arguments += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }
                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                        $Arguments += "  --proto stratum"
                    }

                    If ($Config.UseMinerTweaks -eq $true) { 
                        $Arguments += $_.Tuning
                    }

                    If ($Pools.($_.Algorithm).SSL) { $Arguments += " --ssl true --ssl_verification false" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments --api $($MinerAPIPort) --watchdog 0 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Gminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
