using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/KlausT/ccminer/releases/download/8.25/ccminer-825-cuda100-x64.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGB = 2; MinerSet = 2; Arguments = " --algo c11 --intensity 22" } # CcminerAlexis78-v1.5.2 is faster
    [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGB = 2; MinerSet = 0; Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGB = 2; MinerSet = 0; Arguments = " --algo lyra2v2" }
    [PSCustomObject]@{ Algorithm = "NeoScrypt"; MinMemGB = 2; MinerSet = 2; Arguments = " --algo neoscrypt --intensity 15.5" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Skein";     MinMemGB = 2; MinerSet = 2; Arguments = " --algo skein" } # CcminerAlexis78-v1.5.2 is fastest
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGB = 2; MinerSet = 0; Arguments = " --algo veltor --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Whirlcoin"; MinMemGB = 2; MinerSet = 0; Arguments = " --algo whirlcoin" }
    [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGB = 2; MinerSet = 0; Arguments = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGB = 2; MinerSet = 0; Arguments = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGB = 2; MinerSet = 2; Arguments = " --algo x17 --intensity 22" } # CcminerAlexis78-v1-5-2 is faster
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($SelectedDevices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($SelectedDevices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -le 2GB }) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "Ccminer"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                    }
                }
            }
        }
    }
}
