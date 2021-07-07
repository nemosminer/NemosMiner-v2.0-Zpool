<#
Copyright (c) 2018 MrPlus

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
File:           Brains.ps1
version:        3.8.1.3
version date:   12 November 2019
#>


set-location ($args[0])
# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

function Get-Trendline { 
    param ($data) 
    $n = $data.count 
    If ($n -le 1) { return 0 }
    $sumX = 0 
    $sumX2 = 0 
    $sumXY = 0 
    $sumY = 0 
    for ($i = 1; $i -le $n; $i++) { 
        $sumX += $i 
        $sumX2 += ([Math]::Pow($i, 2)) 
        $sumXY += ($i) * ($data[$i - 1]) 
        $sumY += $data[$i - 1] 
    } 
    $b = [math]::Round(($sumXY - $sumX * $sumY / $n) / ($sumX2 - $sumX * $sumX / $n), 15)
    $a = [math]::Round($sumY / $n - $b * ($sumX / $n), 15)
    return @($a, $b) 
}

function Get-Median {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    begin {
        $numberSeries += @()
    }
    process {
        $numberSeries += $number
    }
    end {
        $sortedNumbers = @($numberSeries | Sort-Object)
        if ($numberSeries.Count % 2) {
            $sortedNumbers[($sortedNumbers.Count / 2) - 1]
        }
        else {
            ($sortedNumbers[($sortedNumbers.Count / 2)] + $sortedNumbers[($sortedNumbers.Count / 2) - 1]) / 2
        }                        
    }
} 

$AlgoObject = @()
$MathObject = @()
$MathObjectFormated = @()
$TestDisplay = @()
$PrevTrend = 0

# Remove progress info from job.childjobs.Progress to avoid memory leak
$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"


