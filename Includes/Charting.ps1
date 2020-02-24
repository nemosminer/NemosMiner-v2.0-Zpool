<#
Copyright (c) 2018 MrPlus
Charting.ps1 File Written By MrPlusGH https://github.com/MrPlusGH

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
File:           Charting.ps1
version:        3.8.1.3
version date:   12 November 2019
#>


param(
   [Parameter(Mandatory = $True)]
   [String]$ChartType = "", 
   [Parameter(Mandatory = $true)]
   [String]$Width = 700, 
   [Parameter(Mandatory = $true)]
   [String]$Height = 85 
)

Function GetNextColor {
   param(
      [Parameter(Mandatory = $true)]
      [String]$BaseColorHex,
      [Parameter(Mandatory = $true)]
      [Int]$Factor
   )
   # Convert to RGB
   $R = [convert]::ToInt32($BaseColorHex.Substring(0, 2), 16)
   $G = [convert]::ToInt32($BaseColorHex.Substring(2, 2), 16)
   $B = [convert]::ToInt32($BaseColorHex.Substring(4, 2), 16)
   # Apply change Factor
   $R = $R + $Factor
   $G = $G + $Factor
   $B = $B + $Factor
   # Convert to Hex
   $R = If (([convert]::Tostring($R, 16)).Length -eq 1) { "0$([convert]::Tostring($R,16))" } else { [convert]::Tostring($R, 16) }
   $G = If (([convert]::Tostring($G, 16)).Length -eq 1) { "0$([convert]::Tostring($R,16))" } else { [convert]::Tostring($G, 16) }
   $B = If (([convert]::Tostring($B, 16)).Length -eq 1) { "0$([convert]::Tostring($R,16))" } else { [convert]::Tostring($B, 16) }
   $R + $G + $B
}

