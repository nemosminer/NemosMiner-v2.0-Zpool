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
File:           include.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

# For SetWindowText
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class Win32 {
    [DllImport("User32.dll", EntryPoint="SetWindowText")]
    public static extern int SetWindowText(IntPtr hWnd, string strTitle);
}
"@

Class Device { 
    [String]$Name
    [String]$Model
    [String]$Vendor
    [Int64]$Memory
    [String]$Type
    [PSCustomObject]$CIM
    [PSCustomObject]$PNP
    [PSCustomObject]$Reg
    [PSCustomObject]$CpuFeatures

    [String]$Status = "Idle"

    [Int]$Bus
    [Int]$Id
    [Int]$Type_Id
    [Int]$Vendor_Id
    [Int]$Type_Vendor_Id

    [Int]$Slot = 0
    [Int]$Type_Slot
    [Int]$Vendor_Slot
    [Int]$Type_Vendor_Slot

    [Int]$Index = 0
    [Int]$Type_Index
    [Int]$Type_Vendor_Index
    [Int]$Vendor_Index
    [Int]$Bus_Index
    [Int]$Bus_Type_Index
    [Int]$Bus_Vendor_Index

    [Int]$PlatformId = 0
    [Int]$PlatformId_Index
    [Int]$Type_PlatformId_Index
    [Int]$Bus_Platform_Index

    [PSCustomObject]$OpenCL = [PSCustomObject]@{ }
    [DeviceState]$State = [DeviceState]::Enabled
    [Bool]$ReadPowerUsage = $false
    [Double]$ConfiguredPowerUsage = 0 # Workaround if device does not expose power usage in sensors
}

enum DeviceState {
    Enabled
    Disabled
    Unsupported
}

Class Pool { 
    # static [Credential[]]$Credentials = @()
    # [Credential[]]$Credential = @()

    [String]$Name
    [String]$Algorithm
    [Int]$BlockHeight = 0
    [Int64]$DAGsize = 0
    [Int]$Epoch = 0
    [String]$Currency = ""
    [String]$CoinName = ""
    [String]$Host
    [String[]]$Hosts
    [UInt16]$Port
    [String]$User
    [String]$Pass
    [String]$Region
    [Boolean]$SSL
    [Double]$Fee
    [Double]$EarningsAdjustmentFactor = 1
    [Double]$EstimateFactor = 1
    [DateTime]$Updated = (Get-Date).ToUniversalTime()
    [System.Nullable[Int]]$Workers
    [Boolean]$Available = $true
    [Boolean]$Disabled = $false
    [String[]]$Reason = @("")
    [Boolean]$Best

    # Stats
    [Double]$Price
    [Double]$Price_Bias
    [Double]$StablePrice
    [Double]$MarginOfError
}

Class Worker { 
    [Pool]$Pool
    [Double]$Fee
    [Double]$Speed
    [Double]$Earning
    [Double]$Earning_Bias
    [Double]$Earning_Accuracy
    [Boolean]$Disabled = $false
    [TimeSpan]$TotalMiningDuration
}

enum MinerStatus { 
    Running
    Idle
    Failed
}

Class Miner { 
    static [Pool[]]$Pools = @()
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()
    [Device[]]$Devices = @()

    [String[]]$Type

    [String]$Name
    [String]$BaseName
    [String]$Version
    [String]$Path
    [String]$URI
    [String]$Arguments
    [String]$CommandLine
    [UInt16]$Port
    [String[]]$DeviceName = @() # derived from devices
    [String[]]$Algorithm = @() # derived from workers
    [Double[]]$Speed_Live = @(0)

    [Double]$Earning # derived from pool and stats
    [Double]$Earning_Bias # derived from pool and stats
    [Double]$Earning_Accuracy # derived from pool and stats
    [Double]$Profit = [Double]::NaN
    [Double]$Profit_Bias = [Double]::NaN

    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$CachedBenchmark = $false

    [Double]$PowerUsage = [Double]::NaN
    [Double]$PowerUsage_Live = [Double]::NaN
    [Double]$PowerCost = [Double]::NaN
    [Boolean]$ReadPowerUsage = $false
    [Boolean]$CachedReadPowerUsage = $false
    [Boolean]$MeasurePowerUsage = $false
    [Boolean]$CachedMeasurePowerUsage = $false

    [Boolean]$Fastest = $false
    [Boolean]$Best = $false
    [Boolean]$New = $false
    [Boolean]$Available = $true
    [Boolean]$Disabled = $false
    [String[]]$Reason
    [Boolean]$Restart = $false # stop and start miner even if best

    hidden [PSCustomObject[]]$Data = $null
    hidden [PSCustomObject[]]$Data2 = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$Process = $null
    hidden [TimeSpan]$Active = [TimeSpan]::Zero

    [Runspace]$GetMinerDataRunspace = $null
    [PowerShell]$GetMinerDataPowerShell = $null

    [Int32]$ProcessId = 0
    [Int]$ProcessPriority = -1

    [Int]$Activated = 0
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusMessage
    [String]$Info
    [DateTime]$StatStart
    [DateTime]$StatEnd
    [TimeSpan[]]$Intervals = @()
    [Int]$DataCollectInterval = 5 # Seconds
    [String]$ShowMinerWindows = "minimized"
    [String]$CachedShowMinerWindows
    [String[]]$Environment = @()
    [Int]$MinDataSamples # for safe hashrate values
    [PSCustomObject]$LastSample # last hash rate sample
    [Int[]]$WarmupTimes # First value: time (in seconds) until first hash rate sample is valid (default 0, accept first sample), second value: time (in seconds) the miner is allowed to warm up, e.g. to compile the binaries or to get the API ready and providing first data samples before it get marked as failed (default 15)
    [DateTime]$BeginTime
    [DateTime]$EndTime
    [TimeSpan]$TotalMiningDuration # derived from pool and stats

    [Double]$AllowedBadShareRatio = 0
    [String]$MinerUri = ""
    [String]$LogFile = ""

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf -ErrorAction Ignore)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        If ($this.Arguments -match "^{.+}$") { 
            Return ($this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
        }
        Else { 
            Return $this.Arguments
        }
    }

    [String]GetCommandLine() { 
        Return "$($this.Path) $($this.GetCommandLineParameters())"
    }

    [Int32]GetProcessId() { 
        Return $this.ProcessId
    }

    hidden StartMining() { 
        $this.Status = [MinerStatus]::Failed
        $this.StatusMessage = "Launching..."
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.New = $true
        $this.Activated++
        $this.Intervals = @()

        $this.Info = "$($this.Name) {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"

        If ($this.Arguments -match "^{.+}$") { 
            $this.CreateConfigFiles()
        }

        If ($this.Process) { 
            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                $this.Process | Remove-Job -Force
            }

            If (-not ($this.Process | Get-Job -ErrorAction SilentlyContinue)) { 
                $this.Active += $this.Process.PSEndTime - $this.Process.PSBeginTime
                $this.Process = $null
            }
        }

        If (-not $this.Process) { 
            If ($this.Benchmark -EQ $true -or $this.MeasurePowerUsage -EQ $true) { $this.Data = $null } # When benchmarking clear data on each miner start
            If (($this.GetType()).Name -in @("VerthashMiner")) { 
                $this.LogFile = $Global:ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\Logs\$($this.Name)-$($this.Port)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt")
            }
            $this.Process = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path $this.Path) -ShowMinerWindows $this.ShowMinerWindows -Priority $this.ProcessPriority -EnvBlock $this.Environment -LogFile $this.LogFile

            # Log switching information to .\Logs\SwitchingLog.csv
            [PSCustomObject]@{ 
                DateTime     = [String](Get-Date -Format o)
                Action       = "Started"
                Name         = $this.Name
                Device       = ($this.Devices.Name | Sort-Object) -join "; "
                Type         = ($this.Type -join " & ")
                Account      = ($this.Workers.Pool.User | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join '; '
                Pool         = ($this.Workers.Pool.Name | Select-Object -Unique) -join "; "
                Algorithm    = ($this.Workers.Pool.Algorithm) -join "; "
                Duration     = ""
                Earning      = [Double]$this.Earning
                Earning_Bias = [Double]$this.Earning_Bias
                Profit       = [Double]$this.Profit
                Profit_Bias  = [Double]$this.Profit_Bias
                CommandLine  = $this.CommandLine
            } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation -ErrorAction Ignore

            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                For ($WaitForPID = 0; $WaitForPID -le 20; $WaitForPID++) { 
                    If ($this.ProcessId = [Int32]((Get-CimInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -like "*$($this.Path)*$($this.GetCommandLineParameters())*" }).ProcessId)) { 
                        $this.Status = [MinerStatus]::Running
                        $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
                        # . "C:\Users\Stephan\Desktop\NemosMiner\Includes\GetMinerDataRunspace.ps1"
                        # Starting Miner Data reader
                        $this | Add-Member -Force @{ DataReaderJob = Start-Job -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -Name "$($this.Name)_DataReader" -ScriptBlock { .\Includes\GetMinerData.ps1 $args[0] $args[1] } -ArgumentList ([String]$this.GetType().Name), ($this | Select-Object -Property Algorithm, AllowedBadShareRatio, DataCollectInterval, Devices, Path, Port, ReadPowerUsage | ConvertTo-Json -WarningAction Ignore) }
                        Break
                    }
                    Start-Sleep -Milliseconds 100
                }
            }
            $this.Info = "$($this.Name) {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
            $this.StatusMessage = "Warming up {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
            $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
            $this.StatStart = (Get-Date).ToUniversalTime()
            $this.Speed_Live = @($this.Algorithm | ForEach-Object { [Double]0 })
        }
    }

    [MinerStatus]GetStatus() { 
        If ($this.Process.State -eq "Running" -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue).ProcessName) { 
            # Use ProcessName, some crashed miners are dead, but may still be found by their processId
            Return [MinerStatus]::Running
        }
        ElseIf ($this.Status -eq "Running") { 
            $this.Status = [MinerStatus]::Failed
            Return $this.Status
        }
        Else { 
            Return $this.Status
        }
    }

    SetStatus([MinerStatus]$Status) { 
        Switch ($Status) { 
            "Running" { 
                If ($Status -eq $this.GetStatus()) { Return }
                $this.StartMining()
            }
            "Idle" { 
                $this.StopMining()
            }
            Default { 
                $this.Status = $Status
                $this.StopMining()
            }
        }
    }

    hidden StopMining() { 
        $this.EndTime = (Get-Date).ToUniversalTime()
        If ($this.Status -eq [MinerStatus]::Running) { 
            $this.StatusMessage = "Stopping..." 
            $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        }
        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue) { 
                Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
            }
            $this.ProcessId = $null
        }

        If ($this.Process) { 
            $this.Process = $null
        }

        # Stop Miner data reader
        Get-Job | Where-Object Name -EQ "$($this.Name)_DataReader" | Stop-Job -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime     = [String](Get-Date -Format o)
            Action       = If ($this.Status -eq [MinerStatus]::Failed) { "Failed" } Else { "Stopped" }
            Name         = $this.Name
            Device       = ($this.Devices.Name | Sort-Object) -join "; "
            Type         = ($this.Type -join " & ")
            Account      = ($this.WorkersRunning.Pool.User | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join '; '
            Pool         = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join "; "
            Algorithm    = ($this.WorkersRunning.Pool.Algorithm) -join "; "
            Duration     = "{0:hh\:mm\:ss}" -f  ($this.EndTime - $this.BeginTime)
            Earning      = [Double]$this.Earning
            Earning_Bias = [Double]$this.Earning_Bias
            Profit       = [Double]$this.Profit
            Profit_Bias  = [Double]$this.Profit_Bias
            CommandLine  = ""
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation -ErrorAction Ignore

        If ($this.Status -eq [MinerStatus]::Running) { 
            $this.Status = [MinerStatus]::Idle
            $this.StatusMessage = "Idle"
        }
        $this.Devices | ForEach-Object { 
            If ($_.State -eq [DeviceState]::Disabled) { $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }
            Else { $_.Status = $this.StatusMessage }
        }

        $this.WorkersRunning = @()
        $this.Info = ""
    }

    [DateTime]GetActiveLast() { 
        If ($this.BeginTime -and $this.EndTime) { 
            Return $this.EndTime.ToUniversalTime()
        }
        ElseIf ($this.BeginTime) { 
            Return [DateTime]::Now.ToUniversalTime()
        }
        Else { 
            Return [DateTime]::MinValue.ToUniversalTime()
        }
    }

    [TimeSpan]GetActiveTime() { 
        If ($this.BeginTime -and $this.EndTime) { 
            Return $this.Active + ($this.EndTime - $this.BeginTime)
        }
        ElseIf ($this.BeginTime) { 
            Return $this.Active + ((Get-Date) - $this.BeginTime)
        }
        Else { 
            Return $this.Active
        }
    }

    [Int]GetActivateCount() { 
        Return $this.Activated
    }

    [Double]GetPowerUsage() { 
        [Device]$Device = $null
        $RegistryData = [PSCustomObject]@{ }
        $RegistryEntry = [PSCustomObject]@{ }
        $RegistryHive = "HKCU:\Software\HWiNFO64\VSB"
        $TotalPowerUsage = [Double]0

        # Read power usage
        If (Test-Path $RegistryHive) { 
            $RegistryData = Get-ItemProperty $RegistryHive
            ForEach ($Device in $this.Devices) { 
                If ($RegistryEntry = $RegistryData.PSObject.Properties | Where-Object { $_.Value -match $Device.Name }) { 
                    $TotalPowerUsage += [Double]($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
                }
                Else { 
                    $TotalPowerUsage += [Double]$Device.ConfiguredPowerUsage # Use configured value
                }
            }
        }
        Return $TotalPowerUsage
    }

    [Double[]]CollectHashRate([String]$Algorithm = [String]$this.Algorithm, [Boolean]$Safe = $this.New) { 
        # Returns an array of two values (safe, unsafe)

        $HashRates_Count = [Int]0
        $HashRates_Average = [Double]0
        $HashRates_Variance = [Double]0

        $Hashrates_Samples = @($this.Data | Where-Object { $_.HashRate.$Algorithm }) # Do not use 0 valued samples


        $HashRates_Count = $Hashrates_Samples.Count
        $HashRates_Average = $Hashrates_Samples.HashRate.$Algorithm | Measure-Object -Average | Select-Object -ExpandProperty Average
        $HashRates_Variance = $Hashrates_Samples.HashRate.$Algorithm | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($HashRates_Count -lt 3 -or $HashRates_Variance -gt 0.05) { 
                Return @(0, $HashRates_Average)
            }
            Else { 
                Return @(($HashRates_Average * (1 + ($HashRates_Variance / 2))), $HashRates_Average)
            }
        }
        Else { 
            Return @($HashRates_Average, $HashRates_Average)
        }
    }

    [Double[]]CollectPowerUsage([Boolean]$Safe = $this.New) { 
        # Returns an array of two values (safe, unsafe)

        $PowerUsages_Count = [Int]0
        $PowerUsages_Average = [Double]0
        $PowerUsages_Variance = [Double]0

        $PowerUsages_Samples = @($this.Data | Where-Object PowerUsage) # Do not use 0 valued samples

        $PowerUsages_Count = $PowerUsages_Samples.Count
        $PowerUsages_Average = $PowerUsages_Samples.PowerUsage | Measure-Object -Average | Select-Object -ExpandProperty Average
        $PowerUsages_Variance = $PowerUsages_Samples.PowerUsage | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($PowerUsages_Count -lt 3 -or $PowerUsages_Variance -gt 0.1) { 
                Return @(0, $PowerUsages_Average)
            }
            Else { 
                Return @(($PowerUsages_Average * (1 + ($PowerUsages_Variance / 2))), $PowerUsages_Average)
            }
        }
        Else { 
            Return @($PowerUsages_Average, $PowerUsages_Average)
        }
    }

    Refresh([Double]$PowerCostBTCperW) { 
        $this.Available = $true
        $this.Benchmark = $false
        $this.Best = $false

        $this.Workers | ForEach-Object { 
            If ($Stat = Get-Stat "$($this.Name)_$($_.Pool.Algorithm)_HashRate") { 
                $_.Speed = $Stat.Hour
                $Factor = [Double]($_.Speed * (1 - $_.Fee) * (1 - $_.Pool.Fee))
                $_.Earning = [Double]($_.Pool.Price * $Factor)
                $_.Earning_Bias = [Double]($_.Pool.Price_Bias * $Factor)
                $_.Earning_Accuracy = [Double](1 - $_.Pool.MarginOfError)
                $_.TotalMiningDuration = $Stat.Duration
            }
            Else { 
                $this.Benchmark = $true
                $_.Speed = [Double]::NaN
                $_.Earning = [Double]::NaN
                $_.Earning_Bias = [Double]::NaN
                $_.Earning_Accuracy = [Double]::Nan
                $_.TotalMiningDuration = New-TimeSpan
            }
        }

        $this.Disabled = $this.Workers | Where-Object Speed -EQ 0

        $this.Earning = 0
        $this.Earning_Bias = 0
        $this.Earning_Accuracy = 0

        $this.Workers | ForEach-Object { 
            $this.Earning += $_.Earning
            $this.Earning_Bias += $_.Earning_Bias
        }

        If ($this.Earning -eq 0) { 
            $this.Earning_Accuracy = 1
        }
        Else { 
            $this.Workers | ForEach-Object { 
                $this.Earning_Accuracy += (($_.Earning_Accuracy * $_.Earning) / $this.Earning)
            }
        }

        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum

        If ($this.ReadPowerUsage) { 
            If ($Stat = Get-Stat "$($this.Name)$(If ($this.Workers.Count -eq 1) { "_$($this.Workers.Pool.Algorithm | Select-Object -Index 0)" })_PowerUsage") { 
                $this.MeasurePowerUsage = $false
                $this.PowerUsage = $Stat.Week
                $this.PowerCost = $this.PowerUsage * $PowerCostBTCperW
                $this.Profit = $this.Earning - $this.PowerCost
                $this.Profit_Bias = $this.Earning_Bias - $this.PowerCost
            }
            Else { 
                $this.MeasurePowerUsage = $true
                $this.PowerUsage = [Double]::NaN
                $this.PowerCost = [Double]::NaN
                $this.Profit = [Double]::NaN
                $this.Profit_Bias = [Double]::NaN
            }
        }
        Else { 
            $this.MeasurePowerUsage = $false
            $this.PowerUsage = [Double]::NaN
            $this.PowerCost = [Double]::NaN
            $this.Profit = [Double]::NaN
            $this.Profit_Bias = [Double]::NaN
        }
    }
}

