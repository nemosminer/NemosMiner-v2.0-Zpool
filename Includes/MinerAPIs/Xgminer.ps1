<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru

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
File:           Xgminer.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Include.psm1

class Xgminer : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = @{ command = "summary"; parameter = "" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server "localhost" -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response.Substring($Response.IndexOf("{"), $Response.LastIndexOf("}") - $Response.IndexOf("{") + 1) -replace " ", "_" | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = If ($Data.SUMMARY.HS_5s) { [Double]$Data.SUMMARY.HS_5s * [Math]::Pow(1000, 0) }
        elseif ($Data.SUMMARY.KHS_5s) { [Double]$Data.SUMMARY.KHS_5s * [Math]::Pow(1000, 1) }
        elseif ($Data.SUMMARY.MHS_5s) { [Double]$Data.SUMMARY.MHS_5s * [Math]::Pow(1000, 2) }
        elseif ($Data.SUMMARY.GHS_5s) { [Double]$Data.SUMMARY.GHS_5s * [Math]::Pow(1000, 3) }
        elseif ($Data.SUMMARY.THS_5s) { [Double]$Data.SUMMARY.THS_5s * [Math]::Pow(1000, 4) }
        elseif ($Data.SUMMARY.PHS_5s) { [Double]$Data.SUMMARY.PHS_5s * [Math]::Pow(1000, 5) }
        elseif ($Data.SUMMARY.KHS_30s) { [Double]$Data.SUMMARY.KHS_30s * [Math]::Pow(1000, 1) }
        elseif ($Data.SUMMARY.MHS_30s) { [Double]$Data.SUMMARY.MHS_30s * [Math]::Pow(1000, 2) }
        elseif ($Data.SUMMARY.GHS_30s) { [Double]$Data.SUMMARY.GHS_30s * [Math]::Pow(1000, 3) }
        elseif ($Data.SUMMARY.THS_30s) { [Double]$Data.SUMMARY.THS_30s * [Math]::Pow(1000, 4) }
        elseif ($Data.SUMMARY.PHS_30s) { [Double]$Data.SUMMARY.PHS_30s * [Math]::Pow(1000, 5) }
        elseif ($Data.SUMMARY.HS_av) { [Double]$Data.SUMMARY.HS_av * [Math]::Pow(1000, 0) }
        elseif ($Data.SUMMARY.KHS_av) { [Double]$Data.SUMMARY.KHS_av * [Math]::Pow(1000, 1) }
        elseif ($Data.SUMMARY.MHS_av) { [Double]$Data.SUMMARY.MHS_av * [Math]::Pow(1000, 2) }
        elseif ($Data.SUMMARY.GHS_av) { [Double]$Data.SUMMARY.GHS_av * [Math]::Pow(1000, 3) }
        elseif ($Data.SUMMARY.THS_av) { [Double]$Data.SUMMARY.THS_av * [Math]::Pow(1000, 4) }
        elseif ($Data.SUMMARY.PHS_av) { [Double]$Data.SUMMARY.PHS_av * [Math]::Pow(1000, 5) }

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.SUMMARY.accepted
            $Shares_Rejected = [Int64]$Data.SUMMARY.rejected
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            $Sample = [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
            Return $Sample
        }
        Return $null
    }
}