[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition

# Defined Charts list
# Front7DaysEarnings
# FrontDayEarningsPoolSplit
# DayPoolSplit

Switch ($ChartType) {
   "Front7DaysEarnings" {
      $Datasource = If (Test-Path ".\Logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null) -ge (Get-Date).AddDays(-8) -and [DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null) -le (Get-Date).AddDays(-1)} }
      $Datasource = $Datasource | Select-Object *, @{Name = "DaySum"; Expression = { $Date = $_.Date; (($Datasource | Where-Object { $_.Date -eq $Date }).DailyEarnings | Measure-Object -sum).sum } }

      $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
      $ChartTitle.Text = ("Earnings Tracker: Earnings of the past 7 days")
      $ChartTitle.Font = "Arial, 10pt"
      $ChartTitle.Alignment = "TopCenter"

      $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
      $Chart.Titles.Add($ChartTitle)
      $Chart.Width = $Width
      $Chart.Height = $Height

      # $Chart.BackColor = [System.Drawing.Color]::White
      $Chart.BackColor = "#F0F0F0"

      $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
      $ChartArea.Name = "ChartArea1"
      $ChartArea.BackColor = "#2B3232"
      # $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
      $ChartArea.BackSecondaryColor = "#777E7E"
      $ChartArea.BackGradientStyle = 3
      $ChartArea.AxisX.labelStyle.Enabled = $False
      $ChartArea.AxisX.Enabled = 2
      $ChartArea.AxisX.MajorGrid.Enabled = $False
      $ChartArea.AxisY.MajorGrid.Enabled = $True
      $ChartArea.AxisY.MajorGrid.LineColor = "#FFFFFF"
      $ChartArea.AxisY.labelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
      # $ChartArea.AxisY.IntervalAutoMode = 0
      $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * 1000 / 4, 3)
      $Chart.ChartAreas.Add($ChartArea)

      # $BaseColor = "424B54"
      $BaseColor = "FFFFFF"
      # $BaseColor = "F7931A"
      $Color = $BaseColor
      $A = 255

      [void]$Chart.Series.Add("Total")
      $Chart.Series["Total"].ChartType = "Column"
      $Chart.Series["Total"].BorderWidth = 3
      # $Chart.Series[$Pool].IsVisibleInLegend = $true
      $Chart.Series["Total"].chartarea = "ChartArea1"
      # $Chart.Series[$Pool].Legend = "Legend1"
      # $Chart.Series[$Pool].color = "#E3B64C"
      $Chart.Series["Total"].color = "#FFFFFF"
      # $Chart.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
      $Chart.Series["Total"].label = "#VALY{N3}"
      # $Chart.Series[$Pool].LabelStyle.ForeColor = "#000000"
      $Chart.Series["Total"].ToolTip = "#VALX: #VALY mBTC" # - Total: #TOTAL mBTC";
      # $Datasource | Select-Object Date, DaySum -Unique | ForEach-Object {$Chart.Series["Total"].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DaySum*1000))) | Out-Null }
      $Datasource | Select-Object Date, DaySum -Unique | ForEach-Object { $Chart.Series["Total"].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DaySum * 1000))) | Out-Null }

      $Chart.Series | ForEach-Object { $_.CustomProperties = "DrawSideBySide=True" }
   }
   "Front7DaysEarningsWithPoolSplit" {
      $Datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { [DateTime]$_.Date -ge (Get-Date).AddDays(-7) } }
      $Datasource = $Datasource | Select-Object *, @{Name = "DaySum"; Expression = { $Date = $_.date; (($Datasource | Where-Object { $_.Date -eq $Date }).DailyEarnings | Measure-Object -sum).sum } }

      $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
      $ChartTitle.Text = ("Front7DaysEarningsWithPoolSplit")
      $ChartTitle.Font = "Arial, 10pt"
      $ChartTitle.Alignment = "TopCenter"

      $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
      $Chart.Titles.Add($ChartTitle)
      $Chart.Width = $Width
      $Chart.Height = $Height

      # $Chart.BackColor = [System.Drawing.Color]::White
      $Chart.BackColor = "#F0F0F0"

      $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
      $ChartArea.Name = "ChartArea1"
      $ChartArea.BackColor = "#2B3232"
      # $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
      $ChartArea.BackSecondaryColor = "#777E7E"
      $ChartArea.BackGradientStyle = 3
      $ChartArea.AxisX.labelStyle.Enabled = $False
      $ChartArea.AxisX.Enabled = 2
      $ChartArea.AxisX.MajorGrid.Enabled = $False
      $ChartArea.AxisY.MajorGrid.Enabled = $True
      $ChartArea.AxisY.MajorGrid.LineColor = "#FFFFFF"
      $ChartArea.AxisY.labelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
      # $ChartArea.AxisY.IntervalAutoMode = 0
      $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * 1000 / 4, 3)
      $Chart.ChartAreas.Add($ChartArea)

      # $BaseColor = "424B54"
      $BaseColor = "FFFFFF"
      # $BaseColor = "F7931A"
      $Color = $BaseColor
      $A = 255
      ForEach ($Pool in ($Datasource.Pool | Sort-Object -unique)) {
         $A = $A - 20
         $Color = GetNextColor -BaseColorHex $Color -Factor -10

         [void]$Chart.Series.Add($Pool)
         $Chart.Series[$Pool].ChartType = "StackedColumn"
         $Chart.Series[$Pool].BorderWidth = 3
         # $Chart.Series[$Pool].IsVisibleInLegend = $true
         $Chart.Series[$Pool].chartarea = "ChartArea1"
         # $Chart.Series[$Pool].Legend = "Legend1"
         # $Chart.Series[$Pool].color = "#E3B64C"
         $Chart.Series[$Pool].color = "#$($Color)"
         # $Chart.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
         # $Chart.Series[$Pool].label = "#VALY"
         $Chart.Series[$Pool].ToolTip = "#SERIESNAME: #VALY mBTC" # - Total: #TOTAL mBTC";
         $Datasource | Where-Object { $_.Pool -eq $Pool } | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DailyEarnings * 1000))) | Out-Null }
      }

      [void]$Chart.Series.Add("Total")
      $Chart.Series["Total"].ChartType = "Column"
      $Chart.Series["Total"].BorderWidth = 3
      # $Chart.Series[$Pool].IsVisibleInLegend = $true
      $Chart.Series["Total"].chartarea = "ChartArea1"
      # $Chart.Series[$Pool].Legend = "Legend1"
      # $Chart.Series[$Pool].color = "#E3B64C"
      $Chart.Series["Total"].color = "#FFFFFF"
      # $Chart.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
      # $Chart.Series[$Pool].label = "#VALY"
      $Chart.Series["Total"].ToolTip = "#SERIESNAME: #VALY mBTC" # - Total: #TOTAL mBTC";
      $Datasource | Select-Object Date, DaySum -Unique | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DaySum * 1000))) | Out-Null }

      $Chart.Series | ForEach-Object { $_.CustomProperties = "DrawSideBySide=True" }
   }
   "DayPoolSplit" {
      $Datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { $_.Date -eq (Get-Date).ToShortDateString() } }
      $Datasource = $Datasource | Where-Object { $_.DailyEarnings -gt 0 } | Sort-Object DailyEarnings -Descending

      $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
      $ChartTitle.Text = ("Todays earnings per pool")
      $ChartTitle.Font = "Arial, 10pt"
      $ChartTitle.Alignment = "TopCenter"

      $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
      $Chart.Titles.Add($ChartTitle)
      $Chart.Width = $Width
      $Chart.Height = $Height

      # $Chart.BackColor = [System.Drawing.Color]::White
      $Chart.BackColor = "#F0F0F0"

      $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
      $ChartArea.Name = "ChartArea1"
      $ChartArea.BackColor = "#2B3232"
      # $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
      $ChartArea.BackSecondaryColor = "#777E7E"
      $ChartArea.BackGradientStyle = 3
      $ChartArea.AxisX.labelStyle.Enabled = $False
      $ChartArea.AxisX.Enabled = 2
      $ChartArea.AxisX.MajorGrid.Enabled = $False
      $ChartArea.AxisY.MajorGrid.Enabled = $True
      $ChartArea.AxisY.MajorGrid.LineColor = "#FFFFFF"
      $ChartArea.AxisY.labelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
      # $ChartArea.AxisY.IntervalAutoMode = 0
      $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * 1000 / 4, 3)
      $Chart.ChartAreas.Add($ChartArea)

      # legend 
      $Legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
      $Legend.name = "Legend1"
      # $Chart.Legends.Add($Legend)

      # $BaseColor = "424B54"
      $BaseColor = "FFFFFF"
      # $BaseColor = "F7931A"
      $Color = $BaseColor
      $A = 255
      ForEach ($Pool in ($Datasource.Pool)) {
         $A = $A - 20
         $Color = GetNextColor -BaseColorHex $Color -Factor -20

         [void]$Chart.Series.Add($Pool)
         $Chart.Series[$Pool].ChartType = "StackedColumn"
         $Chart.Series[$Pool].BorderWidth = 1
         $Chart.Series[$Pool].BorderColor = "#FFFFFF"
         # $Chart.Series[$Pool].IsVisibleInLegend = $true
         $Chart.Series[$Pool].chartarea = "ChartArea1"
         # $Chart.Series[$Pool].Legend = "Legend1"
         # $Chart.Series[$Pool].color = "#E3B64C"
         $Chart.Series[$Pool].color = "#$($Color)"
         # $Chart.Series[$Pool].color = "#FFFFFF"
         # $Chart.Series[$Pool].color = [System.Drawing.Color]::FromArgb($A,247,147,26)
         # $Chart.Series[$Pool].label = "#SERIESNAME: #VALY mBTC"
         $Chart.Series[$Pool].ToolTip = "#SERIESNAME: #VALY mBTC" # - Total: #TOTAL mBTC";
         $Datasource | Where-Object { $_.Pool -eq $Pool } | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Pool , ("{0:N3}" -f ([Decimal]$_.DailyEarnings * 1000))) | Out-Null }
         # $Chart.Series["Data"].Points.DataBindXY($Datasource.pool, $Datasource.DailyEarnings)
      }
   }
}

# save chart
# $Chart.SaveImage("$scriptpath\ChartTest.png","png") | Out-Null
$Chart
