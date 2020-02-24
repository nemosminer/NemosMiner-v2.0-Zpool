If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-nbminer262\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v26.2/NBMiner_26.2_Win.zip"
$Commands = [PSCustomObject]@{ 
    #"grincuckatoo31"   = "-a cuckatoo -o nicehash+tcp://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"grincuckarood29"  = "-a cuckarood -o nicehash+tcp://" #grincuckaroo29
    #"grincuckaroo29"   = "-a cuckaroo -o nicehash+tcp://" #grincuckaroo29
    #"cuckoocycle"      = "-a cuckoo_ae --cuckoo-intensity 0 -o nicehash+tcp://" #cuckoocycle
    "eaglesong+ethash" = "-a eaglesong_ethash -di 24 -o stratum+tcp://" #eaglesong + ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    switch ($_) { 
        "ethash" { $Fee = 0.0065 }
        "eaglesong_ethash" { $Fee = 0.03}
        default { $Fee = 0.02 }
    }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo"
        $HashRates = [PSCustomObject]@{ $Algo2 = $Stats."$($Name)_$($Algo2)_HashRate".Day * (1 - $Fee); $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) }
        $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User)"
        If ($Pools.$Algo2.SSL) { $Algo2Parameter = $Algo2Parameter -replace '\+tcp\://$', '+ssl://' }
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $HashRates = [PSCustomObject]@{ $Algo = ($Stats."$($Name)_$($Algo)_HashRate".Day) * (1 - $Fee) }
        $Algo2Parameter = ""
    }

    If ($Pools.$Algo.SSL) { $_ = $_ -replace '\+tcp\://$', '+ssl://' }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.$Algo.Host):$($Pools.$Algo.Port) -no-nvml --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.$Algo.User):$($Pools.$Algo.Pass)$Algo2Parameter"
        HashRates = $HashRates
        API       = "nbminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
