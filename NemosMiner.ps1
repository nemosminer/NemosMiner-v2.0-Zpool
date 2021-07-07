using module .\Includes\Include.psm1

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
File:           NemosMiner.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [String[]]$Algorithm = @(), # i.e. @("Ethash", "Equihash", "Cryptonight") etc.
    [Parameter(Mandatory = $false)]
    [Double]$AllowedBadShareRatio = 0.1, # Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will marked as failed. Allowed values: 0.00 - 1.00. Default of 0 disables this check
    [Parameter(Mandatory = $false)]
    [Switch]$AutoStart = $false, # If true NemosMiner will start mining automatically
    [Parameter(Mandatory = $false)] 
    [String]$APILogfile = "", # API will log all requests to this file, to disable leave empty
    [Parameter(Mandatory = $false)]
    [Int]$APIPort = 3999, # TCP Port for API & Web GUI
    [Parameter(Mandatory = $false)]
    [Boolean]$AutoUpdate = $false, # Autoupdate
    [Parameter(Mandatory = $false)]
    [Switch]$BalancesTrackerLog = $false, # If true NemosMiner will store all balance tracker data in .\Logs\EarningTrackerLog.csv
    [Parameter(Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 5, # minutes, Interval duration to trigger background task to collect pool balances & earnings dataset to 0 to disable
    [Parameter(Mandatory = $false)]
    [Switch]$CalculatePowerCost = $true, # If true power usage will be read from miners and calculate power cost, required for true profit calculation
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", # Config file name
    [Parameter(Mandatory = $false)]
    [Int]$CPUMinerProcessPriority = "-2", # Process priority for CPU miners
    [Parameter(Mandatory = $false)]
    [String]$Currency = (Get-Culture).NumberFormat.CurrencySymbol, # Main 'real-money' currency, i.e. GBP, USD, AUD, NZD ect. Do not use crypto currencies
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 0, # seconds between stop and start of miners, use only when getting blue screens on miner switches
    [Parameter(Mandatory = $false)]
    [Switch]$DisableDualAlgoMining = $false, # If true NemosMiner will not use any dual algo miners
    [Parameter(Mandatory = $false)]
    [Switch]$DisableMinerFee = $false, # Set to true to disable miner fees (Note: not all miners support turning off their built in fees, others will reduce the hashrate)
    [Parameter(Mandatory = $false)]
    [Switch]$DisableMinersWithFee = $false, # Set to true to disable all miners which contain fees
    [Parameter(Mandatory = $false)]
    [Switch]$DisableSingleAlgoMining = $false, # If true NemosMiner will not use any single algo miners
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 13, # Minutes per Day
    [Parameter(Mandatory = $false)]
    [Double]$EarningsAdjustmentFactor = 1, # Default factor with which NemosMiner multiplies the prices reported by ALL pools. Allowed values: 0.0 - 1.0
    [Parameter(Mandatory = $false)]
    [Switch]$EstimateCorrection = $false, # If true NemosMiner will multiply the algo price by estimate factor (actual_last24h / estimate_last24h) to counter pool overestimated prices
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), # Array of disabled devices, e.g. @("CPU# 00", "GPU# 02");  by default all devices are enabled
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeMinerName = @(), # List of miners to be excluded; Either specify miner short name, e.g. "PhoenixMiner" (without '-v...') to exclude any version of the miner, or use the full miner name incl. version information
    [Parameter(Mandatory = $false)]
    [String[]]$ExtraCurrencies = @("USD", "ETC", "mBTC"), # Extra currencies used in balances summary, Enter 'real-world' or crypto currencies, mBTC (milli BTC) is also allowed
    [Parameter(Mandatory = $false)]
    [Int]$GPUMinerProcessPriority = "-1", # Process priority for GPU miners
    [Parameter(Mandatory = $false)]
    [Double]$IdlePowerUsageW = 60, # Watt, Powerusage of idle system. Part of profit calculation.
    [Parameter(Mandatory = $false)]
    [Int]$IdleSec = 120, # seconds the system must be idle before mining starts (if MineWhenIdle -eq $true)
    [Parameter(Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, # If true NM will ignore miner fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, # If true NM will ignore pool fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, # If true NM will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeOptionalMiners = $true, # If true use the miners in the 'OptionalMiners' directory
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeRegularMiners = $true, # If true use the miners in the 'Miners' directory
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeLegacyMiners = $true, # If true use the miners in the 'LegacyMiners' directory (Miners based on the original MultiPoolMiner format)
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 240, # Average cycle loop duration (seconds) 
    [Parameter(Mandatory = $false)]
    [Switch]$LogBalanceAPIResponse = $false, # If true NemosMiner will log the pool balance API data
    [Parameter(Mandatory = $false)]
    [String[]]$LogToFile = @("Info", "Warn", "Error", "Verbose", "Debug"), # Log level detail to be written to log file, see Write-Message function
    [Parameter(Mandatory = $false)]
    [String[]]$LogToScreen = @("Info", "Warn", "Error", "Verbose", "Debug"), # Log level detail to be written to screen, see Write-Message function
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [Double]$MinAccuracy = 0.5, # Use only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter(Mandatory = $false)]
    [Int]$MinDataSamples = 20, # Minimum number of hash rate samples required to store hash rate
    [Parameter(Mandatory = $false)]
    [Hashtable]$MinDataSamplesAlgoMultiplier = @{ "X25r" = 3 }, # Per algo multiply MinDataSamples by this value
    [Parameter(Mandatory = $false)]
    [Switch]$MinerInstancePerDeviceModel = $true, # If true NemosMiner will create separate miner instances per device model. This will increase profitability. 
    [Parameter(Mandatory = $false)]
    [Int]$MinerSet = 1, # 0: Benchmark best miner per algorithm and device only; 1: Benchmark optimal miners (more than one per algorithm and device); 2: Benchmark all miners per algorithm and device;
    [Parameter(Mandatory = $false)]
    [String]$MiningPoolHubAPIKey = "", # MiningPoolHub API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$MiningPoolHubUserName = "Nemo", # MiningPoolHub UserName
    [Parameter(Mandatory = $false)]
    [Switch]$MineWhenIdle = $false, # If true NemosMiner will start mining only if system is idle for $IdleSec seconds
    [Parameter(Mandatory = $false)]
    [Int]$MinWorker = 10, # Minimum workers mining the algorithm at the pool. If less miners are mining the algorithm then the pool will be disabled. This is also a per-pool setting configurable in 'PoolsConfig.json'
    [Parameter(Mandatory = $false)]
    [String]$MonitoringServer = "", # Monitoring server hostname, default "https://nemosminer.com"
    [Parameter(Mandatory = $false)]
    [String]$MonitoringUser = "", # Unique monitoring user ID 
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPIKey = "", # NiceHash API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPISecret = "", # NiceHash API Secret (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$NiceHashWalletIsInternal = $false, # Set to $true if NiceHashWallet is a NiceHash internal wallet (lower pool fees)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashWallet = "", # NiceHash wallet, if left empty $Wallet is used
    [Parameter(Mandatory = $false)]
    [String]$NiceHashOrganizationId = "", # NiceHash Organization Id (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, # If true NemosMiner will open firewall ports for all miners (requires admin rights!)
    [Parameter(Mandatory = $false)]
    [String]$PayoutCurrency = "BTC", # i.e. BTC, LTC, ZEC, ETH etc., Default PayoutCurrency for all pools that have no other currency configured, PayoutCurrency is also a per pool setting (to be configured in PoolsConfig.json)
    [Parameter(Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", # PoolsConfig file name
    [Parameter(Mandatory = $false)]
    [Uint16]$PoolBalancesUpdateInterval = 15, #NemosMiner will udate balances every n minutes to limit pool API requests. Allowed values 0 - 999 minutes. 0 will disable gathering pool balances
    [Parameter(Mandatory = $false)]
    [String[]]$PoolName = @("Blockmasters", "MiningPoolHub", "NiceHash", "ZergPoolCoins", "ZPool"), 
    [Parameter(Mandatory = $false)]
    [Int]$PoolTimeout = 20, # Time (in seconds) until NemosMiner aborts the pool request (useful if a pool's API is stuck). Note: do not set this value too small or NM will not be able to get any pool data
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerPricekWh = @{"00:00" = 0.26; "12:00" = 0.3 }, # Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerUsage = @{ }, # Static power usage per device in W, e.g. @{ "GPU#03" = 25, "GPU#04 = 55" } (in case HWiNFO cannot read power usage)
    [Parameter(Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, # Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power usage measuring)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingAPIKey = "", # ProHashing API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingMiningMode = "PPS", # Either PPS (Pay Per Share) or PPLNS (Pay per Last N Shares)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingUserName = "nemos", # ProHashing UserName, if left empty then $UserName is used
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", # i.e http://192.0.0.1:8080
    [Parameter(Mandatory = $false)]
    [String]$Region = "Europe West", # Used to determine pool nearest to you.
    [Parameter(Mandatory = $false)]
    [Switch]$ReportToServer = $false, 
    [Parameter(Mandatory = $false)]
    [Double]$RunningMinerGainPct = 12, # As lang as no other miner has earning/profit that are n % higher than the current miner it will not switch
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAccuracy = $true, # Show pool data accuracy column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, # Always show all miners in miner overview (if $false, only the best miners will be shown except when in benchmark / powerusage measurement)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarning = $true, # Show miner earning column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarningBias = $true, # Show miner earning bias column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowMinerFee = $true, # Show miner fee column in miner overview (if fees are available, t.b.d. in miner files, Property '[Double]Fee')
    [Parameter(Mandatory = $false)]
    [String]$ShowMinerWindows = "minimized", # "minimized": miner window is minimized (default), but accessible; "normal": miner windows are shown normally; "hidden": miners will run as a hidden background task and are not accessible (not recommended)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowMinerWindowsNormalWhenBenchmarking = $true, # If true Miner window is shown normal when benchmarking (recommended to better see miner messages)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolBalances = $false, # Display pool balances & earnings information in text window, requires BalancesTrackerPollInterval > 0
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolFee = $true, # Show pool fee column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerCost = $true, # Show Power cost column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfit = $true, # Show miner profit column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfitBias = $true, # Show miner profit bias column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerUsage = $true, # Show Power usage column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowWorkerStatus = $true, 
    [Parameter(Mandatory = $false)]
    [String]$SnakeTailExe = ".\Utils\SnakeTail.exe", # Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter(Mandatory = $false)]
    [String]$SnakeTailConfig = ".\Utils\NemosMiner_LogReader.xml", # Path to SnakeTail session config file
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, # If true NemosMiner will prefer pools which support SSL connections
    [Parameter(Mandatory = $false)]
    [Switch]$StartGUIMinimized = $true, 
    [Parameter(Mandatory = $false)]
    [Switch]$StartPaused = $false, # If true NemosMiner will start background jobs (Earnings Tracker etc.), but will not mine
    [Parameter(Mandatory = $false)]
    [Int]$SyncWindow = 3, # Cycles. Pool prices must all be all have been collected within the last 'SyncWindow' cycles, otherwise the biased value of older poll price data will get reduced more the older the data is
    [Parameter(Mandatory = $false)]
    [Switch]$Transcript = $false, # Enable to write PowerShell transcript files (for debugging)
    [Parameter(Mandatory = $false)]
    [Switch]$UsemBTC = $true, # If true NemosMiner will display BTC values in milli BTC
    [Parameter(Mandatory = $false)]
    [Switch]$UseMinerTweaks = $false, # If true NemosMiner will apply miner specific tweaks, e.g mild overclock. This may improve profitability at the expense of system stability (Admin rights are required)
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "Light", # Light or Full. Defines level of info displayed
    [Parameter(Mandatory = $false)]
    [Double]$UnrealPoolPriceFactor = 2, # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than average price of all other pools with same algo & currency
    [Parameter(Mandatory = $false)]
    [Double]$UnrealMinerEarningFactor = 5, # Ignore miner if resulting profit is more than $Config.UnrealPoolPriceFactor higher than average price of all other miners with same algo
    [Parameter(Mandatory = $false)]
    [Switch]$UseAnycast = $false, # If true pools (currently ZergPool only) will use anycast for best network performance and ping times
    [Parameter(Mandatory = $false)]
    [Int[]]$WarmupTimes = @(0, 15), # First value: time (in seconds) until first hash rate sample is valid (default 0, accept first sample), second value: time (in seconds) the miner is allowed to warm up, e.g. to compile the binaries or to get the API ready and providing first data samples before first data samples before it gets stopped and marked as failed (default 15)
    [Parameter(Mandatory = $false)]
    [Hashtable]$Wallets = @{ "BTC" = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"; "ETC" = "0x7CF99ec9029A98AFd385f106A93977D8105Fec0f"; "ETH" = "0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }, 
    [Parameter(Mandatory = $false)]
    [Switch]$Watchdog = $true, # if true NemosMiner will automatically put pools and/or miners temporarily on hold it they fail a few times in row
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogCount = 3, # Number of watchdog timers
    [Parameter(Mandatory = $false)]
    [Switch]$WebGUI = $true, # If true launch Web GUI (recommended)
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = "ID=testing"
)

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

@"
NemosMiner
Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus & UselessGuru
This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE
"@
Write-Host "`nCopyright and license notices must be preserved.`n" -ForegroundColor Yellow

# Load Branding
$Global:Branding = [PSCustomObject]@{ 
    LogoPath     = "https://raw.githubusercontent.com/Minerx117/UpDateData/master/NM.png"
    BrandName    = "NemosMiner"
    BrandWebSite = "https://nemosminer.com"
    ProductLabel = "NemosMiner"
    Version      = [System.Version]"3.9.9.56"
}

If ($PSVersiontable.PSVersion -lt [System.Version]"7.0.0") { 
    Write-Host "`nUnsupported PowerShell version $($PSVersiontable.PSVersion.ToString()) detected.`n$($Branding.BrandName) requires at least PowerShell version 7.0.0 which can be downloaded from https://github.com/PowerShell/powershell/releases.`n`n" -ForegroundColor Red
    Start-Sleep -Seconds 30
    Exit
}

Try { 
    Add-Type -Path ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    Remove-Item ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -Force -ErrorAction Ignore
    Add-Type -Path ".\Includes\OpenCL\*.cs" -OutputAssembly ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
}

Try { 
    Add-Type -Path ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    Remove-Item ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -Force -ErrorAction Ignore
    Add-Type -Path ".\Includes\CPUID.cs" -OutputAssembly ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
}

# Create directories
If (-not (Test-Path -Path ".\Config" -PathType Container)) { New-Item -Path . -Name "Config" -ItemType Directory | Out-Null }
If (-not (Test-Path -Path ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }

# Initialize global variables
New-Variable Config ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop
New-Variable Stats ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop
New-Variable Variables ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop

$Variables.Miners = [Miner[]]
$Variables.Pools = [Miner]::Pools

# Expand paths
$Variables.MainPath = (Split-Path $MyInvocation.MyCommand.Path)
$Variables.LogFile = "$($Variables.MainPath)\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").log"
$Variables.ConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigFile))"
$Variables.PoolsConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PoolsConfigFile))"
$Variables.BalancesTrackerConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.BalancesTrackerConfigFile))"

