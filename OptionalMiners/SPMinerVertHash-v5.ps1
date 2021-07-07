using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\SPMiner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/SPMinerVertHash/SPMinerVertHash_v5.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "AMD";    MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --verthash-data ..\..\Cache\VertHash.dat --cl-devices" }
    [PSCustomObject]@{ Algorithm = "VertHash"; MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --verthash-data ..\..\Cache\VertHash.dat --cu-devices" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = 0 # Miner has no API Port

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                $MinMemGB = $_.MinMemGB

                If ($_.Algorithm -eq "VertHash" -and (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf ))) { 
                    If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                    $WarmupTimes[1] += 420 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat}
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } )) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "NoAPI"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = 0.01
                        WarmupTimes = $WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
