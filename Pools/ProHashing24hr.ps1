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
File:           ProHashing24hr.ps1
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

If ($PoolsConfig.$Name_Norm.UserName) { 
    Try {
        $Request = (Invoke-RestMethod -Uri "https://prohashing.com/api/v1/status" -TimeoutSec $Config.PoolTimeout -Headers @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }).data
        $Currencies = (Invoke-RestMethod -Uri "https://prohashing.com/api/v1/currencies" -TimeoutSec $Config.PoolTimeout -Headers @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" }).data
    }
    Catch { Return }

    If (-not $Request) { Return }

    $PoolHost = "prohashing.com"
    # $PriceField = "actual_last24h"
    $PriceField = "actual_last24h"
    $PoolRegions = @("EU", "US")

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.estimate_current) -gt 0 } | ForEach-Object {
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolPort = $Request.$_.port
        $Fee = [Decimal]$Request.$_."$($MiningMode)_fee"
        $Divisor = [Double]$Request.$_.mbtc_mh_factor

        $CoinName = ""
        $Currency = ""
        $Pass = @("a=$Algorithm", "n=$($PoolsConfig.$Name_Norm.WorkerName)")

        If ($PoolsConfig.$Name_Norm.MiningMode -eq "PPLNS") { $Pass += "m=PPLNS" }

        $Currency = $Currencies | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Currencies.$_.Algo -eq $Algorithm }
        If ($Currency.Count -eq 1) { 
            If ($CoinName = $Currencies.$Currency.name) { $Pass += "c=$CoinName" }
        }
        Else { 
            $Currency = ""
        }
    
        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor)

        ForEach ($Region in $PoolRegions) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{
                Algorithm                = [String]$Algorithm_Norm
                CoinName                 = [String]($CoinName -ireplace "$Algorithm$" -ireplace "coin$", "Coin" -ireplace "cash$", "Cash" -ireplace "gold$", "Gold" -ireplace "^groestl$", "GroestlCoin" -ireplace "^myriad", "MyriadCoin")
                Currency                 = [String]$Currency
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolsConfig.$Name_Norm.EarningsAdjustmentFactor
                Host                     = "$(If ($Region -eq "eu") {"eu."})$PoolHost"
                Port                     = [UInt16]$PoolPort
                User                     = [String]$PoolsConfig.$Name_Norm.UserName
                Pass                     = [String]($Pass -join ',')
                Region                   = [String]$Region_Norm
                SSL                      = [Bool]$false
                Fee                      = $Fee
                EstimateFactor           = [Decimal]1
            }
        }
    }
}
