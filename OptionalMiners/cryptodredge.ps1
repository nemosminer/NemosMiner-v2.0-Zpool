If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-CryptoDredge0262\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.26.0/CryptoDredge_0.26.0_cuda_11.2_windows.zip"
$Commands = [PSCustomObject]@{ 
    "argon2d250"          = " --intensity 8 -a argon2d250" #argon2d250
    "argon2d500"          = " --intensity 6 -a argon2d-dyn" #Argon2d-dyn
    "argon2d4096"         = " --intensity 8 -a argon2d4096" #argon2d4096
    "allium"              = " --intensity 8 -a allium" #Allium
    "lyra2zz "            = " --intensity 8 -a lyra2zz" #Lyra2zz
    "neoscrypt"           = " --intensity 6 -a neoscrypt" #Neoscrypt
    "skunk"               = " --intensity 8 -a skunk" #Skunk 
    "hmq1725"             = " --intensity 8 -a hmq1725" #Hmq1725
    "mtp"                 = " --intensity 8 -a mtp" # mtp
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "phi2" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    switch ($_) { 
        "mtp" { $Fee = 0.02 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--timeout 180 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) } # substract devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}