Function Get-DefaultAlgorithm {

    # Try { 
    #     $PoolsAlgos = (Invoke-WebRequest "https://nemosminer.com/data/PoolsAlgos.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json
    #     $PoolsAlgos | ConvertTo-Json | Out-File ".\Config\PoolsAlgos.json" 
    # }
    # Catch { 
        If (Test-Path -Path ".\Config\PoolsAlgos.json" -PathType Leaf) { 
            $PoolsAlgos = Get-Content ".\Config\PoolsAlgos.json" | ConvertFrom-Json -ErrorAction Ignore
        }
    # }
    If ($PoolsAlgos) { 
        $PoolsAlgos = $PoolsAlgos.PSObject.Properties | Where-Object { $_.Name -in ($Config.PoolName -replace "24hr$" -replace "Coins$") }
        Return  $PoolsAlgos.Value | Sort-Object -Unique
    }
    Return
}

Function Get-Chart { 

    If ((Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) -and (Test-Path -Path ".\Includes\Charting.ps1" -PathType Leaf)) { 
        $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 150"
        $Chart1.top = 2
        $Chart1.left = 0
        $Global:EarningsPage.Controls.Add($Chart1)
        $Chart1.BringToFront()

        $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 150"
        $Chart2.top = 2
        $Chart2.left = 500
        $Global:EarningsPage.Controls.Add($Chart2)
        $Chart2.BringToFront()

        $Global:EarningsPage.Controls | Where-Object { ($_.GetType()).name -eq "Chart" -and $_ -ne $Chart1 -and $_ -ne $Chart2 } | ForEach-Object { $Global:EarningsPage.Controls[$Global:EarningsPage.Controls.IndexOf($_)].Dispose(); $Global:EarningsPage.Controls.Remove($_) }
    }
}

Function Get-CommandLineParameters { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Arguments
    )

    If ($Arguments -match "^{.+}$") { 
        Return ($Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
    }
    Else { 
        Return $Arguments
    }
}

Function Start-JobInProcess {
    [CmdletBinding()]
    Param
    (
        [ScriptBlock]$ScriptBlock,
        $ArgumentList,
        [String]$Name
    )

    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
namespace InProcess
{
    public class InMemoryJob : System.Management.Automation.Job
    {
        public InMemoryJob(PowerShell PowerShell, string name)
        {
            _PowerShell = PowerShell;
            SetUpStreams(name);
        }
        private void SetUpStreams(string name)
        {
            _PowerShell.Streams.Verbose = this.Verbose;
            _PowerShell.Streams.Error = this.Error;
            _PowerShell.Streams.Debug = this.Debug;
            _PowerShell.Streams.Warning = this.Warning;
            _PowerShell.Streams.Information = this.Information;
            _PowerShell.Runspace.AvailabilityChanged += new EventHandler<RunspaceAvailabilityEventArgs>(Runspace_AvailabilityChanged);
            int id = System.Threading.Interlocked.Add(ref InMemoryJobNumber, 1);
            if (!string.IsNullOrEmpty(name))
            {
                this.Name = name;
            }
            else
            {
                this.Name = "InProcessJob" + id;
            }
        }
        void Runspace_AvailabilityChanged(object sender, RunspaceAvailabilityEventArgs e)
        {
            if (e.RunspaceAvailability == RunspaceAvailability.Available)
            {
                this.SetJobState(JobState.Completed);
            }
        }
        PowerShell _PowerShell;
        static int InMemoryJobNumber = 0;
        public override bool HasMoreData
        {
            get {
                return (Output.Count > 0);
            }
        }
        public override string Location
        {
            get { return "In Process"; }
        }
        public override string StatusMessage
        {
            get { return "A new status message"; }
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (!isDisposed)
                {
                    isDisposed = true;
                    try
                    {
                        if (!IsFinishedState(JobStateInfo.State))
                        {
                            StopJob();
                        }
                        foreach (Job job in ChildJobs)
                        {
                            job.Dispose();
                        }
                    }
                    finally
                    {
                        base.Dispose(disposing);
                    }
                }
            }
        }
        private bool isDisposed = false;
        internal bool IsFinishedState(JobState state)
        {
            return (state == JobState.Completed || state == JobState.Failed || state == JobState.Stopped);
        }
        public override void StopJob()
        {
            _PowerShell.Stop();
            _PowerShell.EndInvoke(_asyncResult);
            SetJobState(JobState.Stopped);
        }
        public void Start()
        {
            _asyncResult = _PowerShell.BeginInvoke<PSObject, PSObject>(null, Output);
            SetJobState(JobState.Running);
        }
        IAsyncResult _asyncResult;
        public void WaitJob()
        {
            _asyncResult.AsyncWaitHandle.WaitOne();
        }
        public void WaitJob(TimeSpan timeout)
        {
            _asyncResult.AsyncWaitHandle.WaitOne(timeout);
        }
    }
}
'@

    Function Get-JobRepository {
        [CmdletBinding()]
        Param()
        $PScmdlet.JobRepository
    }

    Function Add-Job {
        [CmdletBinding()]
        Param
        (
            $Job
        )
        $PScmdlet.JobRepository.Add($Job)
    }

    $PowerShell = [PowerShell]::Create().AddScript($ScriptBlock)

    If ($ArgumentList) {
        $ArgumentList | ForEach-Object {
            $PowerShell.AddArgument($_)
        }
    }

    $MemoryJob = New-Object InProcess.InMemoryJob $PowerShell, $Name

    $MemoryJob.Start()
    Add-Job $MemoryJob
    $MemoryJob
}

Function Start-BrainJob { 

    # Starts Brains if necessary
    $JobNames = @()

    $Config.PoolName | Select-Object | ForEach-Object { 
        If (-not $Variables.BrainJobs.$_) { 
            $BrainPath = "$($Variables.MainPath)\Brains\$($_)"
            $BrainName = (".\Brains\" + $_ + "\Brains.ps1")
            If (Test-Path $BrainName -PathType Leaf) { 
                $Variables.BrainJobs.$_ = (Start-Job -FilePath $BrainName -ArgumentList @($BrainPath))
                If ($Variables.BrainJobs.$_.State -EQ "Running") { 
                    $JobNames += $_
                }
            }
        }
    }
    If ($JobNames -gt 0) { Write-Message "Started Brain Job$(If ($JobNames.Count -gt 1) { "s" } ) ($($JobNames -join ', '))." }
}

Function Stop-BrainJob { 
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs = $Variables.BrainJobs.Keys
    )

    $JobNames = @()

    # Stop Brains if necessary
    $Jobs | Select-Object | ForEach-Object { 
        $Variables.BrainJobs.$_ | Stop-Job -PassThru -ErrorAction Ignore | Remove-Job -ErrorAction Ignore
        $Variables.BrainJobs.Remove($_)
        $JobNames += $_
    }

    If ($JobNames.Count -gt 0) { Write-Message "Stopped Brain Job$(If ($JobNames.Count -gt 1) { "s" } ) ($($JobNames -join ', '))." }
}


