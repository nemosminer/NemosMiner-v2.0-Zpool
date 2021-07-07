If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-Claymore1525\EthDcrMiner64.exe"
$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.5/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.5.zip"
$Commands = [PSCustomObject]@{ 
     "ethash" = "" #Ethash -strap 1 -strap 2 -strap 3 -strap 4 -strap 5 -strap 6
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-wd 0 -esm 3 -allpools 1 -allcoins 1 -platform 1 -mode 1 -mport -$($Variables.AMDMinerAPITCPPort) -epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .99 } # substract 1% devfee
        API       = "ethminer"
        Port      = $Variables.AMDMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
    }
}
