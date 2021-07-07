If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-miniZ18y2\miniZ.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/MiniZ/MiniZ_v1.8y2_win-x64.zip"
$Commands = [PSCustomObject]@{ 
    "equihash144"  = " --par=144,5 --pers auto --ocX" #Equihash144
    "equihash125"  = " --par=125,4 --pers auto --ocX" #Equihash125
    "zhash"        = " --par=144,5 --pers auto --ocX" #Zhash
    "beamv2"       = " --par=beam --pers auto --ocX" #Beamv2
    "beamv3"       = " --par=144,5s --pers auto --ocX" #Beamv3
    "beam"         = " --par=150,5 --pers auto --ocX" #Beam
    "equihash192"  = " --par=192,7 --pers auto --ocX" #Equihash192
    #"equihash96"   = " --par=96,5 --pers auto" #equihash96
    "equihash-btg" = " --par=144,5 --pers BgoldPoW --ocX" # Equihash-btg MPH
    "equihash-zcl" = " --par=192,7 --pers ZcashPoW --ocX" # Equihash-ZCL MPH
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cleanjobs --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 60 --latency --nocolor --extra --tempunits C -cd $($Config.SelGPUDSTM) --telemetry $($Variables.NVIDIAMinerAPITCPPort) --url $($Pools.$Algo.User)@$($Pools.$Algo.Host):$($Pools.$Algo.Port) --pass $($Pools.$Algo.Pass)$($Commands.$_)" #--oc1 --oc2 --f11=0
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .98 } # substract 2% devfee
        API       = "miniZ"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