Function Start-BalancesTracker { 

    If (-not $Variables.CycleRunspace) { 

        Try { 
            $BalancesTrackerRunspace = [runspacefactory]::CreateRunspace()
            $BalancesTrackerRunspace.Open()
            $BalancesTrackerRunspace.SessionStateProxy.SetVariable('Config', $Config)
            $BalancesTrackerRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
            $BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $BalancesTrackerRunspace
            $PowerShell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1")
            $PowerShell.BeginInvoke()

            $Variables.BalancesTrackerRunspace = $BalancesTrackerRunspace
            $Variables.BalancesTrackerRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
        }
        Catch { 
            Write-Message -Level Error "Failed to start Balances Tracker [$Error[0]]."
        }
    }
}


Function Stop-BalancesTracker {
 
    If ($Variables.BalancesTrackerRunspace) { 
        $Variables.BalancesTrackerRunspace.Close()
        If ($Variables.BalancesTrackerRunspace.PowerShell) { $Variables.BalancesTrackerRunspace.PowerShell.Dispose() }
        $Variables.Remove("BalancesTrackerRunspace")
        Write-Message "Stopped Balances Tracker."
    }
}

Function Initialize-API { 

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -eq $true) { 
        $Variables.Remove("APIVersion")
    }

    # Initialize API & Web GUI
    If ($Config.APIPort -and ($Config.APIPort -ne $Variables.APIRunspace.APIPort)) { 
        If (Test-Path -Path .\Includes\API.psm1 -PathType Leaf) { 
            If ($Variables.APIRunspace) { 
                $Variables.APIRunspace.Close()
                If ($Variables.APIRunspace.PowerShell) { $Variables.APIRunspace.PowerShell.Dispose() }
                $Variables.Remove("APIRunspace")
            }

            $TCPClient = New-Object System.Net.Sockets.TCPClient
            $AsyncResult = $TCPClient.BeginConnect("localhost", $Config.APIPort, $null, $null)
            If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
                Write-Message -Level Error "Error starting Web GUI and API on port $($Config.APIPort). Port is in use."
                Try { $TCPClient.EndConnect($AsyncResult) = $null }
                Catch { }
            }
            Else { 
                Import-Module .\Includes\API.psm1

                # Required for stat management
                Get-Stat | Out-Null

                # Start API server
                Start-APIServer -Port $Config.APIPort

                # Wait for API to get ready
                $RetryCount = 3
                While (-not ($Variables.APIVersion) -and $RetryCount -gt 0) { 
                    Start-Sleep -Seconds 1
                    $RetryCount--
                    Try {
                        If ($Variables.APIVersion = (Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIPort)/apiversion" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop)) { 
                            Write-Message "Web GUI and API (version $($Variables.APIVersion)) running on http://localhost:$($Variables.APIRunspace.APIPort)."
                            # Start Web GUI
                            If ($Config.WebGui) { 
                                Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/$(If ($Variables.FreshConfig -eq $true) { "configedit.html" })"
                            }
                            Break
                        }
                    }
                    Catch { 
                    }
                }
                If (-not $Variables.APIVersion) { Write-Message -Level Error "Error starting Web GUI and API on port $($Config.APIPort)." }
                Remove-Variable RetryCount
            }
            Remove-Variable AsyncResult
            Remove-Variable TCPClient
        }
    }
}

Function Initialize-Application { 

    # Keep only the last 10 files
    Get-ChildItem -Path ".\Logs\NemosMiner_*.log" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

    $Variables.ScriptStartDate = (Get-Date).ToUniversalTime()
    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { 
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }

    # Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    If ($Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Proxy }
}

Function Get-Rate {
    # Read exchange rates from min-api.cryptocompare.com
    # Returned decimal values contain as many digits as the native currency
    Try { 
        If ($Rates = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$((@("BTC") + @($Variables.AllCurrencies | Where-Object { $_ -ne "mBTC" } ) | Select-Object -Unique) -join ',')&extraParams=http://nemosminer.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) { 
            $Currencies = $Rates.BTC | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name
            $Currencies | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                $Currency = $_
                $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -ErrorAction Ignore
                $Rates.$Currency | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                    $Rates.$Currency | Add-Member $_ ([Double]($Rates.BTC.$_ / $Rates.BTC.$Currency)) -Force
                }
            }
            # Add mBTC
            $Currencies | ForEach-Object { 
                $Currency = $_
                $mCurrency = "m$($Currency)"
                $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json)
                $Rates.$mCurrency | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                    $Rates.$mCurrency | Add-Member $_ ([Double]($Rates.$Currency.$_) / 1000) -Force
                }
            }

            $Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
                $Currency = $_
                $Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $_ -in $Currencies } | ForEach-Object { 
                    $mCurrency = "m$($_)"
                    $Rates.$Currency | Add-Member $mCurrency ([Double]($Rates.$Currency.$_) * 1000)
                }
            }
            Write-Message "Loaded currency exchange rates from 'min-api.cryptocompare.com'."
            $Variables.Rates = $Rates
        }
        Else { 
            Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
        }
    }
    Catch { 
        Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
    }
}

Function Write-Message { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [String]$Level = "Info", 
        [Parameter(Mandatory = $false)]
        [Switch]$Console = $false
    )

    Begin { }
    Process { 

        If ((-not $Variables.LogFile) -or (-not $Config.LogToScreen) -or ($Level -in $Config.LogToScreen)) { 

            # Update status text box in GUI
            If ($Variables.LabelStatus) { 
                $Variables.LabelStatus.Lines = @($Variables.LabelStatus.Lines | Select-Object -Last 500)
                $Variables.LabelStatus.Lines += $Message
                $Variables.LabelStatus.SelectionStart = $Variables.LabelStatus.TextLength
                $Variables.LabelStatus.ScrollToCaret()
                $Variables.LabelStatus.Refresh()
            }

            Switch ($Level) { 
                'Error' { 
                    Write-Host $Message -ForegroundColor "Red"
                }
                'Warn' { 
                    Write-Host $Message -ForegroundColor "Magenta"
                }
                'Info' { 
                    Write-Host $Message -ForegroundColor "White"
                }
                'Verbose' { 
                    Write-Host $Message -ForegroundColor "Yello"
                }
                'Debug' { 
                    Write-Host $Message -ForegroundColor "Blue"
                }
            }
        }
        If ($Variables.LogFile -and ((-not $Config.LogToFile) -or ($Level -in $Config.LogToFile))) { 
            # Get mutex named NemosMinerWriteLog. Mutexes are shared across all threads and processes. 
            # This lets us ensure only one thread is trying to write to the file at a time. 
            $Mutex = New-Object System.Threading.Mutex($false, "NemosMinerWriteMessage")

            Switch ($Level) { 
                'Error' { 
                    $LevelText = 'ERROR:'
                }
                'Warn' { 
                    $LevelText = 'WARNING:'
                }
                'Info' { 
                    $LevelText = 'INFO:'
                }
                'Verbose' { 
                    $LevelText = 'VERBOSE:'
                }
                'Debug' { 
                    $LevelText = 'DEBUG:'
                }
            }

            # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, write to the log file and release mutex. Otherwise, display an error. 
            If ($Mutex.WaitOne(1000)) { 

                $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                "$Date $LevelText $Message" | Out-File -FilePath $Variables.LogFile -Append -Encoding UTF8
                $Mutex.ReleaseMutex()
            }
            Else { 
                Write-Error -Message "Log file is locked, unable to write message to $($Variables.LogFile)."
            }
        }
    }
    End { }
}

Function Start-IdleMining {
 
    # Function tracks how long the system has been idle and controls the paused state
    $IdleRunspace = [runspacefactory]::CreateRunspace()
    $IdleRunspace.Open()
    Get-Variable -Scope Global | ForEach-Object { 
        Try { 
            $IdleRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        Catch { }
    }
    $IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $IdleRunspace
    $PowerShell.AddScript(
        { 
            # Set the starting directory
            Set-Location (Split-Path $MyInvocation.MyCommand.Path)

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            # No native way to check how long the system has been idle in PowerShell. Have to use .NET code.
            Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

            # Start transcript log
            If ($Config.Transcript -eq $true) { Start-Transcript ".\Logs\IdleMining.log" -Append -Force }

            $ProgressPreference = "SilentlyContinue"
            Write-Message -Level Verbose "Started idle detection. $($Branding.ProductLabel) will start mining when the system is idle for more than $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" } )..."

            While ($true) { 
                $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                # Pause if system has become active
                If ($IdleSeconds -lt $Config.IdleSec -and $Variables.CoreRunspace) { 
                    Write-Message -Level Verbose "System activity detected. Stopping all running miners..."
                    Stop-Mining
                    Write-Message -Level Verbose "Mining is suspended until system is idle again for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" } )..."
                }
                # Check if system has been idle long enough to unpause
                If ($IdleSeconds -ge $Config.IdleSec -and -not $Variables.CoreRunspace) { 
                    Write-Message -Level Verbose "System was idle for $IdleSeconds seconds, start mining..."
                    Start-Mining
                }
                Start-Sleep -Seconds 1
            }
            Return
        }
    ) | Out-Null
    $PowerShell.BeginInvoke()

    $Variables.IdleRunspace = $IdleRunspace
    $Variables.IdleRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
}

Function Stop-IdleMining { 

    If ($Variables.IdleRunspace) { 
        $Variables.IdleRunspace.Close()
        If ($Variables.IdleRunspace.PowerShell) { $Variables.IdleRunspace.PowerShell.Dispose() }
        $Variables.Remove("IdleRunspace")
        Write-Message -Level Verbose "Stopped idle detection."
    }
}

Function Update-Monitoring { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    If ($Config.ReportToServer) { 
        $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
        $Status = If ($Variables.Paused) { "Paused" } Else { "Running" }
        $RunningMiners = $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running }

        # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
        # reveal someone's windows username or other system information they might not want sent
        # For the ones that can be an array, comma separate them
        $Data = $RunningMiners | Sort-Object DeviceName | ForEach-Object { 
            $RunningMiner = $_
            [PSCustomObject]@{ 
                Name           = $RunningMiner.Name
                Path           = Resolve-Path -Relative $RunningMiner.Path
                Type           = $RunningMiner.Type -join ','
                Algorithm      = $RunningMiner.Algorithm -join ','
                Pool           = $RunningMiner.WorkersRunning.Pool.Name -join ','
                CurrentSpeed   = $RunningMiner.Speed_Live
                EstimatedSpeed = $RunningMiner.Workers.Speed
                Earning        = $RunningMiner.Earning
                Profit         = $RunningMiner.Profit
                Currency       = $Config.Currency
            }
        }
        $DataJSON = ConvertTo-Json @($Data)
        # Calculate total estimated profit
        $Earning = [String]([Math]::Round(($data | Measure-Object Earning -Sum).Sum, 8))

        # Send the request
        $Body = @{ user = $Config.MonitoringUser; worker = $Config.WorkerName; version = $Version; status = $Status; profit = $Earning; data = $DataJSON } # Earnings is NOT profit! Needs to be changes in mining monitor server
        Try { 
            $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            If ($Response -eq "Success") { 
                Write-Message -Level Verbose "Reported worker status to monitoring server '$($Config.MonitoringServer)'."
            }
            Else { 
                Write-Message -Level Verbose "Reporting worker status to monitoring server '$($Config.MonitoringServer)' failed: [$($Response)]."
            }
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to send status to $($Config.MonitoringServer)."
        }
    }

    If ($Config.ShowWorkerStatus) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | ForEach-Object { 
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member -Force @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) }

                # If a machine hasn't reported in for > 10 minutes, mark it as offline
                $TimeSinceLastReport = New-TimeSpan -Start $_.date -End (Get-Date)
                If ($TimeSinceLastReport.TotalMinutes -gt 10) { $_.status = "Offline" }
                # Show friendly time since last report in seconds, minutes, hours or days
                If ($TimeSinceLastReport.Days -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} days ago' -f $TimeSinceLastReport.TotalDays }
                }
                ElseIf ($TimeSinceLastReport.Hours -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} hours ago' -f $TimeSinceLastReport.TotalHours }
                }
                ElseIf ($TimeSinceLastReport.Minutes -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} minutes ago' -f $TimeSinceLastReport.TotalMinutes }
                }
                Else { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} seconds ago' -f $TimeSinceLastReport.TotalSeconds }
                }
            }
            $Variables | Add-Member -Force @{ Workers = $Workers }
            $Variables | Add-Member -Force @{ WorkersLastUpdated = (Get-Date) }

            Remove-Variable Workers

            Write-Message -Level Verbose "Retrieved status for workers with ID '$($Config.MonitoringUser)'."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from $($Config.MonitoringServer)."
        }
    }
}

