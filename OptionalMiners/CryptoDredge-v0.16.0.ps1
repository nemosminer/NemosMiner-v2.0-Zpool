using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.16.0/CryptoDredge_0.16.0_cuda_10.0_windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Allium";    Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo=allium --intensity 8" } # CryptoDredge v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo=exosis --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo=dedal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";   Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo=hmq1725 --intensity 8" } # CryptoDredge v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "NeoScrypt"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --algo=neoscrypt --intensity 6 " } # Cryptodredge v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo=phi --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo=phi2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Pipe";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo=pipe --intensity 8" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {
                If ($_.Algorithm -eq "Phi2" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { return }
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo", "intensity") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = "NVIDIA"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url=stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --no-watchdog --no-crashreport --timeout 180 --cpu-priority 4 --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Ccminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
