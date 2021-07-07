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
File:           BMiner.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Include.psm1

class BMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api/v1/status/solver"
        $Request2 = "http://localhost:$($this.Port)/api/v1/status/stratum"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not ($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers })) { Return $null }

        If ($this.AllowedBadShareRatio) { 
            #Read stratum info from API
            Try { 
                $Data | Add-Member stratums (Invoke-RestMethod -Uri $Request2 -TimeoutSec $Timeout).stratums
            }
            Catch { 
                Return $null
            }
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = ""
        $HashRate_Value = [Double]0
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        [Int]$Index = 0

        $this.Algorithm | ForEach-Object {
            $Index = $this.Algorithm.IndexOf($_)
            $HashRate_Name = $_
            $HashRate_Value = [Double](($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers[$Index] }).speed_info.hash_rate | Measure-Object -Sum).Sum
            If (-not $HashRate_Value) { $HashRate_Value = [Double](($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers[$Index] }).speed_info.solution_rate | Measure-Object -Sum).Sum}

            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]$Data.stratums.($Data.stratums | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).accepted_shares
                $Shares_Rejected = [Int64]$Data.stratums.($Data.stratums | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).rejected_shares
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }
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
