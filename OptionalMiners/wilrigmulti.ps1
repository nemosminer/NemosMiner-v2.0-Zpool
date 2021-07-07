if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\AMD-WildRigMulti0283\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.28.3/wildrig-multi-windows-0.28.3.7z"

$Commands = [PSCustomObject]@{
    "mtp"           = " --algo mtp" #Mtp
    "megabtx"       = " --algo megabtx" #KawPow
    "megamec"       = " --algo megamec" #KawPow
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type = "AMD"
        Path = $Path
        Arguments = "--api-port=$($Variables.AMDMinerAPITCPPort) --url=$($Pools.$Algo.Host):$($Pools.$Algo.Port) --opencl-platforms amd --opencl-threads auto --opencl-launch auto --user=$($Pools.$Algo.User) --pass=$($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API = "Xmrig"
        Port = $Variables.AMDMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.$Algo.User
        Host = $Pools.$Algo.Host
        Coin = $Pools.$Algo.Coin
    }
}
