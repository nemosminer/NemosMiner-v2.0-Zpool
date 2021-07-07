If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-Gminer258\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.58/gminer_2_58_windows64.zip"
$Commands = [PSCustomObject]@{ 
    #"beamv2"           = " --devices $($Config.SelGPUDSTM) -a BeamHashII" #Equihash150 (NiceHash)
    #"beamv3"           = " --devices $($Config.SelGPUDSTM) -a BeamHash" #Equihash150,5,3 (NiceHash)
    #"equihash125"      = " --devices $($Config.SelGPUDSTM) -a 125_4" #Equihash125
    #"equihash144"      = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Equihash144
    "equihash96"       = " --devices $($Config.SelGPUDSTM) -a 96_5 --pers auto" #Equihash144
    #"zhash"            = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Zhash
    #"equihash192"      = " --devices $($Config.SelGPUDSTM) -a 192_7 --pers auto" #Equihash192
    #"equihash-btg"     = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers BgoldPoW " # Equihash-btg MPH
    #"grincuckaroo29"   = " --devices $($Config.SelGPUDSTM) --algo cuckaroo29 --pers auto" #Grincuckaroo29
    "grincuckarood29"  = " --devices $($Config.SelGPUDSTM) --algo cuckarood29 --pers auto" #Grincuckarood29
    "cuckoocycle"      = " --devices $($Config.SelGPUDSTM) --algo aeternity --pers auto" #Aeternity 
    #"grincuckatoo31"   = " --devices $($Config.SelGPUDSTM) --algo grin31 --pers auto" #Grincuckatoo31(8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"ethash"           = " --devices $($Config.SelGPUDSTM) --algo ethash --proto stratum" #Ethash
    "eaglesong"        = " --devices $($Config.SelGPUDSTM) --algo eaglesong" #Eaglesong 
    "handshake"        = " --devices $($Config.SelGPUDSTM) --algo handshake" #Handshake 
    #"cuckaroom"        = " --devices $($Config.SelGPUDSTM) --algo grin29" #Cuckaroom 
    "ethash+eaglesong" = " --devices $($Config.SelGPUDSTM) --algo eth+ckb --proto stratum --dproto stratum --dual_intensity 0" #Ethash + Eaglesong
    "ethash+handshake" = " --devices $($Config.SelGPUDSTM) --algo eth+hns --proto stratum --dproto stratum --dual_intensity 0" #Ethash + Handshake
    #"grincuckatoo32"   = " --devices $($Config.SelGPUDSTM) --algo grin32 --pers auto" #grincuckatoo32 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"kawpow"           = " --devices $($Config.SelGPUDSTM) --algo kawpow --pers auto" #KAWPOW
    "cuckaroo29bfc"    = " --devices $($Config.SelGPUDSTM) --algo bfc" #Cuckaroo29bfc
    "cuckarooz29"      = " --devices $($Config.SelGPUDSTM) --algo cuckarooz29" #Cuckarooz29
}
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    Switch ($_) { 
        "ethash" { $Fee = 0.0065 }
        "cuckaroom" { $Fee = 0.03 }
        "ethash+eaglesong" { $Fee = 0.03 }
        "ethash+handshake" { $Fee = 0.03 }
        default { $Fee = 0.02 }
    }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo2"
        $HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee); $Algo2 = $Stats."$($Name)_$($Algo2)_HashRate".Week * (1 - $Fee) } # substract devfee
        $Algo2Parameter = " --dserver $($Pools.$Algo2.Host) --dport $($Pools.$Algo2.Port) --duser $($Pools.$Algo2.User) --dpass $($Pools.$Algo2.Pass)"
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) } # substract devfee
        $Algo2Parameter = ""
    }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "--watchdog 0 --pec 0 --nvml 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.$Algo.Host) --port $($Pools.$Algo.Port) --user $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)$Algo2Parameter$($Commands.$_)"
        HashRates = $HashRates
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
