If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-CryptoDredge0262\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.26.0/CryptoDredge_0.26.0_cuda_11.2_windows.zip"
$Commands = [PSCustomObject]@{ 
    "cryptonight_gpu"     = " -o stratum+tcp://cryptonight_gpu.mine.zergpool.com:4445 --intensity 8 -a cngpu" # CryptonightGPU
    "cryptonight_haven"   = " -o stratum+tcp://cryptonight_haven.mine.zergpool.com:4452 --intensity 8 -a cnhaven" # cnhaven
    "cryptonight_upx"     = " -o stratum+tcp://cryptonight_upx.mine.zergpool.com:4457 --intensity 8 -a cnupx2" # cnhaven
    "argon2ddyn"          = " -o stratum+tcp://argon2d-dyn.mine.zergpool.com:4239 --intensity 6 -a argon2d-dyn" #Argon2d-dyn
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
        Arguments = "--timeout 180 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) } # substract devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}