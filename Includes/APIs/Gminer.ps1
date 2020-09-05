﻿using module ..\Include.psm1

class Gminer : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/stat"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
        }

        $Data | ConvertTo-Json -Compress > ".\Debug\Gminer_$($this.algorithm -join '-').json"

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = ($Data.total_accepted_shares)
            $Shares_Rejected = ($Data.total_rejected_shares)
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($this.Algorithm -ne $HashRate_Name) { 
            $HashRate_Name = [String]($this.Algorithm -ne $HashRate_Name)
            $HashRate_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]($Data.total_accepted_shares2)
                $Shares_Rejected = [Int64]($Data.total_rejected_shares2)
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }

            If ($HashRate_Name) { 
                $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            }
        }

        If ($this.CalculatePowerCost) { 
            $PowerUsage = [Double](($Data.devices | Measure-Object power_usage -Sum).Sum)
        }

        If ($HashRate[0].PSObject.Properties.Value) { 
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

