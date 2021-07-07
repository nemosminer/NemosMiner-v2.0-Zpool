using module .\Include.psm1

<#
Copyright (c) 2018 Nemos, MrPlus & UselessGuru
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH & UseLessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           BalancesTracker.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

# Start the log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\BalancesTracker-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Balances = [Ordered]@{ }
$BalanceObjects = @()
$AllBalanceObjects = @()
$Earnings = @()

While ($true) { 
    If ($Config.BalancesTrackerPollInterval -gt 0) { 

        # Get pools to track
        $PoolsToTrack = @(Get-ChildItem ".\Balances\*.ps1" -File).BaseName -replace "24hr$" -replace "Coins$" | Sort-Object -Unique

        # Only on first run
        If (-not $Now) { 
            Write-Message -Level Info "Balances Tracker started."

            $Balances = [Ordered]@{ }
            $BalanceObjects = @()
            $AllBalanceObjects = @()
            $Earnings = @()

            # Get pools data
            $PoolData = Get-Content ".\Includes\PoolData.json" | ConvertFrom-Json

            # Read existing earning data, use data from last file
            ForEach ($Filename in Get-ChildItem ".\Logs\BalancesTrackerData*.json" | Sort-Object -Descending) {
                $AllBalanceObjects = (Get-Content $Filename | ConvertFrom-Json ) | Where-Object Balance -NE $null
                If ($AllBalanceObjects.Count -gt ($PoolData.Count / 2)) { 
                    $Variables.BalanceData = $AllBalanceObjects
                    Break
                }
            }
            If ($AllBalanceObjects -isnot [Array]) { $AllBalanceObjects = @() }
            Else { $AllBalanceObjects | ForEach-Object { $_.DateTime = [DateTime]$_.DateTime } }

            # Read existing earning data, use data from last file
            ForEach($Filename in (Get-ChildItem ".\Logs\DailyEarnings*.csv" | Sort-Object -Descending)) { 
                $Earnings = @(Import-Csv $FileName -ErrorAction SilentlyContinue)
                If ($Earnings.Count -gt ($PoolData.Count / 2)) { Break }
            }
            If ($Earnings -isnot [Array]) { $Earnings = @() }
        }

        If ($Now.Date -ne (Get-Date).Date) {
            # Keep a copy on start & at date change
            If (Test-Path -Path ".\Logs\BalancesTrackerData.json" -PathType Leaf) { Copy-Item -Path ".\Logs\BalancesTrackerData.json" -Destination ".\Logs\BalancesTrackerData_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").json" }
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { Copy-Item -Path ".\Logs\DailyEarnings.csv" -Destination ".\Logs\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").csv" }
            # If (-not (Test-Path -Path ".\NemosMiner_Dev.ps1")) { 
                # Keep only the last 3 logs
                Get-ChildItem ".\Logs\BalancesTrackerData_*.json" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
                Get-ChildItem ".\Logs\DailyEarnings_*.csv" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
            # }
        }

        $Now = (Get-Date).ToLocalTime()

        # Fetch balances data from pools
        Write-Message "Balances Tracker is requesting data ($($PoolsToTrack -join ', '))..."
        $PoolsToTrack | ForEach-Object { 
            $BalanceObjects += @(& ".\Balances\$($_).ps1")
        }

        # Keep most recent balance objects, keep empty balances for 7 days
        $BalanceObjects = @(@($BalanceObjects + $AllBalanceObjects) | Where-Object { $_.Unpaid -gt 0 -or (($_.Pending -gt 0 -or $_.Balance -gt 0) -and $_.DateTime -gt $Now.AddDays( -7 )) } | Where-Object { $_.Wallet } | Group-Object Pool, Currency, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime | Select-Object -Last 1 })

        # Fix for pool reporting incorrect currency, e.g ZergPool ZER instead of BTC
        $BalanceObjects = @($BalanceObjects | Where-Object { $_.Pool -match "^MiningPoolHub(|Coins)$|^ProHashing(|24h)$" }) + @($BalanceObjects | Where-Object { $_.Pool -notmatch "^MiningPoolHub(|Coins)$|^ProHashing(|24h)$" } | Group-Object Pool, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime | Select-Object -Last 1 })

        # Read exchange rates
        $Variables.BalancesCurrencies = @($BalanceObjects.Currency | Select-Object -Unique)
        $Variables.AllCurrencies = @(@($Config.Currency) + @($Config.Wallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies | Sort-Object -Unique) | Select-Object -Unique)
        Get-Rate

        $BalanceObjects | Where-Object { $_.DateTime.ToLocalTime() -gt $Now } | ForEach-Object { 
            $PoolBalanceObject = $_

            $PoolConfig = $Config.PoolsConfig.($PoolBalanceObject.Pool)

            $PoolBalanceObjects = @($AllBalanceObjects | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Sort-Object DateTime)

            # Get threshold currency and value
            $PayoutThresholdCurrency = $PoolBalanceObject.Currency
            $PayoutThreshold = $PoolBalanceObject.PayoutThreshold

            If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($PoolConfig.PayoutThreshold.$PayoutThresholdCurrency) }

            If (-not $PayoutThreshold -and $PoolBalanceObject.Currency -eq "BTC") { 
                $PayoutThresholdCurrency = "mBTC"
                $PayoutThreshold = [Double]($PoolConfig.PayoutThreshold.$PayoutThresholdCurrency)
            }

            If (-not $PayoutThreshold) { 
                $PayoutThreshold = [Double]($PoolConfig.PayoutThreshold."*")
            }

            If ($PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC -eq $true) { 
                $PayoutThresholdCurrency = "mBTC"
                $PayoutThreshold *= 1000
            }

            $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = $GrowthToday = $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = $Delta = $Payout = $HiddenPending = [Double]0

            If ($PoolBalanceObjects.Count -eq 0) { 
                $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObject.Unpaid))
                $PoolBalanceObject | Add-Member Payout ([Double](0))
                $PoolBalanceObject | Add-Member Total ([Double]($PoolBalanceObject.Unpaid))
                $PoolBalanceObject | Add-Member Delta ([Double]0)

                $PoolBalanceObjects += $PoolBalanceObject
                $AllBalanceObjects += $PoolBalanceObject

                $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = 0
            }
            Else { 
                If ($PoolBalanceObject.Pool -like "NiceHash*") { 
                    If ($PoolBalanceObject.Withdrawal -gt 0) { 
                        # NiceHash temporarily reduces 'Balance' value before paying out
                        $PoolBalanceObject.Balance += $PoolBalanceObject.Withdrawal
                        $Payout = 0
                    }
                    ElseIf (($PoolBalanceObjects | Select-Object -Last 1).Withdrawal -gt 0 -and $PoolBalanceObject.Withdrawal -eq 0) { 
                        # Payout occurred
                        $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Withdrawal
                    }
                    ElseIf ($PoolBalanceObject.Withdrawal -eq 0) { 
                        # NiceHash temporarily hides some 'pending' value while processing payouts
                        If ($PoolBalanceObject.Pending -lt ($PoolBalanceObjects | Select-Object -Last 1).Pending) { 
                            $HiddenPending = ($PoolBalanceObjects | Select-Object -Last 1).Pending - $PoolBalanceObject.Pending
                            $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                        }
                        # When payouts are processed the hidden pending value gets added to the balance
                        If (($PoolBalanceObjects | Select-Object -Last 1).HiddenPending -gt 0) { 
                            If ($PoolBalanceObject.Balance -eq (($PoolBalanceObjects | Select-Object -Last 1).Balance)) { 
                                # Payout processing complete
                                $HiddenPending *= -1
                            }
                            Else { 
                                # Still processing payouts
                                $HiddenPending = ($PoolBalanceObjects | Select-Object -Last 1).HiddenPending
                                $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                            }
                        }
                        If (($PoolBalanceObjects | Select-Object -Last 1).Unpaid -gt $PoolBalanceObject.Unpaid) { 
                            $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Unpaid - $PoolBalanceObject.Unpaid
                        }
                        Else { 
                            $Payout = 0
                        }
                    }
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta + $HiddenPending + $Payout)
                }
                ElseIf ($PoolBalanceObject.Pool -match "^MiningPoolHub(|Coins)$") { 
                    # MiningHubPool never reduces earnings
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    If ($Delta -lt 0) { 
                        # Payout occured
                        $Payout = $Delta * -1
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                ElseIf ($PoolBalanceObject.Pool -match "^ProHashing.*") { 
                    # Pool never reduces earnings
                    $Delta = $PoolBalanceObject.Balance - ($PoolBalanceObjects | Select-Object -Last 1).Balance
                    If ($PoolBalanceObject.Unpaid -lt ($PoolBalanceObjects | Select-Object -Last 1).Unpaid) { 
                        # Payout occured
                        $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Unpaid - $PoolBalanceObject.Unpaid
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $PoolBalanceObject.Unpaid)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                Else { 
                    # AHashPool, BlockMasters, BlazePool, HiveON, NLPool, ZergPool, ZPool
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    # Current 'Unpaid' is smaller
                    If ($Delta -lt 0) { 
                        If (($Delta * -1) -gt $(If ($PayoutThresholdCurrency -eq "mBTC") { $PayoutThreshold / 1000 } Else { $PayoutThreshold }) * 0.5) { 
                            # Payout occured (delta > 50% of payout limit)
                            $Payout = $Delta * -1
                        }
                        Else { 
                            # Pool reduced earnings
                            $Payout = $Delta = 0
                        }
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                $PoolBalanceObject | Add-Member Payout ([Double]$Payout)
                $PoolBalanceObject | Add-Member Paid ([Double](($PoolBalanceObjects.Paid | Measure-Object -Maximum).Maximum + $Payout)) -Force
                $PoolBalanceObject | Add-Member Delta ([Double]$Delta)

                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -lt 1) { 
                    # Only calculate if current balance data
                    If (($PoolBalanceObject.DateTime).ToLocalTime() -gt $Now.AddMinutes( -1 )) { 
                        $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = [Double]($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings)
                    }
                }
                Else { 
                    # Only calculate if current balance data
                    If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -1 ) })   { $Growth1 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -1 ) } | Sort-Object Date | Select-Object -Index 0).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -6 ) })   { $Growth6 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -6 ) } | Sort-Object Date | Select-Object -Index 0).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -24 ) })  { $Growth24 =  [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -24 ) } | Sort-Object Date | Select-Object -Index 0).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -168 ) }) { $Growth168 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -168 ) } | Sort-Object Date | Select-Object -Index 0).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -720 ) }) { $Growth720 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -ge $Now.AddHours( -720 ) } | Sort-Object Date | Select-Object -Index 0).Earnings) }
                }


                If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -lt $Now.AddHours( -1 ) } ) { 
                    $AvgHourlyGrowth = [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalHours)
                }
                Else {
                    $AvgHourlyGrowth = $Growth1
                }
                If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -lt $Now.AddDays( -1 ) }) { 
                    $AvgDailyGrowth = [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalDays)
                }
                Else { 
                    $AvgDailyGrowth = $Growth24
                }
                If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime() -lt $Now.AddDays( -7 ) } ) { 
                    $AvgWeeklyGrowth = [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalDays * 7)
                }
                Else { 
                    $AvgWeeklyGrowth = $Growth168
                }

                If ($PoolBalanceObjects | Where-Object { ($_.DateTime).ToLocalTime().Date -eq $Now.Date }) { 
                    $GrowthToday = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime.ToLocalTime().Date -eq $Now.Date } | Sort-Object Date | Select-Object -Index 0).Earnings)
                    If ($GrowthToday -lt 0) { $GrowthToday = 0 } # to avoid negative numbers
                }

                $PoolBalanceObjects += $PoolBalanceObject
                $AllBalanceObjects += $PoolBalanceObject
            }

            $Balances."$($PoolBalanceObject.Pool) ($($PoolBalanceObject.Currency):$($PoolBalanceObject.Wallet))" = $EarningsObject = [PSCustomObject]@{ 
                Pool                    = $PoolBalanceObject.Pool
                Wallet                  = $PoolBalanceObject.Wallet
                Currency                = $PoolBalanceObject.Currency
                Start                   = $PoolBalanceObjects[0].DateTime
                LastUpdated             = $PoolBalanceObject.DateTime
                Pending                 = [Double]$PoolBalanceObject.Pending
                Balance                 = [Double]$PoolBalanceObject.Balance
                Unpaid                  = [Double]$PoolBalanceObject.Unpaid
                Earnings                = [Double]$PoolBalanceObject.Earnings
                Delta                   = [Double]$PoolBalanceObject.Delta
                Growth1                 = [Double]$Growth1
                Growth6                 = [Double]$Growth6
                Growth24                = [Double]$Growth24
                Growth168               = [Double]$Growth168
                Growth720               = [Double]$Growth720
                GrowthToday             = [Double]$GrowthToday
                AvgHourlyGrowth         = [Double]$AvgHourlyGrowth
                AvgDailyGrowth          = [Double]$AvgDailyGrowth
                AvgWeeklyGrowth         = [Double]$AvgWeeklyGrowth
                EstimatedEndDayGrowth   = If ((($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalHours) -ge 1) { [Double]($AvgHourlyGrowth * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                EstimatedPayDate        = If ($PayoutThreshold) { If ([Double]($PoolBalanceObject.Unpaid) -lt ($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency))) { If (($AvgDailyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-7) { [DateTime]($Now.AddDays(($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency) - $PoolBalanceObject.Unpaid) / ((($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum))) } Else { "Unknown" } } Else { If ($PoolBalanceObject.NextPayout) { $PoolBalanceObject.NextPayout.ToLocalTime() } Else { "Next Payout!" } } } Else { "Unknown" }
                TrustLevel              = [Double](((($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum)
                TotalHours              = [Double](($Now - ($PoolBalanceObjects[0].DateTime).ToLocalTime()).TotalHours)
                PayoutThresholdCurrency = $PayoutThresholdCurrency
                PayoutThreshold         = [Double]$PayoutThreshold
                Payout                  = [Double]$PoolBalanceObject.Payout
                Uri                     = $PoolBalanceObject.Url
            }

            If ($Config.BalancesTrackerLog -eq $true) { 
                $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -ErrorAction Ignore
            }

            $PoolTodayEarning = $Earnings | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Select-Object -Last 1

            If ([String]$PoolTodayEarning.Date -eq $Now.ToString("yyyy-MM-dd")) { 
                $PoolTodayEarning.DailyEarnings = [Double]$GrowthToday
                $PoolTodayEarning.EndTime = $Now.ToString("T")
                $PoolTodayEarning.EndValue = [Double]$PoolBalanceObject.Earnings
                $PoolTodayEarning.Balance = [Double]$PoolBalanceObject.Balance
                $PoolTodayEarning.Unpaid = [Double]$PoolBalanceObject.Unpaid
                $PoolTodayEarning.Payout = [Double]$PoolTodayEarning.Payout + [Double]$PoolBalanceObject.Payout
            }
            Else { 
                If ($PoolTodayEarning) { 
                    $StartValue = [Double]$PoolTodayEarning.EndValue
                }
                Else {
                    $StartValue = [Double]$EarningsObject.Earnings
                }

                $Earnings += [PSCustomObject]@{ 
                    Date          = $Now.ToString("yyyy-MM-dd")
                    Pool          = $EarningsObject.Pool
                    Currency      = $EarningsObject.Currency
                    Wallet        = $PoolBalanceObject.Wallet
                    DailyEarnings = [Double]$GrowthToday
                    StartTime     = $Now.ToString("T")
                    StartValue    = [Double]$StartValue
                    EndTime       = $Now.ToString("T")
                    EndValue      = [Double]$EarningsObject.Earnings
                    Balance       = [Double]$EarningsObject.Balance
                    Pending       = [Double]$EarningsObject.Pending
                    Unpaid        = [Double]$EarningsObject.Unpaid
                    Payout        = [Double]0
                }
            }

            Remove-Variable PoolTodayEarning -ErrorAction Ignore
            Remove-Variable EarningsObject -ErrorAction Ignore
        }

        # Always keep pools sorted, even when new pools were added
        $Variables.Balances = [Ordered]@{ }
        $Balances.Keys | Sort-Object | ForEach-Object { 
            $Variables.Balances.$_ = $Balances.$_
        }

        Try { 
            $Earnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force -ErrorAction Ignore
        }
        Catch { 
            Write-Message -Level Warn "Balances Tracker failed to save earnings data to '.\Logs\DailyEarnings.csv' (should have $($Earnings.count) entries)."
        }

        # Build chart data (used in Web GUI) for last 30 days
        $PoolChartData = [PSCustomObject]@{ }
        $ChartData = $Earnings | Sort-Object Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        $ChartData.Group.Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolChartData | Add-Member @{ $_ = [Double[]]@() }
        }

        # Fill dataset
        ForEach ($PoolEarnings in $ChartData) { 
            $PoolChartData | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $PoolChartData.$_ += ($PoolEarnings.Group | Where-Object Pool -EQ $_ | ForEach-Object { [Double]($_.DailyEarnings) * $Variables.Rates.($_.Currency).BTC } | Measure-Object -Sum).Sum
            }
        }

        $Variables.EarningsChartData = [PSCustomObject]@{
            # CumulatedEarnings = $CumulatedEarnings 
            Currency = ($Config.Currency | Select-Object -Index 0)
            BTCrate = ([Double]($Variables.Rates.BTC.($Config.Currency | Select-Object -Index 0)))
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            # Use dates for x-axis label
            Pools = $PoolChartData
        }

        $Variables.EarningsChartData | ConvertTo-Json | Out-File ".\Logs\EarningsChartData.json" -Encoding UTF8 -ErrorAction Ignore

        # At least 31 days are needed for Growth720
        # For data older 1 week only keep those with delta <> 0
        If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = @($AllBalanceObjects | Where-Object DateTime -GE $Now.AddDays( -31 ) | Where-Object { $_.DateTime -ge $Now.AddDays( -7 ) -or $_.Delta -ne 0 }) }
        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" -ErrorAction Ignore }
        $Variables.BalanceData = $AllBalanceObjects

    }

    If ($ReadBalances) { Return } # Debug stuff

    # Sleep until next update (at least 1 minute, maximum 60 minutes)
    While ((Get-Date).ToLocalTime() -le $Now.AddMinutes((60, (1, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum).Minimum)) { Start-Sleep -Seconds 1 }
}

Write-Message "Balances Tracker stopped."
