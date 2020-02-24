If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-CryptoDredge022\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.22.0/CryptoDredge_0.22.0_cuda_10.0_windows.zip"
$Commands = [PSCustomObject]@{ 
    "argon2d250"          = " --intensity 8 -a argon2d250" #argon2d250
    "argon2d500"          = " --intensity 6 -a argon2d-dyn" #Argon2d-dyn
    "argon2d4096"         = " --intensity 8 -a argon2d4096" #argon2d4096
    "argon2ddyn"          = " --intensity 6 -a argon2d-dyn" #Argon2d-dyn
    #"allium"      = " --intensity 8 -a allium" #Allium
    "lyra2zz "            = " --intensity 8 -a lyra2zz" #Lyra2zz
    #"neoscrypt"   = " --intensity 6 -a neoscrypt" #Neoscrypt
    #"phi2"        = " --intensity 8 -a phi2" #Phi2 
    #"phi2-lux"    = " --intensity 8 -a phi2" #Phi2-lux   
    "lux"                 = " --intensity 8 -a phi2" #Lux
    "lyra2vc0ban"         = " --intensity 8 -a lyra2vc0ban" #Lyra2vc0banHash
    "skunk"               = " --intensity 8 -a skunk" #Skunk 
    #"hmq1725"     = " --intensity 8 -a hmq1725" #Hmq1725
    "chukwa"              = " --intensity 8 -a chukwa" # chukwa
    "pipe"                = " --intensity 8 -a pipe" #Pipe 
    "cryptonight_gpu"     = " --intensity 8 -a cngpu" # CryptonightGPU
    "cryptonight_xeq"     = " --intensity 8 -a cngpu" # CryptonightGPU (XEQ Zergpool)
    "cryptonight_saber"   = " --intensity 8 -a cnsaber" # CryptonightSaber
    "cryptonight_conceal" = " --intensity 8 -a cnconceal" # Cryptonight_Conceal
    "cryptonight_fast"    = " --intensity 8 -a cnfast2" # cnfast2
    "cryptonight_haven"   = " --intensity 8 -a cnhaven" # cnhaven
    "cryptonight_heavy"   = " --intensity 8 -a cnheavy" # cnhaven
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
        Arguments = "--timeout 60 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
