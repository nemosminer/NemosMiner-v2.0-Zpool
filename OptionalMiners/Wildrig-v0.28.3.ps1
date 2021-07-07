using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.28.3/wildrig-multi-windows-0.28.3.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo blake2b-glt" }
    [PSCustomObject]@{ Algorithm = "Bmw512";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo bmw512" } # CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "Dedal";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo dedal" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo exosis" } 
    [PSCustomObject]@{ Algorithm = "Geek";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo hmq1725" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Honeycomb";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo honeycomb" } # Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";      Type = "AMD"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo kawpow" } # TeamRed-v0.8.3 is fastest on Navi
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo lyra2v3" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";    Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo lyra2tdc" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Type = "AMD"; Fee = @(0.02); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Type = "AMD"; Fee = @(0.01); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Type = "AMD"; Fee = @(0.05); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MTP";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo mtp" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Type = "AMD"; Fee = @(0.01); MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Phi5";        Type = "AMD"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo phi5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Type = "AMD"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "Skein2";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x11k" }
    [PSCustomObject]@{ Algorithm = "X16r";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x16r" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x16rt" }
# [PSCustomObject]@{ Algorithm = "X16rv2";      Type = "AMD"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x16rv2" } # Error
    [PSCustomObject]@{ Algorithm = "X16s";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Type = "AMD"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x17r --protocol ufo2" }
    [PSCustomObject]@{ Algorithm = "X21s";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x21s" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "X22i";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x22i" }
    [PSCustomObject]@{ Algorithm = "X33";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "WildKeccak";  Type = "AMD"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo wildkeccak" }

    [PSCustomObject]@{ Algorithm = "AstralHash";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo blake2b-glt" }
    [PSCustomObject]@{ Algorithm = "Bmw512";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo bmw512" } # CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "Dedal";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo dedal" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo exosis" }
    [PSCustomObject]@{ Algorithm = "Geek";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo hmq1725" } # CryptoDredge-v0.26.0 is fastest
#    [PSCustomObject]@{ Algorithm = "Honeycomb";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo honeycomb" } # Algo broken, last working version is 0.17.6
    [PSCustomObject]@{ Algorithm = "JeongHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-jeonghash" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo kawpow" } # NBMiner-v38.1 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo lyra2v3" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";    Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo lyra2tdc" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Type = "NVIDIA"; Fee = @(0.05); MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MTP";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo mtp" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo glt-pawelhash" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Phi5";        Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo phi5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "Skein2";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo skein2" } # CcminerAlexis78-v1.5.2 is fastest
    [PSCustomObject]@{ Algorithm = "SkunkHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo skunkhash" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Sonoa";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo sonoa" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "Timetravel";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x11k" }
    [PSCustomObject]@{ Algorithm = "X16r";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x16r" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x16rt" }
#    [PSCustomObject]@{ Algorithm = "X16rv2";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x16rv2" } # Error
    [PSCustomObject]@{ Algorithm = "X16s";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x16s" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "X17";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x17r --protocol ufo2" }
    [PSCustomObject]@{ Algorithm = "X21s";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x21s" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "X22i";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 15); Arguments = " --algo x22i" } # Trex-v0.21.0 is fastest
    [PSCustomObject]@{ Algorithm = "X33";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "WildKeccak";  Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo wildkeccak" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model | Where-Object { $_.Type -ne "AMD" -or $_.OpenCL.ClVersion -ge "OpenCL C 1.2" })) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($_.Arguments) --api-port=$($MinerAPIPort) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --multiple-instance --opencl-threads auto --opencl-launch auto --opencl-platforms=$($Miner_Devices.PlatformId | Sort-Object -Unique) --opencl-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee # subtract devfee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
