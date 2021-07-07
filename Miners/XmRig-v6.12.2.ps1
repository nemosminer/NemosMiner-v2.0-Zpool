using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/XMRig/XMRigv6122.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "AMD"; MinMemGB = 0.02; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/ccx" } # SRBMinerMulti-v0.7.7 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "AMD"; MinMemGB = 4;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(0, 45); Arguments = " --algo kawpow" } # NBMiner-v38.1 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(0, 30); Arguments = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo argon2/wrkz" }
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "CPU"; MinerSet = 1; WarmupTimes = @(0, 30); Arguments = " --algo cn/double" } # XmrStak-v2.10.8 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/upx2" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/zls" }
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/arq" } # SRBMinerMulti-v0.7.7 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/sfx" } # SRBMinerMulti-v0.7.7 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "NVIDIA"; MinMemGB = 0.02; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/ccx" } # CryptoDredge-v0.26.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/half" } # CryptoDredge-v0.26.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "NVIDIA"; MinMemGB = 4;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "NVIDIA"; MinMemGB = 3;    MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo kawpow" } # Trex-v0.21.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo rx/wow" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    If ($_.Type -eq "AMD") { $Arguments += " --no-cpu --opencl --opencl-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }
                    If ($_.Type -eq "CPU") { $Arguments += " --threads=$($Miner_Devices.CIM.NumberOfLogicalProcessors -1)" }
                    If ($_.Type -eq "NVIDIA") { $Arguments += " --no-cpu --cuda --cuda-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments $(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash" } )$(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --donate-level 0 --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "XmRig"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                        MinerUri    = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                    }
                }
            }
        }
    }
}
