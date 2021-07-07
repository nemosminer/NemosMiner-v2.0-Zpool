If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-sgminer\sgminer.exe"
$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.7.2-1/sgminer-fancyIX-win64-0.7.2-1.zip"
$Commands = [PSCustomObject]@{ 
    #"neoscrypt-xaya" = " -k neoscrypt-xaya" # -s 1 -w 256 -I 17
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "sgminer"
        Port      = $Variables.AMDMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