While ($true) {
    #Get-Config{
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
    else { return }
    $CurDate = Get-Date
    $RetryInterval = 0
    try {
        # $AlgoData = Invoke-WebRequest $PoolStatusUri -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control"="no-cache"} | ConvertFrom-Json
        $AlgoData = Invoke-WebRequest $PoolStatusUri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json
        $APICallFails = 0
    }
    catch {
        $APICallFails++
        $RetryInterval = $Interval * [math]::max(0, $APICallFails - $AllowedAPIFailureCount)
    }
    Foreach ($Algo in ($AlgoData | gm -MemberType NoteProperty).Name) {
        $BasePrice = If ($AlgoData.($Algo).actual_last24h) { $AlgoData.($Algo).actual_last24h / 1000 } else { $AlgoData.($Algo).estimate_last24h }
        $AlgoData.($Algo).estimate_current = [math]::max(0, [decimal]($AlgoData.($Algo).estimate_current * ( 1 - ($PerAPIFailPercentPenalty * [math]::max(0, $APICallFails - $AllowedAPIFailureCount) / 100))))
        $AlgoObject += [PSCustomObject]@{
            Date               = $CurDate
            Name               = $AlgoData.($Algo).name
            Port               = $AlgoData.($Algo).port
            coins              = $AlgoData.($Algo).coins
            Fees               = $AlgoData.($Algo).Fees
            Hashrate           = $AlgoData.($Algo).Hashrate
            Workers            = $AlgoData.($Algo).Workers
            estimate_current   = $AlgoData.($Algo).estimate_current -as [Decimal]
            estimate_last24h   = $AlgoData.($Algo).estimate_last24h
            actual_last24h     = $BasePrice
            hashrate_last24h   = $AlgoData.($Algo).hashrate_last24h
            Last24Drift        = $AlgoData.($Algo).estimate_current - $BasePrice
            Last24DriftSign    = If (($AlgoData.($Algo).estimate_current - $BasePrice) -ge 0) { "Up" } else { "Down" }
            Last24DriftPercent = if ($BasePrice -gt 0) { ($AlgoData.($Algo).estimate_current - $BasePrice) / $BasePrice } else { 0 }
            FirstDate          = ($AlgoObject[0]).Date
            TimeSpan           = If ($AlgoObject.Date -ne $null) { (New-TimeSpan -Start ($AlgoObject[0]).Date -End $CurDate).TotalMinutes }
        }
    }

    # Created here for performance optimization, minimize # of lookups
    $FirstAlgoObject = $AlgoObject[0] # | ? {$_.date -eq ($AlgoObject.Date | measure -Minimum).Minimum}
    $CurAlgoObject = $AlgoObject | ? { $_.date -eq $CurDate }
    $TrendSpanSizets = New-TimeSpan -Minutes $TrendSpanSizeMinutes
    $SampleSizets = New-TimeSpan -Minutes $SampleSizeMinutes
    $SampleSizeHalfts = New-TimeSpan -Minutes ($SampleSizeMinutes / 2)
    $GroupAvgSampleSize = $AlgoObject | ? { $_.Date -ge ($CurDate - $SampleSizets) } | group Name, Last24DriftSign | select Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | measure -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSize = $AlgoObject | ? { $_.Date -ge ($CurDate - $SampleSizets) } | group Name | select Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | measure -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupAvgSampleSizeHalf = $AlgoObject | ? { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | group Name, Last24DriftSign | select Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | measure -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeHalf = $AlgoObject | ? { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | group Name | select Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | measure -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeNoPercent = $AlgoObject | ? { $_.Date -ge ($CurDate - $SampleSizets) } | group Name | select Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | measure -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24Drift } }

    Foreach ($Name in ($AlgoObject.Name | Select -Unique)) {
        $PenaltySampleSize = ((($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | ? { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSize | ? { $_.Name -eq $Name }).Median)
        $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | ? { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | ? { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | ? { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeHalf | ? { $_.Name -eq $Name }).Median)
        $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | ? { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | ? { $_.Name -eq $Name }).Median)
        $Penalty = ($PenaltySampleSizeHalf * $SampleHalfPower + $PenaltySampleSizeNoPercent) / ($SampleHalfPower + 1)
        $LiveTrend = ((Get-Trendline ($AlgoObjects | ? { $_.Name -eq $Name }).estimate_current)[1])
        # $Price = (($Penalty) + ($CurAlgoObject | ? {$_.Name -eq $Name}).actual_last24h) 
        $Price = [math]::max( 0, [decimal](($Penalty) + ($CurAlgoObject | ? { $_.Name -eq $Name }).actual_last24h) )
        If ( $UseFullTrust ) {
            If ( $Penalty -gt 0 ) {
                $Price = [Math]::max([decimal]$Price, [decimal]($CurAlgoObject | ? { $_.Name -eq $Name }).estimate_current)
            }
            else {
                $Price = [Math]::min([decimal]$Price, [decimal]($CurAlgoObject | ? { $_.Name -eq $Name }).estimate_current)
            }
        }

        $MathObject += [PSCustomObject]@{
            Name         = $Name
            DriftAvg     = (($CurAlgoObject | ? { $_.Name -eq $Name }).Last24DriftPercent | measure -Average).Average
            TimeSpan     = ($CurAlgoObject | ? { $_.Name -eq $Name }).TimeSpan
            UpDriftAvg   = ($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Up" }).Avg
            DownDriftAvg = ($GroupAvgSampleSize | ? { $_.Name -eq $Name + ", Down" }).Avg
            Penalty      = $Penalty
            PlusPrice    = $Price
            PlusPriceRaw = [math]::max( 0, [decimal](($Penalty) + ($CurAlgoObject | ? { $_.Name -eq $Name }).actual_last24h) )
            PlusPriceMax = $Price
            CurrentLive  = ($CurAlgoObject | ? { $_.Name -eq $Name }).estimate_current
            Current24hr  = ($CurAlgoObject | ? { $_.Name -eq $Name }).actual_last24h
            Date         = $CurDate
            LiveTrend    = $LiveTrend
            APICallFails = $APICallFails
        }
        # $AlgoData.($Name).actual_last24h = $Price
        $AlgoData.($Name) | Add-Member -Force @{Plus_Price = $Price }
    }
    if ($EnableLog) { $MathObject | Export-Csv -NoTypeInformation -Append $LogDataPath }
    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Set-Content $TransferFile

    # Limit to only sample size + 10 minutes min history
    $AlgoObject = $AlgoObject | ? { $_.Date -ge $CurDate.AddMinutes( - ($SampleSizeMinutes + 10)) }
    (($GroupMedSampleSize | ? { $_.Name -eq $Name }).Count)

    $MathObject = @()
    Sleep ($Interval + $RetryInterval - (Get-Date).Second)
}


