If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-neoscryptxaya02\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer/releases/download/v0.2/neoscryptxayaV02.7z"
$Commands = [PSCustomObject]@{ 
    "neoscrypt-xaya" = " -a neoscrypt-xaya"
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    If ($Algo) { 
        If ($Pools.$($Algo).Name -eq "zergpoolcoins") { 
            $AlgoParameter = "stratum+tcp://neoscrypt-xaya.mine.zergpool.com:4238"
        }
        Else { 
            $AlgoParameter = "stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        }
        [PSCustomObject]@{ 
            Type      = "NVIDIA"
            Path      = $Path
            Arguments = "--cpu-priority 4 -T 50000 -R 1 -i 21 -b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o $AlgoParameter -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
            HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
            API       = "ccminer"
            Port      = $Variables.NVIDIAMinerAPITCPPort #4068
            Wrap      = $false
            URI       = $Uri
        }
    }
}
