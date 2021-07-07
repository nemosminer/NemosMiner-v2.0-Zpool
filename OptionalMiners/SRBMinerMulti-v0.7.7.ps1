using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.7.7/SRBMiner-Multi-0-7-7-win64.zip"
$SelectedDevices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

# Algorithm parameter values are case sensitive!
$AlgorithmDefinitions = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algorithm argon2d_dynamic --gpu-intensity 31 --gpu-boost 50" } # Does not start mining
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm argon2id_chukwa --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";     Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm argon2id_ninja --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "AMD"; Fee = 0.02;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algorithm autolykos2 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm blake2b --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algorithm blake2s --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";  Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_cache --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_ccx --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble"; Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_heavyx --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_gpu --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_upx --gpu-intensity 31 --gpu-boost 50" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_turtle --gpu-intensity 31 --gpu-boost 50" } # TeamRed-v0.8.3 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm cryptonight_xhv --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";         Type = "AMD"; Fee = 0.0085; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm eaglesong --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "AMD"; Fee = 0.0065; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algorithm etchash --gpu-intensity 31 --gpu-boost 50" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Type = "AMD"; Fee = 0.0065; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algorithm ethash --gpu-intensity 31 --gpu-boost 50" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "AMD"; Fee = 0.0065; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 20); Arguments = " --algorithm ethash --gpu-intensity 31 --gpu-boost 50" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Handshake";         Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm bl2bsha3 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "AMD"; Fee = 0.01;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm heavyhash --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm k12 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Kadena";            Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm kadena --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm keccak --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Type = "AMD"; Fee = 0.02;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm lyra2v2_webchain --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Phi5";              Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm phi5 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "UbqHash";           Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algorithm ubqhash --gpu-intensity 31 --gpu-boost 50" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "VerusHash";         Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm verushash --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Type = "AMD"; Fee = 0.0125; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algorithm yescrypt --gpu-intensity 31 --gpu-boost 50" }

    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm argon2d_dynamic" } # Does not start mining
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CpuPower";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CryptonightCache";  Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_cache" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble"; Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_heavyx" }
    # [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_gpu" } # No Hashrate in time
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_turtle" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "CurveHash";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm curvehash" }
    [PSCustomObject]@{ Algorithm = "Eaglesong";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm eaglesong" }
    # [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algorithm etchash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "Ethash";            Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algorithm ethash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algorithm ethash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "GhostRider";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm ghostrider" }
    [PSCustomObject]@{ Algorithm = "Handshake";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm bl2bsha3" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kadena";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm kadena" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "Minotaur";          Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm minotaur" }
    [PSCustomObject]@{ Algorithm = "Panthera";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm panthera" }
    [PSCustomObject]@{ Algorithm = "Phi5";              Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm phi5" }
    [PSCustomObject]@{ Algorithm = "Randomx";           Type = "CPU"; Fee = 0.0085; MinerSet = 1; WarmupTimes = @(0, 45);  Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxL";          Type = "CPU"; Fee = 0.0085; MinerSet = 1; WarmupTimes = @(0, 45);  Arguments = " --algorithm randomxl --randomx-use-1gb-pages" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxArq";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxEpic";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm randomxepic" }
    [PSCustomObject]@{ Algorithm = "RandomxHash2";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 30);  Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxYada";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 30);  Arguments = " --algorithm randomyada" }
    [PSCustomObject]@{ Algorithm = "Rx2";               Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 120); Arguments = " --algorithm rx2" } # No Hashrate in time
    [PSCustomObject]@{ Algorithm = "ScryptN2";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm scryptn2" }
    # [PSCustomObject]@{ Algorithm = "UbqHash";           Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(0, 45);  Arguments = " --algorithm ubqhash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "VerusHash";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "Yespower";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerarwn" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";        Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespoweric" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";      Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespoweriots" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";       Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = "YespowerMgpc";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowermgpc" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerRes";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = "YespowerTide";      Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowertide" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";       Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(0, 15);  Arguments = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithm = "Zentoshi";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(0, 15);  Arguments = " --algorithm balloon_zentoshi" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB

                If ($_.Algorithm -eq "VertHash") { 
                    If (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf )) { 
                        If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                        $_.WarmupTime[1] += 45 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                    }
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })) {

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get commands for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algorithm") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If (($Miner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                        $DeviceArguments = " --cpu-threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                    }
                    Else { 
                        $DeviceArguments = " --gpu-id $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',') --disable-cpu"
                    }

                    $Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"

                    If ($Pools.($_.Algorithm).SSL) { $Arguments += " --ssl true" }
                    If ($_.Algorithm -in @("EtcHash", "Ethash", "UbqHash") -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { $Arguments += " --nicehash true" }
                    If ($_.Algorithm -in @("EtcHash", "Ethash", "UbqHash") -and $Pools.($_.Algorithm).Name -match "^ProHashing.+") { $Arguments += " --esm 1" }

                    $Pass = " --password $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments --wallet $($Pools.($_.Algorithm).User)$Pass --worker $($Config.Workername) --disable-workers-ramp-up --api-enable --api-port $($MinerAPIPort)$DeviceArguments" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "SRBMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)/stats"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
