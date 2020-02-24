If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-trex0146\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.14.6/t-rex-0.14.6-win-cuda10.0.zip"
$Commands = [PSCustomObject]@{ 
    "balloon"    = " -a balloon -i 23" #Balloon
    "astralhash" = " -a astralhash -i 23" #Astralhash
    #"dedal"      = " -a dedal -i 23" #Dedal
    "jeonghash"  = " -a jeonghash -i 23" #Jeonghash
    "padihash"   = " -a padihash -i 23" #Padihash
    "pawelhash"  = " -a pawelhash -i 23" #Pawelhash
    "polytimos"  = " -a polytimos -i 25" #Poly 
    "bcd"        = " -a bcd -i 24" #Bcd 
    "bitcore"    = " -a bitcore -i 25" #Bitcore
    "geek"       = " -a geek -i 23" #Geekcash
    "c11"        = " -a c11 -i 24" #C11 
    "x17"        = " -a x17 -i 24" #X17 
    "x16s"       = " -a x16s -i 24" #X16s 
    "x16r"       = " -a x16r -i 24" #X16r 
    "x16rv2"     = " -a x16rv2 -i 24" #X16rv2 ,mc=RVN
    "x16rt"      = " -a x16rt -i 24" #X16rt
    "sonoa"      = " -a sonoa -i 23" #Sonoa
    "sha256t"    = " -a sha256t -i 26" #Sha256t
    "sha256q"    = " -a sha256q -i 23" #Sha256q 
    "x21s"       = " -a x21s -i 23 " #X21s 
    "x22i"       = " -a x22i -i 23" #X22i 
    "timetravel" = " -a timetravel -i 25" #Timetravel
    "tribus"     = " -a tribus -i 23" #Tribus
    "veil"       = " -a x16rt -i 24" #Veil
    "mtp"        = " -a mtp -i 21" #MTP 
    "x25x"       = " -a x25x -i 21" #x25x
    "honeycomb"  = " -a honeycomb -i 26" #Honeycomb
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--no-watchdog --no-nvml --gpu-report-interval 25 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --quiet -R 1 -T 50000 --cpu-priority 4"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
