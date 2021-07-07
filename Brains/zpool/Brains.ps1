<#
Copyright (c) 2018 MrPlus

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
File:           Brains.ps1
version:        3.9.9.56
version date:   04 July 2021
#>

Set-Location ($args[0])

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

Function Get-Trendline { 
    Param($Data) 
    $n = $Data.count 
    If ($n -le 1) { Return 0 }
    $SumX = 0 
    $SumX2 = 0 
    $SumXY = 0 
    $SumY = 0 
    For ($i = 1; $i -le $n; $i++) { 
        $SumX += $i 
        $SumX2 += ([Math]::Pow($i, 2)) 
        $SumXY += ($i) * ($Data[$i - 1]) 
        $SumY += $Data[$i - 1] 
    } 
    $b = [math]::Round(($SumXY - $SumX * $SumY / $n) / ($SumX2 - $SumX * $SumX / $n), 15)
    $a = [math]::Round($SumY / $n - $b * ($SumX / $n), 15)
    Return @($a, $b) 
}

Function Get-Median {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    $NumberSeries += @()
    $NumberSeries += $Number
    $SortedNumbers = @($NumberSeries | Sort-Object)
    If ($NumberSeries.Count % 2) {
        $SortedNumbers[($SortedNumbers.Count / 2) - 1]
    }
    Else {
        ($SortedNumbers[($SortedNumbers.Count / 2)] + $SortedNumbers[($SortedNumbers.Count / 2) - 1]) / 2
    }                        
} 

$AlgoObject = @()
$MathObject = @()
$TestDisplay = @()
$PrevTrend = 0

# Remove progress info from job.childjobs.Progress to avoid memory leak
$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

