If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
#$Path = ".\Bin\CPU-JayDDee3122\cpuminer-zen.exe" #AMD
$Path = ".\Bin\CPU-JayDDee3122\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.12.2/cpuminer-opt-3.12.2-windows.zip"
$Commands = [PSCustomObject]@{ 
    "lyra2z330" = " -a lyra2z330" #Lyra2z330
    "sha3d"     = " -a sha3d" #sha3d
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    $ThreadCount = $Variables.ProcessorCount - 1
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--hash-meter -q -t $($ThreadCount) --api-bind=$($Variables.CPUMinerAPITCPPort) -o $($Pools.$Algo.Protocol)://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
