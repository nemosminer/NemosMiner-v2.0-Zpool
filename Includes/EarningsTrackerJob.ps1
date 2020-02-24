<#
Copyright (c) 2018 MrPlus
EarningsTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           EarningsTrackerJob.ps1
version:        3.8.1.3
version date:   12 November 2019
#>

# To start the job one could use the following
# $job = Start-Job -FilePath .\EarningTrackerJob.ps1 -ArgumentList $params
# Remove progress info from job.childjobs.Progress to avoid memory leak
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }

If ($WorkingDirectory) { Set-Location $WorkingDirectory }

#Start the log
Start-Transcript -Path ".\Logs\EarningTracker-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force | Out-Null

If (Test-Path ".\Logs\EarningTrackerData.json") { $AllBalanceObjects = (Get-Content ".\logs\EarningTrackerData.json" | ConvertFrom-Json) } Else { $AllBalanceObjects = @() }

$BalanceObjects = @()
$TrustLevel = 0
$StartTime = $LastAPIUpdateTime = Get-Date

While ($true) { 

    #Read Config (ie. Pools to track)
    $EarningsTrackerConfig = Get-content ".\Config\EarningTrackerConfig.json" | ConvertFrom-JSON
    $Interval = $EarningsTrackerConfig.PollInterval
    
    #Filter pools variants
    $TrackPools = @(($EarningsTrackerConfig.pools) -replace "24hr" -replace "coins") | Sort-Object -Unique

    # Get pools api ref
    If (-not $PoolAPI -or ($LastAPIUpdateTime -le (Get-Date).AddDays(-1))) { 
        Try { 
            $PoolAPI = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapiref.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            $PoolAPI | ConvertTo-json | Out-File ".\Config\poolapiref.json" -Force
            $LastAPIUpdateTime = Get-Date
        }
        Catch { $PoolAPI = Get-content ".\Config\poolapiref.json" | Convertfrom-Json }
    }

    #For each pool in config
    #Go loop
    $PoolAPI | Where-Object { $_.EarnTrackSupport -eq "yes" } | Where-Object { $_.Name -in $TrackPools } | ForEach-Object { 
        $Pool = $_.Name -replace "24hr" -replace "coins"
        $APIUri = $_.WalletUri
        $PaymentThreshold = $_.PaymentThreshold
        $BalanceJson = $_.Balance
        $TotalJson = $_.Total

        $ConfName = If ($PoolsConfig.$Pool -ne $null) { $Pool } Else { "default" }
        $PoolConf = $PoolsConfig.$ConfName

        If ($Pool -eq "mph") { 
            $Wallet = $PoolConf.APIKey
        }
        Else { 
            $Wallet = $PoolConf.Wallet
        }

        $CurDate = Get-Date

        Switch ($Pool) { 
            "nicehashV2" { 
                Try { 
                    $TempBalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)/rigs") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json 
                }
                Catch { }
                [Double]$NHTotalBalance = [Double]($TempBalanceData.unpaidAmount) + [Double]($TempBalanceData.externalBalance)
                $TempBalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue $NHTotalBalance -Force
                $TempBalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue $NHTotalBalance -Force
            }
            "mph" { 
                Try { 
                    $TempBalanceData = ((((Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" }).content | ConvertFrom-Json).getuserallbalances).data | Where-Object { $_.coin -eq "bitcoin" }) }
                Catch { } #.confirmed
            }
            default { 
                Try { 
                    $TempBalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json 
                }
                Catch { }
            }
        }
        If ($TempBalanceData.$TotalJson -gt 0) { 
            $BalanceData = $TempBalanceData
            $AllBalanceObjects += [PSCustomObject]@{ 
                Pool         = $Pool
                Date         = $CurDate.ToLocalTime()
                balance      = $BalanceData.$BalanceJson
                unsold       = $BalanceData.unsold
                total_unpaid = $BalanceData.total_unpaid
                total_paid   = $BalanceData.total_paid
                total_earned = ($BalanceData.$BalanceJson, $BalanceData.$TotalJson | Measure-Object -Minimum).Minimum # Pool reduced earnings!
                currency     = $BalanceData.currency
            }

            $BalanceObjects = @($AllBalanceObjects | Where-Object { $_.Pool -eq $Pool } | Sort-Object Date)
            $BalanceObject = $BalanceObjects | Select-Object -Last 1

            If ((($CurDate - ($BalanceObjects[0].Date)).TotalMinutes) -eq 0) { $CurDate = $CurDate.AddMinutes(1) }
            If ((($CurDate - ($BalanceObjects[0].Date)).TotalDays) -ge 1) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth24 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddDays(-1) }).total_earned | Measure-Object -Minimum).Minimum
            }
            If ((($CurDate - ($BalanceObjects[0].Date)).TotalDays) -lt 1) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth24 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDate - ($BalanceObjects[0].Date)).TotalHours) * 24
            }
            If ((($CurDate - ($BalanceObjects[0].Date)).TotalHours) -lt 6) { 
                $Growth1 = $BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                $Growth6 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDate - ($BalanceObjects[0].Date)).TotalHours) * 6
            }
            If ((($CurDate - ($BalanceObjects[0].Date)).TotalHours) -lt 1) { 
                $Growth1 = (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDate - ($BalanceObjects[0].Date)).TotalMinutes) * 60
            }

            $AvgBTCHour = If ((($CurDate - ($BalanceObjects[0].Date)).TotalHours) -ge 1) { (($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($CurDate - ($BalanceObjects[0].Date)).TotalHours) } Else { $Growth1 }
            $EarningsObject = [PSCustomObject]@{ 
                Pool                  = $pool
                Wallet                = $Wallet
                Date                  = $CurDate
                StartTime             = $BalanceObjects[0].Date
                balance               = $BalanceObject.balance
                unsold                = $BalanceObject.unsold
                total_unpaid          = $BalanceObject.total_unpaid
                total_paid            = $BalanceObject.total_paid
                total_earned          = $BalanceObject.total_earned
                currency              = $BalanceObject.currency
                GrowthSinceStart      = $BalanceObject.total_earned - $BalanceObjects[0].total_earned
                Growth1               = $Growth1
                Growth6               = $Growth6
                Growth24              = $Growth24
                AvgHourlyGrowth       = $AvgBTCHour
                BTCD                  = $AvgBTCHour * 24
                EstimatedEndDayGrowth = If ((($CurDate - ($BalanceObjects[0].Date)).TotalHours) -ge 1) { ($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours) } Else { $Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours }
                EstimatedPayDate      = If ($PaymentThreshold) { If ($BalanceObject.balance -lt $PaymentThreshold) { If ($AvgBTCHour -gt 0) { $CurDate.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour) } Else { "Unknown" } } Else { "Next Payout !" } } Else { "Unknown" }
                TrustLevel            = $((($CurDate - ($BalanceObjects[0].Date)).TotalMinutes / 360), 1 | Measure-Object -Minimum).Minimum
                PaymentThreshold      = $PaymentThreshold
                TotalHours            = ($CurDate - ($BalanceObjects[0].Date)).TotalHours
            }
            $EarningsObject
            If ($EarningsTrackerConfig.EnableLog) { $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\EarningTrackerLog.csv" }

            # Read existing earning data
            $DailyEarnings = @()
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue) }

            #Fix typo in field name, convert date format
            If ($DailyEarnings.PrePaimentDayValue | Select-Object) { 
                $DailyEarnings = $DailyEarnings | ForEach-Object  { 
                    [PSCustomObject]@{
                        Date               = [DateTime]::parseexact($_.Date, "MM/dd/yyyy", $null).ToShortDateString()
                        Pool               = $_.Pool
                        DailyEarnings      = $_.DailyEarnings
                        StartTime          = ([DateTime]($_.FirstDayDate)).ToLongTimeString()
                        StartValue         = $_.FirstDayValue
                        EndTime            = ([DateTime]($_.LastDayDate)).ToLongTimeString()
                        EndValue           = $_.LastDayValue
                        PrePaymentDayValue = $_.PrePaimentDayValue
                        Balance            = $_.Balance
                        BTCD               = $_.BTCD
                    }
                }
                $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force
            }

            if ($DailyEarning = $DailyEarnings | Where-Object { [DateTime]$_.Date -match $CurDate.ToShortDateString() -and $_.Pool -eq $Pool }) {
                # pool may have reduced estimated balance, use new balance as start value to avoid negative values
                $DailyEarning.StartValue = ($DailyEarning.StartValue, $BalanceObject.total_earned | Measure-Object -Minimum).Minimum
                $DailyEarning.DailyEarnings = $BalanceObject.total_earned - $DailyEarning.StartValue
                $DailyEarning.EndTime = $BalanceObject.Date.ToLongTimeString()
                $DailyEarning.EndValue = $BalanceObject.total_earned
                If ($BalanceObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { 
                    $DailyEarning.PrePaymentDayValue = $BalanceObjects[$BalanceObjects.Count - 2].total_earned
                    If ($DailyEarning.PrePaymentDayValue -gt 0) { 
                        #Payment occured
                        $DailyEarning.DailyEarnings += $DailyEarning.PrePaymentDayValue
                    }
                }
                $DailyEarning.Balance = $BalanceObject.balance
                $DailyEarning.BTCD = $BalanceObject.Growth24
                Remove-Variable DailyEarning
            }
            Else { 
                $DailyEarnings += [PSCustomObject]@{ 
                    Date               = $CurDate.ToShortDateString()
                    Pool               = $Pool
                    DailyEarnings      = 0
                    StartTime          = $BalanceObject.Date.ToLongTimeString()
                    StartValue         = $BalanceObject.total_earned
                    EndTime            = $BalanceObject.Date.ToLongTimeString()
                    EndValue           = $BalanceObject.total_earned
                    PrePaymentDayValue = 0
                    Balance            = $BalanceObject.Balance
                    BTCD               = $BalanceObject.Growth24
                }
            }
            $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force
            # Some pools do reset "Total" after payment (zpool)
            # Results in showing bad negative earnings
            # Detecting if current is more than 50% less than previous and reset history if so
            If ($BalanceObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Pool -ne $Pool }; $AllBalanceObjects += $BalanceObject }
            Remove-Variable TempBalanceData
        }
    }

    If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Date -ge $CurDate.AddDays(-7) } }

    # Save data only at defined interval. Limit disk access
    If ((Get-Date) -gt $WriteAt) { 
        $WriteAt = (Get-Date).AddMinutes($EarningsTrackerConfig.WriteEvery)
        If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects | ConvertTo-JSON | Out-File ".\Logs\EarningTrackerData.json" }
    }

    # Sleep until next update based on $Interval. Modulo $Interval.
    # Sleep (60*($Interval-((get-date).minute%$Interval))) # Changed to avoid pool API load.
    If (($EarningsObject.Date - $EarningsObject.StartTime).TotalMinutes -le 20) { 
        $Sleep = [Int](60 * ($Interval / 2))
    }
    Else { 
        $Sleep = [Int](60 * ($Interval))
    }

    #Sleep at least 30 seconds
    Start-Sleep (30, $Sleep | Measure-Object -Maximum).Maximum
    Remove-Variable Sleep
}
