using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.16.5/cpuminer-opt-3.16.5-windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Hmq1725";   MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo hmq1725" }
    [PSCustomObject]@{ Algorithm = "Lyra2z330"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo lyra2z330" }
    [PSCustomObject]@{ Algorithm = "m7m";       MinerSet = 2; WarmupTimes = @(0, 0); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "Sha3d";     MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo sha3d" }
    [PSCustomObject]@{ Algorithm = "ScryptN11"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo scrypt(N,1,1)" }
    [PSCustomObject]@{ Algorithm = "VertHash";  MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --algo verthash" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 
    
        If ($Miner_Devices.CpuFeatures -match "sha")        { $Path = ".\Bin\$($Name)\cpuminer-Avx512-sha.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "avx512") { $Path = ".\Bin\$($Name)\cpuminer-Avx512.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "avx2")   { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "avx")    { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "aes")    { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "sse2")   { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
        Else { Return }

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $AlgorithmDefinitions | ForEach-Object {

                If ($_.Algorithm -eq "VertHash") { 
                    If (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf) { 
                        $_.Arguments += " --data-file ..\..\Cache\VertHash.dat"
                    }
                    ElseIf (Test-Path -Path ".\VertHash.dat" -PathType Leaf) { 
                        New-Item -Path . -Name "Cache" -ItemType Directory -ErrorAction Ignore | Out-Null
                        Move-Item -Path ".\VertHash.dat" -Destination ".\Cache" -ErrorAction Ignore
                        $_.Arguments += " --data-file ..\..\Cache\VertHash.dat"
                    }
                    Else { 
                        $_.Arguments += " --verify"
                        $_.WarmupTime[1] += 420 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat}
                    }
                }

                # Get arguments for active miner devices
                # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+ssl" } Else { $Protocol = "stratum+tcp" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $Miner_Devices.Name
                    Type        = "CPU"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --hash-meter --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm   = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                }
            }
        }
    }
}