Function Start-Mining { 

    If (Test-Path -PathType Leaf "$($Variables.MainPath)\Includes\Core.ps1") { 

        If (Test-Path -Path .\Cache\VertHash.dat -PathType Leaf) { 
            Write-Message -Level Verbose "Verifying integrity of VertHash data file (.\Cache\VertHash.dat)..."
            $VertHashCheck = Start-Job ([ScriptBlock]::Create("(Get-FileHash .\Cache\VertHash.dat).Hash -eq 'A55531E843CD56B010114AAF6325B0D529ECF88F8AD47639B6EDEDAFD721AA48'"))
        }

        If (-not $Variables.CoreRunspace) { 
            $Variables.LastDonated = (Get-Date).AddDays(-1).AddHours(1)
            $Variables.Pools = $null
            $Variables.Miners = $null

            $CoreRunspace = [RunspaceFactory]::CreateRunspace()
            $CoreRunspace.Open()
            $CoreRunspace.SessionStateProxy.SetVariable('Config', $Config)
            $CoreRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
            $CoreRunspace.SessionStateProxy.SetVariable('Stats', $Stats)
            $CoreRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $CoreRunspace
            $PowerShell.AddScript("$($Variables.MainPath)\Includes\Core.ps1")
            $PowerShell.BeginInvoke()

            $Variables.CoreRunspace = $CoreRunspace
            $Variables.CoreRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
        }

        If (Test-Path -Path .\Cache\VertHash.dat -PathType Leaf) { 
            If ($VertHashCheck | Wait-Job -Timeout 60 |  Receive-Job -Wait -AutoRemoveJob) { 
                Write-Message -Level Verbose "VertHash data file integrity check: OK."
            }
            Else { 
                Write-Message -Level Warn "VertHash data file (.\Cache\VertHash.dat) is corrupt -> file deleted. It will be recreated by the miners if needed."
                Remove-Item -Path .\Cache\VertHash.dat -Force -ErrorAction Ignore
            }
        }
    }
    Else { 
        Write-Message -Level Error "Corrupt installation. File '$($Variables.MainPath)\Includes\Core.ps1' is missing."
    }
}

Function Stop-Mining { 

    $Variables.Miners | Where-Object { $_.Status -EQ "Running" } | ForEach-Object { 
        Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore
        $_.Status = "Idle"
        $_.Best = $false
        Write-Message -Level Info "Stopped miner '$($_.Info)'."
    }
    $Variables.WatchdogTimers = @()
    $Variables.Summary = ""

    If ($Variables.CoreRunspace) { 
        Write-Message -Level Info "Ending cycle."
        $Variables.CoreRunspace.Close()
        If ($Variables.CoreRunspace.PowerShell) { $Variables.CoreRunspace.PowerShell.Dispose() }
        $Variables.Remove("Timer")
        $Variables.Remove("CoreRunspace")
    }
}


Function Read-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    If ($Global:Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }

    # Load the configuration
    If (Test-Path -PathType Leaf $ConfigFile) { 
        $Config_Tmp = Get-Content $ConfigFile | ConvertFrom-Json -ErrorAction Ignore
        If ($Config_Tmp.PSObject.Properties.Count -eq 0 -or $Config_Tmp -isnot [PSCustomObject]) { 
            Copy-Item -Path $ConfigFile "$($ConfigFile).corrupt" -Force
            Write-Message -Level Warn "Configuration file '$($ConfigFile)' is corrupt."
            $Config.ConfigFileVersionCompatibility = $null
        }
        Else { 
            # Fix upper / lower case (Web GUI is case sensitive)
            $Config_Tmp.PSObject.Properties.Name | ForEach-Object { 
                $Global:Config.Remove($_)
                $Global:Config.$_ = $Config_Tmp.$_ 
            }
        }
        Remove-Variable Config_Tmp
    }
    Else { 
        Write-Message -Level Warn "No valid configuration file found."

        # Prepare new config
        $Variables.FreshConfig = $true
        If (Test-Path -Path ".\Config\PoolsConfig-Recommended.json" -PathType Leaf) { 
            # Add default enabled pools
            $Config.PoolName = @(Get-Content ".\Config\PoolsConfig-Recommended.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore | ForEach-Object { $_ | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $_ -ne "Default" } })
        }

        # Add config items
        $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys } | Sort-Object Name | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Config.$_ = $Value
        }

        $Config | Add-Member ConfigFileVersion ($Variables.CurrentVersion.ToString()) -Force
    }

    # Build pools configuation
    If ($Variables.PoolsConfigFile -and (Test-Path -PathType Leaf $Variables.PoolsConfigFile)) { 
        $Variables.PoolsConfigData = Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json -ErrorAction Ignore
        If ($Variables.PoolsConfigData.PSObject.Properties.Count -eq 0 -or $Variables.PoolsConfigData -isnot [PSCustomObject]) { 
            Write-Message -Level Warn "Pools configuration file '$($Variables.PoolsConfigFile)' is corrupt and will be ignored."
        }
    }

    # Load default PoolData
    $PoolData = Get-Content .\Includes\PoolData.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore

    # Add pool config to config (in-memory only)
    $PoolsConfig = [Ordered]@{ }
    @(@((Get-ChildItem -Path ".\Pools\*.ps1" -File).BaseName -replace "24hr$" -replace "Coins$") + @((Get-ChildItem -Path ".\Balances\*.ps1" -File).BaseName)) | Where-Object { $_ -ne "NiceHash" } | Sort-Object -Unique | ForEach-Object { 
        $PoolName = $_
        $PoolConfig = [PSCustomObject]@{ }
        If ($Variables.PoolsConfigData.$PoolName) { $PoolConfig = $Variables.PoolsConfigData.$PoolName | ConvertTo-Json -ErrorAction Ignore | ConvertFrom-Json }
        ElseIf ($PoolData.$PoolName) { $PoolConfig = $PoolData.$PoolName }
        If (-not $PoolConfig.MinWorker) { $PoolConfig | Add-Member MinWorker $Config.MinWorker -Force }
        If (-not $PoolConfig.PayoutThreshold -and $PoolData.$PoolName.PayoutThreshold) { $PoolConfig | Add-Member PayoutThreshold $PoolData.$PoolName.PayoutThreshold -Force }
        If (-not $PoolConfig.EarningsAdjustmentFactor) { $PoolConfig | Add-Member EarningsAdjustmentFactor $Config.EarningsAdjustmentFactor -Force }
        If (-not $PoolConfig.WorkerName) { $PoolConfig | Add-Member WorkerName $Config.WorkerName -Force }
        Switch ($PoolName) { 
            "HiveON" { 
                If (-not $PoolConfig.PayoutCurrencies) { 
                    $PoolConfig | Add-Member PayoutCurrencies $PoolData.$PoolName.PayoutCurrencies
                }
                If (-not $PoolConfig.Wallets) { 
                    $PoolConfig | Add-Member Wallets ([PSCustomObject]@{ })
                    $Config.Wallets | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $_ -in $PoolConfig.PayoutCurrencies } | ForEach-Object { 
                        $PoolConfig.Wallets | Add-Member $_ ($Config.Wallets.$_)
                    }
                }
            }
            "MiningPoolHub" { 
                If (-not $PoolConfig.UserName) { $PoolConfig | Add-Member UserName $Config.MiningPoolHubUserName -Force }
            }
            "NiceHash External" { 
                If (-not $Config.NiceHashWalletIsInternal) { 
                    If (-not $PoolConfig.Wallets.BTC) { $PoolConfig | Add-Member Wallets ([PSCustomObject]@{ "BTC" = $Config.NiceHashWallet }) -Force }
                }
                If (-not $PoolConfig.Wallets.BTC) { $PoolConfig | Add-Member Wallets ([PSCustomObject]@{ "BTC" = $Config.Wallets.BTC }) -Force }
            }
            "NiceHash Internal" { 
                If ($Config.NiceHashWalletIsInternal -eq $true -and $Config.NiceHashWallet) { 
                    If (-not $PoolConfig.Wallets.BTC) { $PoolConfig | Add-Member Wallets ([PSCustomObject]@{ "BTC" = $Config.NiceHashWallet }) -Force }
                }
            }
            "ProHashing" { 
                If (-not $PoolConfig.UserName) { $PoolConfig | Add-Member UserName $Config.ProHashingUserName -Force }
                If (-not $PoolConfig.MiningMode) { $PoolConfig | Add-Member MiningMode $Config.ProHashingMiningMode -Force }
            }
            Default { 
                If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { 
                    $PoolConfig | Add-Member PayoutCurrency $Config.PayoutCurrency -Force
                }
                If (-not $PoolConfig.Wallets) { 
                    $PoolConfig | Add-Member Wallets ([PSCustomObject]@{ "$($PoolConfig.PayoutCurrency)" = $($Config.Wallets.($PoolConfig.PayoutCurrency)) }) -Force
                }
            }
        }
        If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 1) { $PoolConfig.EarningsAdjustmentFactor = 1 }

        $PoolConfig.PSObject.Members.Remove("PayoutCurrencies")
        $PoolConfig.PSObject.Members.Remove("PayoutCurrency")

        If ($PoolConfig.Algorithm) { $PoolConfig.Algorithm = $PoolConfig.Algorithm -replace " " }

        $PoolsConfig.$PoolName = $PoolConfig
    }

    $Config.PoolsConfig = $PoolsConfig
}

Function Write-Config { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    If ($Global:Config.ManualConfig) { Write-Message "Manual config mode - Not saving config"; Return }

    If (Test-Path $ConfigFile -PathType Leaf) {
        Copy-Item -Path $ConfigFile -Destination "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
    }

    $SortedConfig = $Config | Get-SortedObject
    $ConfigTmp = [Ordered]@{ }
    $SortedConfig.Keys | Where-Object { $_ -notlike "PoolsConfig" } | ForEach-Object { 
        $ConfigTmp[$_] = $SortedConfig.$_
    }
    $ConfigTmp | ConvertTo-Json -Depth 10 | Out-File $ConfigFile -Encoding UTF8 -Force
}

Function Get-SortedObject { 
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$Object
    )

    $Object = $Object | ConvertTo-Json -Depth 20 | ConvertFrom-Json 

    # Build an ordered hashtable of the property-value pairs.
    $SortedObject = [Ordered]@{ }

    Switch -Regex ($Object.GetType().Name) {
        "PSCustomObject" { 
            Get-Member -Type NoteProperty -InputObject $Object | Sort-Object Name | ForEach-Object { 
                # Upper / lower case conversion (Web GUI is case sensitive)
                $PropertyName = $_.Name
                $PropertyName = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $PropertyName }
                If (-not $PropertyName) { $PropertyName = $_.Name }

                If ($Object.$PropertyName -is [Hashtable] -or $Object.$PropertyName -is [PSCustomObject]) { 
                    $SortedObject[$PropertyName] = Get-SortedObject $Object.$PropertyName
                }
                Else { 
                    $SortedObject[$PropertyName] = $Object.$PropertyName
                }
            }
        }
        "Hashtable|SyncHashtable" { 
           $Object.Keys | Sort-Object | ForEach-Object { 
                # Upper / lower case conversion (Web GUI is case sensitive)
                $Key = $_
                $Key = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $Key }
                If (-not $Key) { $Key = $_ }

                If ($Object.$Key -is [Hashtable] -or $Object.$Key -is [PSCustomObject]) { 
                    $SortedObject[$Key] = Get-SortedObject $Object.$Key
                }
                Else { 
                    $SortedObject[$PropertyName] = $Object.$Key
                }
            }
        }
        Default {
            $SortedObject = $Object
        }
    }

    $SortedObject
}