$Variables.CurrentProduct = $Branding.ProductLabel
$Variables.CurrentVersion = $Branding.Version

# Get command line parameters, required in Read-Config
$AllCommandLineParameters = [Ordered]@{ }
$MyInvocation.MyCommand.Parameters.Keys | Where-Object { $_ -notin @("ConfigFile", "PoolsConfigFile", "BalancesTrackerConfigFile", "Verbose", "Debug", "ErrorAction", "WarningAction", "InformationAction", "ErrorVariable", "WarningVariable", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable") } | Sort-Object | ForEach-Object { 
    $AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue
    If ($AllCommandLineParameters.$_ -is [Switch]) { $AllCommandLineParameters.$_ = [Boolean]$AllCommandLineParameters.$_ }
}
$Variables.AllCommandLineParameters = $AllCommandLineParameters

# Load algorithm list
$Variables.Algorithms = Get-Content -Path ".\Includes\Algorithms.txt" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
If (-not $Variables.Algorithms) { 
    Write-Message -Level Error "Terminating Error - Cannot continue!`nFile '$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\Includes\Algorithms.txt'))' is not a valid JSON file. Please restore it from your original download." -Console
    Start-Sleep -Seconds 10
    Exit
}
# Load regions list
$Variables.Regions = Get-Content -Path ".\Includes\Regions.txt" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
If (-not $Variables.Regions) { 
    Write-Message -Level Error "Terminating Error - Cannot continue!`nFile '$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\Includes\Regions.txt'))' is not a valid JSON file. Please restore it from your original download." -Console
    Start-Sleep -Seconds 10
    Exit
}
# Verify pool data
Try { [Void](Get-Content -Path ".\Includes\PoolData.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore) }
Catch { 
    Write-Message -Level Error "Terminating Error - Cannot continue!`nFile '$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\Includes\PoolData.json'))' is not a valid JSON file. Please restore it from your original download." -Console
    Start-Sleep -Seconds 10
    Exit
}

# Read configuration
Read-Config -ConfigFile $Variables.ConfigFile

$AllCommandLineParameters | ForEach-Object { 
    Remove-Variable $_ -ErrorAction SilentlyContinue
}

# Start transcript log
If ($Config.Transcript -eq $true) { Start-Transcript ".\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

Write-Message "Starting $($Branding.ProductLabel)® v$($Variables.CurrentVersion) © 2017-$((Get-Date).Year) Nemo, MrPlus and UselessGuru"
If (-not $Variables.FreshConfig) { Write-Message "Using configuration file '$($Variables.ConfigFile)'." }

# Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
If ((Test-Path $Config.SnakeTailExe -PathType Leaf -ErrorAction Ignore) -and (Test-Path $Config.SnakeTailConfig -PathType Leaf -ErrorAction Ignore)) { 
    $Variables.SnakeTailConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailConfig)
    $Variables.SnakeTailExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailExe)
    If (-not (Get-CimInstance CIM_Process | Where-Object ExecutablePath -EQ $Variables.SnakeTailExe)) { 
        & "$($Variables.SnakeTailExe)" $Variables.SnakeTailConfig
    }
}

#Prerequisites check
Write-Message -Level Verbose "Verifying pre-requisites..." -Console
$Prerequisites = @(
    "$env:SystemRoot\System32\MSVCR120.dll",
    "$env:SystemRoot\System32\VCRUNTIME140.dll",
    "$env:SystemRoot\System32\VCRUNTIME140_1.dll"
)

If ($PrerequisitesMissing = @($Prerequisites | Where-Object { -not (Test-Path $_ -PathType Leaf) })) {
    $PrerequisitesMissing | ForEach-Object { Write-Message -Level Warn "$_ is missing." -Console }
    Write-Message -Level Error "Please install the required runtime modules. Download and extract" -Console
    Write-Message -Level Error "https://github.com/Minerx117/Visual-C-Runtimes-All-in-One-Sep-2019/releases/download/sep2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip" -Console
    Write-Message -Level Error "and run 'install_all.bat'."
    Start-Sleep -Seconds 10
    Exit
}
Else { Write-Message -Level Verbose "Pre-requisites check OK." -Console }
Remove-Variable PrerequisitesMissing, Prerequisites

# Check if new version is available
Get-NMVersion

# Update config file to include all new config items
If ($Variables.AllCommandLineParameters -and (-not $Config.ConfigFileVersion -or [System.Version]::Parse($Config.ConfigFileVersion) -lt $Variables.CurrentVersion )) { 
    Update-ConfigFile -ConfigFile $Variables.ConfigFile
}

Write-Message -Level Verbose "Loading device information..."
$Variables.SupportedDeviceVendors = @("AMD", "INTEL", "NVIDIA")
$Variables.Devices = [Device[]](Get-Device -Refresh)
$Variables.Devices | Where-Object { $_.Vendor -notin $Variables.SupportedDeviceVendors } | ForEach-Object { $_.State = [DeviceState]::Unsupported; $_.Status = "Disabled (Unsupported Vendor: '$($_.Vendor)')" }
$Variables.Devices | Where-Object Name -In $Config.ExcludeDeviceName | ForEach-Object { $_.State = [DeviceState]::Disabled; $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }

# MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
If ($Variables.FreshConfig -eq $true) { $Config.MinerInstancePerDeviceModel = ($Variables.Devices | Group-Object Vendor  | ForEach-Object { ($_.Group.Model | Sort-Object -Unique).Count } | Measure-Object -Maximum).Maximum -gt 1 }

Write-Host "Setting variables..." -ForegroundColor Yellow
$Variables.BrainJobs = @{ }
$Variables.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$Variables.Miners = [Miner[]]@()
$Variables.Pools = [Pool[]]@()
$Variables.ScriptStartTime = (Get-Date).ToUniversalTime()
$Variables.AvailableCommandLineParameters = @($AllCommandLineParameters.Keys | Sort-Object)
$Variables.MyIP = (Get-NetIPConfiguration | Where-Object IPv4DefaultGateway).IPv4Address.IPAddress
$Variables.DriverVersion = @{ }
$Variables.DriverVersion | Add-Member AMD ((($Variables.Devices | Where-Object { $_.Type -EQ "GPU" -and $_.Vendor -eq "AMD" }).OpenCL.DriverVersion | Select-Object -Index 0) -split ' ' | Select-Object -Index 0)
$Variables.DriverVersion | Add-Member NVIDIA ((($Variables.Devices | Where-Object { $_.Type -EQ "GPU" -and $_.Vendor -eq "NVIDIA" }).OpenCL.DriverVersion | Select-Object -Index 0) -split ' ' | Select-Object -Index 0)
$Variables.MiningStatus = $Variables.NewMiningStatus = "Stopped"
$Variables.Strikes = 3
$Variables.WatchdogTimers = @()
$Variables.StatStarts = @()

If (Test-Path -Path ".\Logs\EarningsChartData.json" -PathType Leaf) { $Variables.EarningsChartData = Get-Content ".\Logs\EarningsChartData.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore }

# Rename existing switching log
If (Test-Path -Path ".\Logs\SwitchingLog.csv" -PathType Leaf) { Get-ChildItem -Path ".\Logs\SwitchingLog.csv" -File | Rename-Item -NewName { "SwitchingLog$($_.LastWriteTime.toString('_yyyy-MM-dd_HH-mm-ss')).csv" } }
# Keep only the last 3 logs
Get-ChildItem ".\Logs\SwitchingLog_*.csv" | Sort-Object | Select-Object -SkipLast 3 | Remove-Item -Force -Recurse


If ($env:CUDA_DEVICE_ORDER -ne 'PCI_BUS_ID') { $env:CUDA_DEVICE_ORDER = 'PCI_BUS_ID' } # Align CUDA id with nvidia-smi order
If ($env:GPU_FORCE_64BIT_PTR -ne 1) { $env:GPU_FORCE_64BIT_PTR = 1 }                   # For AMD
If ($env:GPU_MAX_HEAP_SIZE -ne 100) { $env:GPU_MAX_HEAP_SIZE = 100 }                   # For AMD
If ($env:GPU_USE_SYNC_OBJECTS -ne 1) { $env:GPU_USE_SYNC_OBJECTS = 1 }                 # For AMD
If ($env:GPU_MAX_ALLOC_PERCENT -ne 100) { $env:GPU_MAX_ALLOC_PERCENT = 100 }           # For AMD
If ($env:GPU_SINGLE_ALLOC_PERCENT -ne 100) { $env:GPU_SINGLE_ALLOC_PERCENT = 100 }     # For AMD
If ($env:GPU_MAX_WORKGROUP_SIZE -ne 256) { $env:GPU_MAX_WORKGROUP_SIZE = 256 }         # For AMD

If ($Config.AutoStart) { 
    If ($Config.StartPaused) { 
        $Variables.NewMiningStatus = "Paused"
    }
    Else { 
        $Variables.NewMiningStatus = "Running"
    }
    # Trigger start mining in TimerUITick
    $Variables.RestartCycle = $true
}

Write-Host "Importing modules..." -ForegroundColor Yellow
Import-Module NetSecurity -ErrorAction SilentlyContinue
Import-Module Defender -ErrorAction SilentlyContinue
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1" -ErrorAction SilentlyContinue
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction SilentlyContinue

# Unblock files
If (Get-Command "Unblock-File" -ErrorAction SilentlyContinue) { Get-ChildItem -Path . -Recurse | Unblock-File }
If ((Get-Command "Get-MpPreference" -ErrorAction Ignore) -and (Get-MpComputerStatus -ErrorAction Ignore) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
    Start-Process (@{ desktop = "PowerShell"; core = "pwsh" }.$PSEdition) "-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1'
    Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
}

If ($Config.WebGUI -eq $true) { 
    Write-Message -Level Verbose "Initializing API & Web GUI on 'http://localhost:$($Config.APIPort)'..."
    Initialize-API
}

Function Global:TimerUITick { 
    $TimerUI.Enabled = $false

    $Variables.LogFile = "$($Variables.MainPath)\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").log"

    # If something (pause button, idle timer) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Variables.RestartCycle) { 

        If ($Variables.NewMiningStatus -eq "Stopped") { 
            $ButtonPause.Enabled = $false
            $ButtonStart.Enabled = $false
            $ButtonStop.Enabled = $false

            Stop-Mining
            Stop-IdleMining
            Stop-BrainJob
            Stop-BalancesTracker

            $Variables.Summary = ""
            $LabelMiningStatus.Text = "Stopped | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Red
            Clear-Host
            Write-Message -Level Info "$($Branding.ProductLabel) is idle." -Console

            $ButtonPause.Enabled = $true
            $ButtonStart.Enabled = $true
        }
        ElseIf ($Variables.NewMiningStatus -eq "Paused") { 
            If ($Variables.MiningStatus -ne "Paused") { 
                $ButtonPause.Enabled = $false
                $ButtonStart.Enabled = $false
                $ButtonStop.Enabled = $false

                If ($Variables.MiningStatus -eq "Running") { 
                    Stop-Mining
                    Stop-IdleMining
                }
                Else { 
                    Initialize-Application
                    Start-BrainJob
                    Start-BalancesTracker
                }
                Clear-Host
                Write-Message -Level Info "Mining is paused. BrainPlus and Earning tracker running." -Console

                $ButtonStop.Enabled = $true
                $ButtonStart.Enabled = $true

                $LabelMiningStatus.Text = "Paused | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
                $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Blue
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@()
                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@()
                $WorkersDGV.DataSource = [System.Collections.ArrayList]@()
                $TimerUI.Stop
            }
        }
        ElseIf ($Variables.NewMiningStatus -eq "Running") {

            $Variables.UIStyle = $Config.UIStyle
            $Variables.ShowAllMiners = $Config.ShowAllMiners
            $Variables.ShowPoolBalances = $Config.ShowPoolBalances

            $ButtonStop.Enabled = $true
            $ButtonStart.Enabled = $false
            $ButtonPause.Enabled = $true
            If ($Variables.MiningStatus -ne "Running") { 
                Clear-Host
                Write-Host "Mining processes started."
                Initialize-Application
                Start-BrainJob
                Start-BalancesTracker
            }
            If ($Config.MineWhenIdle) { 
                Stop-Mining
                If (-not $Variables.IdleRunspace) { Start-IdleMining }
            }
            Else { 

                Stop-IdleMining
                Start-Mining

                $ButtonStop.Enabled = $true
                $ButtonPause.Enabled = $true

                $LabelMiningStatus.Text = "Running | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
                $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
            }
        }
        $Variables.RestartCycle = $false
        $Variables.MiningStatus = $Variables.NewMiningStatus
    }

    If ($Variables.RefreshNeeded -and $Variables.MiningStatus -eq "Running") { 
        $host.UI.RawUI.WindowTitle = $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion) Runtime: {0:dd} days {0:hh} hrs {0:mm} mins Path: $($Variables.Mainpath)" -f ([TimeSpan]((Get-Date).ToUniversalTime() - $Variables.ScriptStartTime))

        If ($Variables.EndLoop) { 

            # Refresh selected tab
            Switch ($TabControl.SelectedTab.Text) { 
                "Earnings" { Get-Chart }
                "Switching Log" { CheckBoxSwitching_Click }
            }

            If ($Variables.Balances) { 
                $DisplayEarnings = [System.Collections.ArrayList]@(
                    $Variables.Balances.Values | Select-Object @(
                        @{ Name = "Pool"; Expression = { "$($_.Pool -replace 'Internal$', ' (Internal)' -replace 'External', ' (External)') [$($_.Currency)]" } }, 
                        @{ Name = "Balance ($($Config.Currency))"; Expression = { "{0:N8}" -f ($_.Balance * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "Avg. $($Config.Currency)/day"; Expression = { "{0:N8}" -f ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 1h"; Expression = { "{0:N6}" -f ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 6h"; Expression = { "{0:N6}" -f ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 24h"; Expression = { "{0:N6}" -f ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "Est. Pay Date"; Expression = { If ($_.EstimatedPayDate -is [DateTime]) { $_.EstimatedPayDate.ToShortDateString() } Else { $_.EstimatedPayDate } } }, 
                        @{ Name = "PayoutThreshold"; Expression = { "$($_.PayoutThreshold) $($_.PayoutThresholdCurrency) ($('{0:P1}' -f $($_.Balance / ($_.PayoutThreshold * $Variables.Rates.($_.PayoutThresholdCurrency).($_.Currency)))))" } }
                    )
                ) | Sort-Object Pool
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEarnings)
                $EarningsDGV.ClearSelection()
            }

            If ($Variables.Miners) { 
                $DisplayEstimations = [System.Collections.ArrayList]@(
                    $Variables.Miners | Where-Object Available -EQ $true | Select-Object @(
                        @{ Name = "Miner"; Expression = { $_.Name } }, 
                        @{ Name = "Device(s)"; Expression = { $_.DeviceName -join '; ' } }, 
                        @{ Name = "Algorithm(s)"; Expression = { $_.Algorithm -join ' & ' } }, 
                        @{ Name = "PowerUsage"; Expression = { If ($_.MeasurePowerUsage) { "Measuring" } Else { "$($_.PowerUsage.ToString("N3")) W" } } }, 
                        @{ Name = "Hashrate(s)"; Expression = { ($_.Workers.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" -replace '\s+', ' ' } Else { "Benchmarking" } }) -join ' & ' } }, 
                        @{ Name = "$($Config.Currency)/day"; Expression = { ($_.Workers | ForEach-Object { If (-not [Double]::IsNaN($_.Earning)) { ($_.Earning * $Variables.Rates.BTC.($Config.Currency)).ToString("N3") } Else { "Unknown" } }) -join ' + ' } }, 
                        @{ Name = "Pool(s)"; Expression = { ($_.Workers.Pool | ForEach-Object { (@(@($_.Name | Select-Object) + @($_.Coin | Select-Object))) -join '-' }) -join ' & ' }
                        }
                    ) | Sort-Object "m$($Config.PayoutCurrency)/day" -Descending)
                $EstimationsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEstimations)
            }
            $EstimationsDGV.ClearSelection()

            If ($Variables.Workers -and $Config.ShowWorkerStatus) { 
                $DisplayWorkers = [System.Collections.ArrayList]@(
                    $Variables.Workers | Select-Object @(
                        @{ Name = "Worker"; Expression = { $_.worker } }, 
                        @{ Name = "Status"; Expression = { $_.status } }, 
                        @{ Name = "Last seen"; Expression = { "$($_.timesincelastreport -replace '^-')" } }, 
                        @{ Name = "Version"; Expression = { $_.version } }, 
                        @{ Name = "Est. Profit $($Config.Currency)/day"; Expression = { [decimal]($_.Profit * ($Variables.Rates.BTC.($Config.Currency))) } }, 
                        @{ Name = "Miner"; Expression = { $_.data.Name -join '; ' } }, 
                        @{ Name = "Pool(s)"; Expression = { ($_.data.Pool -replace 'Internal$', ' (Internal)' -replace 'External', ' (External)' | ForEach-Object { $_ -split ',' -join ' & ' }) -join '; ' } }, 
                        @{ Name = "Algo(s)"; Expression = { ($_.data.Algorithm | ForEach-Object { $_ -split ',' -join ' & ' }) -join '; ' } }, 
                        @{ Name = "Hashrate(s)"; Expression = { If ($_.data.CurrentSpeed) { ($_.data.CurrentSpeed | ForEach-Object { ($_ -split ',' | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } ) -join ' & ' }) -join '; ' } Else { "" } } }, 
                        @{ Name = "Benchmark Hashrate(s)"; Expression = { If ($_.data.EstimatedSpeed) { ($_.data.EstimatedSpeed | ForEach-Object { ($_ -split ',' | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } ) -join ' & ' }) -join '; ' } Else { "" } }
                        }
                    ) | Sort-Object "Worker Name")
                $WorkersDGV.DataSource = [System.Collections.ArrayList]@($DisplayWorkers)

                # Set row color
                $WorkersDGV.Rows | ForEach-Object { 
                    If ($_.DataBoundItem.Status -eq "Offline") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 213, 142, 176)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Paused") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 247, 252, 168)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Running") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 127, 191, 144)
                    }
                    Else { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
                    }
                }

                $WorkersDGV.ClearSelection()
                $LabelMonitoringWorkers.Text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"
            }

            If ($Variables.Miners) { 
                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@($Variables.Miners | Where-Object { $_.Status -eq "Running" } | Select-Object  @{ Name = "Type"; Expression = { $_.Type -join " & " } }, @{ Name = "Miner"; Expression = { $_.Info } }, @{ Name = "Account(s)"; Expression = { ($_.Workers.Pool.User | Select-Object -Unique | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join ' & ' } }, @{ Name = "Hashrate(s)"; Expression = { If ($_.Speed_Live -contains $null) { ($_.Speed_Live | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join ' & ' } Else { ($_.Workers.Speed | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join ' & ' } } }, @{ Name = "Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f ((Get-Date).ToUniversalTime() - $_.BeginTime) } }, @{ Name = "Total Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.TotalMiningDuration } } | Sort-Object Type)
                $RunningMinersDGV.ClearSelection()

                If (-not ($Variables.Miners | Where-Object { $_.Status -eq "Running" })) { 
                    Write-Message "No miners running. Waiting for next cycle."
                }
            }

            $LabelEarningsDetails.Lines = @($Variables.Summary -replace '<br>|(&ensp;)+', '`n' -replace ' / ', '/' -split '`n')

            Clear-Host

            # Get and display earnings stats
            If ($Variables.Balances -and $Variables.ShowPoolBalances) { 
                $Variables.Balances.Values | ForEach-Object { 
                    If ($_.Currency -eq "BTC" -and $Config.UsemBTC) { $Currency = "mBTC"; $mBTCfactor = 1000 } Else { $Currency = $_.Currency; $mBTCfactor = 1 }
                    Write-Host "$($_.Pool -replace 'Internal$', ' (Internal Wallet)' -replace 'External$', ' (External Wallet)') [$($_.Wallet)]" -BackgroundColor Green -ForegroundColor Black
                    Write-Host "Earned last hour:       $(($_.Growth1 * $mBTCfactor).ToString('N8')) $Currency / $(($_.Growth1 * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "Earned last 24 hours:   $(($_.Growth24 * $mBTCfactor).ToString('N8')) $Currency / $(($_.Growth24 * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "Earned last 7 days:     $(($_.Growth168 * $mBTCfactor).ToString('N8')) $Currency / $(($_.Growth168 * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "≈ average / hour:       $(($_.AvgHourlyGrowth * $mBTCfactor).ToString('N8')) $Currency / $(($_.AvgHourlyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "≈ average / day:        $(($_.AvgDailyGrowth * $mBTCfactor).ToString('N8')) $Currency / $(($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "≈ average / week:       $(($_.AvgWeeklyGrowth * $mBTCfactor).ToString('N8')) $Currency / $(($_.AvgWeeklyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)"
                    Write-Host "Balance:                " -NoNewline; Write-Host "$(($_.Balance * $mBTCfactor).ToString('N8')) $Currency / $(($_.Balance * $Variables.Rates.($_.Currency).($Config.Currency)).ToString('N8')) $($Config.Currency)" -ForegroundColor Yellow
                    Write-Host "                        $(($_.Balance / $_.PayoutThreshold * $mBTCFactor).ToString('P1')) of $(($_.PayoutThreshold).ToString()) $($_.PayoutThresholdCurrency) payment threshold"
                    Write-Host "Estimated Payment Date: $(If ($_.EstimatedPayDate -is [DateTime]) { ($_.EstimatedPayDate).ToString("G")} Else { $_.EstimatedPayDate })`n"
                }
                Remove-Variable Currency -ErrorAction Ignore
            }
            If ($Variables.MinersMissingBinary) { 
                Write-Host "`n"
                Write-Host "Some miners binaries are missing, downloader is installing miner binaries..." -ForegroundColor Yellow
            }

            If ($Variables.Miners | Where-Object Available -EQ $true | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true }) { 
                If ($Config.UIStyle -ne "Full") { 
                    $Variables.UIStyle = "Full"
                    Write-Host "Benchmarking / Measuring power usage: Temporarily switched UI style to 'Full' (Information about miners run in the past, failed miners & watchdog timers will $(If ($Variables.UIStyle -eq "Light") { "not " })be shown)" -ForegroundColor Yellow
                }
            }

            # Display available miners list
            [System.Collections.ArrayList]$Miner_Table = @(
                @{ Label = "Miner"; Expression = { $_.Name } }, 
                @{ Label = "Algorithm(s)"; Expression = { $_.Workers.Pool.Algorithm } }
            )
            If ($Config.ShowMinerFee -and ($Variables.Miners.Workers.Fee )) { 
                $Miner_Table.AddRange(
                    @( <#Miner fees#>
                        @{ Label = "Fee(s)"; Expression = { $_.Workers.Fee | ForEach-Object { "{0:P2}" -f [Double]$_ } } }
                    )
                )
            }
            $Miner_Table.AddRange(
                @( <#Miner speed#>
                    @{ Label = "Hashrate(s)"; Expression = { If (-not $_.Benchmark) { $_.Workers | ForEach-Object { "$($_.Speed | ConvertTo-Hash)/s" } } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } }; Align = 'right' }
                )
            )
            If ($Config.ShowEarning) { 
                $Miner_Table.AddRange(
                    @( <#Miner Earning#>
                        @{ Label = "Earning"; Expression = { If (-not [Double]::IsNaN($_.Earning)) { ConvertTo-LocalCurrency -Value ($_.Earning) -Rate $Variables.Rates.BTC.($Config.Currency) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowEarningBias) { 
                $Miner_Table.AddRange(
                    @( <#Miner EarningsBias#>
                        @{ Label = "EarningBias"; Expression = { If (-not [Double]::IsNaN($_.Earning_Bias)) { ConvertTo-LocalCurrency -Value ($_.Earning_Bias) -Rate $Variables.Rates.BTC.($Config.Currency) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.CalculatePowerCost -and $Config.ShowPowerUsage) { 
                $Miner_Table.AddRange(
                    @( <#Power Usage#>
                        @{ Label = "PowerUsage"; Expression = { If (-not $_.MeasurePowerUsage) { "$($_.PowerUsage.ToString("N2")) W" } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } }; Align = "right" }
                    )
                )
            }
            If ($Config.CalculatePowerCost -and $Config.ShowPowerCost -and $Variables.MiningPowerCost) { 
                $Miner_Table.AddRange(
                    @( <#PowerCost#>
                        @{ Label = "PowerCost"; Expression = { If ($Variables.PowerPricekWh -eq 0) { (0).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates.BTC.($Config.Currency) -Offset 1)") } Else { If (-not [Double]::IsNaN($_.PowerUsage)) { "-$(ConvertTo-LocalCurrency -Value ($_.PowerCost) -Rate ($Variables.Rates.($Config.PayoutCurrency).($Config.Currency)) -Offset 1)" } Else { "Unknown" } } }; Align = "right" }
                    )
                )
            }
            If ($Config.CalculatePowerCost -and $Config.ShowProfit -and $Variables.MiningPowerCost) { 
                $Miner_Table.AddRange(
                    @( <#Mining Profit#>
                        @{ Label = "Profit"; Expression = { If (-not [Double]::IsNaN($_.Profit)) { ConvertTo-LocalCurrency -Value ($_.Profit) -Rate $Variables.Rates.BTC.($Config.Currency) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.CalculatePowerCost -and $Config.ShowProfitBias -and $Variables.MiningPowerCost) { 
                $Miner_Table.AddRange(
                    @( <#Mining ProfitBias#>
                        @{ Label = "ProfitBias"; Expression = { If (-not [Double]::IsNaN($_.Profit_Bias)) { ConvertTo-LocalCurrency -Value ($_.Profit_Bias) -Rate $Variables.Rates.BTC.($Config.Currency) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowAccuracy) { 
                $Miner_Table.AddRange(
                    @( <#Accuracy#>
                        @{ Label = "Accuracy"; Expression = { $_.Workers.Pool.MarginOfError | ForEach-Object { "{0:P0}" -f [Double](1 - $_) } }; Align = 'right' }
                    )
                )
            }
            $Miner_Table.AddRange(
                @( <#Pools#>
                    @{ Label = "Pool(s)"; Expression = { $_.Workers.Pool.Name | ForEach-Object { $_ } } }
                )
            )
            If ($Config.ShowPoolFee -and ($Variables.Miners.Workers.Pool.Fee )) { 
                $Miner_Table.AddRange(
                    @( <#Show pool fees#>
                        @{ Label = "Fee(s)"; Expression = { $_.Workers.Pool.Fee | ForEach-Object { "{0:P2}" -f [Double]$_ } } }
                    )
                )
            }
            If ($Variables.Miners.Workers.Pool.Currency) { 
                $Miner_Table.AddRange(
                    @( <#Currency#>
                        @{ Label = "Currency"; Expression = { $_.Workers.Pool.Currency | ForEach-Object { [String]$_ } } }
                    )
                )
            }
            If ($Variables.Miners.Workers.Pool.CoinName) { 
                $Miner_Table.AddRange(
                    @( <#CoinName#>
                        @{ Label = "CoinName(s)"; Expression = { $_.Workers.Pool.CoinName | ForEach-Object { [String]$_ } } }
                    )
                )
            }
            If ($Variables.CalculatePowerCost) { $SortBy = "Profit" } Else { $SortBy = "Earning" }
            $Variables.Miners | Where-Object Available -EQ $true | Group-Object -Property { $_.DeviceName } | Sort-Object Name | ForEach-Object { 
                $MinersDeviceGroup = @($_.Group)
                $MinersDeviceGroupNeedingBenchmark = @($MinersDeviceGroup | Where-Object Benchmark -EQ $true)
                $MinersDeviceGroupNeedingPowerUsageMeasurement = @($MinersDeviceGroup | Where-Object Enabled -EQ $True | Where-Object MeasurePowerUsage -EQ $true)
                $MinersDeviceGroup = @($MinersDeviceGroup | Where-Object { $Variables.ShowAllMiners -or $_.Fastest -eq $true -or $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or $MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 0 } )
                $MinersDeviceGroup | Where-Object { 
                    $Variables.ShowAllMiners -or <#List all miners#>
                    $_.$SortBy -ge ($MinersDeviceGroup.$SortBy | Sort-Object -Descending | Select-Object -Index (($MinersDeviceGroup.Count, 5 | Measure-Object -Minimum).Minimum - 1)) -or <#Always list at least the top 5 miners per device group#>
                    $_.$SortBy -ge (($MinersDeviceGroup.$SortBy | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% miners per device group#>
                    $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or <#List all miners when benchmarking#>
                    $MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 0 <#List all miners when measuring power usage#>
                } | Sort-Object -Property DeviceName, @{ Expression = { $_.Benchmark -eq $true }; Descending = $true }, @{ Expression = { $_.MeasurePowerUsage -eq $true }; Descending = $true }, @{ Expression = { $_."$($SortBy)_Bias" }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false }, @{ Expression = { $_.Algorithm[0] }; Descending = $false }, @{ Expression = { $_.Algorithm[1] }; Descending = $false } | 
                Format-Table $Miner_Table -GroupBy @{ Name = "Device$(If (@($_).Count -ne 1) { "s" })"; Expression = { "$($_.DeviceName -join ', ') [$(($Variables.Devices | Where-Object Name -In $_.DeviceName).Model -join ', ')]" } } | Out-Host

                # Display benchmarking progress
                If ($MinersDeviceGroupNeedingBenchmark) { 
                    "Benchmarking for device$(If (($MinersDeviceGroup.DeviceName | Select-Object -Unique).Count -gt 1) { " group" } ) ($(($MinersDeviceGroup.DeviceName | Sort-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1){ 's' }) left to complete benchmark." | Out-Host
                }
                # Display power usage measurement progress
                If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                    "Power usage measurement for device$(If (($MinersDeviceGroup.DeviceName | Select-Object -Unique).Count -gt 1) { " group" } ) ($(($MinersDeviceGroup.DeviceName | Sort-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring." | Out-Host
                }
            }

            If ($ProcessesRunning = @($Variables.Miners | Where-Object { $_.Status -eq "Running" })) { 
                Write-Host "Running miner$(If ($ProcessesRunning.Count -eq 1) { ":" } Else { "s: $($ProcessesRunning.Count)" })"
                $ProcessesRunning | Sort-Object { If ($null -eq $_.Process) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                    @{ Label = "Hashrate(s)"; Expression = { If ($_.Speed_Live) { (($_.Speed_Live | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '\s+', ' ' } Else { "n/a" } }; Align = 'right' }, 
                    @{ Label = "PowerUsage"; Expression = { If ($_.PowerUsage_Live) { "$($_.PowerUsage_Live.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                    @{ Label = "Active (this run)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ((Get-Date).ToUniversalTime() - $_.BeginTime) } }, 
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ($_.TotalMiningDuration) } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }

            If ($Variables.UIStyle -eq "Full") { 
                If ($ProcessesIdle = @($Variables.Miners | Where-Object { $_.Activated -and $_.Status -eq "Idle" -and $_.GetActiveLast().ToLocalTime().AddHours(24) -gt (Get-Date) })) { 
                    Write-Host "Previously executed miner$(If ($ProcessesIdle.Count -eq 1) { ":" } Else { "s: $($ProcessesIdle.Count)" })"
                    $ProcessesIdle | Sort-Object { $_.Process.StartTime } -Descending | Select-Object -First ($MinersDeviceGroup.Count * 3) | Format-Table -Wrap (
                        @{ Label = "Hashrate(s)"; Expression = { (($_.Workers.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" } Else { "n/a" } }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { If (-not [Double]::IsNaN($_.PowerUsage)) { "$($_.PowerUsage.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                        @{ Label = "Time since last run"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $((Get-Date) - $_.GetActiveLast().ToLocalTime()) } }, 
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalMiningDuration } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }

                If ($ProcessesFailed = @($Variables.Miners | Where-Object { $_.Activated -and $_.Status -eq "Failed" -and $_.GetActiveLast().ToLocalTime().AddHours(24) -gt (Get-Date)})) { 
                    Write-Host -ForegroundColor Red "Failed miner$(If ($ProcessesFailed.Count -eq 1) { ":" } Else { "s: $($ProcessesFailed.Count)" })"
                    $ProcessesFailed | Sort-Object { If ($null -eq $_.Process) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                        @{ Label = "Hashrate(s)"; Expression = { (($_.Workers.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" } Else { "n/a" } }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { If (-not [Double]::IsNaN($_.PowerUsage)) { "$($_.PowerUsage.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                        @{ Label = "Time since last fail"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $((Get-Date) - $_.GetActiveLast().ToLocalTime()) } }, 
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalMiningDuration } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }
            }

            Remove-Variable SortBy
            Remove-Variable MinersDeviceGroup -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingBenchmark -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingPowerUsageMeasurement -ErrorAction SilentlyContinue
            Remove-Variable Miner_Table -ErrorAction SilentlyContinue

            If ($Config.Watchdog -eq $true -and $Variables.UIStyle -eq "Full") { 
                # Display watchdog timers
                $Variables.WatchdogTimers | Where-Object Kicked -GT $Variables.Timer.AddSeconds( -$Variables.WatchdogReset) | Format-Table -Wrap (
                    @{Label = "Miner Watchdog Timers"; Expression = { $_.MinerName } }, 
                    @{Label = "Pool"; Expression = { $_.PoolName } }, 
                    @{Label = "Algorithm"; Expression = { $_.Algorithm } }, 
                    @{Label = "Device(s)"; Expression = { $_.DeviceName } }, 
                    @{Label = "Last Updated"; Expression = { "{0:mm} min {0:ss} sec ago" -f ((Get-Date).ToUniversalTime() - $_.Kicked) }; Align = 'right' }
                ) | Out-Host
            }

            $Variables.Summary -split '<br>' | ForEach-Object { Write-Host ($_ -replace '&ensp;', ' ' -replace '  +', '; ' -replace '; $') }

            If (-not $Variables.Paused) { 
                If ($Variables.Miners | Where-Object Available -EQ $true | Where-Object { $_.Benchmark -eq $false -or $_.MeasurePowerUsage -eq $false }) { 
                    If ($Variables.MiningEarning -lt $Variables.MiningPowerCost) { 
                        # Mining causes a loss
                        Write-Host -ForegroundColor Red "Mining is currently NOT profitable and causes a loss of $($Config.Currency) $((($Variables.MiningProfit - $Variables.BasePowerCostBTC) * $Variables.Rates.BTC.($Config.Currency)).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates.($Config.PayoutCurrency).($Config.Currency) -Offset 1)"))/day (including Base Power Cost)."
                    }
                    If (($Variables.MiningEarning - $Variables.MiningPowerCost) -lt $Config.ProfitabilityThreshold) { 
                        # Mining profit is below the configured threshold
                        Write-Host -ForegroundColor Blue "Mining profit ($($Config.Currency) $(ConvertTo-LocalCurrency -Value ($Variables.MiningProfit - $Variables.BasePowerCostBTC) -Rate ($Variables.Rates.BTC.($Config.Currency)) -Offset 1)) is below the configured threshold of $($Config.Currency) $($Config.ProfitabilityThreshold.ToString("N$((Get-Culture).NumberFormat.CurrencyDecimalDigits)"))/day; mining is suspended until threshold is reached."
                    }
                }
            }

            Write-Host "--------------------------------------------------------------------------------"
            Write-Host -ForegroundColor Yellow "Last refresh: $(($Variables.Timer).ToLocalTime().ToString('G'))   |   Next refresh: $(($Variables.EndLoopTime).ToString('G'))"
        }

        $Variables.RefreshNeeded = $false

    }
    $TimerUI.Start()
}

Function Form_Load { 
    $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $LabelMiningStatus.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $MainForm.Number = 0
    $TimerUI.Add_Tick(
        { 
            # Display mining information
            If ($host.UI.RawUI.KeyAvailable) { 
                $KeyPressed = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown, IncludeKeyUp"); Start-Sleep -Milliseconds 300; $host.UI.RawUI.FlushInputBuffer()
                If ($KeyPressed.KeyDown) { 
                    Switch ($KeyPressed.Character) { 
                        "a" { 
                            $Variables.ShowAllMiners = -not $Variables.ShowAllMiners
                            Write-Host "Toggled displaying all available miners to " -NoNewline; If ($Variables.ShowAllMiners) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            $Variables.RefreshNeeded = $true
                            Start-Sleep -Seconds 2
                        }
                        "b" { 
                            $Variables.ShowPoolBalances = -not $Variables.ShowPoolBalances
                            Write-Host "Toggled displaying pool balances to " -NoNewline; If ($Variables.ShowPoolBalances) { Write-Host "on" -ForegroundColor Green -NoNewline } Else { Write-Host "off" -ForegroundColor Red -NoNewline }; Write-Host "."
                            $Variables.RefreshNeeded = $true
                            Start-Sleep -Seconds 2
                        }
                        "s" { 
                            If ($Variables.UIStyle -eq "Light") { $Variables.UIStyle = "Full" }
                            Else { $Variables.UIStyle = "Light" }
                            Write-Host "UI style set to " -NoNewline; Write-Host "$($Variables.UIStyle)" -ForegroundColor Blue -NoNewline; Write-Host " (Information about miners run in the past, failed miners & watchdog timers will " -NoNewline; If ($Variables.UIStyle -eq "Light") { Write-Host "not" -ForegroundColor Red -NoNewline; Write-Host " " -NoNewline }; Write-Host "be shown)."
                            $Variables.RefreshNeeded = $true
                            Start-Sleep -Seconds 2
                        }
                    }
                }
            }

            $TimerUI.Interval = 50

            # Timer never disposes objects until it is disposed
            $MainForm.Number += 1
            $TimerUI.Stop()

            TimerUITick
            If ($MainForm.Number -gt 6000) { 
                $MainForm.Number = 0
                $TimerUI.Remove_Tick( { TimerUITick })
                $TimerUI.Dispose()
                $TimerUI = New-Object System.Windows.Forms.Timer
                $TimerUI.Add_Tick( { TimerUITick })
            }
            $TimerUI.Start()
        }
    )

    $TimerUI.Interval = 50
    $TimerUI.Stop()

    If ($CheckBoxConsole.Checked) { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 0)
        Write-Message "Console window hidden"
    }
    Else { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 8)
    }
    $TimerUI.Enabled = $true
}

Function CheckedListBoxPools_Click ($Control) { 
    If ($Control.SelectedItem -in $Control.CheckedItems) { 
        $Control.CheckedItems | Where-Object { $_ -ne $Control.SelectedItem -and ($_ -replace "24hr" -replace "Coins") -like "$($Control.SelectedItem -replace "24hr" -replace "Coins")" } | ForEach-Object { 
            $Control.SetItemChecked($Control.Items.IndexOf($_), $false)
        }
    }
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainForm = New-Object System.Windows.Forms.Form
$NMIcon = New-Object system.drawing.icon ("$($PWD)\Includes\NM.ICO")
$MainForm.Icon = $NMIcon
$MainForm.ClientSize = [System.Drawing.Size]::new(740, 463) # best to keep under 800x600
$MainForm.Text = "Form"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = 'Fixed3D'
$MainForm.MaximizeBox = $false
If ($Config.StartGUIMinimized) { $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }

$MainForm.Add_Shown(
    { 
        # TimerCheckVersion
        $TimerCheckVersion = New-Object System.Windows.Forms.Timer
        $TimerCheckVersion.Enabled = $true
        $TimerCheckVersion.Interval = 1 <#timer resolution 1 ms#> * 1000 <#milliseconds#> * 60 <#seconds#> * 60 <#minutes#> * 24 <#hours#>
        $TimerCheckVersion.Add_Tick(
            { 
                Get-NMVersion
            }
        )
    }
)

$MainForm.Add_FormClosing(
    { 
        $TimerUI.Stop()

        Stop-Mining
        Stop-IdleMining
        Stop-BrainJob
        Stop-BalancesTracker
    }
)

$MainForm | Add-Member -Name "Variables" -Value $Variables -MemberType NoteProperty -Force

$Variables.StatusText = "Idle"
$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$Global:EarningsPage = New-Object System.Windows.Forms.TabPage
$Global:EarningsPage.Text = "Earnings"
$SwitchingPage = New-Object System.Windows.Forms.TabPage
$SwitchingPage.Text = "Switching Log"
$MonitoringPage = New-Object System.Windows.Forms.TabPage
$MonitoringPage.Text = "Rig Monitoring"
$EstimationsPage = New-Object System.Windows.Forms.TabPage
$EstimationsPage.Text = "Benchmarks"

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$TabControl.Location = [System.Drawing.Point]::new(10, 91)
$TabControl.Name = "TabControl"
$TabControl.Width = 722
$TabControl.Height = 363
$TabControl.Controls.AddRange(@($RunPage, $Global:EarningsPage, $SwitchingPage, $MonitoringPage, $EstimationsPage))

$TabControl_SelectedIndexChanged = {
    Switch ($TabControl.SelectedTab.Text) { 
        "Earnings" { Get-Chart }
        "Switching Log" { CheckBoxSwitching_Click }
    }
}
$TabControl.Add_SelectedIndexChanged($TabControl_SelectedIndexChanged)

$MainForm.Controls.Add($TabControl)

# Form Controls
$MainFormControls = @()

$PictureBoxLogo = New-Object Windows.Forms.PictureBox
$PictureBoxLogo.Width = 47 #$img.Size.Width
$PictureBoxLogo.Height = 47 #$img.Size.Height
$PictureBoxLogo.SizeMode = 1
$PictureBoxLogo.ImageLocation = $Branding.LogoPath
$MainFormControls += $PictureBoxLogo

$LabelEarningsDetails = New-Object System.Windows.Forms.TextBox
$LabelEarningsDetails.Tag = ""
$LabelEarningsDetails.MultiLine = $true
$LabelEarningsDetails.Text = ""
$LabelEarningsDetails.AutoSize = $false
$LabelEarningsDetails.Width = 382
$LabelEarningsDetails.Height = 77 # 62
$LabelEarningsDetails.Location = [System.Drawing.Point]::new(57, 2)
$LabelEarningsDetails.Font = [System.Drawing.Font]::new("Lucida Console", 10)
$LabelEarningsDetails.BorderStyle = 'None'
$LabelEarningsDetails.BackColor = [System.Drawing.SystemColors]::Control
$LabelEarningsDetails.ForeColor = [System.Drawing.Color]::Green
$LabelEarningsDetails.Visible = $true
$MainFormControls += $LabelEarningsDetails

$LabelMiningStatus = New-Object System.Windows.Forms.Label
$LabelMiningStatus.Text = "$($Config.PayoutCurrency)/day"
$LabelMiningStatus.AutoSize = $false
$LabelMiningStatus.Width = 473
$LabelMiningStatus.Height = 35
$LabelMiningStatus.Location = [System.Drawing.Point]::new(247, 2)
$LabelMiningStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 14)
$LabelMiningStatus.TextAlign = "MiddleRight"
$LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
$LabelMiningStatus.BackColor = [System.Drawing.Color]::Transparent
$MainFormControls += $LabelMiningStatus

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.Text = "Start"
$ButtonStart.Width = 60
$ButtonStart.Height = 30
$ButtonStart.Location = [System.Drawing.Point]::new(550, 62)
$ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStart.Visible = $true
$ButtonStart.Enabled = (-not $Config.Autostart)
$MainFormControls += $ButtonStart

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.Text = "Pause"
$ButtonPause.Width = 60
$ButtonPause.Height = 30
$ButtonPause.Location = [System.Drawing.Point]::new(610, 62)
$ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonPause.Visible = $true
$ButtonPause.Enabled = $Config.Autostart
$MainFormControls += $ButtonPause

$ButtonStop = New-Object System.Windows.Forms.Button
$ButtonStop.Text = "Stop"
$ButtonStop.Width = 60
$ButtonStop.Height = 30
$ButtonStop.Location = [System.Drawing.Point]::new(670, 62)
$ButtonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStop.Visible = $true
$ButtonStop.Enabled = $Config.Autostart
$MainFormControls += $ButtonStop

$LabelNotifications = New-Object System.Windows.Forms.TextBox
$LabelNotifications.Tag = ""
$LabelNotifications.MultiLine = $true
$LabelNotifications.Text = ""
$LabelNotifications.AutoSize = $false
$LabelNotifications.Width = 280
$LabelNotifications.Height = 18
$LabelNotifications.Location = [System.Drawing.Point]::new(10, 49)
$LabelNotifications.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelNotifications.BorderStyle = 'None'
$LabelNotifications.BackColor = [System.Drawing.SystemColors]::Control
$LabelNotifications.Visible = $true
$MainFormControls += $LabelNotifications

# Run Page Controls
$RunPageControls = @()

$Variables.LabelStatus = New-Object System.Windows.Forms.TextBox
$Variables.LabelStatus.MultiLine = $true
$Variables.LabelStatus.Scrollbars = "Vertical" 
$Variables.LabelStatus.Text = ""
$Variables.LabelStatus.AutoSize = $true
$Variables.LabelStatus.Width = 708
$Variables.LabelStatus.Height = 202
$Variables.LabelStatus.Location = [System.Drawing.Point]::new(2, 2)
$Variables.LabelStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$RunPageControls += $Variables.LabelStatus

$LabelCopyright = New-Object System.Windows.Forms.LinkLabel
$LabelCopyright.Location = New-Object System.Drawing.Size(220, 214)
$LabelCopyright.Size = New-Object System.Drawing.Size(490, 16)
$LabelCopyright.LinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.ActiveLinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.TextAlign = "MiddleRight"
$LabelCopyright.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus && UselessGuru"
$LabelCopyright.Add_Click( { Start-Process "https://github.com/Minerx117/NemosMiner/blob/master/LICENSE" })
$RunPageControls += $LabelCopyright

$LabelRunningMiners = New-Object System.Windows.Forms.Label
$LabelRunningMiners.Text = "Running Miners"
$LabelRunningMiners.AutoSize = $false
$LabelRunningMiners.Width = 202
$LabelRunningMiners.Height = 16
$LabelRunningMiners.Location = [System.Drawing.Point]::new(2, 213)
$LabelRunningMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RunPageControls += $LabelRunningMiners

$RunningMinersDGV = New-Object System.Windows.Forms.DataGridView
$RunningMinersDGV.Width = 708
$RunningMinersDGV.Height = 100
$RunningMinersDGV.Location = [System.Drawing.Point]::new(2, 232)
$RunningMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$RunningMinersDGV.RowHeadersVisible = $false
$RunningMinersDGV.AllowUserToOrderColumns = $true
$RunningMinersDGV.AllowUserToResizeColumns = $true
$RunningMinersDGV.AllowUserToResizeRows = $false
$RunningMinersDGV.ReadOnly = $true
$RunPageControls += $RunningMinersDGV

# Earnings Page Controls
$EarningsPageControls = @()

$LabelEarnings = New-Object System.Windows.Forms.Label
$LabelEarnings.Text = "Earnings statistics per pool"
$LabelEarnings.AutoSize = $false
$LabelEarnings.Width = 202
$LabelEarnings.Height = 16
$LabelEarnings.Location = [System.Drawing.Point]::new(2, 149)
$LabelEarnings.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EarningsPageControls += $LabelEarnings

$EarningsDGV = New-Object System.Windows.Forms.DataGridView
$EarningsDGV.Width = 708
$EarningsDGV.Height = 165
$EarningsDGV.Location = [System.Drawing.Point]::new(2, 167)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.RowHeadersVisible = $false
$EarningsDGV.AllowUserToOrderColumns = $true
$EarningsDGV.AllowUserToResizeColumns = $true
$EarningsDGV.AllowUserToResizeRows = $false
$EarningsDGV.ReadOnly = $true
$EarningsPageControls += $EarningsDGV

# Switching Page Controls
$SwitchingPageControls = @()

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.Text = "CPU"
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.Width = 60
$CheckShowSwitchingCPU.Height = 20
$CheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(2, 2)
$CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingCPU
$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.Text = "NVIDIA"
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.Width = 70
$CheckShowSwitchingNVIDIA.Height = 20
$CheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(62, 2)
$CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingNVIDIA
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.Text = "AMD"
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.Width = 100
$CheckShowSwitchingAMD.Height = 20
$CheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(137, 2)
$CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingAMD
$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

Function CheckBoxSwitching_Click { 
    If (-not $SwitchingDGV.DataSource) { 
        $CheckShowSwitchingAMD.Checked = ($Variables.Devices | Where-Object { $_.State -eq [DeviceState]::Enabled } | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "AMD")
        $CheckShowSwitchingCPU.Checked = ($Variables.Devices | Where-Object { $_.State -eq [DeviceState]::Enabled } | Where-Object Name -Like "CPU#*")
        $CheckShowSwitchingNVIDIA.Checked = ($Variables.Devices | Where-Object { $_.State -eq [DeviceState]::Enabled } | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "NVIDIA")
    }
    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path -Path ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $Variables.SwitchingLog = @(Get-Content ".\Logs\SwitchingLog.csv" | ConvertFrom-Csv | Select-Object -Last 1000 | Select-Object @("DateTime", "Action", "Name", "Type", "Account", "Pool", "Algorithm", "Duration")); [Array]::Reverse($Variables.SwitchingLog)
        $SwitchingDGV.DataSource = [System.Collections.ArrayList]($Variables.SwitchingLog | Where-Object { $_.Type -in $SwitchingDisplayTypes } | ForEach-Object { $_.Datetime = (Get-Date $_.DateTime).ToString("G"); $_ })
        $SwitchingDGV.Columns[0].HeaderText = "Date & Time";
    }
}

$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.Width = 708
$SwitchingDGV.Height = 310
$SwitchingDGV.Location = [System.Drawing.Point]::new(2, 22)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.RowHeadersVisible = $false
$SwitchingDGV.ColumnHeadersVisible = $true
$SwitchingDGV.AllowUserToOrderColumns = $true
$SwitchingDGV.AllowUserToResizeColumns = $true
$SwitchingDGV.AllowUserToResizeRows = $false
$SwitchingDGV.ReadOnly = $true
$SwitchingPageControls += $SwitchingDGV

# Estimations Page Controls
$EstimationsDGV = New-Object System.Windows.Forms.DataGridView
$EstimationsDGV.Width = 708
$EstimationsDGV.Height = 330
$EstimationsDGV.Location = [System.Drawing.Point]::new(2, 2)
$EstimationsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EstimationsDGV.RowHeadersVisible = $false
$EstimationsDGV.ColumnHeadersVisible = $true
$EstimationsDGV.AllowUserToOrderColumns = $true
$EstimationsDGV.AllowUserToResizeColumns = $true
$EstimationsDGV.AllowUserToResizeRows = $false
$EstimationsDGV.ReadOnly = $true

# Monitoring Page Controls
$MonitoringPageControls = @()

$LabelMonitoringWorkers = New-Object System.Windows.Forms.Label
$LabelMonitoringWorkers.Text = "Worker Status"
$LabelMonitoringWorkers.AutoSize = $false
$LabelMonitoringWorkers.Width = 708
$LabelMonitoringWorkers.Height = 18
$LabelMonitoringWorkers.Location = [System.Drawing.Point]::new(2, 4)
$LabelMonitoringWorkers.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringPageControls += $LabelMonitoringWorkers

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.Width = 708
$WorkersDGV.Height = 275
$WorkersDGV.Location = [System.Drawing.Point]::new(2, 22)
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.RowHeadersVisible = $false
$WorkersDGV.ColumnHeadersVisible = $true
$WorkersDGV.AllowUserToOrderColumns = $true
$WorkersDGV.AllowUserToResizeColumns = $true
$WorkersDGV.AllowUserToResizeRows = $false
$WorkersDGV.ReadOnly = $true
$MonitoringPageControls += $WorkersDGV

$ConfigMonitoringInGUI = New-Object System.Windows.Forms.LinkLabel
$ConfigMonitoringInGUI.Location = New-Object System.Drawing.Size(2, 304)
$ConfigMonitoringInGUI.Size = New-Object System.Drawing.Size(355, 20)
$ConfigMonitoringInGUI.LinkColor = [System.Drawing.Color]::Blue
$ConfigMonitoringInGUI.ActiveLinkColor = [System.Drawing.Color]::Blue
$ConfigMonitoringInGUI.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigMonitoringInGUI.TextAlign = "MiddleLeft"
$ConfigMonitoringInGUI.Text = "To edit the monitoring settings use the Web GUI"
$ConfigMonitoringInGUI.Add_Click( { Start-Process "http://localhost:$($Config.APIPort)/rigmonitor.html" })
$MonitoringPageControls += $ConfigMonitoringInGUI

$MainForm | Add-Member -Name Number -Value 0 -MemberType NoteProperty

$TimerUI = New-Object System.Windows.Forms.Timer
$TimerUI.Enabled = $false

$ButtonPause.Add_Click(
    { 
        $Variables.NewMiningStatus = "Paused"
        $Variables.RestartCycle = $true
    }
)

$ButtonStop.Add_Click(
    { 
        $Variables.NewMiningStatus = "Stopped"
        $Variables.RestartCycle = $true
    }
)

$ButtonStart.Add_Click(
    { 
        $Variables.NewMiningStatus = "Running"
        $Variables.RestartCycle = $true
    }
)

$ShowWindow = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$ParentPID = (Get-CimInstance -Class Win32_Process -Filter "ProcessID = $pid").ParentProcessId
$ConsoleHandle = (Get-Process -Id $ParentPID).MainWindowHandle
$ConsoleHandle = (Get-Process -Id $pid).MainWindowHandle

$MainForm.Controls.AddRange($MainFormControls)
$RunPage.Controls.AddRange(@($RunPageControls))
$Global:EarningsPage.Controls.AddRange(@($EarningsPageControls))
$SwitchingPage.Controls.AddRange(@($SwitchingPageControls))
$EstimationsPage.Controls.AddRange(@($EstimationsDGV))
$MonitoringPage.Controls.AddRange($MonitoringPageControls)

$MainForm.Add_Load(
    { 
        Form_Load
    }
)

If ($Variables.APIVersion -ne "" -and $Variables.FreshConfig -eq $true) { 
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("This is the first time you have started $($Variables.CurrentProduct).`n`nUse the configuration editor to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!", 0, "Welcome to $($Variables.CurrentProduct) v$($Variables.CurrentVersion)", 4096) | Out-Null
    Remove-Variable wshell
}

[Void]$MainForm.ShowDialog()
