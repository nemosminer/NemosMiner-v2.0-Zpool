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
File:           MiningPoolHub.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$RetryCount = 3
$RetryDelay = 10

While (-not ($APIResponse) -and $RetryCount -gt 0 -and $Config.MiningPoolHubAPIKey) { 
    $RetryCount--
    Try { 
        If ($APIResponse = Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getuserallbalances&api_key=$($Config.MiningPoolHubAPIKey)" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop) { 

            If ($Config.LogBalanceAPIResponse -eq $true) { 
                $APIResponse | Add-Member DateTime ((Get-Date).ToUniversalTime()) -Force
                $APIResponse | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$($Name).json"
            }

            $APIResponse.getuserallbalances.data | Where-Object coin | Where-Object confirmed -gt 0 | ForEach-Object { 
                $Currency = ""
                $RetryCount2 = 3
                $GetPoolInfo = $null

                While (-not ($GetPoolInfo) -and $RetryCount2 -gt 0) { 
                    $RetryCount2--
                    Try { 
                        $GetPoolInfo = Invoke-RestMethod "http://$($_.coin).miningpoolhub.com/index.php?page=api&action=getpoolinfo&api_key=$($Config.MiningPoolHubAPIKey)" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | Select-Object -ExpandProperty getpoolinfo | Select-Object -ExpandProperty data

                        If ($Config.LogBalanceAPIResponse -eq $true) { 
                            $GetPoolInfo | Add-Member DateTime ((Get-Date).ToUniversalTime()) -Force
                            $GetPoolInfo | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$($Name).json"
                        }
                        $Currency = $GetPoolInfo | Select-Object -ExpandProperty currency
                    }
                    Catch { 
                        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
                    }
                }

                If (-not $Currency) { 
                    Write-Message -Level Warn "Cannot determine balance for currency ($(If ($_.coin) { $_.coin }  Else { "unknown" } )) - cannot convert some balances to BTC or other currencies."
                }
                Else { 
                    # Prefer custom payout threshold
                    $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.$Currency

                    If ((-not $PayoutThreshold) -and $Currency -eq "BTC" -and $Config.PoolsConfig.$Name.PayoutThreshold.mBTC) { $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.mBTC / 1000 }
                    If (-not $PayoutThreshold) { $PayoutThreshold = $GetPoolInfo | Select-Object -ExpandProperty min_ap_threshold }

                    If ($_.confirmed -gt 0) { 
                        [PSCustomObject]@{ 
                            DateTime        = (Get-Date).ToUniversalTime()
                            Pool            = "$Name"
                            Currency        = $Currency
                            Wallet          = $Config.MiningPoolHubUserName
                            Pending         = [Double]$_.unconfirmed
                            Balance         = [Double]$_.confirmed
                            Unpaid          = [Double]($_.confirmed + $_.unconfirmed)
                            # Total           = [Double]($_.confirmed + $_.unconfirmed + $_.ae_confirmed + $_.ae_unconfirmed + $_.exchange)
                            PayoutThreshold = [Double]$PayoutThreshold
                            Url             = "https://$($_.coin).miningpoolhub.com/index.php?page=account&action=pooledit"
                        }
                    }
                }
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }
}