While ($true) {
    If (Test-Path ".\BrainConfig.xml") {
        $Config = Import-Clixml ".\BrainConfig.xml"
        $SampleSizeMinutes = $Config.SampleSizeMinutes
        $TrendSpanSizeMinutes = $Config.TrendSpanSizeMinutes
        $SampleHalfPower = $Config.SampleHalfPower
        $ManualPriceFactor = $Config.ManualPriceFactor
        $Interval = $Config.Interval
        $LogDataPath = $Config.LogDataPath
        $TransferFile = $Config.TransferFile
        $EnableLog = $Config.EnableLog
        $PoolName = $Config.PoolName
        $PoolStatusUri = $Config.PoolStatusUri
        $PerAPIFailPercentPenalty = $Config.PerAPIFailPercentPenalty
        $AllowedAPIFailureCount = $Config.AllowedAPIFailureCount
        $UseFullTrust = $Config.UseFullTrust
    }
    Else { Return }

    $CurDate = (Get-Date).ToUniversalTime()
    $RetryInterval = 0

    Try {
        $AlgoData = Invoke-RestMethod -Uri $PoolStatusUri -Headers @{"Cache-Control" = "no-cache" }
        $APICallFails = 0
    }
    Catch {
        $APICallFails++
        $RetryInterval = $Interval * [math]::max(0, $APICallFails - $AllowedAPIFailureCount)
    }

    ForEach ($Algo in ($AlgoData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)) {
        $BasePrice = If ($AlgoData.$Algo.actual_last24h) { [Double]($AlgoData.$Algo.actual_last24h / 1000) } Else { [Double]($AlgoData.$Algo.estimate_last24h) }
        $AlgoData.$Algo.estimate_current = [math]::max(0, [Double]($AlgoData.$Algo.estimate_current * ( 1 - ($PerAPIFailPercentPenalty * [math]::max(0, $APICallFails - $AllowedAPIFailureCount) / 100))))
        $AlgoObject += [PSCustomObject]@{
            Date               = $CurDate
            Name               = $AlgoData.$Algo.name
            Port               = $AlgoData.$Algo.port
            coins              = $AlgoData.$Algo.coins
            Fees               = $AlgoData.$Algo.Fees
            Hashrate           = $AlgoData.$Algo.Hashrate
            Workers            = $AlgoData.$Algo.Workers
            estimate_current   = $AlgoData.$Algo.estimate_current -as [Double]
            estimate_last24h   = $AlgoData.$Algo.estimate_last24h
            actual_last24h     = $BasePrice
            hashrate_last24h   = $AlgoData.$Algo.hashrate_last24h
            Last24Drift        = $AlgoData.$Algo.estimate_current - $BasePrice
            Last24DriftSign    = If (($AlgoData.$Algo.estimate_current - $BasePrice) -ge 0) { "Up" } Else { "Down" }
            Last24DriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
            FirstDate          = ($AlgoObject[0]).Date
            TimeSpan           = If ($AlgoObject.Date -ne $null) { (New-TimeSpan -Start ($AlgoObject[0]).Date -End $CurDate).TotalMinutes }
        }
    }

    # Created here For performance optimization, minimize # of lookups
    $FirstAlgoObject = $AlgoObject[0] # | Where-Object {$_.date -eq ($AlgoObject.Date | Measure-Object -Minimum).Minimum}
    $CurAlgoObject = $AlgoObject | Where-Object { $_.date -eq $CurDate }
    $TrendSpanSizets = New-TimeSpan -Minutes $TrendSpanSizeMinutes
    $SampleSizets = New-TimeSpan -Minutes $SampleSizeMinutes
    $SampleSizeHalfts = New-TimeSpan -Minutes ($SampleSizeMinutes / 2)
    $GroupAvgSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupAvgSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeNoPercent = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24Drift } }

    ForEach ($Name in ($AlgoObject.Name | Select-Object -Unique)) {
        $PenaltySampleSize = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Median)
        $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
        $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
        $Penalty = ($PenaltySampleSizeHalf * $SampleHalfPower + $PenaltySampleSizeNoPercent) / ($SampleHalfPower + 1)
        $LiveTrend = ((Get-Trendline ($AlgoObjects | Where-Object { $_.Name -eq $Name }).estimate_current)[1])
        # $Price = (($Penalty) + ($CurAlgoObject | Where-Object {$_.Name -eq $Name}).actual_last24h) 
        $Price = [math]::max( 0, [Double](($Penalty) + ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h) )
        If ( $UseFullTrust ) {
            If ( $Penalty -gt 0 ) {
                $Price = [Math]::max([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
            }
            Else {
                $Price = [Math]::min([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
            }
        }

        If ($EnableLog) { 
            $MathObject += [PSCustomObject]@{
                Name         = $Name
                DriftAvg     = (($CurAlgoObject | Where-Object { $_.Name -eq $Name }).Last24DriftPercent | Measure-Object -Average).Average
                TimeSpan     = ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).TimeSpan
                UpDriftAvg   = ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Avg
                DownDriftAvg = ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Avg
                Penalty      = $Penalty
                PlusPrice    = $Price
                PlusPriceRaw = [math]::max( 0, [Double](($Penalty) + ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h) )
                PlusPriceMax = $Price
                CurrentLive  = ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current
                Current24hr  = ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h
                Date         = $CurDate
                LiveTrend    = $LiveTrend
                APICallFails = $APICallFails
            }
        }
        # $AlgoData.($Name).actual_last24h = $Price
        $AlgoData.($Name) | Add-Member -Force @{ Plus_Price = $Price }
    }

    If ($EnableLog) { $MathObject | Export-Csv -NoTypeInformation -Append $LogDataPath }

    $AlgoData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
        If ([Double]($AlgoData.$_.actual_last24h) -gt 0) { 
            $AlgoData.$_ | Add-Member Updated $CurDate
        }
        Else { 
            $AlgoData.PSObject.Properties.Remove($_)
        }
    }
    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Set-Content $TransferFile

    # Limit to only sample size + 10 minutes min history
    $AlgoObject = $AlgoObject | Where-Object { $_.Date -ge $CurDate.AddMinutes( - ($SampleSizeMinutes + 10)) }

    $MathObject = @()
    Start-Sleep ($Interval + $RetryInterval - (Get-Date).Second)
}
