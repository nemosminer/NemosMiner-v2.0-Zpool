If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
#$Path = ".\Bin\CPU-JayDDe3155\cpuminer-zen.exe" #AMD
$Path = ".\Bin\CPU-JayDDee3165\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.16.5/cpuminer-opt-3.16.5-windows.zip"
$Commands = [PSCustomObject]@{ 
    "lyra2z330" = " -a lyra2z330" #Lyra2z330
    "sha3d"     = " -a sha3d" #sha3d
    "scryptn11" = " -a scrypt:2048" #scryptn11 
    "m7m"       = " -a m7m" #m7m
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    $ThreadCount = $Variables.ProcessorCount - 1
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--hash-meter -q -t $($ThreadCount) --api-bind=$($Variables.CPUMinerAPITCPPort) -o $($Pools.$Algo.Protocol)://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
