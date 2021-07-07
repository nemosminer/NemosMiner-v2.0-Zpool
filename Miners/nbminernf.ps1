If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-nbminer376\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v37.6/NBMiner_37.6_Win.zip"
$Commands = [PSCustomObject]@{ 
    #"grincuckatoo31"   = "-a cuckatoo -o nicehash+tcp://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"grincuckatoo32"   = "-a cuckatoo32 -o nicehash+tcp://" #grincuckatoo32 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"grincuckarood29"  = "-a cuckarood --fee 1 -o nicehash+tcp://" #grincuckaroo29
    #"grincuckaroo29"   = "-a cuckaroo --fee 1 -o nicehash+tcp://" #grincuckaroo29
    #"cuckoocycle"      = "-a cuckoo_ae --fee 1 --cuckoo-intensity 0 -o nicehash+tcp://" #cuckoocycle
    #"kawpow"           = "-a kawpow -o stratum+tcp://" #kawpow
    #"etchash"          = "-a etchash -o nicehash+tcp://" #etchash
    "octopus"          = "-a octopus -o stratum+tcp://" #octopus
    "autolykos"        = "-a ergo -o stratum+tcp://" #autolykos
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    switch ($_) { 
        "ethash" { $Fee = 0.00 }
        "eaglesong_ethash" { $Fee = 0.00 }
        "autolykos" { $Fee = 0.00 }
        default { $Fee = 0.00 }
    }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo"
        $HashRates = [PSCustomObject]@{ $Algo2 = $Stats."$($Name)_$($Algo2)_HashRate".Week * (1 - $Fee); $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) }
        If ($Pools.$($Algo2).Name -eq "MPH") { 
            $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User):$($Pools.$Algo2.Pass)"
        }
        Else { 
            $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User):$($Pools.$Algo2.Pass)"
        }
        If ($Pools.$Algo2.SSL) { $Algo2Parameter = $Algo2Parameter -replace '\+tcp\://$', '+ssl://' }
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $HashRates = [PSCustomObject]@{ $Algo = ($Stats."$($Name)_$($Algo)_HashRate".Week) * (1 - $Fee) }
        $Algo2Parameter = ""
    }

    If ($Pools.$Algo.SSL) { $_ = $_ -replace '\+tcp\://$', '+ssl://' }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.$Algo.Host):$($Pools.$Algo.Port) --fee 0 --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.$Algo.User):$($Pools.$Algo.Pass)$Algo2Parameter"
        HashRates = $HashRates
        API       = "nbminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
