
using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v38.1/NBMiner_38.1_Win.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 2.0; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo ergo --platform 2" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 4.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.01; MinMemGB = 5.0; MinMemGBWin10 = 4.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo ethash --enable-dag-cache --platform 2 --enable-dag-cache" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 3.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo ethash --platform 2 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "AMD"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.12.2 is almost as fast but has no fee
 
    [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -mt 1 --algo beamv3 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";   Type = "NVIDIA"; Fee = 0.02; MinMemGB = 8.0; MinMemGBWin10 = 10.0; MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -mt 1 --algo cuckatoo32 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";     Type = "NVIDIA"; Fee = 0.02; MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " -mt 1 --algo cuckoo_ae --platform 1" } # GMiner-v2.59 is fastest
    [PSCustomObject]@{ Algorithm = "Ergo";         Type = "NVIDIA"; Fee = 0.02; MinMemGB = 5.0; MinMemGBWin10 = 5.0;  MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -mt 1 --algo ergo --platform 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " -mt 1 --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " -mt 1 --algo ethash --enable-dag-cache --platform 1 --enable-dag-cache" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " -mt 1 --algo ethash --platform 1 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " -mt 1 --algo kawpow --platform 1" } # XmRig-v6.12.2 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Sero";         Type = "NVIDIA"; Fee = 0.02; MinMemGB = 2.0; MinMemGBWin10 = 2.0;  MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " -mt 1 --algo progpow_sero --platform 1" }
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.03; MinMemGB = 5.0; MinMemGBWin10 = 5.0;  MinComputeCapability = 6.1; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " -mt 1 --algo octopus --platform 1" } # Trex-v0.21.0 is fastest
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 
                If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPow") -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } # Ethash on Navi is slow

                $Arguments = $_.Arguments
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                $MinComputeCapability = $_.MinComputeCapability

                # Windows 10 requires more memory on some algos
                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB = $_.MinMemGBWin10 } Else { $MinMemGB = $_.MinMemGB }

                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { [Double]($_.OpenCL.ComputeCapability) -ge $MinComputeCapability })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -match "^EtcHash$|^Ethash.*|^Cuck.*") { 
                        If ($Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                            $Protocol = "nicehash+tcp://"
                        }
                        Else { 
                            $Protocol = "ethproxy+tcp://"
                        }
                    }
                    Else { 
                        $Protocol = "stratum+tcp://"
                    }
                    If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace '\+tcp\://$', '+ssl://' }

                    $Arguments += " --url $($Protocol)$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --password $($Pools.($_.Algorithm).Pass)"

                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Arguments += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $_.Fee = 0
                        $Arguments += " --fee 0"
                    }

                    If ($Pools.($_.Algorithm).Name -match "^MiningPoolHub(|Coins)$") { $WarmupTimes[0] += 30; $WarmupTimes[1] += 15 } # Seconds longer for MPH because of long connect issue

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "NBMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
