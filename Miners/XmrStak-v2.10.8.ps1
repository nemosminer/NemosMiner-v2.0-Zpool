using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmr-stak.exe"
$Uri = "https://github.com/fireice-uk/xmr-stak/releases/download/2.10.8/xmr-stak-win64-2.10.8.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGB = 4; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGB = 3; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" } # SRBMinerMulti-v0.7.7 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGB = 1; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGB = 1; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGB = 2; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGB = 2; Type = "AMD"; MinerSet = 1; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }
    # [PSCustomObject]@{ Algorithm = "CryptonightXhv";      MinMemGB = 4; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" } # Invalid coin
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGB = 2; Type = "AMD"; MinerSet = 0; WarmupTimes = @(0, 60); Arguments = " --noCPU --noNVIDIA --amd" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    Type = "CPU"; MinerSet = 1; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --noAMD --noNVIDIA --cpu" }

    [PSCustomObject]@{ Algorithm = "CryptonightBittube2"; MinMemGB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";      MinMemGB = 3; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";     MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";   MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteItbc"; MinMemGB = 1; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";    MinMemGB = 1; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # CryptoDredge-v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightMsr";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";        MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";   MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";       MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";       MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
    # [PSCustomObject]@{ Algorithm = "CryptonightXhv";      MinMemGB = 4; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" } # Invalid coin
    [PSCustomObject]@{ Algorithm = "CryptonightXtl";      MinMemGB = 2; Type = "NVIDIA"; MinerSet = 0; WarmupTimes = @(0, 0); Arguments = " --noAMD --noCPU --openCLVendor NVIDIA --nvidia" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Currency = @{ 
        "CryptonightBittube2" = "cryptonight_bittube2"
        "CryptonightGpu"      = "cryptonight_gpu"
        "CryptonightLite"     = "cryptonight_lite"
        "CryptonightLiteV1"   = "cryptonight_lite_v7"
        "CryptonightLiteItbc" = "cryptonight_lite_v7_xor"
        "CryptonightXhv"      = "cryptonight_haven"
        "CryptonightHeavy"    = "cryptonight_heavy"
        "CryptonightMsr"      = "cryptonight_masari"
        "CryptonightR"        = "cryptonight_r"
        "CryptonightDouble"   = "cryptonight_v8_double"
        "CryptonightRwz"      = "cryptonight_v8_reversewaltz"
        "CryptonightV1"       = "cryptonight_v7"
        "CryptonightXtl"      = "cryptonight_v7_stellite"
        "CryptonightV2"       = "cryptonight_v8"
    }

    $Coins = @("aeon7", "bbscoin", "bittube", "freehaven", "graft", "haven", "intense", "masari", "monero" ,"qrl", "ryo", "stellite", "turtlecoin")

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object { -not $Pools.($_.Algorithm).SSL } | Where-Object Type -eq $_.Type | ForEach-Object { 

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Note: For fine tuning directly edit the config files in the miner binary directory
                    $ConfigFileName = "$((@("Config") + @($_.Type) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').txt"
                    $MinerThreadsConfigFileName = "$((@("ThreadsConfig") + @($_.Type) + @($_.Algorithm) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt"
                    $PlatformThreadsConfigFileName = "$((@("HwConfig") + @($_.Type) + @($_.Algorithm) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') | Select-Object) -join '-').txt"
                    $PoolFileName = "$([System.Web.HttpUtility]::UrlEncode((@("PoolConf") + @($($Pools.($_.Algorithm).Name -replace "-Coins" -replace "24hr")) + @($_.Algorithm) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) | Select-Object) -join '-')).txt"

                    $Parameters = [PSCustomObject]@{ 
                        PoolFile = [PSCustomObject]@{ 
                            FileName = $PoolFileName
                            Content  = [PSCustomObject]@{ 
                                pool_list = @(
                                    [PSCustomObject]@{ 
                                        pool_address    = "$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"
                                        wallet_address  = $Pools.($_.Algorithm).User
                                        pool_password   = $Pools.($_.Algorithm).Pass
                                        use_nicehash    = $($Pools.($_.Algorithm).Name -like "NiceHash*")
                                        use_tls         = $Pools.($_.Algorithm).SSL
                                        tls_fingerprint = ""
                                        pool_weight     = 1
                                        rig_id          = "$($Config.Pools.$($Pools.($_.Algorithm).Name).Worker)"
                                    }
                                )
                                currency = $(If ($Coins -icontains $Pools.($_.Algorithm).CoinName) { $Pools.($_.Algorithm).CoinName } Else { $Currency.($_.Algorithm) })
                            }
                        }
                        ConfigFile = [PSCustomObject]@{ 
                            FileName = $ConfigFileName
                            Content  = [PSCustomObject]@{ 
                                call_timeout    = 10
                                retry_time      = 10
                                giveup_limit    = 0
                                verbose_level   = 99
                                print_motd      = $true
                                h_print_time    = 60
                                aes_override    = $null
                                use_slow_memory = "warn"
                                tls_secure_algo = $true
                                daemon_mode     = $false
                                flush_stdout    = $false
                                output_file     = ""
                                httpd_port      = [UInt16]$MinerAPIPort
                                http_login      = ""
                                http_pass       = ""
                                prefer_ipv4     = $true
                            }
                        }
                        Commands = ("--poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $MinerThreadsConfigFileName --noUAC --httpd $($MinerAPIPort)").trim()
                        Devices  = @($Miner_Devices.$DeviceEnumerator | Sort-Object)
                        HwDetectCommands = ("--poolconf $PoolFileName --config $ConfigFileName$($_.Arguments) $PlatformThreadsConfigFileName --httpd $($MinerAPIPort)").trim()
                        MinerThreadsConfigFileName = $MinerThreadsConfigFileName
                        Platform = $Platform
                        PlatformThreadsConfigFileName = $PlatformThreadsConfigFileName
                        Threads = 1
                    }

                    If ($Miner_Devices.PlatformId) { $Parameters.ConfigFile.Content | Add-Member "platform_index" (($Miner_Devices | Select-Object PlatformId -Unique).PlatformId) }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = $Parameters
                        Algorithm   = $_.Algorithm
                        API         = "Fireice"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fees        = 0.02
                        MinerUri    = "http://localhost:$($MinerAPIPort)/h"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
