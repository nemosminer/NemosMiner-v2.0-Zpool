using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nheqminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/0.8.2/nheqminer082.7z"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "VerusHash"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " -v" } # Does not work
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) {

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $AlgorithmDefinitions | ForEach-Object {

            # Get arguments for active miner devices
            # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name        = $Miner_Name
                DeviceName  = $Miner_Devices.Name
                Type        = "CPU"
                Path        = $Path
                Arguments   = ("$($_.Arguments) -l $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -u $($Pools.($_.Algorithm).User) -p $($Pools.($_.Algorithm).Pass) -t $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) -a $MinerAPIPort" -replace "\s+", " ").trim()
                Algorithm   = $_.Algorithm
                API         = "Nheq"
                Port        = $MinerAPIPort
                URI         = $Uri
                WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
            }
        }
    }
}
