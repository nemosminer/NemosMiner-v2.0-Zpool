<#
Copyright (c) 2018-2020 Nemo & MrPlus

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           Core.ps1
version:        3.8.1.3
version date:   11 February 2020
#>

Function InitApplication { 
    $Variables | Add-Member -Force @{ SourcesHash = @() }
    $Variables | Add-Member -Force @{ ProcessorCount = (Get-WmiObject -class win32_processor).NumberOfLogicalProcessors }

    If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

    $Variables | Add-Member -Force @{ ScriptStartDate = (Get-Date) }
    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { 
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }

    If ($env:CUDA_DEVICE_ORDER -ne 'PCI_BUS_ID') { $env:CUDA_DEVICE_ORDER = 'PCI_BUS_ID' } # Align CUDA id with nvidia-smi order
    If ($env:GPU_FORCE_64BIT_PTR -ne 1) { $env:GPU_FORCE_64BIT_PTR = 1 }                   # For AMD
    If ($env:GPU_MAX_HEAP_SIZE -ne 100) { $env:GPU_MAX_HEAP_SIZE = 100 }                   # For AMD
    If ($env:GPU_USE_SYNC_OBJECTS -ne 1) { $env:GPU_USE_SYNC_OBJECTS = 1 }                 # For AMD
    If ($env:GPU_MAX_ALLOC_PERCENT -ne 100) { $env:GPU_MAX_ALLOC_PERCENT = 100 }           # For AMD
    If ($env:GPU_SINGLE_ALLOC_PERCENT -ne 100) { $env:GPU_SINGLE_ALLOC_PERCENT = 100 }     # For AMD
    If ($env:GPU_MAX_WORKGROUP_SIZE -ne 256) { $env:GPU_MAX_WORKGROUP_SIZE = 256 }         # For AMD

    #Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    Import-Module NetSecurity -ErrorAction SilentlyContinue
    Import-Module Defender -ErrorAction SilentlyContinue
    Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1" -ErrorAction SilentlyContinue
    Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction SilentlyContinue
    If ($PSEdition -eq 'core') { Import-Module -SkipEditionCheck NetTCPIP -ErrorAction SilentlyContinue }

    If (Get-Command "Unblock-File" -ErrorAction SilentlyContinue) { Get-ChildItem . -Recurse | Unblock-File }
    If ((Get-Command "Get-MpPreference" -ErrorAction SilentlyContinue) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process (@{ desktop = "powershell"; core = "pwsh" }.$PSEdition) "-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1'; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
    }

    If ($Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Proxy }
    Update-Status("Initializing Variables...")
    $Variables | Add-Member -Force @{ DecayStart = Get-Date }
    $Variables | Add-Member -Force @{ DecayPeriod = 120 } #seconds
    $Variables | Add-Member -Force @{ DecayBase = 1 - 0.1 } #decimal percentage
    $Variables | Add-Member -Force @{ ActiveMinerPrograms = @() }
    $Variables | Add-Member -Force @{ Miners = @() }
    #Start the log
    Start-Transcript -Path ".\Logs\miner-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
    # Purge Logs more than 10 days
    If ((Get-ChildItem ".\Logs\miner-*.log").Count -gt 10) { 
        Get-ChildItem ".\Logs\miner-*.log" | Where-Object { $_.name -notin (Get-ChildItem ".\Logs\miner-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10).FullName } | Remove-Item -Force -Recurse
    }
    #Update stats with missing data and set to today's date/time
    $Variables.StatusText = "Preparing stats data..."
    Get-Stat; $Now = (Get-Date).ToUniversalTime(); if ($Stats ) { $Stats | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Stats.$_.Updated = $Now } }
    #Set donation parameters
    $Variables | Add-Member -Force @{ DonateRandom = [PSCustomObject]@{ } }
    $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
    If ($Config.Donate -lt 1) { $Config.Donate = (0, (0..0)) | Get-Random }
    $Variables | Add-Member -Force @{ WalletBackup = $Config.Wallet }
    $Variables | Add-Member -Force @{ UserNameBackup = $Config.UserName }
    $Variables | Add-Member -Force @{ WorkerNameBackup = $Config.WorkerName }
    $Variables | Add-Member -Force @{ EarningsPool = "" }
    $Variables | Add-Member -Force @{ BrainJobs = @() }
    $Variables | Add-Member -Force @{ EarningsTrackerJobs = @() }
    $Variables | Add-Member -Force @{ Earnings = @{ } }

    $Variables | Add-Member -Force @{ StartPaused = $False }
    $Variables | Add-Member -Force @{ Started = $False }
    $Variables | Add-Member -Force @{ Paused = $False }
    $Variables | Add-Member -Force @{ RestartCycle = $False }

    $Location = $Config.Location
 
    # Find available TCP Ports
    $StartPort = 4068
    $Config.Type | Sort-Object | ForEach-Object { 
        Update-Status("Finding available TCP Port for $($_)")
        $Port = Get-FreeTcpPort($StartPort)
        $Variables | Add-Member -Force @{ "$($_)MinerAPITCPPort" = $Port }
        Update-Status("Miners API Port: $($Port)")
        $StartPort = $Port + 1
    }
    Start-Sleep 2
}

Function Start-ChildJobs { 
    # Starts Brains if necessary
    $Config.PoolName | ForEach-Object { 
        If ($_ -notin $Variables.BrainJobs.PoolName) { 
            $BrainPath = "$($Variables.MainPath)\Brains\$($_)"
            $BrainName = (".\Brains\" + $_ + "\Brains.ps1")
            If (Test-Path $BrainName -PathType Leaf) { 
                Update-Status("Starting Brains for $($_)...")
                $BrainJob = Start-Job -FilePath $BrainName -ArgumentList @($BrainPath)
                $BrainJob | Add-Member -Force @{ PoolName = $_ }
                $Variables.BrainJobs += $BrainJob
                Remove-Variable BrainJob
            }
        }
    }
    # Starts Earnings Tracker Job if necessary
    $StartDelay = 0
    # If ($Config.TrackEarnings -and (($EarningTrackerConfig.Pools | sort) -ne ($Config.PoolName | sort))) { 
    # Update-Status("Updating Earnings Tracker Configuration")
    # $EarningTrackerConfig = Get-Content ".\Config\EarningTrackerConfig.json" | ConvertFrom-Json
    # $EarningTrackerConfig | Add-Member -Force @{ "Pools" = ($Config.PoolName) }
    # $EarningTrackerConfig | ConvertTo-Json | Out-File ".\Config\EarningTrackerConfig.json"
    # }

    If (($Config.TrackEarnings) -and (-not ($Variables.EarningsTrackerJobs))) { 
        $Params = @{ 
            WorkingDirectory = ($Variables.MainPath)
            PoolsConfig      = $Config.PoolsConfig
        }
        $EarningsJob = Start-Job -FilePath ".\Includes\EarningsTrackerJob.ps1" -ArgumentList $Params
        If ($EarningsJob) { 
            Update-Status("Starting Earnings Tracker")
            $Variables.EarningsTrackerJobs += $EarningsJob
            Remove-Variable EarningsJob
            # Delay Start when several instances to avoid conflicts.
        }
    }
}

Function NPMCycle { 
    $CycleTime = Measure-Command -Expression { 
        If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1"); "LoadedInclude" | Out-Host }

        $Variables | Add-Member -Force @{ EndLoop = $False }

        Update-Status("Starting Cycle")
        $DecayExponent = [Int](((Get-Date) - $Variables.DecayStart).TotalSeconds / $Variables.DecayPeriod)

        # Ensure we get the hashrate for running miners prior looking for best miner
        $Variables.ActiveMinerPrograms | ForEach-Object { 
            If ($_.Process -eq $null -or $_.Process.HasExited) { 
                If ($_.Status -eq "Running") { $_.Status = "Failed" }
            }
            Else { 
                $Miner = $_
                #Read hashrate from miner
                $Miner_HashRates = Get-HashRate $Miner.API $Miner.Port $Miner.Algorithms
                $Miner.HashRates = @($Miner_HashRates | Select-Object -First $Miner.Algorithms.Count)
                # we don't want to store hashrates if we run less than $Config.StatsInterval sec
                $WasActive = [Math]::Round(((Get-Date) - $_.Process.StartTime).TotalSeconds)
                If ($WasActive -ge $Config.StatsInterval) { 
                    If ($Miner.New) { $Miner.Benchmarked++ }
                    If ($Miner_HashRates.Count -ge $_.Algorithms.Count) { 
                        $Miner.Algorithms | ForEach-Object {
                            $HashRate = $Miner.HashRates | Select-Object -Index ([Array]::indexof($Miner.Algorithms, $_))
                            Update-Status("Saving hash rate ($($Miner.Name)_$($_)_HashRate: $(($HashRate | ConvertTo-Hash) -replace ' '))$(If (-not (Get-Stat -Name "$($Miner.Name)_$($_)_HashRate")) { " [Benchmark done]" })")
                            $Stat = Set-Stat -Name "$($Miner.Name)_$($_)_HashRate" -Value $HashRate
                        }
                        $Miner.New = $false
                        $Miner.Hashrate_Gathered = $true
                    }
                }
            }
        }
        #Activate or deactivate donation
        If ((Get-Date).AddDays(-1).AddMinutes($Config.Donate) -ge $Variables.LastDonated -and $Variables.DonateRandom.wallet -eq $Null) { 
            # Get donation addresses randomly from agreed developers list
            # This will fairly distribute donations to Developers
            # Developers list and wallets is publicly available at: https://nemosminer.com/data/devlist.json & https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json
            Try { 
                $Donation = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            }
            Catch { 
                $Donation = @([PSCustomObject]@{ Name = "nemo"; Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"; UserName = "nemo" }, [PSCustomObject]@{ Name = "mrplus"; Wallet = "134bw4oTorEJUUVFhokDQDfNqTs7rBMNYy"; UserName = "mrplus" })
            }
            If ($Donation -ne $null) { 
                If ($Config.Donate -lt 3) { $Config.Donate = (0, (3..8)) | Get-Random }
                $Variables.DonateRandom = $Donation | Get-Random
                $Config | Add-Member -Force @{ PoolsConfig = [PSCustomObject]@{ default = [PSCustomObject]@{ Wallet = $Variables.DonateRandom.Wallet; UserName = $Variables.DonateRandom.UserName; WorkerName = "$($Variables.CurrentProduct)$($Variables.CurrentVersion.ToString().replace('.',''))"; PricePenaltyFactor = 1 } } }
            }
        }
        If (((Get-Date).AddDays(-1) -ge $Variables.LastDonated -and $Variables.DonateRandom.Wallet -ne $Null) -or (-not $Config.PoolsConfig)) { 
            $Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value { 
                If (Test-Path ".\Config\PoolsConfig.json" -PathType Leaf) { 
                    Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-Json
                }
                Else { 
                    [PSCustomObject]@{ default = [PSCustomObject]@{ 
                            Wallet      = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                            UserName    = "nemo"
                            WorkerName  = "NemosMinerNoCfg"
                            PoolPenalty = 1
                        }
                    }
                }
            }
            $Variables.LastDonated = Get-Date
            $Variables.DonateRandom = [PSCustomObject]@{ }
        }

        # Update-Status("Loading BTC rate from 'api.coinbase.com'...")
        Update-Status("Loading BTC rate from 'min-api.cryptocompare.com'...")
        Get-Rates

        $PoolFilter = @()
        $Config.PoolName | ForEach-Object { $PoolFilter += ($_ += ".*") }
        Update-Status("Loading stats for pool$(If ($PoolFilter.Count -ne 1) { "s" }) $(($Config.PoolName | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ', ')...")
        Do {
            $AllPools = If (Test-Path "Pools" -PathType Container) {
                Get-ChildItemContent "Pools" -Include $PoolFilter | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } | Where-Object { 
                    $_.SSL -EQ $Config.SSL -and 
                    ($Config.PoolName.Count -eq 0 -or ($_.Name -in $Config.PoolName)) -and 
                    (-not $Config.Algorithm -or ((-not ($Config.Algorithm | Where-Object { $_ -like "+*" }) -or $_.Algorithm -in ($Config.Algorithm | Where-Object { $_ -like "+*" }).Replace("+", "")) -and (-not ($Config.Algorithm | Where-Object { $_ -like "-*" }) -or $_.Algorithm -notin ($Config.Algorithm | Where-Object { $_ -like "-*" }).Replace("-", ""))) )
                }
            }
            If ($AllPools.Count -eq 0) {
                Update-Status("! Error contacting pool retrying in 30 seconds..")
                Start-Sleep 30
            }
        } While ($AllPools.Count -eq 0)

        Update-Status("Computing pool stats...")
        # Use location as preference and not the only one
        $LocPools = @($AllPools | Where-Object { $_.Location -eq $Config.Location })
        $AllPools = $LocPools + @($AllPools | Where-Object { $_.name -notin $LocPools.name })
        Remove-Variable LocPools
        # Filter Algo based on Per Pool Config
        $PoolsConf = $Config.PoolsConfig
        $AllPools = $AllPools | Where-Object { $_.Name -notin ($PoolsConf | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -or ($_.Name -in ($PoolsConf | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -and ((-not ( $PoolsConf.($_.Name).Algorithm | Where-Object { $_ -like "+*" }) -or ("+$($_.Algorithm)" -in $PoolsConf.($_.Name).Algorithm)) -and ("-$($_.Algorithm)" -notin $PoolsConf.($_.Name).Algorithm))) }
        $Variables.AllPools = $AllPools
        # If ($AllPools.Count -eq 0) { $Update-Status("Error contacting pool, retrying..."); $timerCycle.Interval = 15000; $timerCycle.Start(); return }
        $Pools = [PSCustomObject]@{ }
        $Pools_Comparison = [PSCustomObject]@{ }
        $AllPools.Algorithm | Sort-Object -Unique | ForEach-Object { 
            $Pools | Add-Member $_ ($AllPools | Where-Object Algorithm -EQ $_ | Sort-Object Price -Descending | Select-Object -First 1)
            $Pools_Comparison | Add-Member $_ ($AllPools | Where-Object Algorithm -EQ $_ | Sort-Object StablePrice -Descending | Select-Object -First 1)
        }

        If ((Test-Path ".\Config\MinersHash.json" -PathType Leaf) -and (Test-Path .\Miners -PathType Container)) { 
            Update-Status("Looking for miner files changes...")
            $MinersHash = Get-Content ".\Config\MinersHash.json" | ConvertFrom-Json
            Compare-Object @($MinersHash | Select-Object) @(Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash | Select-Object) -Property "Hash", "Path" | Sort-Object "Path" -Unique | ForEach-Object { 
                If (Test-Path $_.Path -PathType Leaf) { 
                    Update-Status("Miner Updated: $($_.Path)")
                    $NewMiner = &$_.path
                    $NewMiner | Add-Member -Force @{ Name = (Get-Item $_.Path).BaseName }
                    $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" -and $_.Path -eq (Resolve-Path $NewMiner.Path) } | ForEach-Object { 
                        [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
                        If ($Filtered.Count -eq 0) { 
                            If ($_.Process -eq $null) { 
                                $_.Status = "Failed"
                            }
                            ElseIf ($_.Process.HasExited -eq $false) { 
                                Update-Status("Closing miner ($($Miner.Name) {$(($Miner.Algorithm | ForEach-Object { "$($_)@$($Miner.PoolNames | Select-Object -Index ([Array]::indexof($Miner.Algorithm, $_)))" }) -join "; ")}) for update.")
                                $_.Process.CloseMainWindow() | Out-Null
                                Start-Sleep 1
                                # simply "Kill with power"
                                Stop-Process $_.Process -Force | Out-Null
                                Start-Sleep 1
                                $_.Status = "Idle"
                            }
                            #Restore Bias for non-active miners
                            $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | ForEach-Object { $_.Profit_Bias = $_.Profit_Bias_Orig }
                        }
                    }
                    Get-ChildItem -path ".\Stats\" -filter "$($NewMiner.Name)_*.txt" | Remove-Item -Force -Recurse
                    Remove-Item -Force -Recurse (Split-Path $NewMiner.Path)
                }
                $MinersHash = Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash
                $MinersHash | ConvertTo-Json | Out-File ".\Config\MinersHash.json"
            }
        }

        Update-Status("Loading miners...")
        $Variables | Add-Member -Force @{ Miners = @() }
        $Variables.Miners = @(
            If ($Config.IncludeRegularMiners -and (Test-Path "Miners" -PathType Container)) { Get-ChildItemContent "Miners" }
            If ($Config.IncludeOptionalMiners -and (Test-Path "OptionalMiners" -PathType Container)) { Get-ChildItemContent "OptionalMiners" }
            If (Test-Path "CustomMiners" -PathType Container) { Get-ChildItemContent "CustomMiners" }
        ) | Select-Object | ForEach-Object { $_.Content | Add-Member @{ Name = $_.Name } -ErrorAction SilentlyContinue; $_.Content } | 
        Where-Object { $Config.Type.Count -eq 0 -or (Compare-Object $Config.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | 
        Where-Object { -not ($Config.Algorithm | Where-Object { $_.StartsWith("+") }) -or (Compare-Object (($Config.Algorithm | Where-Object { $_.StartsWith("+") }).Replace("+", "")) $_.HashRates.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | 
        Where-Object { $Config.MinerName.Count -eq 0 -or (Compare-Object $Config.MinerName ($_.Name -split '-' | Select-Object -Index 0) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }
    
        $Variables.Miners = $Variables.Miners | Select-Object | ForEach-Object { 
            $Miner = $_
            If (-not (Test-Path $Miner.Path -Type Leaf)) { 
                Update-Status("Downloading $($Miner.Name)...")
                If ((Split-Path $Miner.URI -Leaf) -eq (Split-Path $Miner.Path -Leaf)) { 
                    New-Item (Split-Path $Miner.Path) -ItemType "Directory" | Out-Null
                    Invoke-WebRequest $Miner.URI -TimeoutSec 15 -OutFile $_.Path -UseBasicParsing
                }
                ElseIf (([IO.FileInfo](Split-Path $_.URI -Leaf)).Extension -eq '') { 
                    $Path_Old = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-ChildItem -Path $_.Root -Include (Split-Path $Miner.Path -Leaf) -Recurse -ErrorAction Ignore } | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
                    $Path_New = $Miner.Path

                    If ($Path_Old -ne $null) { 
                        If (Test-Path (Split-Path $Path_New)) { (Split-Path $Path_New) | Remove-Item -Recurse -Force }
                        (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                    }
                    Else { 
                        Update-Status("Cannot find $($Miner.Path) distributed at $($Miner.URI). ")
                    }
                }
                Else { 
                    Expand-WebRequest $Miner.URI (Split-Path $Miner.Path)
                }
            }
            Else { 
                $Miner | Add-Member "Host" @($Miner.HashRates.PSObject.Properties.Name | ForEach-Object { $Pools.$_.Host }) -Force
                $Miner | Add-Member "User" @($Miner.Hashrates.PSObject.Properties.Name | ForEach-Object { $Pools.$_.User }) -Force
                $Miner | Add-Member "Coin" @($Miner.Hashrates.PSObject.Properties.Name | ForEach-Object { $Pools.$_.Coin }) -Force
                # Filter empty pool data; JSON miners (e.g. gminerdual) cannot not check if a pool host is available
                If ($Miner.Host -notcontains $null) { $Miner }
            }
        }

        Update-Status("Comparing miners and pools...")
        If ($Variables.Miners.Count -eq 0) { Update-Status("No Miners!") } #; Start-Sleep $Config.Interval; continue}

        $Variables.Miners | ForEach-Object { 
            $Miner = $_
            $Miner_HashRates = [PSCustomObject]@{ }
            $Miner_Pools = [PSCustomObject]@{ }
            $Miner_Pools_Comparison = [PSCustomObject]@{ }
            $Miner_Profits = [PSCustomObject]@{ }
            $Miner_Profits_Comparison = [PSCustomObject]@{ }
            $Miner_Profits_Bias = [PSCustomObject]@{ }
            $Miner_Types = $Miner.Type | Select-Object -Unique
            $Miner_Indexes = $Miner.Index | Select-Object -Unique
            $Miner.HashRates.PSObject.Properties.Name | ForEach-Object { #temp fix, must use 'PSObject.Properties' to preserve order
                $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
                $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pools.$_)
                $Miner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$Pools_Comparison.$_)
                $Miner_Profits | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price)
                $Miner_Profits_Comparison | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools_Comparison.$_.Price)
                $Miner_Profits_Bias | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price * (1 - ($Config.MarginOfError * [Math]::Pow($Variables.DecayBase, $DecayExponent))))
            }
            $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure-Object -Sum).Sum
            $Miner_Profit_Comparison = [Double]($Miner_Profits_Comparison.PSObject.Properties.Value | Measure-Object -Sum).Sum
            $Miner_Profit_Bias = [Double]($Miner_Profits_Bias.PSObject.Properties.Value | Measure-Object -Sum).Sum
            $Miner.HashRates.PSObject.Properties.Name | ForEach-Object { #temp fix, must use 'PSObject.Properties' to preserve order 
                If (-not [String]$Miner.HashRates.$_) { 
                    $Miner_HashRates.$_ = $null
                    $Miner_Profits.$_ = $null
                    $Miner_Profits_Comparison.$_ = $null
                    $Miner_Profits_Bias.$_ = $null
                    $Miner_Profit = $null
                    $Miner_Profit_Comparison = $null
                    $Miner_Profit_Bias = $null
                }
            }
            If ($Miner_Types -eq $null) { $Miner_Types = $Variables.Miners.Type | Select-Object -Unique }
            If ($Miner_Indexes -eq $null) { $Miner_Indexes = $Variables.Miners.Index | Select-Object -Unique }
            If ($Miner_Types -eq $null) { $Miner_Types = "" }
            If ($Miner_Indexes -eq $null) { $Miner_Indexes = 0 }
            $Miner.HashRates = $Miner_HashRates
            $Miner | Add-Member Pools $Miner_Pools
            $Miner | Add-Member Profits $Miner_Profits
            $Miner | Add-Member Profits_Comparison $Miner_Profits_Comparison
            $Miner | Add-Member Profits_Bias $Miner_Profits_Bias
            $Miner | Add-Member Profit $Miner_Profit
            $Miner | Add-Member Profit_Comparison $Miner_Profit_Comparison
            $Miner | Add-Member Profit_Bias $Miner_Profit_Bias
            $Miner | Add-Member Profit_Bias_Orig $Miner_Profit_Bias
            $Miner | Add-Member Type $Miner_Types -Force
            $Miner | Add-Member Index $Miner_Indexes -Force
            
            if ($Miner.Arguments -isnot [String]) { $Miner.Arguments = $Miner.Arguments | ConvertTo-Json -Depth 10 -Compress }
            
            $Miner.Path = Convert-Path $Miner.Path
        }
        $Variables.Miners | ForEach-Object { 
            $Miner = $_ 
            $Miner_Devices = $Miner.Device | Select-Object -Unique
            If ($Miner_Devices -eq $null) { $Miner_Devices = ($Variables.Miners | Where-Object { (Compare-Object $Miner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }).Device | Select-Object -Unique }
            If ($Miner_Devices -eq $null) { $Miner_Devices = $Miner.Type }
            $Miner | Add-Member Device $Miner_Devices -Force
        }
        # Remove miners when no estimation info from pools or 0BTC. Avoids mining when algo down at pool or benchmarking for ever
        $Variables.Miners = $Variables.Miners | Where-Object { ($_.Pools.PSObject.Properties.Value.Price -ne $null) -and ($_.Pools.PSObject.Properties.Value.Price -gt 0) }

        #Don't penalize active miners. Miner could switch a little bit later and we will restore his bias in this case
        $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" } | ForEach-Object { $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | ForEach-Object { $_.Profit_Bias = $_.Profit * (1 + $Config.ActiveMinerGainPct / 100) } }
        #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
        $BestMiners = $Variables.Miners | Select-Object Type, Index -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.Type $_.Type | Measure-Object).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure-Object).Count -eq 0 } | Sort-Object -Descending { ($_ | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_ | Measure-Object Profit_Bias -Sum).Sum }, { ($_ | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1) }
        $BestDeviceMiners = $Variables.Miners | Select-Object Device -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.Device $_.Device | Measure-Object).Count -eq 0 } | Sort-Object -Descending { ($_ | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_ | Measure-Object Profit_Bias -Sum).Sum }, { ($_ | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1) }
        $BestMiners_Comparison = $Variables.Miners | Select-Object Type, Index -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.Type $_.Type | Measure-Object).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure-Object).Count -eq 0 } | Sort-Object -Descending { ($_ | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_ | Measure-Object Profit_Comparison -Sum).Sum }, { ($_ | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1) }
        $BestDeviceMiners_Comparison = $Variables.Miners | Select-Object Device -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.Device $_.Device | Measure-Object).Count -eq 0 } | Sort-Object -Descending { ($_ | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_ | Measure-Object Profit_Comparison -Sum).Sum }, { ($_ | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1) }
        $Miners_Type_Combos = @([PSCustomObject]@{ Combination = @() }) + (Get-Combination ($Variables.Miners | Select-Object Type -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty Type -Unique) ($_.Combination | Select-Object -ExpandProperty Type) | Measure-Object).Count -eq 0 })
        $Miners_Index_Combos = @([PSCustomObject]@{ Combination = @() }) + (Get-Combination ($Variables.Miners | Select-Object Index -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty Index -Unique) ($_.Combination | Select-Object -ExpandProperty Index) | Measure-Object).Count -eq 0 })
        $Miners_Device_Combos = (Get-Combination ($Variables.Miners | Select-Object Device -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty Device -Unique) ($_.Combination | Select-Object -ExpandProperty Device) | Measure-Object).Count -eq 0 })
        $BestMiners_Combos = $Miners_Type_Combos | ForEach-Object { $Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach-Object { $Miner_Index_Combo = $_.Combination; [PSCustomObject]@{ Combination = $Miner_Type_Combo | ForEach-Object { $Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $Miner_Index_Combo | ForEach-Object { $Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $BestMiners | Where-Object { ([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count } } } } } }
        $BestMiners_Combos += $Miners_Device_Combos | ForEach-Object { $Miner_Device_Combo = $_.Combination; [PSCustomObject]@{ Combination = $Miner_Device_Combo | ForEach-Object { $Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $BestDeviceMiners | Where-Object { ([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count } } } }
        $BestMiners_Combos_Comparison = $Miners_Type_Combos | ForEach-Object { $Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach-Object { $Miner_Index_Combo = $_.Combination; [PSCustomObject]@{ Combination = $Miner_Type_Combo | ForEach-Object { $Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $Miner_Index_Combo | ForEach-Object { $Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $BestMiners_Comparison | Where-Object { ([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count } } } } } }
        $BestMiners_Combos_Comparison += $Miners_Device_Combos | ForEach-Object { $Miner_Device_Combo = $_.Combination; [PSCustomObject]@{ Combination = $Miner_Device_Combo | ForEach-Object { $Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ')$'; $BestDeviceMiners_Comparison | Where-Object { ([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count } } } }
        $BestMiners_Combo = $BestMiners_Combos | Sort-Object -Descending { ($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Profit_Bias -Sum).Sum }, { ($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1 | Select-Object -ExpandProperty Combination
        $BestMiners_Combo_Comparison = $BestMiners_Combos_Comparison | Sort-Object -Descending { ($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Profit_Comparison -Sum).Sum }, { ($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -First 1 | Select-Object -ExpandProperty Combination

        # No CPU mining if GPU miner prevents it
        If ($BestMiners_Combo.PreventCPUMining -contains $true) { 
            $BestMiners_Combo = $BestMiners_Combo | Where-Object { $_.type -ne "CPU" }
            Update-Status("Miner prevents CPU mining")
        }

        # Ban miners if too many failures as defined by MaxMinerFailure
        # 0 means no ban
        # Int value means ban after x failures
        # defaults to 3 if no value in config
        # ** Ban is not persistent across sessions **
        #Ban Failed Miners code by @MrPlusGH
        If ($Config.MaxMinerFailure -gt 0) { 
            $Config | Add-Member -Force @{ MaxMinerFailure = If ($Config.MaxMinerFailure) { $Config.MaxMinerFailure } Else { 3 } }
            $BannedMiners = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Failed" -and $_.FailedCount -ge $Config.MaxMinerFailure }
            # $BannedMiners | ForEach { Update-Status("BANNED: $($_.Name) / $($_.Algorithms). Too many failures. Consider Algo exclusion in config.") }
            $BannedMiners | ForEach-Object { "BANNED: $($_.Name) / $($_.Algorithms). Too many failures. Consider Algo exclusion in config." | Out-Host }
            $Variables.Miners = $Variables.Miners | Where-Object { $_.Path -notin $BannedMiners.Path -and $_.Arguments -notin $BannedMiners.Arguments }
        }

        #Add the most profitable miners to the active list
        $BestMiners_Combo | ForEach-Object { 
            If (($Variables.ActiveMinerPrograms | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments).Count -eq 0) { 
                $Variables.ActiveMinerPrograms += [PSCustomObject]@{ 
                    Type              = $_.Type
                    Name              = $_.Name
                    Path              = $_.Path
                    Arguments         = $_.Arguments
                    Wrap              = $_.Wrap
                    Process           = $null
                    API               = $_.API
                    Port              = $_.Port
                    Algorithms        = @($_.HashRates.PSObject.Properties.Name)
                    New               = $false
                    Active            = [TimeSpan]0
                    TotalActive       = [TimeSpan]0
                    Activated         = 0
                    Status            = "Idle"
                    HashRates         = @()
                    PoolNames         = @($_.HashRates.PSObject.Properties.Name | ForEach-Object { $Pools.$_.Name })
                    Benchmarked       = 0
                    Hashrate_Gathered = ($_.HashRates.PSObject.Properties.Value -ne $null)
                    User              = $_.User
                    Host              = $_.Host
                    Coin              = $_.Coin
                }
            }
        }
        #Stop or start miners in the active list depending on if they are the most profitable
        # We have to stop processes first or the port would be busy
        $Variables.ActiveMinerPrograms | ForEach-Object { 
            [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
            If ($Filtered.Count -eq 0) { 
                If ($_.Process -eq $null) { 
                    $_.Status = "Failed"
                }
                ElseIf ($_.Process.HasExited -eq $false) { 
                    $Miner = $_
                    Update-Status("Closing miner ($($Miner.Name) {$(($Miner.Algorithms | ForEach-Object { "$($_)@$($Miner.PoolNames | Select-Object -Index ([Array]::indexof($Miner.Algorithms, $_)))" }) -join "; ")}).")
                    $_.Process.CloseMainWindow() | Out-Null
                    Start-Sleep 1
                    # simply "Kill with power"
                    Stop-Process $_.Process -Force | Out-Null
                    # try to kill any process with the same path, in case it is still running but the process handle is incorrect
                    $KillPath = $_.Path
                    If (Get-Process | Where-Object { $_.Path -eq $KillPath } | Stop-Process -Force) { 
                        Start-Sleep 1
                    }
                    $_.Status = "Idle"
                    $_.TotalActive += (-$_.Active + ($_.Active = (Get-Date) - $_.Process.StartTime))
                }
                #Restore Bias for non-active miners
                $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | ForEach-Object { $_.Profit_Bias = $_.Profit_Bias_Orig }
            }
        }
        $NewMiner = $false
        $CurrentMinerHashrate_Gathered = $false 
        $Variables.ActiveMinerPrograms | ForEach-Object { 
            [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
            If ($Filtered.Count -gt 0) { 
                If ($_.Process -eq $null -or $_.Process.HasExited -ne $false) { 
                    # Log switching information to .\Logs\switching.log
                    [PSCustomObject]@{ Date = (Get-Date); "Type" = $_.Type; "Algo(s)" = "$($_.Algorithms -join ';')"; "Wallet(s)" = "$(($_.User | Select-Object -Unique) -join ';')" ;  "Username" = $Config.UserName ; "Host(s)" = "$(($_.host | Select-Object -Unique) -join ';')" } | Export-Csv .\Logs\switching.log -Append -NoTypeInformation

                    # Launch prerun if exists
                    If ($_.Type -ne "AMD" -and (Test-Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($_.Type -ne "NVIDIA" -and (Test-Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($_.Type -ne "CPU" -and (Test-Path ".\Utils\Prerun\CPUPrerun.bat"-PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($_.Type -ne "CPU") { 
                        $PrerunName = ".\Utils\Prerun\" + $_.Algorithms + ".bat"
                        $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                        If (Test-Path $PrerunName -PathType Leaf) { 
                            Update-Status("Launching Prerun: $PrerunName")
                            Start-Process $PrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                            Start-Sleep 2
                        }
                        ElseIf (Test-Path $DefaultPrerunName -PathType Leaf) { 
                            Update-Status("Launching Prerun: $DefaultPrerunName")
                            Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                            Start-Sleep 2
                        }
                    }

                    Start-Sleep $Config.Delay #Wait to prevent BSOD
                    $Miner = $_
                    Update-Status("$(If ($Miner.Hashrates) { "Starting" } Else { "Benchmarking" } ) miner ($($Miner.Name) {$(($Miner.Algorithms | ForEach-Object { "$($_)@$($Miner.PoolNames | Select-Object -Index ([Array]::indexof($Miner.Algorithms, $_)))" }) -join "; ")}).")
                    $Variables.DecayStart = Get-Date
                    $_.New = $true
                    $_.Activated++
                    $Arguments = $_.Arguments
                    If ($Arguments -match "^{.+}$") { 
                        $Parameters = $Arguments | ConvertFrom-Json

                        #Write config files. Keep separate files, do not overwrite to preserve optional manual customization
                        If (-not (Test-Path "$(Split-Path $_.Path)\$($Parameters.ConfigFile.FileName)" -PathType Leaf)) { $Parameters.ConfigFile.Content | Set-Content "$(Split-Path $_.Path)\$($Parameters.ConfigFile.FileName)" -ErrorAction Ignore }
                        $Arguments = $Parameters.Commands
                    }

                    If ($_.Process -ne $null) { $_.Active = [TimeSpan]0 }
                    If ($_.Wrap) { $_.Process = Start-Process -FilePath "PowerShell" -ArgumentList "-executionpolicy bypass -command . '$(Convert-Path ".\Includes\Wrapper.ps1")' -ControllerProcessID $PID -Id '$($_.Port)' -FilePath '$($_.Path)' -ArgumentList '$Arguments' -WorkingDirectory '$(Split-Path $_.Path)'" -PassThru }
                    Else { $_.Process = Start-SubProcess -FilePath $_.Path -ArgumentList $Arguments -WorkingDirectory (Split-Path $_.Path) }
                    If ($_.Process -eq $null) { $_.Status = "Failed" }
                    Else { 
                        $_.Status = "Running"
                        $NewMiner = $true
                        #Newly started miner should look better than others in the first run too
                        $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $Arguments | ForEach-Object { $_.Profit_Bias = $_.Profit * (1 + $Config.ActiveMinerGainPct / 100) }
                    }
                }
                Else { 
                    $_.TotalActive += (-$_.Active + ($_.Active = (Get-Date) - $_.Process.StartTime))
                }
                $CurrentMinerHashrate_Gathered = $_.Hashrate_Gathered
            }
        }
        #Set idle duration a few seconds as to not overload the APIs
        If ($NewMiner -or -not $CurrentMinerHashrate_Gathered) { 
            $Variables.TimeToSleep = $Config.StatsInterval

            # If ($Config.Interval -ge $Config.FirstInterval -and $Config.Interval -ge $Config.StatsInterval) { $Variables.TimeToSleep = $Config.Interval }
            # ElseIf ($CurrentMinerHashrate_Gathered -eq $true) { $Variables.TimeToSleep = $Config.FirstInterval }
            # Else { $Variables.TimeToSleep = $Config.StatsInterval }
        }
        Else { 
            $Variables.TimeToSleep = $Config.Interval
        }
        "--------------------------------------------------------------------------------" | Out-Host

        #Save current hash rates
        $Variables.ActiveMinerPrograms | ForEach-Object { 
            If ($_.Process -eq $null -or $_.Process.HasExited) { 
                If ($_.Status -eq "Running") { $_.Status = "Failed" }
            }
            Else { 
                $Miner = $_
                #Read hashrate from miner
                $Miner_HashRates = Get-HashRate $Miner.API $Miner.Port $Miner.Algorithms
                $Miner.HashRates = @($Miner_HashRates | Select-Object -First $Miner.Algorithms.Count)
                # we don't want to store hashrates if we run less than $Config.StatsInterval sec
                $WasActive = [Math]::Round(((Get-Date) - $_.Process.StartTime).TotalSeconds)
                If ($WasActive -ge $Config.StatsInterval) { 
                    If ($Miner.New) { $Miner.Benchmarked++ }
                    If ($Miner_HashRates.Count -ge $_.Algorithms.Count) { 
                        $Miner.Algorithms | ForEach-Object {
                            $HashRate = $Miner.HashRates | Select-Object -Index ([Array]::indexof($Miner.Algorithms, $_))
                            Update-Status("Saving hash rate ($($Miner.Name)_$($_)_HashRate: $(($HashRate | ConvertTo-Hash) -replace ' '))$(If (-not (Get-Stat -Name "$($Miner.Name)_$($_)_HashRate")) { " [Benchmark done]" })")
                            $Stat = Set-Stat -Name "$($Miner.Name)_$($_)_HashRate" -Value $HashRate
                        }
                        $Miner.New = $false
                        $Miner.Hashrate_Gathered = $true
                    }
                }
            }
            #Benchmark timeout
            #        if($_.Benchmarked -ge 6 -or ($_.Benchmarked -ge 2 -and $_.Activated -ge 2))
            #        { 
            #            for($i = 0; $i -lt $_.Algorithms.Count; $i++)
            #            { 
            #                if((Get-Stat "$($_.Name)_$($_.Algorithms | Select-Object -Index $i)_HashRate") -eq $null)
            #                { 
            #                    $Stat = Set-Stat -Name "$($_.Name)_$($_.Algorithms | Select-Object -Index $i)_HashRate" -Value 0
            #                }
            #            }
            #        }
        }
        # }

        <#
        For some reason (need to investigate) $Variables.ActiveMinerPrograms.psobject.TypeNames
        Inflates adding several lines at each loop and causing a memory leak after long runtime
        Code below copies the object which results in a new version which avoid the problem.
        Will need rework. 
        #>
        $Variables.ActiveMinerPrograms | Where-Object { $_.Status -ne "Running" } | ForEach-Object { $_.process = $_.process | Select-Object HasExited, StartTime, ExitTime }
        $ActiveMinerProgramsCOPY = @()
        $Variables.ActiveMinerPrograms | ForEach-Object { $ActiveMinerCOPY = [PSCustomObject]@{ }; $_.PSObject.Properties | Sort-Object Name | ForEach-Object { $ActiveMinerCOPY | Add-Member -Force @{ $_.Name = $_.Value } }; $ActiveMinerProgramsCOPY += $ActiveMinerCOPY }
        $Variables.ActiveMinerPrograms = $ActiveMinerProgramsCOPY
        Remove-Variable ActiveMinerProgramsCOPY
        Remove-Variable ActiveMinerCOPY
    
        $Error.Clear()
    
        Get-Job | Where-Object { $_.State -eq "Completed" } | Remove-Job
        If ($Variables.BrainJobs.count -gt 0) { 
            $Variables.BrainJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Error.Clear() } }
            $Variables.BrainJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Progress.Clear() } }
            $Variables.BrainJobs.ChildJobs | ForEach-Object { $_.Output.Clear() }
        }
        If ($Variables.EarningsTrackerJobs.count -gt 0) { 
            $Variables.EarningsTrackerJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Error.Clear() } }
            $Variables.EarningsTrackerJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Progress.Clear() } }
            $Variables.EarningsTrackerJobs.ChildJobs | ForEach-Object { $_.Output.Clear() }
        }

        # Re-Read stats
        Update-Status("Updating stats data...")
        Get-Stat

        # Mostly used for debug. Will execute code found in .\EndLoopCode.ps1 if exists.
        If (Test-Path ".\EndLoopCode.ps1" -PathType Leaf) { Invoke-Expression (Get-Content ".\EndLoopCode.ps1" -Raw) }
    }

    "Cycle Time (seconds): $($CycleTime.TotalSeconds)" | Out-Host
    $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
    $Variables | Add-Member -Force @{ EndLoop = $True }
}
#Stop the log
# Stop-Transcript
