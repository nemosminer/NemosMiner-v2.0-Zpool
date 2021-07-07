using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://phoenixminer.info/downloads/PhoenixMiner_5.6d_Windows.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v2.59 is just as fast, PhoenixMiner-v5.6d is maybe faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1" } # GMiner-v2.59 is just as fast, PhoenixMiner-v5.6d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 20); Arguments = " -amd -eres 1" } # GMiner-v2.59 is just as fast, PhoenixMiner-v5.6d is maybe faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -dcoin blake2s" } # Dual mininig with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg56002212#msg56002212)
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 15); Arguments = " -amd -eres 1 -coin UBQ" }
    # [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 15); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" } # Dual mininig with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg56002212#msg56002212)

    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v2.59 is just as fast, PhoenixMiner-v5.6d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" } # Dual mininig with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg56002212#msg56002212)
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1" } # GMiner-v2.59 is just as fast, PhoenixMiner-v5.6d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 20); Arguments = " -nvidia -eres 1" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 15); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 15); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @($null, 10, 20, 30, 40) # $null is for auto-tuning
    }

    # Build command sets for intensities
    $AlgorithmDefinitions = $AlgorithmDefinitions | ForEach-Object { 
        $_.PsObject.Copy()
        $Arguments = $_.Arguments
        ForEach ($Intensity in ($Intensities.($_.Algorithm[1]) | Select-Object)) { 
            $_ | Add-Member Arguments "$Arguments -sci $Intensity" -Force
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0 ) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                # If ($_.Algorithm[1]) { $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "$AMD Radeon RX 5[0-9]{3}.*$" }) } # Dual mining not supported on Navi

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Pass = $($Pools.($_.Algorithm[0]).Pass)
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    $Arguments += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $Pass"

                    If ($_.Algorithm[0] -in @("EtcHash", "Ethash", "UbqHash")) {
                        If ($Pools.($_.Algorithm[0]).Name -match "^MiningPoolHub(|Coins)$") { 
                            $Arguments += " -proto 1"
                        }
                        If ($Pools.($_.Algorithm[0]).Name -match "^NiceHash$") { 
                            $Arguments += " -proto 4"
                        }
                    }

                    If ($Miner_Devices.Vendor -eq "AMD" -and -not $_.Algorithm[1]) { 
                        If (($_.OpenCL.GlobalMemSize / 1GB) -ge (2 * $MinMemGB)) { 
                            # Faster AMD "turbo" kernels require twice as much VRAM
                            $Arguments += " -clkernel 3"
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $Arguments += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    }

                    If ($Config.UseMinerTweaks -eq $true) { 
                        $Arguments += $_.Tuning
                    }

                    If (-not $_.Intensity) { $WarmupTimes[0] += 45; $WarmupTimes[1] += 45 } # Allow extra seconds for auto-tuning
                    If ($Pools.($_.Algorithm[0]).Name -match "^MiningPoolHub*") { $WarmupTimes[0] += 15; $WarmupTimes[1] += 15 } # Allow extra seconds for MPH because of long connect issue

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:d}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
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
