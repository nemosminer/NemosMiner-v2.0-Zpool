<#
Copyright (c) 2018-2020 Nemo

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
File:           NemosMiner.ps1
version:        3.8.1.3
version date:   07 February 2020
#>

param(
    [Parameter(Mandatory = $false)]
    [String]$Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE", 
    [Parameter(Mandatory = $false)]
    [String]$UserName = "Nemo", 
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = "ID=NemosMiner-v3.8.1.3", 
    [Parameter(Mandatory = $false)]
    [Int]$API_ID = 0, 
    [Parameter(Mandatory = $false)]
    [String]$API_Key = "", 
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 240, #seconds before between cycles after the first has passed 
    [Parameter(Mandatory = $false)]
    [Int]$FirstInterval = 120, #seconds of the first cycle of activated or started first time miner
    [Parameter(Mandatory = $false)]
    [Int]$StatsInterval = 270, #seconds of current active to gather hashrate if not gathered yet
    [Parameter(Mandatory = $false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, 
    [Parameter(Mandatory = $false)]
    [Array]$Type = "nvidia", #AMD/NVIDIA/CPU
    [Parameter(Mandatory = $false)]
    [String]$SelGPUDSTM = "0 1",
    [Parameter(Mandatory = $false)]
    [String]$SelGPUCC = "0,1",
    [Parameter(Mandatory = $false)]
    [Array]$Algorithm = $null, #i.e. Ethash,Equihash,Cryptonight ect.
    [Parameter(Mandatory = $false)]
    [Array]$MinerName = $null, 
    [Parameter(Mandatory = $false)]
    [Array]$PoolName = $null, 
    [Parameter(Mandatory = $false)]
    [Array]$Currency = ("USD"), #i.e. GBP,USD,AUD,NZD ect.
    [Parameter(Mandatory = $false)]
    [Array]$Passwordcurrency = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 14, #Minutes per Day
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 1, #seconds before opening each miner
    [Parameter(Mandatory = $false)]
    [Int]$GPUCount = 1, # Number of GPU on the system
    [Parameter(Mandatory = $false)]
    [Int]$ActiveMinerGainPct = 21, # percent of advantage that active miner has over candidates in term of profit
    [Parameter(Mandatory = $false)]
    [Float]$MarginOfError = 0, #0.4, # knowledge about the past wont help us to predict the future so don't pretend that Week_Fluctuation means something real
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "Light", # Light or Full. Defines level of info displayed
    [Parameter(Mandatory = $false)]
    [Bool]$TrackEarnings = $True, # Display earnings information
    [Parameter(Mandatory = $false)]
    [Bool]$Autoupdate = $True, # Autoupdate
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\config.json",
    [Parameter(Mandatory = $false)]
    [Int]$APIPort = 3999
)

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

. .\Includes\include.ps1
. .\Includes\Core.ps1

@"
NemosMiner
Copyright (c) 2018-$((Get-Date).Year) Nemo and MrPlus
This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

"@
Write-Host -F Yellow " Copyright and license notices must be preserved."
@"
"@

# Load Branding
$Branding = [PSCustomObject]@{ 
    LogoPath     = "https://raw.githubusercontent.com/Minerx117/UpDateData/master/NM.png"
    BrandName    = "NemosMiner"
    BrandWebSite = "https://nemosminer.com"
    ProductLabel = "NemosMiner"
}

# #Start the log
# Start-Transcript ".\Logs\$($Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"
# Write-Log "Starting $($Branding.ProductLabel) © 2018-$((Get-Date).Year) Nemo and MrPlus"

#Initialize variables
New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
New-Variable Variables ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
New-Variable Stats ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop

$Variables | Add-Member -Force -MemberType ScriptProperty -Name 'StatusText' -Value { $this._StatusText; $This._StatusText = @() } -SecondValue { If (!$this._StatusText) { $this._StatusText = @() } ; $this._StatusText += $args[0]; $Variables | Add-Member -Force @{ RefreshNeeded = $True } }

#Initialize API (for debug purposes)
If (Test-Path -Path .\Includes\API.psm1 -PathType Leaf) { 
    Import-Module .\Includes\API.psm1
    Start-APIServer -Port $APIPort
}

Function Global:TimerUITick { 
    $TimerUI.Enabled = $False

    # If something (pause button, idle timer) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Variables.RestartCycle) { 
        $Variables.RestartCycle = $False
        Stop-Mining
        Start-Mining
        If ($Variables.Paused) { 
            $EarningsDGV.DataSource = [System.Collections.ArrayList]@()
            $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@()
            $WorkersDGV.DataSource = [System.Collections.ArrayList]@()
            $LabelBTCD.ForeColor = "Red"
            $TimerUI.Stop
        }
    }

    If ($Variables.RefreshNeeded -and $Variables.Started -and -not $Variables.Paused) { 
        If (-not $Variables.EndLoop) { Update-Status($Variables.StatusText) }
        # $TimerUI.Interval = 1

        $LabelBTCD.ForeColor = "Green"
        Start-ChildJobs

        $Variables.EarningsTrackerJobs | Where-Object { $_.state -eq "Running" } | ForEach-Object { 
            $EarnTrack = $_ | Receive-Job
            If ($EarnTrack) { 
                $EarnTrack | Where-Object { $_.Pool -ne "" } | Sort-Object date, pool | Select-Object -Last ($EarnTrack.Pool | Sort-Object -Unique).Count | ForEach-Object { 
                    If ($true) { 
                        #$_.Pool -in ($Config.PoolName -replace "24hr","" -replace "plus","")) { 
                        $Variables.EarningsPool = $_.Pool
                        $Variables.Earnings.($_.Pool) = $_
                    }
                }
                Remove-Variable EarnTrack
            }
        }

        If ((Compare-Object -ReferenceObject $CheckedListBoxPools.Items -DifferenceObject ((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq "=>" }).InputObject -gt 0) { 
            (Compare-Object -ReferenceObject $CheckedListBoxPools.Items -DifferenceObject ((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq "=>" }).InputObject | ForEach-Object { If ($_ -ne $null) { } $CheckedListBoxPools.Items.AddRange($_) }
            $Config.PoolName | ForEach-Object { $CheckedListBoxPools.SetItemChecked($CheckedListBoxPools.Items.IndexOf($_), $True) }
        }
        $Variables | Add-Member -Force @{ InCycle = $True }
        # $MainForm.Number +=1 
        $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion) Runtime: {0:dd\ \d\a\y\s\ hh\ \h\r\s\ mm\ \m\i\n\s} Path: $(Split-Path $script:MyInvocation.MyCommand.Path)" -f ([TimeSpan]((Get-Date) - $Variables.ScriptStartDate))
        $host.UI.RawUI.WindowTitle = $MainForm.Text

        If ($Variables.EndLoop) { 
            $SwitchingDisplayTypes = @()
            $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
            If (Test-Path ".\Logs\switching.log") { $SwitchingArray = [System.Collections.ArrayList]@(@((Get-Content ".\Logs\switching.log" -First 1) , (Get-Content ".\Logs\switching.log" -last 50)) | ConvertFrom-Csv | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Select-Object -Last 13) }
            $SwitchingDGV.DataSource = $SwitchingArray

            # Fixed memory leak to chart object not being properly disposed in 5.3.0
            # https://stackoverflow.com/questions/8466343/why-controls-do-not-want-to-get-removed

            If (Test-Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { 
                $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 105"
                $Chart1.top = 54
                $Chart1.left = 0
                $RunPage.Controls.Add($Chart1)
                $Chart1.BringToFront()

                $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 105"
                $Chart2.top = 54
                $Chart2.left = 500
                $RunPage.Controls.Add($Chart2)
                $Chart2.BringToFront()

                $RunPage.Controls | Where-Object { ($_.gettype()).name -eq "Chart" -and $_ -ne $Chart1 -and $_ -ne $Chart2 } | ForEach-Object { $RunPage.Controls[$RunPage.Controls.IndexOf($_)].Dispose(); $RunPage.Controls.Remove($_) }
            }

            If ($Variables.Earnings -and $Config.TrackEarnings) { 
                $DisplayEarnings = [System.Collections.ArrayList]@($Variables.Earnings.Values | Select-Object @(
                    @{ Name = "Pool"; Expression = { $_.Pool } },
                    @{ Name = "Trust"; Expression = { "{0:P0}" -f $_.TrustLevel } },
                    @{ Name = "Balance"; Expression = { [decimal]$_.Balance } },
                    @{ Name = "BTC/D"; Expression = { "{0:N8}" -f ($_.BTCD) } },
                    @{ Name = "m$([char]0x20BF) in 1h"; Expression = { "{0:N6}" -f ($_.Growth1 * 1000 * 24) } },
                    @{ Name = "m$([char]0x20BF) in 6h"; Expression = { "{0:N6}" -f ($_.Growth6 * 1000 * 4) } },
                    @{ Name = "m$([char]0x20BF) in 24h"; Expression = { "{0:N6}" -f ($_.Growth24 * 1000) } },
                    @{ Name = "Est. Pay Date"; Expression = { If ($_.EstimatedPayDate -is 'DateTime') { $_.EstimatedPayDate.ToShortDateString() } Else { $_.EstimatedPayDate } } },
                    @{ Name = "PaymentThreshold"; Expression = { "$($_.PaymentThreshold) ($('{0:P0} ' -f $($_.Balance / $_.PaymentThreshold)))" } }
                ) | Sort-Object "m$([char]0x20BF) in 1h", "m$([char]0x20BF) in 6h", "m$([char]0x20BF) in 24h" -Descending)
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEarnings)
                $EarningsDGV.ClearSelection()
            }

            If ($Variables.Miners) { 
                $DisplayEstimations = [System.Collections.ArrayList]@($Variables.Miners | Select-Object @(
                    @{ Name = "Miner"; Expression = { $_.Name } },
                    @{ Name = "Algorithm(s)"; Expression = { $_.HashRates.PSObject.Properties.Name -join ' & ' } },
                    @{ Name = "Speed"; Expression = { ($_.HashRates.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { "$($_ | ConvertTo-Hash)/s" -replace '  ', ' ' } Else { "Benchmarking" } }) -join ' & ' } },
                    @{ Name = "mBTC/Day"; Expression = { ($_.Profits.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { ($_ * 1000).ToString("N3") } Else { "Benchmarking" } }) -join ' + ' } },
                    @{ Name = "$($Config.Currency)/Day"; Expression = { ($_.Profits.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { ($_ * ($Variables.Rates.($Config.Currency))).ToString("N3") } Else { "Benchmarking" } }) -join ' + ' } },
                    @{ Name = "BTC/GH/Day"; Expression = { ($_.Pools.PSObject.Properties.Value.Price | ForEach-Object { ($_ * 1000000000).ToString("N5") }) -join ' + ' } },
                    @{ Name = "Pool(s)"; Expression = { ($_.Pools.PSObject.Properties.Value | ForEach-Object { (@($_.Name | Select-Object) + @($_.Coin | Select-Object)) -join '-' }) -join ';' } }
                ) | Sort-Object "mBTC/Day" -Descending)
                $EstimationsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEstimations)
            }
            $EstimationsDGV.ClearSelection()

            $SwitchingDGV.ClearSelection()

            If ($Variables.Workers -and $Config.ShowWorkerStatus) { 
                $DisplayWorkers = [System.Collections.ArrayList]@($Variables.Workers | Select-Object @(
                    @{ Name = "Worker"; Expression = { $_.worker } },
                    @{ Name = "Status"; Expression = { $_.status } },
                    @{ Name = "Last Seen"; Expression = { $_.timesincelastreport } },
                    @{ Name = "Version"; Expression = { $_.version } },
                    @{ Name = "Est. BTC/Day"; Expression = { [decimal]$_.profit } },
                    @{ Name = "Miner"; Expression = { $_.data.name -join ',' } },
                    @{ Name = "Pool"; Expression = { $_.data.pool -join ',' } },
                    @{ Name = "Algo(s)"; Expression = { $_.data.algorithm -join ',' } },
                    @{ Name = "Speed(s)"; Expression = { If ($_.data.currentspeed) { ($_.data.currentspeed | ConvertTo-Hash) -join ',' } Else { "" } } },
                    @{ Name = "Benchmark Speed"; Expression = { If ($_.data.estimatedspeed) { ($_.data.estimatedspeed | ConvertTo-Hash) -join ',' } Else { "" } } }
                ) | Sort-Object "Worker Name")
                $WorkersDGV.DataSource = [System.Collections.ArrayList]@($DisplayWorkers)

                # Set row color
                $WorkersDGV.Rows | ForEach-Object { 
                    If ($_.DataBoundItem.Status -eq "Offline") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 213, 142, 176)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Paused") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 247, 252, 168)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Running") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 127, 191, 144)
                    }
                    Else { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
                    }
                }

                $WorkersDGV.ClearSelection()
                $LabelMonitoringWorkers.text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"
            }

            If ($Variables.ActiveMinerPrograms) { 
                # $MinerHosts = $_.Algorithm | ForEach-Object {
                #     $Pools.$_
                #     "$($_)@$($Miner.PoolName | Select-Object -Index ([Array]::indexof($Miner.Algorithm, $_)))" }) -join "; ")}). "

                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@($Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" } | Select-Object Type, @{ Name = "Algorithm(s)"; Expression = { $_.Algorithms -join "; " } }, Name, @{ Name = "HashRate(s)"; Expression = { "$($_.HashRates | ConvertTo-Hash)/s" -join "; " } }, @{ Name = "Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.Active } }, @{ Name = "Total Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.TotalActive } }, @{ Name = "Host(s)"; Expression = { $($_.Host | Select-Object) -join '; '} }  | Sort-Object Type)
                $RunningMinersDGV.ClearSelection()
            
                [Array]$ProcessRunning = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" }
                If ($ProcessRunning -eq $null) { 
                    # Update-Status("No miner running")
                }
            }
            $LabelBTCPrice.text = If ($Variables.Rates.$($Config.Currency) -gt 0) { "1 BTC = $(($Variables.Rates.($Config.Currency)).ToString('n')) $($Config.Currency)" }
            $Variables | Add-Member -Force @{ InCycle = $False }

            If ($Variables.Earnings.Values -ne $Null) { 
                $LabelBTCD.Text = "Avg: " + ("{0:N6}" -f ($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum) + " $([char]0x20BF)/D   |   " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000)) + " m$([char]0x20BF)/D"
                
                $LabelEarningsDetails.Lines = @()
                # If ((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum*1000*24) -lt ((($Variables.Earnings.Values | Measure-Object -Property BTCD -Sum).sum*1000)*0.999)) { 
                # $LabelEarningsDetails.ForeColor = "Red" } Else { $LabelEarningsDetails.ForeColor = "Green" }
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  1h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24)) + " m$([char]0x20BF)/D " + $TrendSign
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  6h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4)) + " m$([char]0x20BF)/D " + $TrendSign
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property BTCD -Sum).sum * 1000 * 0.96), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last 24h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000)) + " m$([char]0x20BF)/D " + $TrendSign
                Remove-Variable TrendSign
            }
            Else { 
                $LabelBTCD.Text = "Waiting data from pools."
                $LabelEarningsDetails.Lines = @()
            }

            If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
            If (-not (IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }

            $Variables | Add-Member -Force @{ CurrentProduct = (Get-Content .\Version.json | ConvertFrom-Json).Product }
            $Variables | Add-Member -Force @{ CurrentVersion = [Version](Get-Content .\Version.json | ConvertFrom-Json).Version }
            $Variables | Add-Member -Force @{ CurrentVersionAutoUpdated = (Get-Content .\Version.json | ConvertFrom-Json).AutoUpdated.Value }
            If ((Get-Content .\Version.json | ConvertFrom-Json).AutoUpdated -and $LabelNotifications.Lines[$LabelNotifications.Lines.Count - 1] -ne "Auto Updated on $($Variables.CurrentVersionAutoUpdated)") { 
                $LabelNotifications.ForeColor = "Green"
                Update-Notifications("Running $($Variables.CurrentProduct) Version $([Version]$Variables.CurrentVersion)")
                Update-Notifications("Auto Updated on $($Variables.CurrentVersionAutoUpdated)")
            }

            #Display mining information
            If ($host.UI.RawUI.Keyavailable) { 
                $KeyPressed = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp"); Start-Sleep -Milliseconds 300; $host.UI.RawUI.FlushInputBuffer()
                If ($KeyPressed.KeyDown) { 
                    Switch ($KeyPressed.Character) { 
                        "s" { If ($Config.UIStyle -eq "Light") { $Config.UIStyle = "Full" } Else { $Config.UIStyle = "Light" } }
                        "e" { $Config.TrackEarnings = -not $Config.TrackEarnings }
                    }
                }
            }
            Clear-Host
            If ($Config.UIStyle -eq "Full" -and ([Array]$ProcessesIdle = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Run Miners" })) { 
                Write-Host "Run Miners: " $ProcessesIdle.Count
                $ProcessesIdle | Sort-Object { If ($_.Process -eq $null) { (Get-Date) } Else { $_.Process.ExitTime } } | Format-Table -Wrap (
                    @{ Label = "Run"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } },
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)" } }  
                ) | Out-Host
            }

            Write-Host "Exchange Rate: 1 BTC = $($Variables.Rates.($Config.Currency).ToString('n')) $($Config.Currency)"
            # Get and display earnings stats
            If ($Variables.Earnings -and $Config.TrackEarnings) { 
                $Variables.Earnings.Values | Sort-Object { $_.Pool } | ForEach-Object { 
                    Write-Host "+++++" $_.Wallet -B DarkBlue -F DarkGray -NoNewline; Write-Host " $($_.Pool)"
                    Write-Host "Trust Level:                $(($_.TrustLevel).ToString('P0'))" -NoNewline; Write-Host -F darkgray " (based on data from $(([DateTime]$_.Date - [DateTime]$_.StartTime).ToString('%d\ \d\a\y\s\ hh\ \h\r\s\ mm\ \m\i\n\s')))"
                    Write-Host "Average mBTC/Hour:          $(($_.AvgHourlyGrowth * 1000).ToString('N6'))"
                    Write-Host "Average mBTC/Day:" -NoNewline; Write-Host "           $(($_.BTCD * 1000).ToString('N6'))" -F Yellow
                    Write-Host "Balance mBTC:               $(($_.Balance).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold).ToString('N3')) BTC payment threshold)"
                    Write-Host "Balance $($Config.Currency):                $(($_.Balance * $Variables.Rates.($Config.Currency)).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold * $Variables.Rates.($Config.Currency)).ToString('n')) $($Config.Currency) payment threshold)"
                    Write-Host "Estimated Pay Date:         $(if ($_.EstimatedPayDate -is [DateTime]) { ($_.EstimatedPayDate).ToShortDateString() } Else { "$($_.EstimatedPayDate)" })"
                }
            }

            If ($Variables.Miners | Where-Object { $_.HashRates.PSObject.Properties.Value -eq $null }) { $Config.UIStyle = "Full" }

            If ($Config.UIStyle -eq "Full" -and $Variables.Miners) { 
                $Variables.Miners | Sort-Object -Descending Type, Profit | Format-Table -GroupBy Type (
                    @{ Label = "Miner"; Expression = { $_.Name -split '-' | Select-Object -Index 0 } }, 
                    @{ Label = "Algorithm(s)"; Expression = { $_.HashRates.PSObject.Properties.Name -join ' & ' } }, 
                    @{ Label = "Speed"; Expression = { (($_.HashRates.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { "$($_ | ConvertTo-Hash)/s" } Else { "Benchmarking" } }) -join ' & ') -replace '  ', ' ' } ; Align = 'right' }, 
                    @{ Label = "mBTC/Day"; Expression = { If ($_.Profit -ne $null) { ($_.Profit * 1000).ToString("N5") } Else { "Benchmarking" } } ; Align = 'right' }, 
                    @{ Label = "$($Config.Currency)/Day"; Expression = { If ($_.Profit -ne $null) { ($_.Profit * $Variables.Rates.($Config.Currency)).ToString("N3") } Else { "Benchmarking" } } ; Align = 'right' }, 
                    @{ Label = "BTC/GH/Day"; Expression = { ($_.Pools.PSObject.Properties.Value.Price | ForEach-Object { ($_ * 1000000000).ToString("N5") }) -join ' + ' } ; Align = 'right' },
                    @{ Label = "Pool(s)"; Expression = { ($_.Pools.PSObject.Properties.Value | ForEach-Object { (@($_.Name | Select-Object) + @($_.Coin | Select-Object)) -join '-' }) -join ' & ' } }
                ) | Out-Host
            }

            #Display active miners list
            If ([Array]$ProcessRunning = $Variables.ActiveMinerPrograms | Where-Object{ $_.Status -eq "Running" }) { 
                Write-Host "Running: $($ProcessRunning.Count)" 
                $ProcessRunning | Sort-Object { If ($_.Process -eq $null) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                    @{ Label = "Speed"; Expression = { (($_.HashRates | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '  ', ' ' } ; Align = 'right' }, 
                    @{ Label = "Active (this run)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { ((Get-Date) - $_.Process.StartTime) }) } },
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ($_.TotalActive + ((Get-Date) - $_.Process.StartTime) - $_.Active) } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }

            If ($Config.UIStyle -eq "Full" -and ([Array]$ProcessesIdle = $Variables.ActiveMinerPrograms | Where-Object { $_.Activated -and $_.Status -eq "Idle" })) { 
                Write-Host "Previously Executed:"
                $ProcessesIdle | Sort-Object { $_.Process.StartTime } -Descending | Select-Object -First ($Config.Type.Count * 3) | Format-Table -Wrap (
                    @{ Label = "Speed"; Expression = { (($_.HashRates | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ') -replace '  ', ' ' } ; Align = 'right' }, 
                    @{ Label = "Time since run"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { (Get-Date) - $_.Process.ExitTime }) } },
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalActive } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }

            If ($Config.UIStyle -eq "Full" -and ([Array]$ProcessesFailed = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Failed" })) { 
                Write-Host -ForegroundColor Red "Failed: $($ProcessesFailed.Count)"
                $ProcessesFailed | Sort-Object { If ($_.Process -eq $null) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                    @{ Label = "Speed"; Expression = { (($_.HashRates | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ') -replace '  ', ' ' } ; Align = 'right' }, 
                    @{ Label = "Time since fail"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { (Get-Date) - $_.Process.ExitTime }) } },
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalActive } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }
            Write-Host "--------------------------------------------------------------------------------"
            Write-Host -ForegroundColor Yellow "Last refresh: $((Get-Date).ToString('g'))   |   Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
            Update-Status($Variables.StatusText)
        }
        If (Test-Path ".\EndUIRefresh.ps1" -PathType Leaf) { Invoke-Expression (Get-Content ".\EndUIRefresh.ps1" -Raw) }

        $Variables.RefreshNeeded = $False
    }
    $TimerUI.Start()
}

Function Form_Load { 
    $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $LabelBTCD.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $MainForm.Number = 0
    $TimerUI.Add_Tick(
        { 
            # Timer never disposes objects until it is disposed
            $MainForm.Number = $MainForm.Number + 1
            $TimerUI.Stop()
            TimerUITick
            If ($MainForm.Number -gt 6000) { 
                # Write-Host -B R "Releasing Timer"
                $MainForm.Number = 0
                # $TimerUI.Stop()
                $TimerUI.Remove_Tick( { TimerUITick })
                $TimerUI.Dispose()
                $TimerUI = New-Object System.Windows.Forms.Timer
                $TimerUI.Add_Tick( { TimerUITick })
                # $TimerUI.Start()
            }
            $TimerUI.Start()
        }
    )
    $TimerUI.Interval = 50
    $TimerUI.Stop()
        
    If ($CheckBoxConsole.Checked) { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 0)
        Update-Status("Console window hidden")
    }
    Else { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 8)
        # Update-Status("Console window shown")
    }
}

Function CheckedListBoxPools_Click ($Control) { 
    $Config | Add-Member -Force @{ $Control.Tag = $Control.CheckedItems }
    $EarningTrackerConfig = Get-Content ".\Config\EarningTrackerConfig.json" | ConvertFrom-JSON
    $EarningTrackerConfig | Add-Member -Force @{ "Pools" = ($Control.CheckedItems.Replace("24hr", "")).Replace("Plus", "") | Sort-Object -Unique }
    $EarningTrackerConfig | ConvertTo-Json | Out-File ".\Config\EarningTrackerConfig.json"
}

Function PrepareWriteConfig { 
    If ($Config.ManualConfig) { Update-Status("Manual config mode - Not saving config"); return }
    If ($Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }
    $Config | Add-Member -Force @{ $TBAddress.Tag = $TBAddress.Text }
    $Config | Add-Member -Force @{ $TBWorkerName.Tag = $TBWorkerName.Text }
    $ConfigPageControls | Where-Object { (($_.gettype()).Name -eq "CheckBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Checked } }
    $ConfigPageControls | Where-Object { (($_.gettype()).Name -eq "TextBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Text } }
    $ConfigPageControls | Where-Object { (($_.gettype()).Name -eq "TextBox") -and ($_.Tag -eq "GPUCount") } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = [Int]$_.Text }
        If ($CheckBoxDisableGPU0.checked -and [Int]$_.Text -gt 1) { $FirstGPU = 1 } Else { $FirstGPU = 0 }
        $Config | Add-Member -Force @{ SelGPUCC = (($FirstGPU..($_.Text - 1)) -join ",") }
        $Config | Add-Member -Force @{ SelGPUDSTM = (($FirstGPU..($_.Text - 1)) -join " ") }
    }
    $ConfigPageControls | Where-Object { (($_.gettype()).Name -eq "TextBox") -and ($_.Tag -eq "Algorithm") } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = @($_.Text -split ",") }
    }
    $ConfigPageControls | Where-Object { (($_.gettype()).Name -eq "TextBox") -and ($_.Tag -in @("Donate", "Interval", "ActiveMinerGainPct")) } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = [Int]$_.Text }
    }
    $Config | Add-Member -Force @{ $CheckedListBoxPools.Tag = $CheckedListBoxPools.CheckedItems }

    $MonitoringSettingsControls | Where-Object { (($_.gettype()).Name -eq "CheckBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Checked } }
    $MonitoringSettingsControls | Where-Object { (($_.gettype()).Name -eq "TextBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Text } }

    Write-Config -ConfigFile $ConfigFile
    Load-Config -ConfigFile $ConfigFile
    $MainForm.Refresh
    # [System.Windows.Forms.Messagebox]::show("Please restart NPlusMiner",'Config saved','ok','Information') | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

If (Test-Path ".\Logs\switching.log" -PathType Leaf) { $SwitchingArray = [System.Collections.ArrayList]@(@((Get-Content ".\Logs\switching.log" -First 1) , (Get-Content ".\Logs\switching.log" -last 50)) | ConvertFrom-Csv | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Select-Object -Last 13) }

$MainForm = New-Object System.Windows.Forms.Form
$NMIcon = New-Object system.drawing.icon ("$($PWD)\Includes\NM.ICO")
$MainForm.Icon = $NMIcon
$MainForm.ClientSize = '740,450' # best to keep under 800,600
$MainForm.text = "Form"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = 'Fixed3D'
$MainForm.MaximizeBox = $false

$MainForm.Add_Shown(
    { 
        # Check if new version is available
        Update-Status("Checking version")
        Try { 
            $Version = Invoke-WebRequest "https://nemosminer.com/data/version.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
        }
        Catch { $Version = Get-Content ".\Config\version.json" | ConvertFrom-Json }
        If ($Version -ne $null) { $Version | ConvertTo-Json | Out-File ".\Config\version.json" }
        If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$Version.Version -gt $Variables.CurrentVersion -and $Version.Update) { 
            Update-Status("Version $($Version.Version) available. (You are running $($Variables.CurrentVersion))")
            # If ([Version](GetNVIDIADriverVersion) -ge [Version]$Version.MinNVIDIADriverVersion){ 
            $LabelNotifications.ForeColor = "Green"
            $LabelNotifications.Lines += "Version $([Version]$Version.Version) available"
            $LabelNotifications.Lines += $Version.Message
            If ($Config.Autoupdate -and ! $Config.ManualConfig) { Autoupdate }
            # } Else { 
            # Update-Status("Version $($Version.Version) available. Please update NVIDIA driver. Will not AutoUpdate")
            # $LabelNotifications.ForeColor = "Red"
            # $LabelNotifications.Lines += "Driver update required. Version $([Version]$Version.Version) available"
            # }
        }

        # TimerCheckVersion
        $TimerCheckVersion = New-Object System.Windows.Forms.Timer
        $TimerCheckVersion.Enabled = $true
        $TimerCheckVersion.Interval = 700 * 60 * 1000
        $TimerCheckVersion.Add_Tick( { 
                Update-Status("Checking version")
                Try { 
                    $Version = Invoke-WebRequest "https://nemosminer.com/data/version.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
                }
                Catch { $Version = Get-Content ".\Config\version.json" | ConvertFrom-Json }
                If ($Version -ne $null) { $Version | ConvertTo-Json | Out-File ".\Config\version.json" }
                If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$Version.Version -gt $Variables.CurrentVersion -and $Version.Update) { 
                    Update-Status("Version $($Version.Version) available. (You are running $($Variables.CurrentVersion))")
                    # If ([Version](GetNVIDIADriverVersion) -ge [Version]$Version.MinNVIDIADriverVersion){ 
                    $LabelNotifications.ForeColor = "Green"
                    $LabelNotifications.Lines += "Version $([Version]$Version.Version) available"
                    $LabelNotifications.Lines += $Version.Message
                    If ($Config.Autoupdate -and ! $Config.ManualConfig) { Autoupdate }
                    # } Else { 
                    # Update-Status("Version $($Version.Version) available. Please update NVIDIA driver. Will not AutoUpdate")
                    # $LabelNotifications.ForeColor = "Red"
                    # $LabelNotifications.Lines += "Driver update required. Version $([Version]$Version.Version) available"
                    # }
                }
            })
        # Detects GPU count If 0 or Null in config
        If ($Config.GPUCount -eq $null -or $Config.GPUCount -lt 1) { 
            If ($Config -eq $null) {
                $Config = [Hashtable]::Synchronized(@{ })
            }
            $Config | Add-Member -Force @{ GPUCount = DetectGPUCount }
            $TBGPUCount.Text = $Config.GPUCount
            PrepareWriteConfig
        }
        # Start on load if Autostart
        If ($Config.Autostart) { $ButtonStart.PerformClick() }
        If ($Config.StartGUIMinimized) { $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }
    }
)

$MainForm.Add_FormClosing(
    { 
        $TimerUI.Stop()
        Update-Status("Stopping jobs and miner")

        If ($Variables.EarningsTrackerJobs) { $Variables.EarningsTrackerJobs | ForEach-Object { $_ | Stop-Job | Remove-Job } }
        If ($Variables.BrainJobs) { $Variables.BrainJobs | ForEach-Object { $_ | Stop-Job | Remove-Job } }

        If ($Variables.ActiveMinerPrograms) { 
            $Variables.ActiveMinerPrograms | ForEach-Object { 
                [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
                If ($Filtered.Count -eq 0) { 
                    If ($_.Process -eq $null) { 
                        $_.Status = "Failed"
                    }
                    ElseIf ($_.Process.HasExited -eq $false) { 
                        $_.Active += (Get-Date) - $_.Process.StartTime
                        $_.Process.CloseMainWindow() | Out-Null
                        Start-Sleep 1
                        # simply "Kill with power"
                        Stop-Process $_.Process -Force | Out-Null
                        Write-Host -ForegroundColor Yellow "closing miner"
                        Start-Sleep 1
                        $_.Status = "Idle"
                    }
                }
            }
        }

        # $Result = $powershell.EndInvoke($Variables.CycleRunspaceHandle)
        If ($CycleRunspace) { $CycleRunspace.Close() }
        If ($powershell) { $powershell.Dispose() }

        If ($IdleRunspace) { $IdleRunspace.Close() }
        If ($IdlePowershell) { $IdlePowershell.Dispose() }
    }
)

Load-Config -ConfigFile $ConfigFile

$Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value { 
    If (Test-Path ".\Config\PoolsConfig.json" -PathType Leaf) { 
        Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-json
    }
    Else { 
        [PSCustomObject]@{ default = [PSCustomObject]@{ 
                Wallet             = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                UserName           = "nemo"
                WorkerName         = "NemosMinerNoCfg"
                PricePenaltyFactor = 1
            }
        }
    }
}

$MainForm | Add-Member -Name "Config" -Value $Config -MemberType NoteProperty -Force

$SelGPUDSTM = $Config.SelGPUDSTM
$SelGPUCC = $Config.SelGPUCC
$MainForm | Add-Member -Name "Variables" -Value $Variables -MemberType NoteProperty -Force

$Variables | Add-Member -Force @{ CurrentProduct = (Get-Content .\Version.json | ConvertFrom-Json).Product }
$Variables | Add-Member -Force @{ CurrentVersion = [Version](Get-Content .\Version.json | ConvertFrom-Json).Version }
$Variables | Add-Member -Force @{ CurrentVersionAutoUpdated = (Get-Content .\Version.json | ConvertFrom-Json).AutoUpdated.Value }
$Variables.StatusText = "Idle"
$TabControl = New-object System.Windows.Forms.TabControl
$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$SwitchingPage = New-Object System.Windows.Forms.TabPage
$SwitchingPage.Text = "Switching"
$ConfigPage = New-Object System.Windows.Forms.TabPage
$ConfigPage.Text = "Config"
$MonitoringPage = New-Object System.Windows.Forms.TabPage
$MonitoringPage.Text = "Monitoring"
$EstimationsPage = New-Object System.Windows.Forms.TabPage
$EstimationsPage.Text = "Benchmarks"

$tabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$tabControl.Location = New-Object System.Drawing.Point(10, 91)
$tabControl.Name = "tabControl"
$tabControl.width = 720
$tabControl.height = 359
$MainForm.Controls.Add($tabControl)
$TabControl.Controls.AddRange(@($RunPage, $SwitchingPage, $ConfigPage, $MonitoringPage, $EstimationsPage))

# Form Controls
$MainFormControls = @()

# $Logo = [System.Drawing.Image]::Fromfile('.\config\logo.png')
$PictureBoxLogo = new-object Windows.Forms.PictureBox
$PictureBoxLogo.Width = 47 #$img.Size.Width
$PictureBoxLogo.Height = 47 #$img.Size.Height
# $PictureBoxLogo.Image = $Logo
$PictureBoxLogo.SizeMode = 1
$PictureBoxLogo.ImageLocation = $Branding.LogoPath
$MainFormControls += $PictureBoxLogo

$LabelEarningsDetails = New-Object System.Windows.Forms.TextBox
$LabelEarningsDetails.Tag = ""
$LabelEarningsDetails.MultiLine = $true
$LabelEarningsDetails.text = ""
$LabelEarningsDetails.AutoSize = $false
$LabelEarningsDetails.width = 200 #382
$LabelEarningsDetails.height = 47 #62
$LabelEarningsDetails.location = New-Object System.Drawing.Point(57, 2)
$LabelEarningsDetails.Font = 'lucida console,10'
$LabelEarningsDetails.BorderStyle = 'None'
$LabelEarningsDetails.BackColor = [System.Drawing.SystemColors]::Control
$LabelEarningsDetails.ForeColor = "Green"
$LabelEarningsDetails.Visible = $True
# $TBNotifications.TextAlign                = "Right"
$MainFormControls += $LabelEarningsDetails

$LabelBTCD = New-Object System.Windows.Forms.Label
$LabelBTCD.text = "BTC/D"
$LabelBTCD.AutoSize = $False
$LabelBTCD.width = 473
$LabelBTCD.height = 35
$LabelBTCD.location = New-Object System.Drawing.Point(247, 2)
$LabelBTCD.Font = 'Microsoft Sans Serif, 14'
$LabelBTCD.TextAlign = "MiddleRight"
$LabelBTCD.ForeColor = "Green"
$LabelBTCD.Backcolor = "Transparent"
# $LabelBTCD.BorderStyle              = 'FixedSingle'
$MainFormControls += $LabelBTCD

$LabelBTCPrice = New-Object System.Windows.Forms.Label
$LabelBTCPrice.text = If ($Variables.Rates.$Currency -gt 0) { "BTC/$($Config.Currency) $($Variables.Rates.$Currency)" }
$LabelBTCPrice.AutoSize = $false
$LabelBTCPrice.width = 400
$LabelBTCPrice.height = 20
$LabelBTCPrice.location = New-Object System.Drawing.Point(510, 39)
$LabelBTCPrice.Font = 'Microsoft Sans Serif, 8'
# $LabelBTCPrice.ForeColor              = "Gray"
$MainFormControls += $LabelBTCPrice

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.text = "Pause"
$ButtonPause.width = 60
$ButtonPause.height = 30
$ButtonPause.location = New-Object System.Drawing.Point(610, 62)
$ButtonPause.Font = 'Microsoft Sans Serif, 10'
$ButtonPause.Visible = $False
$MainFormControls += $ButtonPause

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.text = "Start"
$ButtonStart.width = 60
$ButtonStart.height = 30
$ButtonStart.location = New-Object System.Drawing.Point(670, 62)
$ButtonStart.Font = 'Microsoft Sans Serif, 10'
$MainFormControls += $ButtonStart

$LabelNotifications = New-Object System.Windows.Forms.TextBox
$LabelNotifications.Tag = ""
$LabelNotifications.MultiLine = $true
# $TBNotifications.Scrollbars             = "Vertical" 
$LabelNotifications.text = ""
$LabelNotifications.AutoSize = $false
$LabelNotifications.width = 280
$LabelNotifications.height = 18
$LabelNotifications.location = New-Object System.Drawing.Point(10, 49)
$LabelNotifications.Font = 'Microsoft Sans Serif, 10'
$LabelNotifications.BorderStyle = 'None'
$LabelNotifications.BackColor = [System.Drawing.SystemColors]::Control
$LabelNotifications.Visible = $True
# $TBNotifications.TextAlign                = "Right"
$MainFormControls += $LabelNotifications

$LabelAddress = New-Object System.Windows.Forms.Label
$LabelAddress.text = "Wallet Address"
$LabelAddress.AutoSize = $false
$LabelAddress.width = 100
$LabelAddress.height = 20
$LabelAddress.location = New-Object System.Drawing.Point(10, 68)
$LabelAddress.Font = 'Microsoft Sans Serif, 10'
$MainFormControls += $LabelAddress

$TBAddress = New-Object System.Windows.Forms.TextBox
$TBAddress.Tag = "Wallet"
$TBAddress.MultiLine = $False
# $TBAddress.Scrollbars             = "Vertical" 
$TBAddress.text = $Config.Wallet
$TBAddress.AutoSize = $false
$TBAddress.width = 280
$TBAddress.height = 20
$TBAddress.location = New-Object System.Drawing.Point(112, 68)
$TBAddress.Font = 'Microsoft Sans Serif, 10'
# $TBAddress.TextAlign                = "Right"
$MainFormControls += $TBAddress

# Run Page Controls
$RunPageControls = @()

$LabelStatus = New-Object System.Windows.Forms.TextBox
$LabelStatus.MultiLine = $true
$LabelStatus.Scrollbars = "Vertical" 
$LabelStatus.text = ""
$LabelStatus.AutoSize = $true
$LabelStatus.width = 712
$LabelStatus.height = 50
$LabelStatus.location = New-Object System.Drawing.Point(2, 2)
$LabelStatus.Font = 'Microsoft Sans Serif, 10'
$RunPageControls += $LabelStatus

If (Test-Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { 

    $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 105"
    $Chart1.top = 54
    $Chart1.left = 2
    $RunPageControls += $Chart1

    $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 105"
    $Chart2.top = 54
    $Chart2.left = 500
    $RunPageControls += $Chart2
}

$EarningsDGV = New-Object System.Windows.Forms.DataGridView
$EarningsDGV.width = 712
# $EarningsDGV.height                                     = 305
# $EarningsDGV.height                                     = 170
$EarningsDGV.height = 85
$EarningsDGV.location = New-Object System.Drawing.Point(2, 159)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.AutoSizeColumnsMode = "Fill"
$EarningsDGV.RowHeadersVisible = $False
$RunPageControls += $EarningsDGV

$LabelGitHub = New-Object System.Windows.Forms.LinkLabel
# $LabelGitHub.Location           = New-Object System.Drawing.Size(415,39)
# $LabelGitHub.Size               = New-Object System.Drawing.Size(160,18)
$LabelGitHub.Location = New-Object System.Drawing.Size(600, 246)
$LabelGitHub.Size = New-Object System.Drawing.Size(160, 20)
$LabelGitHub.LinkColor = "BLUE"
$LabelGitHub.ActiveLinkColor = "BLUE"
$RunPageControls += $LabelGitHub

$LabelCopyright = New-Object System.Windows.Forms.LinkLabel
# $LabelCopyright.Location        = New-Object System.Drawing.Size(415,61)
# $LabelCopyright.Size            = New-Object System.Drawing.Size(200,20)
$LabelCopyright.Location = New-Object System.Drawing.Size(360, 246)
$LabelCopyright.Size = New-Object System.Drawing.Size(250, 14)
$LabelCopyright.LinkColor = "BLUE"
$LabelCopyright.ActiveLinkColor = "BLUE"
$LabelCopyright.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo and MrPlus"
$LabelCopyright.Add_Click( { [System.Diagnostics.Process]::start("https://github.com/Minerx117/NemosMiner/blob/master/LICENSE") })
$RunPageControls += $LabelCopyright

$LabelRunningMiners = New-Object System.Windows.Forms.Label
$LabelRunningMiners.text = "Running Miners"
$LabelRunningMiners.AutoSize = $false
$LabelRunningMiners.width = 200
$LabelRunningMiners.height = 20
$LabelRunningMiners.location = New-Object System.Drawing.Point(2, 246)
$LabelRunningMiners.Font = 'Microsoft Sans Serif, 10'
$RunPageControls += $LabelRunningMiners

$RunningMinersDGV = New-Object System.Windows.Forms.DataGridView
$RunningMinersDGV.width = 712
# $EarningsDGV.height                                     = 305
$RunningMinersDGV.height = 95
$RunningMinersDGV.location = New-Object System.Drawing.Point(2, 266)
$RunningMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$RunningMinersDGV.AutoSizeColumnsMode = "Fill"
$RunningMinersDGV.RowHeadersVisible = $False
$RunPageControls += $RunningMinersDGV

# Switching Page Controls
$SwitchingPageControls = @()

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.text = "CPU"
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.width = 60
$CheckShowSwitchingCPU.height = 20
$CheckShowSwitchingCPU.location = New-Object System.Drawing.Point(2, 2)
$CheckShowSwitchingCPU.Font = 'Microsoft Sans Serif, 10'
$CheckShowSwitchingCPU.Checked = ("CPU" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingCPU

$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.text = "NVIDIA"
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.width = 70
$CheckShowSwitchingNVIDIA.height = 20
$CheckShowSwitchingNVIDIA.location = New-Object System.Drawing.Point(62, 2)
$CheckShowSwitchingNVIDIA.Font = 'Microsoft Sans Serif, 10'
$CheckShowSwitchingNVIDIA.Checked = ("NVIDIA" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingNVIDIA

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.text = "AMD"
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.width = 100
$CheckShowSwitchingAMD.height = 20
$CheckShowSwitchingAMD.location = New-Object System.Drawing.Point(137, 2)
$CheckShowSwitchingAMD.Font = 'Microsoft Sans Serif, 10'
$CheckShowSwitchingAMD.Checked = ("AMD" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingAMD

$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }

Function CheckBoxSwitching_Click { 
    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path ".\Logs\switching.log" -PathType Leaf) { $SwitchingArray = [System.Collections.ArrayList]@(@((Get-Content ".\Logs\switching.log" -First 1) , (Get-Content ".\Logs\switching.log" -last 50)) | ConvertFrom-Csv | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Select-Object -Last 13) }
    $SwitchingDGV.DataSource = $SwitchingArray
}


$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.width = 712
$SwitchingDGV.height = 333
$SwitchingDGV.location = New-Object System.Drawing.Point(2, 22)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.RowHeadersVisible = $False
$SwitchingDGV.DataSource = $SwitchingArray
$SwitchingPageControls += $SwitchingDGV

# Estimations Page Controls
$EstimationsDGV = New-Object System.Windows.Forms.DataGridView
$EstimationsDGV.width = 712
$EstimationsDGV.height = 350
$EstimationsDGV.location = New-Object System.Drawing.Point(2, 2)
$EstimationsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EstimationsDGV.AutoSizeColumnsMode = "Fill"
$EstimationsDGV.RowHeadersVisible = $False

# Config Page Controls
$ConfigPageControls = @()

$LabelWorkerName = New-Object System.Windows.Forms.Label
$LabelWorkerName.text = "Worker Name"
$LabelWorkerName.AutoSize = $false
$LabelWorkerName.width = 120
$LabelWorkerName.height = 20
$LabelWorkerName.location = New-Object System.Drawing.Point(2, 2)
$LabelWorkerName.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelWorkerName

$TBWorkerName = New-Object System.Windows.Forms.TextBox
$TBWorkerName.Tag = "WorkerName"
$TBWorkerName.MultiLine = $False
# $TBWorkerName.Scrollbars              = "Vertical" 
$TBWorkerName.text = $Config.WorkerName
$TBWorkerName.AutoSize = $false
$TBWorkerName.width = 300
$TBWorkerName.height = 20
$TBWorkerName.location = New-Object System.Drawing.Point(122, 2)
$TBWorkerName.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBWorkerName

$LabelUserName = New-Object System.Windows.Forms.Label
$LabelUserName.text = "MPH UserName"
$LabelUserName.AutoSize = $false
$LabelUserName.width = 120
$LabelUserName.height = 20
$LabelUserName.location = New-Object System.Drawing.Point(2, 24)
$LabelUserName.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelUserName

$TBUserName = New-Object System.Windows.Forms.TextBox
$TBUserName.Tag = "UserName"
$TBUserName.MultiLine = $False
# $TBUserName.Scrollbars                = "Vertical" 
$TBUserName.text = $Config.UserName
$TBUserName.AutoSize = $false
$TBUserName.width = 300
$TBUserName.height = 20
$TBUserName.location = New-Object System.Drawing.Point(122, 24)
$TBUserName.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBUserName

$LabelInterval = New-Object System.Windows.Forms.Label
$LabelInterval.text = "Interval"
$LabelInterval.AutoSize = $false
$LabelInterval.width = 120
$LabelInterval.height = 20
$LabelInterval.location = New-Object System.Drawing.Point(2, 46)
$LabelInterval.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelInterval

$TBInterval = New-Object System.Windows.Forms.TextBox
$TBInterval.Tag = "Interval"
$TBInterval.MultiLine = $False
# $TBWorkerName.Scrollbars              = "Vertical" 
$TBInterval.text = $Config.Interval
$TBInterval.AutoSize = $false
$TBInterval.width = 300
$TBInterval.height = 20
$TBInterval.location = New-Object System.Drawing.Point(122, 46)
$TBInterval.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBInterval

$LabelLocation = New-Object System.Windows.Forms.Label
$LabelLocation.text = "Location"
$LabelLocation.AutoSize = $false
$LabelLocation.width = 120
$LabelLocation.height = 20
$LabelLocation.location = New-Object System.Drawing.Point(2, 68)
$LabelLocation.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelLocation

$TBLocation = New-Object System.Windows.Forms.TextBox
$TBLocation.Tag = "Location"
$TBLocation.MultiLine = $False
# $TBLocation.Scrollbars                = "Vertical" 
$TBLocation.text = $Config.Location
$TBLocation.AutoSize = $false
$TBLocation.width = 300
$TBLocation.height = 20
$TBLocation.location = New-Object System.Drawing.Point(122, 68)
$TBLocation.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBLocation

$LabelGPUCount = New-Object System.Windows.Forms.Label
$LabelGPUCount.text = "GPU Count"
$LabelGPUCount.AutoSize = $false
$LabelGPUCount.width = 120
$LabelGPUCount.height = 20
$LabelGPUCount.location = New-Object System.Drawing.Point(2, 90)
$LabelGPUCount.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelGPUCount

$TBGPUCount = New-Object System.Windows.Forms.TextBox
$TBGPUCount.Tag = "GPUCount"
$TBGPUCount.MultiLine = $False
# $TBGPUCount.Scrollbars                = "Vertical" 
$TBGPUCount.text = $Config.GPUCount
$TBGPUCount.AutoSize = $false
$TBGPUCount.width = 50
$TBGPUCount.height = 20
$TBGPUCount.location = New-Object System.Drawing.Point(122, 90)
$TBGPUCount.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBGPUCount

$CheckBoxDisableGPU0 = New-Object System.Windows.Forms.CheckBox
$CheckBoxDisableGPU0.Tag = "DisableGPU0"
$CheckBoxDisableGPU0.text = "Disable GPU0"
$CheckBoxDisableGPU0.AutoSize = $false
$CheckBoxDisableGPU0.width = 140
$CheckBoxDisableGPU0.height = 20
$CheckBoxDisableGPU0.location = New-Object System.Drawing.Point(177, 90)
$CheckBoxDisableGPU0.Font = 'Microsoft Sans Serif, 10'
$CheckBoxDisableGPU0.Checked = $Config.DisableGPU0
$ConfigPageControls += $CheckBoxDisableGPU0
    
$ButtonDetectGPU = New-Object System.Windows.Forms.Button
$ButtonDetectGPU.text = "Detect GPU"
$ButtonDetectGPU.width = 100
$ButtonDetectGPU.height = 20
$ButtonDetectGPU.location = New-Object System.Drawing.Point(320, 90)
$ButtonDetectGPU.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $ButtonDetectGPU

$ButtonDetectGPU.Add_Click( { $TBGPUCount.text = DetectGPUCount })

$LabelAlgos = New-Object System.Windows.Forms.Label
$LabelAlgos.text = "Algorithm"
$LabelAlgos.AutoSize = $false
$LabelAlgos.width = 120
$LabelAlgos.height = 20
$LabelAlgos.location = New-Object System.Drawing.Point(2, 112)
$LabelAlgos.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelAlgos

$TBAlgos = New-Object System.Windows.Forms.TextBox
$TBAlgos.Tag = "Algorithm"
$TBAlgos.MultiLine = $False
# $TBAlgos.Scrollbars               = "Vertical" 
$TBAlgos.text = $Config.Algorithm -Join ","
$TBAlgos.AutoSize = $false
$TBAlgos.width = 300
$TBAlgos.height = 20
$TBAlgos.location = New-Object System.Drawing.Point(122, 112)
$TBAlgos.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBAlgos

$LabelCurrency = New-Object System.Windows.Forms.Label
$LabelCurrency.text = "Currency"
$LabelCurrency.AutoSize = $false
$LabelCurrency.width = 120
$LabelCurrency.height = 20
$LabelCurrency.location = New-Object System.Drawing.Point(2, 134)
$LabelCurrency.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelCurrency

$TBCurrency = New-Object System.Windows.Forms.TextBox
$TBCurrency.Tag = "Currency"
$TBCurrency.MultiLine = $False
# $TBCurrency.Scrollbars                = "Vertical" 
$TBCurrency.text = $Config.Currency
$TBCurrency.AutoSize = $false
$TBCurrency.width = 300
$TBCurrency.height = 20
$TBCurrency.location = New-Object System.Drawing.Point(122, 134)
$TBCurrency.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBCurrency

$LabelPwdCurrency = New-Object System.Windows.Forms.Label
$LabelPwdCurrency.text = "Pwd Currency"
$LabelPwdCurrency.AutoSize = $false
$LabelPwdCurrency.width = 120
$LabelPwdCurrency.height = 20
$LabelPwdCurrency.location = New-Object System.Drawing.Point(2, 156)
$LabelPwdCurrency.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelPwdCurrency

$TBPwdCurrency = New-Object System.Windows.Forms.TextBox
$TBPwdCurrency.Tag = "Passwordcurrency"
$TBPwdCurrency.MultiLine = $False
# $TBPwdCurrency.Scrollbars             = "Vertical" 
$TBPwdCurrency.text = $Config.Passwordcurrency
$TBPwdCurrency.AutoSize = $false
$TBPwdCurrency.width = 300
$TBPwdCurrency.height = 20
$TBPwdCurrency.location = New-Object System.Drawing.Point(122, 156)
$TBPwdCurrency.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBPwdCurrency

$LabelDonate = New-Object System.Windows.Forms.Label
$LabelDonate.text = "Donate"
$LabelDonate.AutoSize = $false
$LabelDonate.width = 120
$LabelDonate.height = 20
$LabelDonate.location = New-Object System.Drawing.Point(2, 178)
$LabelDonate.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelDonate

$TBDonate = New-Object System.Windows.Forms.TextBox
$TBDonate.Tag = "Donate"
$TBDonate.MultiLine = $False
# $TBDonate.Scrollbars              = "Vertical" 
$TBDonate.text = $Config.Donate
$TBDonate.AutoSize = $false
$TBDonate.width = 300
$TBDonate.height = 20
$TBDonate.location = New-Object System.Drawing.Point(122, 178)
$TBDonate.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBDonate

$LabelProxy = New-Object System.Windows.Forms.Label
$LabelProxy.text = "Proxy"
$LabelProxy.AutoSize = $false
$LabelProxy.width = 120
$LabelProxy.height = 20
$LabelProxy.location = New-Object System.Drawing.Point(2, 178)
$LabelProxy.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelProxy

$TBProxy = New-Object System.Windows.Forms.TextBox
$TBProxy.Tag = "Proxy"
$TBProxy.MultiLine = $False
# $TBProxy.Scrollbars               = "Vertical" 
$TBProxy.text = $Config.Proxy
$TBProxy.AutoSize = $false
$TBProxy.width = 300
$TBProxy.height = 20
$TBProxy.location = New-Object System.Drawing.Point(122, 178)    
$TBProxy.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBProxy

$LabelActiveMinerGainPct = New-Object System.Windows.Forms.Label
$LabelActiveMinerGainPct.text = "ActiveMinerGain%"
$LabelActiveMinerGainPct.AutoSize = $false
$LabelActiveMinerGainPct.width = 120
$LabelActiveMinerGainPct.height = 20
$LabelActiveMinerGainPct.location = New-Object System.Drawing.Point(2, 202)
$LabelActiveMinerGainPct.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelActiveMinerGainPct

$TBActiveMinerGainPct = New-Object System.Windows.Forms.TextBox
$TBActiveMinerGainPct.Tag = "ActiveMinerGainPct"
$TBActiveMinerGainPct.MultiLine = $False
# $TBActiveMinerGainPct.Scrollbars              = "Vertical" 
$TBActiveMinerGainPct.text = $Config.ActiveMinerGainPct
$TBActiveMinerGainPct.AutoSize = $false
$TBActiveMinerGainPct.width = 300
$TBActiveMinerGainPct.height = 20
$TBActiveMinerGainPct.location = New-Object System.Drawing.Point(122, 202)
$TBActiveMinerGainPct.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBActiveMinerGainPct

$LabelMPHAPIKey = New-Object System.Windows.Forms.Label
$LabelMPHAPIKey.text = "MPH API Key"
$LabelMPHAPIKey.AutoSize = $false
$LabelMPHAPIKey.width = 120
$LabelMPHAPIKey.height = 20
$LabelMPHAPIKey.location = New-Object System.Drawing.Point(2, 224)
$LabelMPHAPIKey.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelMPHAPIKey

$TBMPHAPIKey = New-Object System.Windows.Forms.TextBox
$TBMPHAPIKey.Tag = "APIKEY"
$TBMPHAPIKey.MultiLine = $False
$TBMPHAPIKey.text = $Config.APIKEY
$TBMPHAPIKey.AutoSize = $false
$TBMPHAPIKey.width = 300
$TBMPHAPIKey.height = 20
$TBMPHAPIKey.location = New-Object System.Drawing.Point(122, 224)
$TBMPHAPIKey.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $TBMPHAPIKey

$LabelMinersTypes = New-Object System.Windows.Forms.Label
$LabelMinersTypes.text = "Miners Types"
$LabelMinersTypes.AutoSize = $false
$LabelMinersTypes.width = 120
$LabelMinersTypes.height = 20
$LabelMinersTypes.location = New-Object System.Drawing.Point(2, 246)
$LabelMinersTypes.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelMinersTypes

$CheckBoxMinerTypeCPU = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeCPU.Tag = "TypeCPU"
$CheckBoxMinerTypeCPU.text = "CPU"
$CheckBoxMinerTypeCPU.AutoSize = $false
$CheckBoxMinerTypeCPU.width = 60
$CheckBoxMinerTypeCPU.height = 20
$CheckBoxMinerTypeCPU.location = New-Object System.Drawing.Point(124, 246)
$CheckBoxMinerTypeCPU.Font = 'Microsoft Sans Serif, 10'
$CheckBoxMinerTypeCPU.Checked = ($CheckBoxMinerTypeCPU.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeCPU

$CheckBoxMinerTypeCPU.Add_Click(
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            # If ($Variables."$($This.Text)MinerAPITCPPort" -eq $Null){ 
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $Null -or ($Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Update-Status("Finding available TCP Port for $($This.Text)")
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Update-Status("Miners API Port: $($Port)")
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxMinerTypeNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeNVIDIA.Tag = "TypeNVIDIA"
$CheckBoxMinerTypeNVIDIA.text = "NVIDIA"
$CheckBoxMinerTypeNVIDIA.AutoSize = $false
$CheckBoxMinerTypeNVIDIA.width = 70
$CheckBoxMinerTypeNVIDIA.height = 20
$CheckBoxMinerTypeNVIDIA.location = New-Object System.Drawing.Point(186, 246)
$CheckBoxMinerTypeNVIDIA.Font = 'Microsoft Sans Serif, 10'
$CheckBoxMinerTypeNVIDIA.Checked = ($CheckBoxMinerTypeNVIDIA.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeNVIDIA

$CheckBoxMinerTypeNVIDIA.Add_Click(
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $Null -or ($Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Update-Status("Finding available TCP Port for $($This.Text)")
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Update-Status("Miners API Port: $($Port)")
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxMinerTypeAMD = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeAMD.Tag = "TypeAMD"
$CheckBoxMinerTypeAMD.text = "AMD"
$CheckBoxMinerTypeAMD.AutoSize = $false
$CheckBoxMinerTypeAMD.width = 60
$CheckBoxMinerTypeAMD.height = 20
$CheckBoxMinerTypeAMD.location = New-Object System.Drawing.Point(261, 246)
$CheckBoxMinerTypeAMD.Font = 'Microsoft Sans Serif, 10'
$CheckBoxMinerTypeAMD.Checked = ($CheckBoxMinerTypeAMD.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeAMD

$CheckBoxMinerTypeAMD.Add_Click( 
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $Null -or ($Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Update-Status("Finding available TCP Port for $($This.Text)")
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Update-Status("Miners API Port: $($Port)")
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxAutostart = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutostart.Tag = "Autostart"
$CheckBoxAutostart.text = "Auto Start"
$CheckBoxAutostart.AutoSize = $false
$CheckBoxAutostart.width = 100
$CheckBoxAutostart.height = 20
$CheckBoxAutostart.location = New-Object System.Drawing.Point(560, 2)
$CheckBoxAutostart.Font = 'Microsoft Sans Serif, 10'
$CheckBoxAutostart.Checked = $Config.Autostart
$ConfigPageControls += $CheckBoxAutostart

$CheckBoxAutoStart.Add_Click(
    { 
        # Disable CheckBoxStartPaused and mine when idle when Auto Start is unchecked
        If ($CheckBoxAutoStart.Checked) { 
            $CheckBoxStartPaused.Enabled = $True
            $CheckBoxMineWhenIdle.Enabled = $True
            $TBIdleSec.Enabled = $True
        }
        Else { 
            $CheckBoxStartPaused.Checked = $False
            $CheckBoxStartPaused.Enabled = $False
            $CheckBoxMineWhenIdle.Checked = $False
            $CheckBoxMineWhenIdle.Enabled = $False
            $TBIdleSec.Enabled = $False
        }
    }
)

$CheckBoxStartPaused = New-Object System.Windows.Forms.CheckBox
$CheckBoxStartPaused.Tag = "StartPaused"
$CheckBoxStartPaused.text = "Pause on Auto Start"
$CheckBoxStartPaused.AutoSize = $false
$CheckBoxStartPaused.width = 160
$CheckBoxStartPaused.height = 20
$CheckBoxStartPaused.location = New-Object System.Drawing.Point(560, 24)
$CheckBoxStartPaused.Font = 'Microsoft Sans Serif, 10'
$CheckBoxStartPaused.Checked = $Config.StartPaused
$CheckBoxStartPaused.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxStartPaused

$CheckBoxMineWhenIdle = New-Object System.Windows.Forms.CheckBox
$CheckBoxMineWhenIdle.Tag = "MineWhenIdle"
$CheckBoxMineWhenIdle.text = "Mine only when idle"
$CheckBoxMineWhenIdle.AutoSize = $false
$CheckBoxMineWhenIdle.width = 160
$CheckBoxMineWhenIdle.height = 20
$CheckBoxMineWhenIdle.location = New-Object System.Drawing.Point(560, 46)
$CheckBoxMineWhenIdle.Font = 'Microsoft Sans Serif, 10'
$CheckBoxMineWhenIdle.Checked = $Config.MineWhenIdle
$CheckBoxMineWhenIdle.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxMineWhenIdle

$TBIdleSec = New-Object System.Windows.Forms.TextBox
$TBIdleSec.Tag = "IdleSec"
$TBIdleSec.MultiLine = $False
$TBIdleSec.text = If ($Config.IdleSec -gt 1) { $Config.IdleSec } Else { 120 }
$TBIdleSec.AutoSize = $false
$TBIdleSec.width = 50
$TBIdleSec.height = 20
$TBIdleSec.location = New-Object System.Drawing.Point(580, 68)
$TBIdleSec.Font = 'Microsoft Sans Serif, 10'
$TBIdleSec.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $TBIdleSec

$LabelIdleSec = New-Object System.Windows.Forms.Label
$LabelIdleSec.text = "seconds"
$LabelIdleSec.AutoSize = $false
$LabelIdleSec.width = 60
$LabelIdleSec.height = 20
$LabelIdleSec.location = New-Object System.Drawing.Point(630, 68)
$LabelIdleSec.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $LabelIdleSec

$CheckBoxEarningTrackerLogs = New-Object System.Windows.Forms.CheckBox
$CheckBoxEarningTrackerLogs.Tag = "EnableEarningsTrackerLogs"
$CheckBoxEarningTrackerLogs.text = "Earnings Tracker Logs"
$CheckBoxEarningTrackerLogs.AutoSize = $false
$CheckBoxEarningTrackerLogs.width = 160
$CheckBoxEarningTrackerLogs.height = 20
$CheckBoxEarningTrackerLogs.location = New-Object System.Drawing.Point(560, 90)
$CheckBoxEarningTrackerLogs.Font = 'Microsoft Sans Serif, 10'
$CheckBoxEarningTrackerLogs.Checked = $Config.EnableEarningsTrackerLogs
$ConfigPageControls += $CheckBoxEarningTrackerLogs

$CheckBoxGUIMinimized = New-Object System.Windows.Forms.CheckBox
$CheckBoxGUIMinimized.Tag = "StartGUIMinimized"
$CheckBoxGUIMinimized.text = "Start UI minimized"
$CheckBoxGUIMinimized.AutoSize = $false
$CheckBoxGUIMinimized.width = 160
$CheckBoxGUIMinimized.height = 20
$CheckBoxGUIMinimized.location = New-Object System.Drawing.Point(560, 112)
$CheckBoxGUIMinimized.Font = 'Microsoft Sans Serif, 10'
$CheckBoxGUIMinimized.Checked = $Config.StartGUIMinimized
$ConfigPageControls += $CheckBoxGUIMinimized

$CheckBoxAutoUpdate = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutoUpdate.Tag = "AutoUpdate"
$CheckBoxAutoUpdate.text = "Auto Update"
$CheckBoxAutoUpdate.AutoSize = $true
$CheckBoxAutoUpdate.width = 100
$CheckBoxAutoUpdate.height = 20
$CheckBoxAutoUpdate.location = New-Object System.Drawing.Point(560, 134)
$CheckBoxAutoUpdate.Font = 'Microsoft Sans Serif, 10'
$CheckBoxAutoUpdate.Checked = $Config.AutoUpdate
# $CheckBoxAutoUpdate.Enabled               =   $False
$ConfigPageControls += $CheckBoxAutoUpdate

$CheckBoxIncludeRegularMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeRegularMiners.Tag = "IncludeRegularMiners"
$CheckBoxIncludeRegularMiners.text = "Regular Miners"
$CheckBoxIncludeRegularMiners.AutoSize = $false
$CheckBoxIncludeRegularMiners.width = 160
$CheckBoxIncludeRegularMiners.height = 20
$CheckBoxIncludeRegularMiners.location = New-Object System.Drawing.Point(560, 156)
$CheckBoxIncludeRegularMiners.Font = 'Microsoft Sans Serif, 10'
$CheckBoxIncludeRegularMiners.Checked = $Config.IncludeRegularMiners
$ConfigPageControls += $CheckBoxIncludeRegularMiners

$CheckBoxIncludeOptionalMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeOptionalMiners.Tag = "IncludeOptionalMiners"
$CheckBoxIncludeOptionalMiners.text = "Optional Miners"
$CheckBoxIncludeOptionalMiners.AutoSize = $false
$CheckBoxIncludeOptionalMiners.width = 160
$CheckBoxIncludeOptionalMiners.height = 20
$CheckBoxIncludeOptionalMiners.location = New-Object System.Drawing.Point(560, 178)
$CheckBoxIncludeOptionalMiners.Font = 'Microsoft Sans Serif, 10'
$CheckBoxIncludeOptionalMiners.Checked = $Config.IncludeOptionalMiners
$ConfigPageControls += $CheckBoxIncludeOptionalMiners

$CheckBoxConsole = New-Object System.Windows.Forms.CheckBox
$CheckBoxConsole.Tag = "HideConsole"
$CheckBoxConsole.text = "Hide Console"
$CheckBoxConsole.AutoSize = $false
$CheckBoxConsole.width = 160
$CheckBoxConsole.height = 20
$CheckBoxConsole.location = New-Object System.Drawing.Point(560, 200)
$CheckBoxConsole.Font = 'Microsoft Sans Serif, 10'
$CheckBoxConsole.Checked = $Config.HideConsole
$ConfigPageControls += $CheckBoxConsole

$ButtonLoadDefaultPoolsAlgos = New-Object System.Windows.Forms.Button
$ButtonLoadDefaultPoolsAlgos.text = "Load default algos for selected pools"
$ButtonLoadDefaultPoolsAlgos.width = 250
$ButtonLoadDefaultPoolsAlgos.height = 30
$ButtonLoadDefaultPoolsAlgos.location = New-Object System.Drawing.Point(358, 300)
$ButtonLoadDefaultPoolsAlgos.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $ButtonLoadDefaultPoolsAlgos

$ButtonLoadDefaultPoolsAlgos.Add_Click(
    { 
        Try { 
            $PoolsAlgos = Invoke-WebRequest "https://nemosminer.com/data/PoolsAlgos.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json; $PoolsAlgos | ConvertTo-Json | Out-File ".\Config\PoolsAlgos.json" 
        }
        Catch { $PoolsAlgos = Get-Content ".\Config\PoolsAlgos.json" | ConvertFrom-Json }
        If ($PoolsAlgos) { 
            $PoolsAlgos = $PoolsAlgos.PSObject.Properties | Where-Object { $_.Name -in $Config.PoolName }
            $PoolsAlgos = $PoolsAlgos.Value | Sort-Object -Unique
            $TBAlgos.text = $PoolsAlgos -Join ","
        }
    }
)

$ButtonWriteConfig = New-Object System.Windows.Forms.Button
$ButtonWriteConfig.text = "Save Config"
$ButtonWriteConfig.width = 100
$ButtonWriteConfig.height = 30
$ButtonWriteConfig.location = New-Object System.Drawing.Point(610, 300)
$ButtonWriteConfig.Font = 'Microsoft Sans Serif, 10'
$ConfigPageControls += $ButtonWriteConfig

$ButtonWriteConfig.Add_Click( { PrepareWriteConfig })

$LabelPoolsSelect = New-Object System.Windows.Forms.Label
$LabelPoolsSelect.text = "Do not select multiple variants of the same pool"
$LabelPoolsSelect.AutoSize = $false
$LabelPoolsSelect.width = 130
$LabelPoolsSelect.height = 50
$LabelPoolsSelect.location = New-Object System.Drawing.Point(427, 2)
$LabelPoolsSelect.Font = 'Microsoft Sans Serif, 10'
$LabelPoolsSelect.TextAlign = 'MiddleCenter'
$LabelPoolsSelect.BorderStyle = 'FixedSingle'
$ConfigPageControls += $LabelPoolsSelect

$CheckedListBoxPools = New-Object System.Windows.Forms.CheckedListBox
$CheckedListBoxPools.Tag = "PoolName"
$CheckedListBoxPools.height = 240
$CheckedListBoxPools.width = 130
$CheckedListBoxPools.text = "Pools"
$CheckedListBoxPools.location = New-Object System.Drawing.Point(427, 54)
$CheckedListBoxPools.CheckOnClick = $True
$CheckedListBoxPools.BackColor = [System.Drawing.SystemColors]::Control
$CheckedListBoxPools.Items.Clear()
$CheckedListBoxPools.Items.AddRange(((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique))
$CheckedListBoxPools.Add_SelectedIndexChanged( { CheckedListBoxPools_Click($This) })
$Config.PoolName | Where-Object { $_ -in $CheckedListBoxPools.Items } | ForEach-Object { $CheckedListBoxPools.SetItemChecked($CheckedListBoxPools.Items.IndexOf($_), $True) }

$ConfigPageControls += $CheckedListBoxPools

# Monitoring Page Controls
$MonitoringPageControls = @()
$MonitoringSettingsControls = @()

$LabelMonitoringWorkers = New-Object System.Windows.Forms.Label
$LabelMonitoringWorkers.text = "Worker Status"
$LabelMonitoringWorkers.AutoSize = $false
$LabelMonitoringWorkers.width = 710
$LabelMonitoringWorkers.height = 20
$LabelMonitoringWorkers.location = New-Object System.Drawing.Point(2, 4)
$LabelMonitoringWorkers.Font = 'Microsoft Sans Serif, 10'
$MonitoringPageControls += $LabelMonitoringWorkers

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.width = 710
$WorkersDGV.height = 244
$WorkersDGV.location = New-Object System.Drawing.Point(2, 24)
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.AutoSizeColumnsMode = "AllCells"
$WorkersDGV.RowHeadersVisible = $False
$MonitoringPageControls += $WorkersDGV

$GroupMonitoringSettings = New-Object System.Windows.Forms.GroupBox
$GroupMonitoringSettings.Height = 60
$GroupMonitoringSettings.Width = 710
$GroupMonitoringSettings.Text = "Monitoring Settings"
$GroupMonitoringSettings.Location = New-Object System.Drawing.Point(1, 272)
$MonitoringPageControls += $GroupMonitoringSettings

$LabelMonitoringServer = New-Object System.Windows.Forms.Label
$LabelMonitoringServer.text = "Server"
$LabelMonitoringServer.AutoSize = $false
$LabelMonitoringServer.width = 60
$LabelMonitoringServer.height = 20
$LabelMonitoringServer.location = New-Object System.Drawing.Point(2, 15)
$LabelMonitoringServer.Font = 'Microsoft Sans Serif, 10'
$MonitoringSettingsControls += $LabelMonitoringServer

$TBMonitoringServer = New-Object System.Windows.Forms.TextBox
$TBMonitoringServer.Tag = "MonitoringServer"
$TBMonitoringServer.MultiLine = $False
$TBMonitoringServer.text = $Config.MonitoringServer
$TBMonitoringServer.AutoSize = $false
$TBMonitoringServer.width = 260
$TBMonitoringServer.height = 20
$TBMonitoringServer.location = New-Object System.Drawing.Point(62, 15)
$TBMonitoringServer.Font = 'Microsoft Sans Serif, 10'
$MonitoringSettingsControls += $TBMonitoringServer

$CheckBoxReportToServer = New-Object System.Windows.Forms.CheckBox
$CheckBoxReportToServer.Tag = "ReportToServer"
$CheckBoxReportToServer.text = "Report to server"
$CheckBoxReportToServer.AutoSize = $false
$CheckBoxReportToServer.width = 130
$CheckBoxReportToServer.height = 20
$CheckBoxReportToServer.location = New-Object System.Drawing.Point(324, 15)
$CheckBoxReportToServer.Font = 'Microsoft Sans Serif, 10'
$CheckBoxReportToServer.Checked = $Config.ReportToServer
$MonitoringSettingsControls += $CheckBoxReportToServer

$CheckBoxShowWorkerStatus = New-Object System.Windows.Forms.CheckBox
$CheckBoxShowWorkerStatus.Tag = "ShowWorkerStatus"
$CheckBoxShowWorkerStatus.text = "Show other workers"
$CheckBoxShowWorkerStatus.AutoSize = $false
$CheckBoxShowWorkerStatus.width = 145
$CheckBoxShowWorkerStatus.height = 20
$CheckBoxShowWorkerStatus.location = New-Object System.Drawing.Point(456, 15)
$CheckBoxShowWorkerStatus.Font = 'Microsoft Sans Serif, 10'
$CheckBoxShowWorkerStatus.Checked = $Config.ShowWorkerStatus
$MonitoringSettingsControls += $CheckBoxShowWorkerStatus

$LabelMonitoringUser = New-Object System.Windows.Forms.Label
$LabelMonitoringUser.text = "User ID"
$LabelMonitoringUser.AutoSize = $false
$LabelMonitoringUser.width = 60
$LabelMonitoringUser.height = 20
$LabelMonitoringUser.location = New-Object System.Drawing.Point(2, 37)
$LabelMonitoringUser.Font = 'Microsoft Sans Serif, 10'
$MonitoringSettingsControls += $LabelMonitoringUser

$TBMonitoringUser = New-Object System.Windows.Forms.TextBox
$TBMonitoringUser.Tag = "MonitoringUser"
$TBMonitoringUser.MultiLine = $False
$TBMonitoringUser.text = $Config.MonitoringUser
$TBMonitoringUser.AutoSize = $false
$TBMonitoringUser.width = 260
$TBMonitoringUser.height = 20
$TBMonitoringUser.location = New-Object System.Drawing.Point(62, 37)
$TBMonitoringUser.Font = 'Microsoft Sans Serif, 10'
$MonitoringSettingsControls += $TBMonitoringUser

$ButtonGenerateMonitoringUser = New-Object System.Windows.Forms.Button
$ButtonGenerateMonitoringUser.text = "Generate New User ID"
$ButtonGenerateMonitoringUser.width = 160
$ButtonGenerateMonitoringUser.height = 20
$ButtonGenerateMonitoringUser.location = New-Object System.Drawing.Point(324, 37)
$ButtonGenerateMonitoringUser.Font = 'Microsoft Sans Serif, 10'
$ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.text -eq "")
$MonitoringSettingsControls += $ButtonGenerateMonitoringUser

$ButtonGenerateMonitoringUser.Add_Click( { $TBMonitoringUser.text = [GUID]::NewGuid() })
# Only enable the generate button when user is blank.
$TBMonitoringUser.Add_TextChanged( { $ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.text -eq "") })

$ButtonMonitoringWriteConfig = New-Object System.Windows.Forms.Button
$ButtonMonitoringWriteConfig.text = "Save Config"
$ButtonMonitoringWriteConfig.width = 100
$ButtonMonitoringWriteConfig.height = 30
$ButtonMonitoringWriteConfig.location = New-Object System.Drawing.Point(600, 15)
$ButtonMonitoringWriteConfig.Font = 'Microsoft Sans Serif, 10'
$MonitoringSettingsControls += $ButtonMonitoringWriteConfig
$ButtonMonitoringWriteConfig.Add_Click( { PrepareWriteConfig })

$MainForm | Add-Member -Name number -Value 0 -MemberType NoteProperty

$TimerUI = New-Object System.Windows.Forms.Timer
# $TimerUI.Add_Tick({ TimerUI_Tick})

$TimerUI.Enabled = $false

$ButtonPause.Add_Click(
    { 
        If (-not $Variables.Paused) { 
            Update-Status("Stopping miners")
            $Variables.Paused = $True

            # Stop and start mining to immediately switch to paused state without waiting for current NMCycle to finish
            $Variables.RestartCycle = $True

            $ButtonPause.Text = "Mine"
            Update-Status("Mining paused. BrainPlus and Earning tracker running.")
            $LabelBTCD.Text = "Mining Paused | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            # $TimerUI.Stop()
        }
        Else { 
            $Variables.Paused = $False
            $ButtonPause.Text = "Pause"
            $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
            $TimerUI.Start()

            # Stop and start mining to immediately switch to unpaused state without waiting for current sleep to finish
            $Variables.RestartCycle = $True
        }
    }
)

$ButtonStart.Add_Click(
    { 
        If ($Variables.Started) { 
            $ButtonPause.Visible = $False
            Update-Status("Stopping cycle")
            $Variables.Started = $False
            Update-Status("Stopping jobs and miner")

            $Variables.EarningsTrackerJobs | ForEach-Object { $_ | Stop-Job -PassThru | Remove-Job }
            $Variables.EarningsTrackerJobs = @()
            $Variables.BrainJobs | ForEach-Object { $_ | Stop-Job -PassThru | Remove-Job }
            $Variables.BrainJobs = @()

            Stop-Mining

            # Stop idle tracking
            If ($IdleRunspace) { $IdleRunspace.Close() }
            If ($IdlePowershell) { $IdlePowershell.Dispose() }

            $LabelBTCD.Text = "Stopped | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            Update-Status("Idle")
            $ButtonStart.Text = "Start"
            # $TimerUI.Interval = 1000
            $TimerUI.Stop()
        }
        Else { 
            If (-not (IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }
            If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
            PrepareWriteConfig
            $ButtonStart.Text = "Stop"
            InitApplication
            $Variables | Add-Member -Force @{ MainPath = (Split-Path $script:MyInvocation.MyCommand.Path) }

            Start-IdleTracking

            If ($Config.MineWhenIdle) { 
                # Disable the pause button - pausing controlled by idle timer
                $Variables.Paused = $True
                $ButtonPause.Visible = $False
            }
            Else { 
                $ButtonPause.Visible = $True
            }
            $TimerUI.Start()

#$DebugLoop = $true # Enable for debug only!
While ($DebugLoop) {
    NPMCycle #Added temporary, set a trace point.
}

            Start-Mining

            $Variables.Started = $True
        }
    }
)

$ShowWindow = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$ParentPID = (Get-CimInstance -Class Win32_Process -Filter "ProcessID = $pid").ParentProcessId
$ConsoleHandle = (Get-Process -Id $ParentPID).MainWindowHandle
$ConsoleHandle = (Get-Process -Id $pid).MainWindowHandle

$MainForm.Controls.AddRange($MainFormControls)
$RunPage.Controls.AddRange(@($RunPageControls))
$SwitchingPage.Controls.AddRange(@($SwitchingPageControls))
$EstimationsPage.Controls.AddRange(@($EstimationsDGV))
$ConfigPage.Controls.AddRange($ConfigPageControls)
$GroupMonitoringSettings.Controls.AddRange($MonitoringSettingsControls)
$MonitoringPage.Controls.AddRange($MonitoringPageControls)

$MainForm.Add_Load( { Form_Load } )
# $TimerUI.Add_Tick({ TimerUI_Tick})

[Void]$MainForm.ShowDialog()
