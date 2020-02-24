If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-CryptoDredge0160\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.16.0/CryptoDredge_0.16.0_cuda_10.0_windows.zip"
$Commands = [PSCustomObject]@{ 
    "exosis"    = " --intensity 8 -a exosis" #Exosis  
    "phi"       = " --intensity 8 -a phi" #Phi
    "dedal"     = " --intensity 8 -a dedal" #Dedal
    "allium"    = " --intensity 8 -a allium" #Allium  
    "neoscrypt" = " --intensity 6 -a neoscrypt" #Neoscrypt
    "phi2"      = " --intensity 8 -a phi2" #Phi2 
    "phi2-lux"  = " --intensity 8 -a phi2" #Phi2-lux   
    "hmq1725"   = " --intensity 8 -a hmq1725" #Hmq1725
    "pipe"      = " --intensity 8 -a pipe" #Pipe 
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--timeout 60 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