Function Set-Stat { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = (Get-Date), 
        [Parameter(Mandatory = $false)]
        [TimeSpan]$Duration, 
        [Parameter(Mandatory = $false)]
        [Bool]$FaultDetection = $true, 
        [Parameter(Mandatory = $false)]
        [Bool]$ChangeDetection = $false, 
        [Parameter(Mandatory = $false)]
        [Int]$ToleranceExceeded = 3
    )

    $Timer = $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20

    $Stat = Get-Stat -Name $Name

    If ($Stat -is [Hashtable] -and $Stat.IsSynchronized) { 
        If (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        If (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        If ($Duration -le 0) { Return $Stat }

        If ($FaultDetection) { 
            $ToleranceMin = $Stat.Week * (1 - [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
            $ToleranceMax = $Stat.Week * (1 + [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
        }
        Else { 
            $ToleranceMin = $ToleranceMax = $Value
        }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { 
            $Stat.ToleranceExceeded ++
        }
        Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded -and $Stat.Week -gt 0) { 
            If ($Name -match ".+_HashRate$") { 
                Write-Message -Level Warn "Failed saving hash rate ($($Name): $(($Value | ConvertTo-Hash) -replace '\s+', '')). It is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [Attempt $($Stats.($Stat.Name).ToleranceExceeded) of 3 until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerUsage") { 
                Write-Message -Level Warn "Failed saving power usage ($($Name): $($Value.ToString("N2"))W). It is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Attempt $($Stats.($Stat.Name).ToleranceExceeded) of 3 until enforced update]."
            }
        }
        Else { 
            If ($Stat.ToleranceExceeded -eq $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1) { 
                If ($Value) { 
                    If ($Name -match ".+_HashRate$") { 
                        Write-Message -Level Warn "Saved hash rate ($($Name): $(($Value | ConvertTo-Hash) -replace '\s+', '')). It was forcefully updated because it was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) for $($Stats.($Stat.Name).ToleranceExceeded) times in a row."
                    }
                    ElseIf ($Name -match ".+_PowerUsage$") { 
                        Write-Message -Level Warn "Saved power usage ($($Name): $($Value.ToString("N2"))W). It was forcefully updated because it was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) for $($Stats.($Stat.Name).ToleranceExceeded) times in a row."
                    }
                }

                Remove-Stat -Name $Name
                $Stat = Set-Stat -Name $Name -Value $Value
            }
            Else { 
                $Span_Minute = [Math]::Min($Duration.TotalMinutes / [Math]::Min($Stat.Duration.TotalMinutes, 1), 1)
                $Span_Minute_5 = [Math]::Min(($Duration.TotalMinutes / 5) / [Math]::Min(($Stat.Duration.TotalMinutes / 5), 1), 1)
                $Span_Minute_10 = [Math]::Min(($Duration.TotalMinutes / 10) / [Math]::Min(($Stat.Duration.TotalMinutes / 10), 1), 1)
                $Span_Hour = [Math]::Min($Duration.TotalHours / [Math]::Min($Stat.Duration.TotalHours, 1), 1)
                $Span_Day = [Math]::Min($Duration.TotalDays / [Math]::Min($Stat.Duration.TotalDays, 1), 1)
                $Span_Week = [Math]::Min(($Duration.TotalDays / 7) / [Math]::Min(($Stat.Duration.TotalDays / 7), 1), 1)

                $Stat.Name = $Name
                $Stat.Live = $Value
                $Stat.Minute_Fluctuation = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
                $Stat.Minute = ((1 - $Span_Minute) * $Stat.Minute) + ($Span_Minute * $Value)
                $Stat.Minute_5_Fluctuation = ((1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation) + ($Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue)))
                $Stat.Minute_5 = ((1 - $Span_Minute_5) * $Stat.Minute_5) + ($Span_Minute_5 * $Value)
                $Stat.Minute_10_Fluctuation = ((1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation) + ($Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue)))
                $Stat.Minute_10 = ((1 - $Span_Minute_10) * $Stat.Minute_10) + ($Span_Minute_10 * $Value)
                $Stat.Hour_Fluctuation = ((1 - $Span_Hour) * $Stat.Hour_Fluctuation) + ($Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue)))
                $Stat.Hour = ((1 - $Span_Hour) * $Stat.Hour) + ($Span_Hour * $Value)
                $Stat.Day_Fluctuation = ((1 - $Span_Day) * $Stat.Day_Fluctuation) + ($Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue)))
                $Stat.Day = ((1 - $Span_Day) * $Stat.Day) + ($Span_Day * $Value)
                $Stat.Week_Fluctuation = ((1 - $Span_Week) * $Stat.Week_Fluctuation) + ($Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue)))
                $Stat.Week = ((1 - $Span_Week) * $Stat.Week) + ($Span_Week * $Value)
                $Stat.Duration = $Stat.Duration + $Duration
                $Stat.Updated = $Updated
                $Stat.Timer = $Timer
                $Stat.ToleranceExceeded = [UInt16]0
            }
        }
    }
    Else { 

       If (-not $Duration) { $Duration = [TimeSpan]::FromMinutes(1) }

       $Global:Stats.$Name = $Stat = [Hashtable]::Synchronized(
           @{ 
               Name                  = [String]$Name
               Live                  = [Double]$Value
               Minute                = [Double]$Value
               Minute_Fluctuation    = [Double]0
               Minute_5              = [Double]$Value
               Minute_5_Fluctuation  = [Double]0
               Minute_10             = [Double]$Value
               Minute_10_Fluctuation = [Double]0
               Hour                  = [Double]$Value
               Hour_Fluctuation      = [Double]0
               Day                   = [Double]$Value
               Day_Fluctuation       = [Double]0
               Week                  = [Double]$Value
               Week_Fluctuation      = [Double]0
               Duration              = [TimeSpan]$Duration
               Updated               = [DateTime]$Updated
               ToleranceExceeded     = [UInt16]0
               Timer                 = [DateTime]$Timer
           }
       )
    }

    @{ 
        Live                  = [Double]$Stat.Live
        Minute                = [Double]$Stat.Minute
        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
        Minute_5              = [Double]$Stat.Minute_5
        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
        Minute_10             = [Double]$Stat.Minute_10
        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
        Hour                  = [Double]$Stat.Hour
        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
        Day                   = [Double]$Stat.Day
        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
        Week                  = [Double]$Stat.Week
        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
        Duration              = [String]$Stat.Duration
        Updated               = [DateTime]$Stat.Updated
    } | ConvertTo-Json | Set-Content $Path

    $Stat
}

Function Get-Stat { 
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = (
            & { 
                [String[]]$StatFiles = (Get-ChildItem -Path "Stats" -File -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
                ($Global:Stats.Keys | Select-Object | Where-Object { $_ -notin $StatFiles }) | ForEach-Object { $Global:Stats.Remove($_) } # Remove stat if deleted on disk
                $StatFiles
            }
        )
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        $Stat_Name = $_
        If ($Global:Stats.$Stat_Name -isnot [Hashtable] -or -not $Global:Stats.$Stat_Name.IsSynchronized) { 
            If ($Global:Stats -isnot [Hashtable] -or -not $Global:Stats.IsSynchronized) { 
                $Global:Stats = [Hashtable]::Synchronized(@{ })
            }

            # Reduce number of errors
            If (-not (Test-Path -Path "Stats\$Stat_Name.txt" -PathType Leaf)) { 
                If (-not (Test-Path -Path "Stats" -PathType Container)) { 
                    New-Item "Stats" -ItemType "directory" -Force | Out-Null
                }
                Return
            }

            Try { 
                $Stat = Get-Content "Stats\$Stat_Name.txt" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $Global:Stats.$Stat_Name = [Hashtable]::Synchronized(
                    @{ 
                        Name                  = [String]$Stat_Name
                        Live                  = [Double]$Stat.Live
                        Minute                = [Double]$Stat.Minute
                        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
                        Minute_5              = [Double]$Stat.Minute_5
                        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
                        Minute_10             = [Double]$Stat.Minute_10
                        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
                        Hour                  = [Double]$Stat.Hour
                        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
                        Day                   = [Double]$Stat.Day
                        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
                        Week                  = [Double]$Stat.Week
                        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
                        Duration              = [TimeSpan]$Stat.Duration
                        Updated               = [DateTime]$Stat.Updated
                        ToleranceExceeded     = [UInt16]0
                    }
                )
            }
            Catch { 
                Write-Message -Level Warn "Stat file ($Stat_Name) is corrupt and will be reset."
                Remove-Stat $Stat_Name
            }
        }

        $Global:Stats.$Stat_Name
    }
}

Function Remove-Stat { 
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @(Get-ChildItem -Path "Stats" -Directory -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
       Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
        If ($Global:Stats.$_) { $Global:Stats.Remove($_) }
    }
}

Function Get-ArgumentsPerDevice { 

    # filters the command to contain only parameter values for present devices
    # if a parameter has multiple values, only the values for the available devices are included
    # parameters with a single value are valid for all devices and remain untouched
    # excluded parameters are passed unmodified

    Param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Command, 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeParameters = "", 
        [Parameter(Mandatory = $false)]
        [Int[]]$DeviceIDs
    )

    $CommandPerDevice = ""

    " $($Command.TrimStart().TrimEnd())" -split "(?=\s+[-]{1,2})" | ForEach-Object { 
        $Token = $_
        $Prefix = ""
        $ParameterValueSeparator = ""
        $ValueSeparator = ""
        $Values = ""

        If ($Token -match "(?:^\s[-=]+)" <#supported prefix characters are listed in brackets [-=]#>) { 
            $Prefix = "$($Token -split $Matches[0] | Select-Object -Index 0)$($Matches[0])"
            $Token = $Token -split $Matches[0] | Select-Object -Last 1

            If ($Token -match "(?:[ =]+)" <#supported separators are listed in brackets [ =]#>) { 
                $ParameterValueSeparator = $Matches[0]
                $Parameter = $Token -split $ParameterValueSeparator | Select-Object -Index 0
                $Values = $Token.Substring(("$Parameter$($ParameterValueSeparator)").length)

                If ($Parameter -notin $ExcludeParameters -and $Values -match "(?:[,; ]{1})" <#supported separators are listed in brackets [,; ]#>) { 
                    $ValueSeparator = $Matches[0]
                    $RelevantValues = @()
                    $DeviceIDs | ForEach-Object { 
                        $RelevantValues += ($Values.Split($ValueSeparator) | Select-Object -Index $_)
                    }
                    $CommandPerDevice += "$Prefix$Parameter$ParameterValueSeparator$($RelevantValues -join $ValueSeparator)"
                }
                Else { $CommandPerDevice += "$Prefix$Parameter$ParameterValueSeparator$Values" }
            }
            Else { $CommandPerDevice += "$Prefix$Token" }
        }
        Else { $CommandPerDevice += $Token }
    }
    $CommandPerDevice
}

