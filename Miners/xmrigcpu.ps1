If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\CPU-XMRigv6122\xmrig.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/XMRig/XMRigv6122.7z"
$Commands = [PSCustomObject]@{ 
    "randomxmonero"       = " -o stratum+tcp://randomxmonero.usa-west.nicehash.com:3380 -a rx/0 --nicehash" #RandomX
    "randomwow"           = " -o stratum+tcp://randomwow.mine.zergpool.com:4460 -a rx/wow --nicehash" #Randomwow
    "cryptonight_haven"   = " -o stratum+tcp://cryptonight_haven.mine.zergpool.com:4452 -a cn-heavy/xhv --nicehash" #cryptonight_haven
    "cryptonight_upx"     = " -o stratum+tcp://cryptonight_upx.mine.zergpool.com:4457 -a cn/upx2 --nicehash" #cryptonight_upx
}
$ThreadCount = $Variables.ProcessorCount - 1
$Port = $Variables.CPUMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "-t $($ThreadCount) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --http-port=$($Variables.CPUMinerAPITCPPort) --donate-level 0 --retries=90 --retry-pause=1 --cpu-priority 3"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week } #Recompiled 0% fee
        API       = "XMRig"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
    }
}
