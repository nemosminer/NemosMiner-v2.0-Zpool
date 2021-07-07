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
File:           XmRig.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Include.psm1

class XmRig : Miner { 
    [String]GetCommandLineParameters() { 
        If ($this.Arguments -match "^{.+}$") { 
            Return ($this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
        }
        Else { 
            Return $this.Arguments
        }
    }

    CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"

            $ThreadsConfig = [PSCustomObject]@{ }
            $ThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.ThreadsConfigFileName)"

            If ($Parameters.ConfigFile.Content.threads) { 
                #Write full config file, ignore possible hw change
                $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -ErrorAction SilentlyContinue -Force
            }
            else { 
                #Check if we have a valid hw file for all installed hardware. If hardware / device order has changed we need to re-create the config files. 
                $ThreadsConfig = Get-Content $ThreadsConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
                If ($ThreadsConfig.Count -lt 1) { 
                    If (Test-Path "$(Split-Path $this.Path)\$($this.Algorithm | Select-Object -Index 0)-*.json" -PathType Leaf) { 
                        #Remove old config files, thread info is no longer valid
                        Write-Message -Level Warn "Hardware change detected. Deleting existing configuration files for miner '$($this.Info)'."
                        Remove-Item "$(Split-Path $this.Path)\ThreadsConfig-$($this.Algorithm | Select-Object -Index 0)-*.json" -Force -ErrorAction SilentlyContinue
                    }
                    #Temporarily start miner with pre-config file (without threads config). Miner will then update hw config file with threads info
                    $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Set-Content $ThreadsConfigFile -Force
                    $this.Process = Invoke-CreateProcess -Binary $this.Path -ArgumentList $Parameters.HwDetectCommands -WorkingDirectory (Split-Path $this.Path) -ShowMinerWindows $this.ShowMinerWindows -Priority ($this.DeviceName -like "CPU#*") { -2 } Else { -1 } -EnvBlock $this.Environment

                    If ($this.Process) { 
                        $this.ProcessId = [Int32]((Get-CIMInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -like "*$($this.Path)*$($Parameters.HwDetectCommands)*" }).ProcessId)
                        For ($WaitForThreadsConfig = 0; $WaitForThreadsConfig -le 60; $WaitForThreadsConfig++) { 
                            If ($ThreadsConfig = @(Get-Content $ThreadsConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue).threads) { 
                                If ($this.DeviceName -like "GPU#*") { 
                                    ConvertTo-Json -InputObject @($ThreadsConfig | Sort-Object -Property Index -Unique) -Depth 10 | Set-Content $ThreadsConfigFile -ErrorAction SilentlyContinue -Force
                                }
                                Else { 
                                    ConvertTo-Json -InputObject @($ThreadsConfig | Select-Object -Unique) -Depth 10 | Set-Content $ThreadsConfigFile -ErrorAction SilentlyContinue -Force
                                }
                                Break
                            }
                            Start-Sleep -Milliseconds 500
                        }
                        Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
                        $this.Process = $null
                    }
                    Else { 
                        Write-Message -Level Error "Running temporary miner failed - cannot create threads config files for '$($this.Info)' [Error: '$($Error | Select-Object -Index 0)']."
                        Return
                    }
                }

                If (-not ((Get-Content $ConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue).threads)) { 
                    #Threads config in config file is invalid, retrieve from threads config file
                    $ThreadsConfig = Get-Content $ThreadsConfigFile | ConvertFrom-Json
                    If ($ThreadsConfig.Count -ge 1) { 
                        #Write config files. Overwrite because we need to add thread info
                        If ($this.DeviceName -like "GPU#*") { 
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array](($ThreadsConfig | Where-Object { $Parameters.Devices -contains $_.index })) * $Parameters.Threads) -Force
                        }
                        Else { 
                            #CPU thread config does not contain index information
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array]($ThreadsConfig * $Parameters.Threads)) -Force
                        }
                        $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Force
                    }
                    Else { 
                        Write-Message -Level Error "Error parsing threads config file - cannot create miner config files for '$($this.Info)' [Error: '$($Error | Select-Object -Index 0)']."
                        Return
                    }
                }
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -Index 0)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api.json"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]$Data.hashrate.total[0]
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.hashrate.total[1] } #fix
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.hashrate.total[2] } #fix

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.results.shares_good
            $Shares_Rejected = [Int64]($Data.results.shares_total - $Data.results.shares_good)
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
