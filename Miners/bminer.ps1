If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-Bminer1605\bminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/16.0.5/bminer-v16.0.5-21104ec.zip"
$Commands = [PSCustomObject]@{ 
    #"equihashBTG"      = "-uri zhash://" #EquihashBTG
    #"equihash144"      = "-pers auto -uri equihash1445://" #Equihash144
    #"zhash"            = "-pers auto -uri equihash1445://" #Zhash
    "ethash"           = "-uri ethstratum://" #Ethash
    #"cuckoocycle"      = "-uri aeternity://" #aeternity
    #"beamv2"           = "-uri beamhash2://" #beam
    #"grincuckarood29"  = "-uri cuckaroo29d://" #grincuckaroo29 
    #"grincuckatoo31"   = "-uri cuckatoo31://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram) 
    "cuckaroom"        = "-uri cuckaroo29m://" #cuckaroo29m
    "ethash+blake14r"  = "-uri ethstratum://" #Ethash & Blake14r dual mining
    "ethash+blake2s"   = "-uri ethstratum://" #Ethash & Blake2s dual mining
    "ethash+tensority" = "-uri ethstratum://" #Ethash & Bytom dual mining
    "ethash+vbk"       = "-uri ethstratum://" #Ethash & VBK & Bytom dual mining
    "tensority"        = "-uri ethstratum://" #Tensority

}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 

    If ($Pools.$Algo.SSL) { $_ = $_ -replace '\://$', '+ssl://' }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo2"
        $HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day; $Algo2 = $Stats."$($Name)_$($Algo2)_HashRate".Day }
        $Algo2Parameter = " -uri2 $($_ -split '\+' | Select-Object -Index 1)$(If ($Pools.$Algo2.SSL) { '+ssl' })://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.Pass))@$($Pools.$Algo2.Host):$($Pools.$Algo2.Port)"
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        $Algo2Parameter = ""
    }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.Pass))@$($Pools.$Algo.Host):$($Pools.$Algo.Port) -max-temperature 94 -nofee -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port$Algo2Parameter"
        HashRates = $HashRates
        API       = "bminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri
    }
}
