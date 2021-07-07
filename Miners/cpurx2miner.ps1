If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-RX2miner110\cpuminer.exe"
$Uri = "https://github.com/LUX-Core/rx2-cpuminer/releases/download/1.1.0/cpuminer.exe"
$Commands = [PSCustomObject]@{ 
     "rx2" = "" #Rx2
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    switch ($_) { 
        default { $ThreadCount = $Variables.ProcessorCount - 1 }
    }
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = " -t $($ThreadCount) -a rx2 -R 1 -b $($Variables.CPUMinerAPITCPPort) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
