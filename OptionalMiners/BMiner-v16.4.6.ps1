using module ..\Includes\Include.psm1

# Return #too many bad shares

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-v16.4.6-d77cc9b-amd64.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Type = "AMD"; Fee = @(0.0065);    MinMemGB = 5.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy") }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Type = "AMD"; Fee = @(0.0065);    MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy") }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake");       Type = "AMD"; Fee = @(0.0065, 0); MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy", " -uri2 handshake") } # Error flag -uri2: Unsupported scheme
    # [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Handshake"); Type = "AMD"; Fee = @(0.0065, 0); MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy", " -uri2 handshake") } # Error flag -uri2: Unsupported scheme

    [PSCustomObject]@{ Algorithm = @("BeamV3");        Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 5.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri beam") } # NBMiner-v36.0 is faster but has 2% fee
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc"); Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 8.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri bfc") }
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");   Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri cuckaroo29m") }
    [PSCustomObject]@{ Algorithm = @("CuckarooZ29");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri cuckaroo29z") } # GMiner-v2.59 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri cuckatoo31") }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri cuckatoo32") }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri aeternity") }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");  Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -pers auto -uri equihash1445") } # MiniZ-v1.6x is fastest
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri zhash") }
    [PSCustomObject]@{ Algorithm = @("Ethash");        Type = "NVIDIA"; Fee = @(0.0065); MinMemGB = 5.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy") }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");  Type = "NVIDIA"; Fee = @(0.0065); MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri ethproxy") }
    [PSCustomObject]@{ Algorithm = @("KawPoW");        Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri raven") }
    [PSCustomObject]@{ Algorithm = @("Octopus");       Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri conflux") } # NBMiner-v38.1 is faster is faster but has 2% fee
    [PSCustomObject]@{ Algorithm = @("Qitmeer");       Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri qitmeer") }
    [PSCustomObject]@{ Algorithm = @("Sero");          Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(0, 30); Protocol = @(" -uri sero") }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # # Does not seem to make any difference for Handshake
    # # Intensities for 2. algorithm
    # $Intensities = [PSCustomObject]@{ 
    #     "Handshake" = @(0, 10, 30, 60, 100, 150, 210) # 0 = Auto-Intensity
    # }

    # # Build command sets for intensities
    # $AlgorithmDefinitions = $AlgorithmDefinitions | ForEach-Object { 
    #     $_.PsObject.Copy()
    #     $Arguments = ""
    #     ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
    #         $_ | Add-Member Arguments " -dual-subsolver -1 -dual-intensity $Intensity" -Force
    #         $_ | Add-Member Intensity $Intensity -Force
    #         $_.PsObject.Copy()
    #     }
    # }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = [String]$_.Arguments
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
                $MinMemGB = $_.MinMemGB

                If ($_.Algorithm[0] -in @("Ethash", "KawPoW")) { 
                    $MinMemGB = ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB
                }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } )
                $Miner_Devices = @($Miner_Devices | Where-Object { (-not $_.CIM.CurrentRefreshRate) -or (($_.OpenCL.GlobalMemSize - 0.5) / 1GB) -ge $MinMemGB } ) # Reserve 512 MB when GPU with connected monitor
                If ($_.Algorithm[0] -match "$Ethash.*") { $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "$AMD Radeon RX 5[0-9]{3}.*" }) } # Ethash mining not supported on Navi
                If ($_.Algorithm[1]) { $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "$AMD Radeon RX 5[0-9]{3}.*" }) } # Dual mining not supported on Navi

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-CommandPerDevice -Command $Arguments -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Pass = $($Pools.($_.Algorithm[0]).Pass)
                    If ($Pools.($_.Algorithm).Name -match "$ProHashing.*" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$(($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB)" }

                    $Protocol = $_.Protocol[0]
                    If ($_.Algorithm[0] -in @("Ethash", "KawPoW") -and $Pools.($_.Algorithm[0]).Name -match "$NiceHash^|$MPH(Coins)^|$ProHashing^") { $Protocol = $Protocol -replace "ethproxy", "ethstratum" }
                    If ($Pools.($_.Algorithm[0]).SSL) { $Protocol = "$($Protocol)+ssl" }

                    $Arguments += "$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).User)):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"

                    If ($_.Algorithm[1]) { 
                        $Protocol2 = $_.Protocol[1]
                        If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { $Protocol2 = "$($Protocol2)+ssl" }
                        $Arguments += "$($Protocol2)://$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User)):$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass))@$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port)"
                    }

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $Arguments += " -nofee"
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                    }
 
                    If ($_.Algorithm[1] -and (-not $_.Intensity)) { 
                        # Allow 75 seconds for auto-tuning
                        $WarmupTimes[0] += 75; $WarmupTimes[1] += 75
                    }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments -watchdog=false -api 127.0.0.1:$($MinerAPIPort) -devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { "$(If ($Miner_Devices.Vendor -eq "AMD") { "amd:" }){0:x}" -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API         = "Bminer"
                        Port        = $MinerAPIPort
                        URI         = $URI
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
