using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nsfminer.exe"
$Uri = "https://github.com/no-fee-ethereum-mining/nsfminer/releases/download/v1.3.14/nsfminer_1.3.14-windows_10-cuda_11.3-opencl.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 4.0; Type = "AMD";    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --opencl --devices" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3.0; Type = "AMD";    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --opencl --devices" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGB = 5.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --cuda --devices" } # PhoenixMiner-v5.6d is fastest but has dev fee
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGB = 3.0; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --cuda --devices" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
)

$Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object { 
            $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
            $MinMemGB = $_.MinMemGB
            If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
            }

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                # Get arguments for active miner devices
                # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @() -DeviceIDs $Miner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$|^ZergPool(|Coins)") { $Protocol = "-P stratum2+tcp" }
                ElseIf ($Pools.($_.Algorithm).Name -like "HiveON*") { $Protocol = "-P stratum1+tcp" }
                Else { $Protocol = "-P stratum+tcp" }

                If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace "tcp", "ssl" }

                If ($Pools.($_.Algorithm).Name -match "^MiningPoolHub(|Coins)$") { $WarmupTimes[1] += 30 }

                If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Arguments += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                $Pass = $($Pools.($_.Algorithm).Pass)
                If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $Miner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm).User)):$Pass@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --api-port -$MinerAPIPort $($_.Arguments) $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                }
            }
        }
    }
}

