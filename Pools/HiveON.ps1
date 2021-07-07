<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru


NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           ZergPoolCoins.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = $Name -replace "24hr" -replace "Coins$"

If ($Config.Wallets) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://hiveon.net/api/v1/stats/pool" -Headers @{"Cache-Control" = "no-cache" } -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Request.cryptoCurrencies | Where-Object { $Config.Wallets.($_.Name) } | ForEach-Object { 

        $Currency = $_.name
        $CoinName = $_.title
        $Algorithm_Norm = Get-Algorithm $Currency

        $Divisor = $_.profitPerPower

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]($Request.stats.$Currency.expectedReward24H * $Variables.Rates.$Currency.BTC / $Divisor))

        Try { $EstimateFactor = $Request.stats.$Currency.expectedReward24H / $Request.stats.$Currency.meanExpectedReward24H }
        Catch { $EstimateFactor = 1 }

        ForEach ($Server in $_.Servers) {
            $Region = $Server.Region
            If ($Region_Norm = Get-Region $Region) { # Only accept regions that can be resolved by regions.txt

                [PSCustomObject]@{ 
                    Algorithm                = [String]$Algorithm_Norm
                    CoinName                 = [String]$CoinName
                    Currency                 = [String]$Currency
                    Price                    = [Double]$Stat.Live
                    StablePrice              = [Double]$Stat.Week
                    MarginOfError            = [Double]$Stat.Week_Fluctuation
                    EarningsAdjustmentFactor = [Double]$PoolsConfig.$Name_Norm.EarningsAdjustmentFactor
                    Host                     = [String]$Server.host
                    Port                     = [UInt16]$Server.ports[0]
                    User                     = "$($Config.Wallets.$Currency).$($PoolsConfig.$Name_Norm.WorkerName)"
                    Pass                     = "x"
                    Region                   = [String]$Region_Norm
                    SSL                      = [Bool]$false
                    Fee                      = [Decimal]0
                    EstimateFactor           = [Decimal]$EstimateFactor
                }
            }
        }
    }
}
