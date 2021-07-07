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
File:           EthMiner.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Include.psm1

class EthMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server "localhost" -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]($this.Algorithm[0])
        $HashRate_Value = [Double]($Data.result[2] -split ";")[0]
        If ($Data.result[0] -notmatch "^TT-Miner") { 
            If ($this.Algorithm -eq "EtcHash")          { $HashRate_Value *= 1000 }
            ElseIf ($this.Algorithm -eq "Ethash")       { $HashRate_Value *= 1000 }
            ElseIf ($this.Algorithm -eq "EthashLowMem") { $HashRate_Value *= 1000 }
            ElseIf ($this.Algorithm -eq "UbqHash")      { $HashRate_Value *= 1000 }
        }
        If ($this.Algorithm -eq "NeoScrypt")           { $HashRate_Value *= 1000 }
        ElseIf ($this.Algorithm -eq "BitcoinInterest") { $HashRate_Value *= 1000 }

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]($Data.result[2] -split ";")[1]
            $Shares_Rejected = [Int64]($Data.result[2] -split ";")[2]
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.Algorithm -ne $HashRate_Name) { # Dual algo mining

            $HashRate_Name = [String]($this.Algorithm -ne $HashRate_Name)
            $HashRate_Value = [Double]($Data.result[4] -split ";")[0]

            If ($this.Algorithm -eq "Blake2s") { $HashRate_Value *= 1000 }
            If ($this.Algorithm -eq "Keccak") { $HashRate_Value *= 1000 }

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]($Data.result[4] -split ";")[1]
                $Shares_Rejected = [Int64]($Data.result[4] -split ";")[2]
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }

            If ($HashRate_Name) { 
                $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
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
