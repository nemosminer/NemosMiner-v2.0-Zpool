using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.5/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.5.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.006);        MinMemGB = 5; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -platform 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");      Fee = @(0.006);        MinMemGB = 3; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 20); Arguments = " -platform 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin blake2s -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake2s"); Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin blake2s -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin dcr -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin keccak -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin lbc -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin pasc -platform 1" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "AMD"; MinerSet = 0; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin sc -platform 1" }

    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.006);        MinMemGB = 5; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -platform 2" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");      Fee = @(0.006);        MinMemGB = 3; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 20); Arguments = " -platform 2" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin blake2s -platform 2" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 0; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin dcr -platform 2" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 0; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin keccak -platform 2" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 0; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin lbc -platform 2" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 0; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin pasc -platform 2" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.006, 0.006); MinMemGB = 5; Type = "NVIDIA"; MinerSet = 0; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -dcoin sc -platform 2" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @(10, 30, 50, 70)
        "Decred"  = @(10, 20, 30, 40)
        "Keccak"  = @(1, 3, 6, 9)
        "Lbry"    = @(10, 20, 30, 40)
        "Pascal"  = @(20, 40, 60)
        "Sia"     = @(20, 40, 60, 80)
    }

    # Build command sets for intensities
    $AlgorithmDefinitions = $AlgorithmDefinitions | ForEach-Object { 
        $_.PsObject.Copy()
        $Arguments = $_.Arguments
        ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
            $_ | Add-Member Arguments "$Arguments -dcri $Intensity" -Force
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $WarmupTimes = $_.WarmupTimes
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm[0]).DAGSize -gt 0) { 
                    $MinMemGB = ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB
                }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                If ($_.Algorithm[1]) { 
                    $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "^AMD Radeon RX 5[0-9]{3}.*" }) # Dual mining not supported on Navi
                    $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "^GTX1660.*GB$" }) # Dual mining not supported on GTX1660 cards
                }

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm[0]).SSL) {
                        $Arguments += " -checkcert 0"
                        If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                            $Arguments += " -esm 3"
                            $Protocol = "stratum+ssl://"
                        }
                        Else { 
                            $Protocol = "ssl://"
                        }
                    }
                    Else { 
                        If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                            $Arguments += " -esm 3"
                            $Protocol = "stratum+tcp://"
                        }
                        Else { 
                            $Protocol = ""
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $Arguments += " -dpool $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpsw $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    }

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $Arguments += " -nofee 1"
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).Count
                    }

                    $Pass = $($Pools.($_.Algorithm[0]).Pass)
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    If (-not $_.Intensity) { $WarmupTimes[0] += 15; $WarmupTimes[1] += 15 } # Allow extra seconds for auto-tuning

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("-epool $Protocol$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -ewal $($Pools.($_.Algorithm[0]).User) -epsw $Pass$Arguments -dbg -1 -wd 0 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
