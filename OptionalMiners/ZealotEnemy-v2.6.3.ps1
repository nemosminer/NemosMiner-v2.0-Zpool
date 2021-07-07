using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\z-enemy.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/Z-Enemy/z-enemy-2.6.3-win-cuda11.1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Aergo";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo aergo --intensity 23" }
    [PSCustomObject]@{ Algorithm = "BCD";        MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Bitcore";    MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo bitcore --intensity 22" }
    [PSCustomObject]@{ Algorithm = "C11";        MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "Hex";        MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo hex --intensity 24" }
    [PSCustomObject]@{ Algorithm = "KawPoW";     MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo kawpow --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Phi";        MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Phi2";       MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo phi2" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo poly" }
#    [PSCustomObject]@{ Algorithm = "SkunkHash";  MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo skunk" } # No hashrate in time
#    [PSCustomObject]@{ Algorithm = "Sonoa";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo sonoa" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Timetravel"; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo timetravel" }
#    [PSCustomObject]@{ Algorithm = "Tribus";     MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo tribus" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "X16r";       MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x16r" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "X16rv2";     MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";       MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo x16s" }
#    [PSCustomObject]@{ Algorithm = "X17";        MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo x17" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Xevan";      MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo xevan --intensity 22" }
    )

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --api-bind 0 --api-bind-http $MinerAPIPort --statsavg 5 --retry-pause 1 --quiet --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Trex"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = 0.01 # dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = @($_.WarmupTimes) # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
