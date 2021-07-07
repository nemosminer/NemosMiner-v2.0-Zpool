using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miniZ.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/MiniZ_v1.8y2_win-x64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";       MinMemGB = 4.0; Fee = 0.02;   MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --par=beam3 --pers=Beam-PoW --ocX" } # NBMiner-v38.1 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1254"; MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=125,4 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1445"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=144,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1505"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=150,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash1927"; MinMemGB = 2.3; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=192,7 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash2109"; MinMemGB = 2.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=210,9 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "Equihash965";  MinMemGB = 2.0; Fee = 0.02;   MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --par=96,5 --smart-pers --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";  MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=144,5 --pers BgoldPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";  MinMemGB = 3.0; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=192,7 --pers ZcashPoW --ocX" }
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4.0; Fee = 0.0075; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --par=Ethash --ocX" }
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3.0; Fee = 0.0075; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --par=Ethash --ocX" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      MinMemGB = 5.0; Fee = 0.0075; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --par=EtcHash --ocX" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --par=kawpow --pers=RAVENCOINKAWPOW --ocX" }
    [PSCustomObject]@{ Algorithm = "Veil";         MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=ProgPow --pers=veil --ocX" }
    [PSCustomObject]@{ Algorithm = "Veriblock";    MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=ProgPowZ --pers=zano --ocX" }
    [PSCustomObject]@{ Algorithm = "Zano";         MinMemGB = 3.0; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --par=vProgPow --pers=VeriBlock --ocX" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("par", "pers", "ocX") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Pass = " --pass $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    
                    If ($Config.UseMinerTweaks -eq $true) { 
                        $Arguments += " --oc1"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($Arguments) --url $(If ($Pools.($_.Algorithm).SSL) { "ssl://" } )$($Pools.($_.Algorithm).User)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)$Pass --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 10 --latency --all-shares --extra --tempunits C --show-pers --fee-time=60 --telemetry $($MinerAPIPort) --cuda-devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "MiniZ"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee # Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes     = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
