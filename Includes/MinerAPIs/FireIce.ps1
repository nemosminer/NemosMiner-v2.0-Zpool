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
File:           FireIce.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Include.psm1

class Fireice : Miner { 
    [String]GetCommandLineParameters() { 
        If ($this.Arguments -match "^{.+}$") { 
            Return ($this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
        }
        Else { 
            Return $this.Arguments
        }
    }

    CreateConfigFiles() { 
        Try { 
            $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"
            $PoolFile = "$(Split-Path $this.Path)\$($Parameters.PoolFile.FileName)"
            $PlatformThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.PlatformThreadsConfigFileName)"
            $MinerThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.MinerThreadsConfigFileName)"
            $ThreadsConfig = ""

            #Write pool config file, overwrite every time
            ($Parameters.PoolFile.Content | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$', ',' | Set-Content -Path $PoolFile -Force
            #Write config file, keep existing file to preserve user custom config
            If (-not (Test-Path -Path $ConfigFile -PathType Leaf)) { ($Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$' | Set-Content -Path $ConfigFile }

            #Check if we have a valid hw file for all installed hardware. If hardware / device order has changed we need to re-create the config files. 
            If (-not (Test-Path -Path $PlatformThreadsConfigFile -PathType Leaf)) { 
                If (Test-Path -Path "$(Split-Path $this.Path)\$MinerThreadsConfigFile" -PathType Leaf) { 
                    #Remove old config files, thread info is no longer valid
                    Write-Message -Level Warn "Hardware change detected. Deleting existing configuration files for miner $($this.Info)'."
                    Remove-Item -Path "$(Split-Path $this.Path)\$MinerThreadsConfigFile" -Force -ErrorAction SilentlyContinue
                }

                #Temporarily start miner with empty thread conf file. The miner will then create a hw config file with default threads info for all platform hardware
                $this.Process = Invoke-CreateProcess -Binary $this.Path -ArgumentList $Parameters.HwDetectCommands -WorkingDirectory (Split-Path $this.Path) -ShowMinerWindows $this.ShowMinerWindows -Priority ($this.DeviceName -like "CPU#*") { -2 } Else { -1 } -EnvBlock $this.Environment

                If ($this.Process) { 
                    $this.ProcessId = [Int32]((Get-CIMInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -like "*$($this.Path)*$($Parameters.HwDetectCommands)*" }).ProcessId)
                    For ($WaitForThreadsConfig = 0; $WaitForThreadsConfig -le 60; $WaitForThreadsConfig++) { 
                        If (Test-Path -Path $PlatformThreadsConfigFile -PathType Leaf) { 
                            #Read hw config created by miner
                            $ThreadsConfig = (Get-Content -Path $PlatformThreadsConfigFile) -replace '^\s*//.*' | Out-String
                            #Set bfactor to 11 (default is 6 which makes PC unusable)
                            $ThreadsConfig = $ThreadsConfig -replace '"bfactor"\s*:\s*\d,', '"bfactor" : 11,'
                            #Reformat to proper json
                            $ThreadsConfigJson = "{$($ThreadsConfig -replace '\/\*.*' -replace '\*\/' -replace '\*.+' -replace '\s' -replace ',\},]', '}]' -replace ',\},\{', '},{' -replace '},]', '}]' -replace ',$', '')}" | ConvertFrom-Json
                            #Keep one instance per gpu config
                            $ThreadsConfigJson | Add-Member gpu_threads_conf ($ThreadsConfigJson.gpu_threads_conf | Sort-Object -Property Index -Unique) -Force
                            #Write json file
                            $ThreadsConfigJson | ConvertTo-Json -Depth 10 | Set-Content -Path $PlatformThreadsConfigFile -Force
                            Break
                        }
                        Start-Sleep -Milliseconds 500
                    }
                    Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
                    $this.Process = $null
                }
                Else { 
                    Write-Message -Level Error "Running temporary miner failed - cannot create threads config file '$($this.Info)' [Error: '$($Error | Select-Object -Index 0)']."
                    Return
                }
            }
            If (-not (Test-Path $MinerThreadsConfigFile -PathType Leaf)) { 
                #Retrieve hw config from platform config file
                $ThreadsConfigJson = Get-Content -Path $PlatformThreadsConfigFile | ConvertFrom-Json -ErrorAction SilentlyContinue
                #Filter index for current cards and apply threads
                $ThreadsConfigJson | Add-Member gpu_threads_conf ([Array]($ThreadsConfigJson.gpu_threads_conf | Where-Object { $Parameters.Devices -contains $_.Index }) * $Parameters.Threads) -Force
                #Create correct numer of CPU threads
                $ThreadsConfigJson | Add-Member cpu_threads_conf ([Array]$ThreadsConfigJson.cpu_threads_conf * $Parameters.Threads) -Force
                #Write config file
                ($ThreadsConfigJson | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$' | Set-Content -Path $MinerThreadsConfigFile -Force
            }
        }
        catch { 
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