Function Get-ChildItemContent { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Path, 
        [Parameter(Mandatory = $false)]
        [Hashtable]$Parameters = @{ }, 
        [Parameter(Mandatory = $false)]
        [Switch]$Threaded = $false, 
        [Parameter(Mandatory = $false)]
        [String]$Priority
    )

    $DefaultPriority = ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass
    If ($Priority) { ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass = $Priority } Else { $Priority = $DefaultPriority }

    $ScriptBlock = { 
        Param(
            [Parameter(Mandatory = $true)]
            [String]$Path, 
            [Parameter(Mandatory = $false)]
            [Hashtable]$Parameters = @{ }, 
            [Parameter(Mandatory = $false)]
            [String]$Priority = "BelowNormal"
        )

        ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass = $Priority

        Function Invoke-ExpressionRecursive ($Expression) { 
            If ($Expression -is [String]) { 
                If ($Expression -match '\$') { 
                    Try { $Expression = Invoke-Expression $Expression }
                    Catch { $Expression = Invoke-Expression "`"$Expression`"" }
                }
            }
            ElseIf ($Expression -is [PSCustomObject]) { 
                $Expression | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
                    $Expression.$_ = Invoke-ExpressionRecursive $Expression.$_
                }
            }
            Return $Expression
        }

        Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue | ForEach-Object { 
            $Name = $_.BaseName
            $Content = @()
            If ($_.Extension -eq ".ps1") { 
                $Content = & { 
                    If ($Parameters.Count) { 
                        $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }
                        & $_.FullName @Parameters
                    }
                    Else { 
                        & $_.FullName
                    }
                }
            }
            Else { 
                $Content = & { 
                    $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }
                    Try { 
                        ($_ | Get-Content | ConvertFrom-Json) | ForEach-Object { Invoke-ExpressionRecursive $_ }
                    }
                    Catch [ArgumentException] { 
                        $null
                    }
                }
                If ($null -eq $Content) { $Content = $_ | Get-Content }
            }
            $Content | ForEach-Object { 
                [PSCustomObject]@{ Name = $Name; Content = $_ }
            }
        }
    }

    If ($Threaded) { 
        $PowerShell = [PowerShell]::Create().AddScript($ScriptBlock)
        [Void]$PowerShell.AddArgument($Path)
        [Void]$PowerShell.AddArgument($Parameters)
        [Void]$PowerShell.AddArgument($Priority)

        $Job = $PowerShell.BeginInvoke()
        $PowerShell | Add-Member Job $Job

        Return $PowerShell
    }
    Else { 
        Return (& $ScriptBlock -Path $Path -Parameters $Parameters)
    }
}

Function Invoke-TcpRequest { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Server, 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout # seconds
    )

    Try { 
        $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
        $Stream = $Client.GetStream()
        $Writer = New-Object System.IO.StreamWriter $Stream
        $Reader = New-Object System.IO.StreamReader $Stream
        $Client.SendTimeout = $Timeout * 1000
        $Client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Request)
        $Response = $Reader.ReadLine()
    }
    Catch { $Error.Remove($error[$Error.Count - 1]) }
    Finally { 
        If ($Reader) { $Reader.Close() }
        If ($Writer) { $Writer.Close() }
        If ($Stream) { $Stream.Close() }
        If ($Client) { $Client.Close() }
    }

    $Response
}

Function Get-CpuId { 

    # Brief : gets CPUID (CPU name and registers)

    # OS Features
    # $OS_x64 = "" # not implemented
    # $OS_AVX = "" # not implemented
    # $OS_AVX512 = "" # not implemented

    # Vendor
    $vendor = "" # not implemented

    $info = [CpuID]::Invoke(0)
    # convert 16 bytes to 4 ints for compatibility with existing code
    $info = [int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    $nIds = $info[0]

    $info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($info, 0 * 4) # not sure as to why 'nExIds' is unsigned; may not be necessary
    # convert 16 bytes to 4 ints for compatibility with existing code
    $info = [int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    # Detect Features
    $features = @{ }
    If ($nIds -ge 0x00000001) { 

        $info = [CpuID]::Invoke(0x00000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.MMX = ($info[3] -band ([int]1 -shl 23)) -ne 0
        $features.SSE = ($info[3] -band ([int]1 -shl 25)) -ne 0
        $features.SSE2 = ($info[3] -band ([int]1 -shl 26)) -ne 0
        $features.SSE3 = ($info[2] -band ([int]1 -shl 00)) -ne 0

        $features.SSSE3 = ($info[2] -band ([int]1 -shl 09)) -ne 0
        $features.SSE41 = ($info[2] -band ([int]1 -shl 19)) -ne 0
        $features.SSE42 = ($info[2] -band ([int]1 -shl 20)) -ne 0
        $features.AES = ($info[2] -band ([int]1 -shl 25)) -ne 0

        $features.AVX = ($info[2] -band ([int]1 -shl 28)) -ne 0
        $features.FMA3 = ($info[2] -band ([int]1 -shl 12)) -ne 0

        $features.RDRAND = ($info[2] -band ([int]1 -shl 30)) -ne 0
    }

    If ($nIds -ge 0x00000007) { 

        $info = [CpuID]::Invoke(0x00000007)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.AVX2 = ($info[1] -band ([int]1 -shl 05)) -ne 0

        $features.BMI1 = ($info[1] -band ([int]1 -shl 03)) -ne 0
        $features.BMI2 = ($info[1] -band ([int]1 -shl 08)) -ne 0
        $features.ADX = ($info[1] -band ([int]1 -shl 19)) -ne 0
        $features.MPX = ($info[1] -band ([int]1 -shl 14)) -ne 0
        $features.SHA = ($info[1] -band ([int]1 -shl 29)) -ne 0
        $features.PREFETCHWT1 = ($info[2] -band ([int]1 -shl 00)) -ne 0

        $features.AVX512_F = ($info[1] -band ([int]1 -shl 16)) -ne 0
        $features.AVX512_CD = ($info[1] -band ([int]1 -shl 28)) -ne 0
        $features.AVX512_PF = ($info[1] -band ([int]1 -shl 26)) -ne 0
        $features.AVX512_ER = ($info[1] -band ([int]1 -shl 27)) -ne 0
        $features.AVX512_VL = ($info[1] -band ([int]1 -shl 31)) -ne 0
        $features.AVX512_BW = ($info[1] -band ([int]1 -shl 30)) -ne 0
        $features.AVX512_DQ = ($info[1] -band ([int]1 -shl 17)) -ne 0
        $features.AVX512_IFMA = ($info[1] -band ([int]1 -shl 21)) -ne 0
        $features.AVX512_VBMI = ($info[2] -band ([int]1 -shl 01)) -ne 0
    }

    If ($nExIds -ge 0x80000001) { 

        $info = [CpuID]::Invoke(0x80000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.x64 = ($info[3] -band ([int]1 -shl 29)) -ne 0
        $features.ABM = ($info[2] -band ([int]1 -shl 05)) -ne 0
        $features.SSE4a = ($info[2] -band ([int]1 -shl 06)) -ne 0
        $features.FMA4 = ($info[2] -band ([int]1 -shl 16)) -ne 0
        $features.XOP = ($info[2] -band ([int]1 -shl 11)) -ne 0
    }

    # wrap data into PSObject
    [PSCustomObject]@{ 
        Vendor   = $vendor
        Name     = $name
        Features = $features.Keys.ForEach{ If ($features.$_) { $_ } }
    }
}

Function Get-Device { 
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @(), 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeName = @(), 
        [Parameter(Mandatory = $false)]
        [Switch]$Refresh = $false
    )

    If ($Name) { 
        $DeviceList = Get-Content ".\Includes\Devices.txt" | ConvertFrom-Json
        $Name_Devices = $Name | ForEach-Object { 
            $Name_Split = $_ -split '#'
            $Name_Split = @($Name_Split | Select-Object -Index 0) + @($Name_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $Name_Split += @("*") * (100 - $Name_Split.Count)

            $Name_Device = $DeviceList.("{0}" -f $Name_Split) | Select-Object *
            $Name_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Name_Device.$_ = $Name_Device.$_ -f $Name_Split }

            $Name_Device
        }
    }

    If ($ExcludeName) { 
        If (-not $DeviceList) { $DeviceList = Get-Content -Path ".\Includes\Devices.txt" | ConvertFrom-Json }
        $ExcludeName_Devices = $ExcludeName | ForEach-Object { 
            $ExcludeName_Split = $_ -split '#'
            $ExcludeName_Split = @($ExcludeName_Split | Select-Object -Index 0) + @($ExcludeName_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $ExcludeName_Split += @("*") * (100 - $ExcludeName_Split.Count)

            $ExcludeName_Device = $DeviceList.("{0}" -f $ExcludeName_Split) | Select-Object *
            $ExcludeName_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $ExcludeName_Device.$_ = $ExcludeName_Device.$_ -f $ExcludeName_Split }

            $ExcludeName_Device
        }
    }

    If ($Variables.Devices -isnot [Device[]] -or $Refresh) { 
        [Device[]]$Variables.Devices = @()

        $Id = 0
        $Type_Id = @{ }
        $Vendor_Id = @{ }
        $Type_Vendor_Id = @{ }

        $Slot = 0
        $Type_Slot = @{ }
        $Vendor_Slot = @{ }
        $Type_Vendor_Slot = @{ }

        $Index = 0
        $Type_Index = @{ }
        $Vendor_Index = @{ }
        $Type_Vendor_Index = @{ }
        $PlatformId = 0
        $PlatformId_Index = @{ }
        $Type_PlatformId_Index = @{ }

        # Get WDDM data
        Try { 
            Get-CimInstance CIM_Processor | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                # Add normalised values
                $Variables.Devices += $Device = [PSCustomObject]@{ 
                    Name   = $null
                    Model  = $Device_CIM.Name
                    Type   = "CPU"
                    Bus    = $null
                    Vendor = $(
                        Switch -Regex ($Device_CIM.Manufacturer) { 
                            "Advanced Micro Devices" { "AMD" }
                            "Intel" { "INTEL" }
                            "NVIDIA" { "NVIDIA" }
                            "AMD" { "AMD" }
                            Default { $Device_CIM.Manufacturer -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                        }
                    )
                    Memory = $null
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = (($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                $Type_Id.($Device.Type)++

                # Read CPU features
                $Device | Add-Member CpuFeatures ((Get-CpuId).Features | Sort-Object)

                # Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                }
            }

            Get-CimInstance CIM_VideoController | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { 
                    $Device_PNP = [PSCustomObject]@{ }
                    Get-PnpDevice $Device_CIM.PNPDeviceID | Get-PnpDeviceProperty | ForEach-Object { $Device_PNP | Add-Member $_.KeyName $_.Data }
                    $Device_PNP = $Device_PNP | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    $Device_Reg = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)" | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_CIM.Name
                        Type   = "GPU"
                        Bus    = $(
                            If ($Device_PNP.DEVPKEY_Device_BusNumber -is [Int64] -or $Device_PNP.DEVPKEY_Device_BusNumber -is [Int32]) { 
                                [Int64]$Device_PNP.DEVPKEY_Device_BusNumber
                            }
                        )
                        Vendor = $(
                            Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                    }
                }
                Else { 
                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_CIM.Name
                        Type   = "GPU"
                        Vendor = $(
                            Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                    }
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }
                #Unsupported devices start at DeviceID 100 (to not disrupt device order when running in a Citrix / RDP session)
                If ($Device.Vendor -in $Variables.SupportedDeviceVendors) { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                }
                Else { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f ($Device.Type_Id + 100))"
                }
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                If ($Device.Vendor -in $Variables.SupportedDeviceVendors) { $Type_Id.($Device.Type)++ }

                # Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                    PNP = $Device_PNP
                    Reg = $Device_Reg
                }
            }
        }
        Catch { 
            Write-Message -Level Warn "WDDM device detection has failed. "
        }

        # Get OpenCL data
        Try { 
            [OpenCl.Platform]::GetPlatformIDs() | ForEach-Object { 
                [OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All) | ForEach-Object { $_ | ConvertTo-Json -WarningAction SilentlyContinue } | Select-Object -Unique | ForEach-Object { 
                    $Device_OpenCL = $_ | ConvertFrom-Json

                    # Add normalised values
                    $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_OpenCL.Name
                        Type   = $(
                            Switch -Regex ([String]$Device_OpenCL.Type) { 
                                "CPU" { "CPU" }
                                "GPU" { "GPU" }
                                Default { [String]$Device_OpenCL.Type -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Bus    = $(
                            If ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
                                [Int64]$Device_OpenCL.PCIBus
                            }
                        )
                        Vendor = $(
                            Switch -Regex ([String]$Device_OpenCL.Vendor) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { [String]$Device_OpenCL.Vendor -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [UInt64]$Device_OpenCL.GlobalMemSize
                    }

                    $Device | Add-Member @{ 
                        Id             = [Int]$Id
                        Type_Id        = [Int]$Type_Id.($Device.Type)
                        Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                    }
                    #Unsupported devices start at DeviceID 100 (to not disrupt device order when running in a Citrix / RDP session)
                    If ($Device.Vendor -in $Variables.SupportedDeviceVendors) { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                    }
                    Else { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f ($Device.Type_Id) + 100)"
                    }
                    $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                    If ($Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus) { 
                        $Device = $Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus
                    }
                    ElseIf ($Device.Type -eq "GPU" -and ($Device.Vendor -eq "AMD" -or $Device.Vendor -eq "NVIDIA")) { 
                        $Variables.Devices += $Device

                        If (-not $Type_Vendor_Id.($Device.Type)) { 
                            $Type_Vendor_Id.($Device.Type) = @{ }
                        }

                        $Id++
                        $Vendor_Id.($Device.Vendor)++
                        $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                        If ($Device.Vendor -in $Variables.SupportedDeviceVendors) { $Type_Id.($Device.Type)++ }
                    }

                    # Add OpenCL specific data
                    $tmp = [Int]$PlatformId_Index.($PlatformId) # temp fix. PlatformId_Index is broken without this
                    $Device | Add-Member @{ 
                        Index                 = [Int]$Index
                        Type_Index            = [Int]$Type_Index.($Device.Type)
                        Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
                        Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                        PlatformId            = [Int]$PlatformId
                        PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
                        Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)
                    } -Force

                    # Add raw data
                    $Device | Add-Member @{ 
                        OpenCL = $Device_OpenCL
                    } -Force

                    If (-not $Type_Vendor_Index.($Device.Type)) { 
                        $Type_Vendor_Index.($Device.Type) = @{ }
                    }
                    If (-not $Type_PlatformId_Index.($Device.Type)) { 
                        $Type_PlatformId_Index.($Device.Type) = @{ }
                    }

                    $Index++
                    $Type_Index.($Device.Type)++
                    $Vendor_Index.($Device.Vendor)++
                    $Type_Vendor_Index.($Device.Type).($Device.Vendor)++
                    $PlatformId_Index.($PlatformId)++
                    $Type_PlatformId_Index.($Device.Type).($PlatformId)++
                }

                $PlatformId++
            }

            $Variables.Devices | Where-Object Bus -Is [Int64] | Sort-Object Bus | ForEach-Object { 
                $_ | Add-Member @{ 
                    Slot             = [Int]$Slot
                    Type_Slot        = [Int]$Type_Slot.($_.Type)
                    Vendor_Slot      = [Int]$Vendor_Slot.($_.Vendor)
                    Type_Vendor_Slot = [Int]$Type_Vendor_Slot.($_.Type).($_.Vendor)
                }

                If (-not $Type_Vendor_Slot.($_.Type)) { 
                    $Type_Vendor_Slot.($_.Type) = @{ }
                }

                $Slot++
                $Type_Slot.($_.Type)++
                $Vendor_Slot.($_.Vendor)++
                $Type_Vendor_Slot.($_.Type).($_.Vendor)++
            }
        }
        Catch { 
            Write-Message -Level Warn "OpenCL device detection has failed. "
        }
    }

    $Variables.Devices | ForEach-Object { 
        [Device]$Device = $_

        $Device.Bus_Index = @($Variables.Devices.Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Type_Index = @(($Variables.Devices | Where-Object Type -EQ $Device.Type).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Vendor_Index = @(($Variables.Devices | Where-Object Vendor -EQ $Device.Vendor).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Platform_Index = @(($Variables.Devices | Where-Object Platform -EQ $Device.Platform).Bus | Sort-Object).IndexOf([Int]$Device.Bus)

        If (-not $Name -or ($Name_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
            If (-not $ExcludeName -or -not ($ExcludeName_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
                $Device
            }
        }
    }
}

Filter ConvertTo-Hash { 
    $Units = " kMGTPEZY " # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    "{0:n2} $($Units[$Base1000])H" -f ($_ / [Math]::Pow(1000, $Base1000))
}

Function Get-DigitsFromValue {

    # To get same numbering scheme regardless of value base currency value (size) to determine formatting

    # Length is calculated as follows:
    # Output will have as many digits as the integer value is to the power of 10
    # e.g. Rate is between 100 -and 999, then Digits is 3
    # The bigger the number, the more decimal digits
    # Use $Offset to add/remove decimal places

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$Offset = 0
    )

    $Digits = [math]::Floor($Value).ToString().Length + $Offset
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    $Digits
}

Function ConvertTo-LocalCurrency { 

    # To get same numbering scheme regardless of value
    # Use $Offset to add/remove decimal places

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $true)]
        [Double]$Rate, 
        [Parameter(Mandatory = $false)]
        [Int]$Offset
    )

    $Digits = ([math]::truncate(10 - $Offset - [math]::log($Rate, 10)))
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    ($Value * $Rate).ToString("N$($Digits)")
}

Function Get-Combination { 
    Param(
        [Parameter(Mandatory = $true)]
        [Array]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{ }

    For ($i = 0; $i -lt $Value.Count; $i++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $i) = $Value[$i] }
    }

    $Combination_Keys = $Combination | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    For ($i = $SizeMin; $i -le $SizeMax; $i++) { 
        $x = [Math]::Pow(2, $i) - 1

        While ($x -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ Combination = $Combination_Keys | Where-Object { $_ -band $x } | ForEach-Object { $Combination.$_ } }
            $smallest = ($x -band - $x)
            $ripple = $x + $smallest
            $new_smallest = ($ripple -band - $ripple)
            $ones = (($new_smallest / $smallest) -shr 1) - 1
            $x = $ripple -bor $ones
        }
    }
}

Function Invoke-CreateProcess {

    # Based on https://github.com/FuzzySecurity/PowerShell-Suite/blob/master/Invoke-CreateProcess.ps1

    Param (
        [Parameter(Mandatory = $true)]
        [String]$BinaryPath,
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = $null,
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [Parameter(Mandatory = $false)]
        [ValidateRange(-2, 3)]
        [Int]$Priority = 0, # NORMAL
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock = "",
        [Parameter(Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, # CREATE_NEW_CONSOLE
        [Parameter(Mandatory = $false)]
        [String]$ShowMinerWindows = "minimized",
        [Parameter(Mandatory = $false)]
        [String]$StartF = 0x00000001, # STARTF_USESHOWWINDOW
        [Parameter(Mandatory = $false)]
        [String]$LogFile,
        [Parameter(Mandatory = $false)]
        [String]$WindowTitle = ""
    )

    $PriorityNames = [PSCustomObject]@{ -2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime" }

    $Job = Start-Job -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $ShowMinerWindows, $StartF, $PID { 
        Param($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $ShowMinerWindows, $StartF, $ControllerProcessID)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        If ($null -eq $ControllerProcess) { Return }

        # Define all the structures for CreateProcess
        Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct PROCESS_INFORMATION
{
    public IntPtr hProcess; public IntPtr hThread; public uint dwProcessId; public uint dwThreadId;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct STARTUPINFO
{
    public uint cb; public string lpReserved; public string lpDesktop; public string lpTitle;
    public uint dwX; public uint dwY; public uint dwXSize; public uint dwYSize; public uint dwXCountChars;
    public uint dwYCountChars; public uint dwFillAttribute; public uint dwFlags; public short wShowWindow;
    public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput;
    public IntPtr hStdError;
}

[StructLayout(LayoutKind.Sequential)]
public struct SECURITY_ATTRIBUTES
{
    public int length; public IntPtr lpSecurityDescriptor; public bool bInheritHandle;
}

public static class Kernel32
{
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CreateProcess(
        string lpApplicationName, string lpCommandLine, ref SECURITY_ATTRIBUTES lpProcessAttributes, 
        ref SECURITY_ATTRIBUTES lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, 
        IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, 
        out PROCESS_INFORMATION lpProcessInformation);
}
"@

        Switch ($ShowMinerWindows) {
            "hidden" { $ShowWindow = "0x0000" } # SW_HIDE
            "normal" { $ShowWindow = "0x0001" } # SW_SHOWNORMAL
            Default  { $ShowWindow = "0x0007" } # SW_SHOWMINNOACTIVE
        }

        # Set local environment
        $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

        # StartupInfo Struct
        $StartupInfo = New-Object STARTUPINFO
        $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
        $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
        $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct Size

        # ProcessInfo Struct
        $ProcessInfo = New-Object PROCESS_INFORMATION

        # SECURITY_ATTRIBUTES Struct (Process & Thread)
        $SecAttr = New-Object SECURITY_ATTRIBUTES
        $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

        # CreateProcess --> lpCurrentDirectory
        If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # Call CreateProcess
        [Kernel32]::CreateProcess($BinaryPath, "$BinaryPath $ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo) | Out-Null

        $Process = Get-Process -Id $ProcessInfo.dwProcessId
        If ($null -eq $Process) { 
            [PSCustomObject]@{ ProcessId = $null }
            Return
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        Do { If ($ControllerProcess.WaitForExit(250)) { $Process.CloseMainWindow() | Out-Null } }
        While ($Process.HasExited -eq $false)
    }

    Do { Start-Sleep -Milliseconds 50; $JobOutput = Receive-Job $Job }
    While ($null -eq $JobOutput)

    $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
    If ($Process) { $Process.PriorityClass = $PriorityNames.$Priority }

    Return $Job
}

Function Start-SubProcess { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$FilePath, 
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = "", 
        [Parameter(Mandatory = $false)]
        [String]$LogPath = "", 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [ValidateRange(-2, 3)]
        [Parameter(Mandatory = $false)]
        [Int]$Priority = 0, 
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock
    )

    If ($EnvBlock) { $EnvBlock | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force } }

    $ScriptBlock = "Set-Location '$WorkingDirectory'; (Get-Process -Id `$PID).PriorityClass = '$(@{-2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime"}[$Priority])'; "
    $ScriptBlock += "& '$FilePath'"
    If ($ArgumentList) { $ScriptBlock += " $ArgumentList" }
    $ScriptBlock += " *>&1"
    $ScriptBlock += " | Write-Output"
    If ($LogPath) { $ScriptBlock += " | Tee-Object '$LogPath'" }

    Start-Job ([ScriptBlock]::Create($ScriptBlock))
}

Function Expand-WebRequest { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    If (-not $Path) { $Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName }
    If (-not (Test-Path -Path ".\Downloads" -PathType Container)) { New-Item "Downloads" -ItemType "directory" | Out-Null }
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    If (Test-Path $FileName -PathType Leaf) { Remove-Item $FileName }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $Uri -OutFile $FileName -UseBasicParsing

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Minimized

        If (Test-Path $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        # use first (topmost) directory in case, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various sub dirs
        $Path_Old = (Get-ChildItem -Path $Path_Old -File -Recurse | Where-Object { $_.Name -EQ $(Split-Path $Path -Leaf) }).Directory | Select-Object -Index 0

        If ($Path_Old) { 
            Move-Item $Path_Old $Path_New -PassThru | ForEach-Object -Process { $_.LastWriteTime = Get-Date }
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            If (Test-Path $Path_Old -PathType Container) { Remove-Item -Path $Path_Old -Recurse -Force }
        }
        Else { 
            Throw "Error: Cannot find '$Path'."
        }
    }
}

Function Get-Algorithm { 
    Param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm = ""
    )

    If (-not (Test-Path Variable:Global:Algorithms -ErrorAction SilentlyContinue)) {
        $Global:Algorithms = Get-Content ".\Includes\Algorithms.txt" | ConvertFrom-Json
    }

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower() -replace '-' -replace '_' -replace '/' -replace ' ')

    If ($Global:Algorithms.$Algorithm) { $Global:Algorithms.$Algorithm }
    Else { $Algorithm }
}

Function Get-Region { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Region,
        [Parameter(Mandatory = $false)]
        [Switch]$List = $false
    )

    If (-not (Test-Path Variable:Global:Regions -ErrorAction SilentlyContinue)) { 
        $Global:Regions = Get-Content ".\Includes\Regions.txt" | ConvertFrom-Json
    }

    If ($List) { Return $Global:Regions.$Region }

    If ($Global:Regions.$Region) { 
       Return $($Global:Regions.$Region | Select-Object -Index 0)
    }
    Return $null
}

