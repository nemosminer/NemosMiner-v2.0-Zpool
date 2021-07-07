If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-Phoenix56d\PhoenixMiner.exe"
$Uri = "https://phoenixminer.info/downloads/PhoenixMiner_5.6d_Windows.zip"
$Commands = [PSCustomObject]@{ 
    "ethash"  = "" #Ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-proto 4 -amd -mport -$($Variables.AMDMinerAPITCPPort) -epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .9935 } # substract 0.65% devfee
        API       = "ethminer"
        Port      = $Variables.AMDMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
    }
}
