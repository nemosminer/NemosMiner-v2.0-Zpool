using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.20.0/t-rex-0.20.0-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";    Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " --algo etchash --intensity 25" } # GMiner-v2.51 is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";     Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " --algo ethash --intensity 25" } # GMiner-v2.51 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";     Fee = 0.01; MinMemGB = 3; MinerSet = 0; Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.10.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "MTP";        Fee = 0.01; MinMemGB = 3; MinerSet = 0; Arguments = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithm = "MTPTcr";     Fee = 0.01; MinMemGB = 3; MinerSet = 0; Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithm = "Multi";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Octopus";    Fee = 0.02; MinMemGB = 5; MinerSet = 0; Arguments = " --algo octopus --intensity 25" }
    [PSCustomObject]@{ Algorithm = "ProgPoW";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpow" }
    [PSCustomObject]@{ Algorithm = "Tensority";  Fee = 0.03; MinMemGB = 2; MinerSet = 0; Arguments = " --algo tensority --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Veil";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithm = "VeriBlock";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = "Zano";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpowz --intensity 25" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                    $WarmupTime = 45 # Seconds, max. wait time until first data sample
                }
                ElseIf ($_.Algorithm -eq "Lyra2Z") { $WarmupTime = 60 } # Seconds, max. wait time until first data sample
                ElseIf ($_.Algorithm -match "^Octopus$|^Sonoa$") { $WarmupTime = 30 } # Seconds, max. wait time until first data sample
                ElseIf ($_.Algorithm -match "^MegaBtx$|^MTP$") { $WarmupTime = 15 } # Seconds, max. wait time until first data sample
                Else { $WarmupTime = 0 } # Seconds, max. wait time until first data sample

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    If ($Miner_Devices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -le 2 }) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                        $Stratum = "stratum2"
                    }
                    Else {
                        $Stratum = "stratum"
                    }
                    If ($Pools.($_.Algorithm).SSL -eq $true) { $Stratum += "+ssl://" } Else { $Stratum += "+tcp://" }

                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("SERO", "ZANO")) { 
                            $Coin = " --coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                    # From now on the username (-u) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                    If ($_.Algorithm -in @("Ethash", "KawPow", "ProgPoW") -and ($Pools.($_.Algorithm).User -split "\.").Count -eq 2) { 
                        $User = " --user $($Pools.($_.Algorithm).User) --worker $($Pools.($_.Algorithm).User -split "\." | Select-Object -Index 1)"
                    }
                    Else { 
                        $User = " --user $($Pools.($_.Algorithm).User)"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Arguments) --url $Stratum$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)$User --pass $($Pools.($_.Algorithm).Pass) --no-strict-ssl$(If ($Config.UseMinerTweaks -eq $true) { " --mt 3" }) $Coin --no-watchdog --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --api-read-only --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "Trex"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee # Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                        PowerUsageInAPI = $true
                        WarmupTime      = $WarmupTime # Seconds, additional wait time until first data sample
                    }
                }
            }
        }
    }
}