Function Get-NMVersion { 

    # Check if new version is available
    Try { 
        # $UpdateVersion = Invoke-WebRequest "https://nemosminer.com/data/Initialize-Autoupdate.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
        $UpdateVersion = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/NemosMiner/testing/Version.txt" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    Catch { 
    }

    If ($UpdateVersion.Product -eq $Variables.CurrentProduct -and [Version]$UpdateVersion.Version -gt $Variables.CurrentVersion) { 
        If ($UpdateVersion.AutoUpdate -eq $true) { 
            If ($Config.AutoUpdate) { 
                Initialize-Autoupdate -UpdateVersion $UpdateVersion
            }
            Else { 
                Write-Message -Level Verbose "Version checker: New Version $($UpdateVersion.Version) found. Auto Update is disabled in config - You must update manually."
            }
        }
        Else { 
            Write-Message -Level Verbose "$($UpdateVersion.Product) $($UpdateVersion.Version) does not support auto-update. You must update manually."
        }
    }
    Else { 
        Write-Message -Level Verbose "Version checker: $($Variables.CurrentProduct) $($Variables.CurrentVersion) is current - no update available."
    }
}

Function Initialize-Autoupdate { 
    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    Set-Location $Variables.MainPath
    $UpdateLog = "$($Variables.MainPath)\Logs\AutoupdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"
    $BackupFile = "AutoupdateBackup_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").zip"

    # GitHub only suppors TLSv1.2 since feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    $NemosMinerFileHash = (Get-FileHash ".\NemosMiner.ps1").Hash

    "Version checker: New version $($UpdateVersion.Version) found. " | Tee-Object $UpdateLog | Write-Message -Level Verbose
    "Starting auto update - Logging changes to '$UpdateLog'." | Tee-Object $UpdateLog | Write-Message -Level Verbose

    # Setting autostart to true
    If ($Variables.MiningStatus -eq "Running") { $Config.AutoStart = $true }

    # Download update file
    $UpdateFileName = ".\$($UpdateVersion.Product)-$($UpdateVersion.Version)"
    "Downloading new version..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
    Try { 
        Invoke-WebRequest $UpdateVersion.Uri -OutFile "$($UpdateFileName).zip" -TimeoutSec 15 -UseBasicParsing
    }
    Catch { 
        "Downloading failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
        Return
    }
    If (-not (Test-Path -Path ".\$($UpdateFileName).zip" -PathType Leaf)) { 
        Write-Message -Level Error "Cannot find update file. Cannot complete auto-update :-("
        Return
    }

    If ($Variables.CurrentVersion -le [System.Version]"3.9.9.17" -and $UpdateVersion.Version -ge [System.Version]"3.9.9.17") {
        # Balances & earnings files are no longer compatible
        Write-Message -Level Warn "Balances & Earnings files are no longer compatible and will be reset."
    }

    # Backup current version folder in zip file; exclude existing zip files and download folder
    "Backing up current version as '$($BackupFile)'..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Start-Process ".\Utils\7z" "a $($BackupFile) .\* -x!*.zip -x!downloads  -x!cache -x!$UpdateLog -bb1 -bd" -RedirectStandardOutput "$($UpdateLog)_tmp" -Wait -WindowStyle Hidden
    Add-Content $UpdateLog (Get-Content -Path "$($UpdateLog)_tmp")
    Remove-Item -Path "$($UpdateLog)_tmp" -Force

    If (-not (Test-Path .\$BackupFile -PathType Leaf)) { 
        "Backup failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
        Return
    }

    #Stop all background processes
    Stop-Mining
    Stop-IdleMining
    Stop-BrainJob
    Stop-BalancesTracker

    If ($Variables.CurrentVersion -le [System.Version]"3.9.9.17" -and $UpdateVersion -ge [System.Version]"3.9.9.17") {
        # Remove balances & earnings files that are no longer compatible
        If (Test-Path -Path ".\Logs\BalancesTrackerData*.*") { Get-ChildItem -Path ".\Logs\BalancesTrackerData*.*" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }
        If (Test-Path -Path ".\Logs\DailyEarnings*.*") { Get-ChildItem -Path ".\Logs\DailyEarnings*.*" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }
    }

    # Pre update specific actions if any
    # Use PreUpdateActions.ps1 in new release to place code
    # If (Test-Path -Path ".\$UpdateFilePath\PreUpdateActions.ps1" -PathType Leaf) { 
    #     Invoke-Expression (Get-Content ".\$UpdateFilePath\PreUpdateActions.ps1" -Raw)
    # }

    # Empty folders
    If (Test-Path -Path ".\Brains") { Get-ChildItem -Path ".\Brains" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }
    If (Test-Path -Path ".\Pools") { Get-ChildItem -Path ".\Pools\" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }
    If (Test-Path -Path ".\Web") { Get-ChildItem -Path ".\Web" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }

    # Unzip in child folder excluding config
    "Unzipping update..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Start-Process ".\Utils\7z" "x $($UpdateFileName).zip -o.\$($UpdateFileName) -y -spe -xr!config -bb1 -bd" -RedirectStandardOutput "$($UpdateLog)_tmp" -Wait -WindowStyle Hidden
    Add-Content $UpdateLog (Get-Content -Path "$($UpdateLog)_tmp")
    Remove-Item -Path "$($UpdateLog)_tmp" -Force

    #Testing files are in a subdirectory
    $UpdateFilePath = $UpdateFileName
    If ((Get-ChildItem -Path $UpdateFileName -Directory).Count -eq 1) { 
        $UpdateFilePath = "$UpdateFileName\$((Get-ChildItem -Path $UpdateFileName -Directory).Name)"
    }

    # Stop Snaketail
    If ($Variables.SnakeTailExe) { 
        "Stopping SnakeTail..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        (Get-CimInstance CIM_Process | Where-Object ExecutablePath -EQ $Variables.SnakeTailExe).ProcessId | ForEach-Object { Stop-Process -Id $_ }
    }

    # Copy files
    "Copying new files ..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Get-ChildItem -Path ".\$UpdateFilePath\*" -Recurse | ForEach-Object { 
        $DestPath = $_.FullName.Replace($UpdateFilePath -replace '^\.', '')
        If ($_.Attributes -eq "Directory") { 
            If (-not (Test-Path -Path $DestPath -PathType Container)) { 
                New-Item -Path $DestPath -ItemType Directory -Force
                "Created directory '$DestPath'"
            }
        }
        Else { 
            Copy-Item -Path $_ -Destination $DestPath -Force -ErrorAction Ignore
            "Copied '$($_.Name)' to '$Destpath'" | Out-File -FilePath $UpdateLog -Append
        }
    }

    # Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
    If ((Test-Path $Config.SnakeTailExe -PathType Leaf -ErrorAction Ignore) -and (Test-Path $Config.SnakeTailConfig -PathType Leaf -ErrorAction Ignore)) { 
        "Restarting SnakeTail..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        & "$($Variables.SnakeTailExe)" $Variables.SnakeTailConfig
    }

    # Post update actions
    If (Test-Path  -Path ".\OptionalMiners" -PathType Container) { 
        # Remove any obsolete Optional miner file (ie. not in new version OptionalMiners)
        Get-ChildItem -Path ".\OptionalMiners" -File | Where-Object { $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\OptionalMiners" -File).name } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append }
        # Update Optional Miners to Miners If in use
        Get-ChildItem -Path ".\OptionalMiners" -File | Where-Object { $_.name -in (Get-ChildItem -Path ".\Miners" -File).name } | ForEach-Object { Copy-Item -Path $_.FullName -Destination ".\Miners" -Force; "Copied $($_.Name) to '.\Miners'" | Out-File -FilePath $UpdateLog -Append }
    }

    # Remove any obsolete miner file (ie. not in new version Miners or OptionalMiners)
    If (Test-Path -Path ".\Miners" -PathType Container) { Get-ChildItem -Path ".\Miners" -File | Where-Object { $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\Miners" -File).name -and $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\OptionalMiners" -File).name } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append } }

    # Get all miner names and remove obsolete stat files from miners that no longer exist
    $MinerNames = @( )
    If (Test-Path -Path ".\Miners" -PathType Container) { Get-ChildItem -Path ".\Miners" -File | ForEach-Object { $MinerNames += $_.Name -replace $_.Extension } }
    If (Test-Path -Path ".\OptionalMiners" -PathType Container) { Get-ChildItem -Path ".\OptionalMiners" -File | ForEach-Object { $MinerNames += $_.Name -replace $_.Extension } }
    If (Test-Path -Path ".\Stats" -PathType Container) { 
        Get-ChildItem -Path ".\Stats\*_HashRate.txt" -File | Where-Object { (($_.name -Split '-' | Select-Object -First 2) -Join '-') -notin $MinerNames } | ForEach-Object { Remove-Item -Path $_ -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append }
        Get-ChildItem -Path ".\Stats\*_PowerUsage.txt" -File | Where-Object { (($_.name -Split '-' | Select-Object -First 2) -Join '-') -notin $MinerNames } | ForEach-Object { Remove-Item -Path $_ -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append }
    }

    If ($ObsoleteStatFiles.Count -gt 0) { 
        "Removing obsolete stat files from miners that no longer exist..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $ObsoleteStatFiles | ForEach-Object { 
            Remove-Item -Path $_ -Force
            "Removed '$_'" | Out-File -FilePath $UpdateLog -Append
        }
    }

    # Remove temp files
    "Removing temporary files..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Remove-Item .\$UpdateFileName -Force -Recurse
    Remove-Item ".\$($UpdateFileName).zip" -Force
    If (Test-Path -Path ".\PreUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PreUpdateActions.ps1" -Force
        "Removed '.\PreUpdateActions.ps1'."
    }
    If (Test-Path -Path ".\PostUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PostUpdateActions.ps1" -Force
        "Removed '.\PostUpdateActions.ps1'."
    }
    Get-ChildItem -Path "AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $BackupFile } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append }
    Get-ChildItem -Path ".\Logs\AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $UpdateLog } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append }

    # Start new instance
    If ($UpdateVersion.RequireRestart -or ($NemosMinerFileHash -ne (Get-FileHash ".\NemosMiner.ps1").Hash)) { 
        "Starting updated version..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $StartCommand = ((Get-CimInstance win32_process -Filter "ProcessID=$PID" | Select-Object CommandLine).CommandLine)
        $NewKid = Invoke-CimMethod -ClassName Win32_Process -MethodName "Create" -Arguments @{ CommandLine = "$StartCommand"; CurrentDirectory = $Variables.MainPath }
        Start-Sleep 5

        # Giving 10 seconds for process to start
        $Waited = 0
        While (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction silentlycontinue) -and ($waited -le 10)) { Start-Sleep -Seconds 1; $waited++ }
        If (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction silentlycontinue)) { 
            "Failed to start new instance of $($Variables.CurrentProduct)." | Tee-Object $UpdateLog -Append | Write-Message -Level Error
            Return
        }
    }

    ((Get-Content -Path ".\Version.txt").trim() | ConvertFrom-Json) | Add-Member @{ AutoUpdated = ((Get-Date).DateTime) } -Force | ConvertTo-Json | Out-File ".\Version.txt"

    "Successfully updated $($UpdateVersion.Product) to version $($UpdateVersion.Version)." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose

    # Display changelog
    Notepad .\ChangeLog.txt
    # (New-Object -ComObject WScript.Shell).AppActivate((get-process notepad).MainWindowTitle)

    If ($UpdateVersion.RequireRestart -or ($NemosMinerFileHash -ne (Get-FileHash ".\NemosMiner.ps1").Hash)) { 
        # Kill old instance
        "Killing old instance..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        Start-Sleep -Seconds 2
        If (Get-Process -Id $NewKid.ProcessId) { Stop-Process -Id $PID }
    }
}

Function Update-ConfigFile {

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    # Changed config items
    $Config.GetEnumerator().Name | ForEach-Object { 
        Switch ($_) { 
            "ActiveMinergain" { $Config.RunningMinerGainPct = $Config.$_; $Config.Remove($_) }
            "APIKEY" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesLog = $Config.$_; $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "MPHAPIKey" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "MPHUserName"  { $Config.MiningPoolHubUserName = $Config.$_; $Config.Remove($_) }
            "NoDualAlgoMining" { $Config.DisableDualAlgoMining = $Config.$_; $Config.Remove($_) }
            "NoSingleAlgoMining" { $Config.DisableSingleAlgoMining = $Config.$_; $Config.Remove($_) }
            "PasswordCurrency" { $Config.PayoutCurrency = $Config.$_; $Config.Remove($_) }
            "PricePenaltyFactor" { $Config.EarningsAdjustmentFactor = $Config.$_; $Config.Remove($_) }
            "ReadPowerUsage" { $Config.CalculatePowerCost = $Config.$_; $Config.Remove($_) }
            "UserName" { 
                If (-not $Config.MiningPoolHubUserName) { $Config.MiningPoolHubUserName = $Config.$_ }
                If (-not $Config.ProHashingUserName) { $Config.ProHashingUserName = $Config.$_ }
                $Config.Remove($_)
            }
            "Wallet" { 
                If (-not $Config.Wallets) { 
                    $Config | Add-Member @{ Wallets = $Variables.AllCommandLineParameters.Wallets }
                }
                $Config.Wallets.BTC = $Config.$_
                $Config.Remove($_)
            }
            "WaitForMinerData" { $Config.WarmupTimes = @(0, $Config.$_); $Config.Remove($_) }
            "WarmupTime" { $Config.WarmupTimes = @(0, $Config.$_); $Config.Remove($_) }
            Default { 
                If ($_ -notin @(@($Variables.AllCommandLineParameters.Keys) + @("PoolsConfig"))) { $Config.Remove($_) } # Remove unsupported config item
            }
        }
    }

    # Add new config items
    If ($New_Config_Items = $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys }) { 
        $New_Config_Items | Sort-Object Name | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Config.$_ = $Value
        }
        Remove-Variable Value -ErrorAction Ignore
    }

    # Change currency names, remove mBTC
    If ($Config.Currency -is [Array]) { 
        $Config.Currency = $Config.Currency | Select-Object -Index 0
        $Config.ExtraCurrencies = @($Config.Currency | Select-Object -Skip 1 | Where-Object { $_ -ne "mBTC" } | Select-Object)
    }

    # Move [PayoutCurrency] wallet to wallets
    If ($PoolsConfig = Get-Content .\Config\PoolsConfig.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore) { 
        $PoolsConfig  | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
            If (-not $PoolsConfig.$_.Wallets -and $PoolsConfig.$_.Wallet) { 
                $PoolsConfig.$_ | Add-Member Wallets @{ "$($PoolsConfig.$_.PayoutCurrency)" = $PoolsConfig.$_.Wallet } -ErrorAction Ignore
                $PoolsConfig.$_.PSObject.Members.Remove("Wallet")
            }
        }
        $PoolsConfig | ConvertTo-Json | Set-Content .\Config\PoolsConfig.json -Force
    }

    # Rename MPH to MiningPoolHub
    If ($Config.PoolName -contains @("MPH")) { 
        $Config.PoolName = @($Config.PoolName | Where-Object { $_ -ne "MPH" }), "MiningPoolHub"
    }
    If ($Config.PoolName -contains @("MPHCoins")) { 
        $Config.PoolName = $Config.PoolName | Where-Object { $_ -ne "MPHCoins" }, "MiningPoolHubCoins"
    }

    # Available regions have changed
    If (-not (Get-Region $Config.Region -List)) { 
        # Write message about new mining regions
        Switch ($Config.Region) { 
            "India"    { $Config.Region = "Japan" }
            "HongKong" { $Config.Region = "Japan" }
            "Japan"    { $Config.Region = "Japan" }
            "Europe"   { $Config.Region = "Europe West" }
            "Russia"   { $Config.Region = "Europe East" }
            "US"       { $Config.Region = "USA West" }
            "Brazil"   { $Config.Region = "USA West" }
            Default    { $Config.Region = "Europe West" }
        }
        Write-Message -Level Warn "Available mining locations have changed. Please verify your configuration." -Console
    }

    $Config | Add-Member ConfigFileVersion ($Variables.CurrentVersion.ToString()) -Force
    Write-Config -ConfigFile $ConfigFile
    "Updated configuration file '$($ConfigFile)' to version $($Variables.CurrentVersion.ToString())." | Write-Message -Level Verbose 
    Remove-Variable New_Config_Items -ErrorAction Ignore
}

Function Test-Prime { 
    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    For ([Int64]$i = 2; $i -lt [Int64][Math]::Pow($Number, 0.5); $i++) { If ($Number % $i -eq 0) { Return $false } }

    Return $true
}

Function Get-DAGsize { 
    Param(
        [Parameter(Mandatory = $false)]
        [Double]$Block = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400,
        [Parameter(Mandatory = $false)]
        [String]$Coin
    )

    Switch ($Coin) {
        "ETC" { If ($Block -ge 11700000 ) { $Epoch_Length = 60000 } Else { $Epoch_Length = 30000 } }
        "RVN" { $Epoch_Length = 7500 }
        default { $Epoch_Length = 30000 }
    }

    $DATASET_BYTES_INIT = [Math]::Pow(2, 30)
    $DATASET_BYTES_GROWTH = [Math]::Pow(2, 23)
    $MIX_BYTES = 128

    $Size = $DATASET_BYTES_INIT + $DATASET_BYTES_GROWTH * [Math]::Floor($Block / $EPOCH_LENGTH)
    $Size -= $MIX_BYTES
    While (-not (Test-Prime ($Size / $MIX_BYTES))) { $Size -= 2 * $MIX_BYTES }

    Return $Size
}