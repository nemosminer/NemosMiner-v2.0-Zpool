# NemosMiner

NemosMiner monitors mining pools in real-time in order to find the most profitable Algo

Updated 04 July 2021


Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru

This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Updated/Maintained by Nemo/Minerx117 & UselessGuru

with alot of help from MrPlusGH, grantemsley & UselessGuru. Without them NemosMiner would not be possible.

NemosMiner code is partly based on

- MultiPoolMiner which can be found here: https://github.com/MultiPoolMiner/MultiPoolMiner

- NPlusMiner which can be found here: https://github.com/MrPlusGH/NPlusMiner


Note: This beta version is **NOT backwards compatible** with the current 3.8.x code base.
It is highly recommended to install this version to a new directory.

Some configuration options have changed. See 'Changed Config Items.txt' for more information.
NemosMiner will automatically convert an existing configuration file.

*****

**Main features:**
   - GUI and easy configuration
   - Auto Benchmarks Each algo to get optimal speeds 
   - Fully automated 
   - Auto Downloads Miners
   - Auto Updates
   - Monitoring
   - Earnings graph

*****

Easy configuration, easy start:

      Run NemosMiner.bat
      1. Config tab
      2. Set your Wallet address and Username
      3. Select your pool 
      4. Save Config
      5. Start

      Note: 2. you only need to change Username if you are using Miningpoolhub or ProHashing

   Algorithm selection / removal

      +[algorithm] to enable algorithm
      -[algorithm] to disable algorithm

      If '+' is used, then only the explicitly enabled algorithms are used
      If '-' is used, then all algorithms except the disabled ones are used
      Leave empty to use ALL available algorithms (not recommended as it may cause more miner switching)

      Do not combine + and - for the same algo

      Examples:
      Algorithm list = -x16r
      Will mine anything but x16r

      Algorithm list = -x16r,-bcd
      Will mine anything but x16r and bcd

      Algorithm list = +x16r
      Will mine only x16r

      Algorithm list = +x16r,+bcd
      Will mine only x16r and BCD

      Algorithm list blank
      Will mine anything

   Pools Variants

      *24hr  - uses last 24hour price data in pool API to calculate profit (no estimates or advanced calculations)

      *Plus - uses advanced calculations to reduce uneeded switching

      normal - uses current price data in pool API to calculate profit (no estimates or advanced calculations)

      *Coins - uses advanced calculations, mines only top paying coin in Algo (MiningPoolHub & ZergPool)


   Developer/Contributors Donation: 
      The list and wallets is publicly available at: https://nemosminer.com/data/devlist.json

      Donation Fee = 0.9%
      There is 13 minute per day default donation (0.9%),
      which can be increased or decreased in the config tab, 
      please help support the great team behind NemosMiner by leaving mining donations turned on.
      We want to stay completely transparent on the way fees are managed in the product.
      Fees cycle occurs once every 24 hours for the selected amount of time (13 minutes). 
      Donation start time is randomized each day.
      If Interval is set higher than the donation time, the interval will prime.
      Example for default parameters (13 minutes):
      - NemosMiner was started at 10:00h
      - First donation cycle starts somewhen beween 10:01h and 23:47h and will then donate for 13 minutes, then mine for you again until the next donation run. 
      - After 00:00h the donation start time is randomized again. 
      - When donation start time is reached it will then donate for 13 minutes, then mine for you again until the next donation run.
      All donation time and addresses are recorded in the logs folder.

   NemosMiner Monitoring Server: https://nemosminer.com

      Keep tabs on all your mining rigs from one place
      You can now optionally monitor all your workers remotely, both in the GUI and via https://nemosminer.com  
      Monitoring setup instructions https://nemosminer.com/setup.php 

   GUI

      Since version 3.9.9.x (Beta) NemosMiner has a Web GUI making it easy to configure and run.
      NemosMiner relies on config files. No need to edit bat files. Simply run NemosMiner.bat
      Set the config in the Web GUI, apply & start mining

   Pause mining

      Ability to pause miners while keeping other jobs running (pause button)
      This will stop mining activity
      BrainPlus will still run in the background avoiding the learning phase on resume
      EarningTracker will still run in the background avoiding the learning phase on resume

   PreRun

      Ability to run a batch prior switching to a specific miner and/or algorithm.
      The prerun scripts can be used to set per miner/algorithm OC via nvidiaInspector or OverdriveNTool.
      Before starting a miner executable NemosMiner is trying to launch one of the following 3 prerun scripts (in this order):
      1. <MinerName>_<Algorithm>.bat
         Simply create a file named <MinerName>_<AlgorithmName>.bat in prerun folder, e.g. 'Bminer-v16.3.1-1xRadeonRX5808GB-Handshake-10.bat' or 'CcminerMTP-v1.3.2-1xGTX10606GB_MTP.bat'
      2. <Algorithm>.bat
         Simply create a file named <AlgorithmName>.bat in prerun folder, e.g. 'Ethash.bat'
      3. default.bat
         If neither of the two above exist, NemosMiner will try to launch prerun\default.bat
      Use overclock with caution

   Per pools config (Advanced)

      **This is for advanced users. Do not use if you do not know what you are doing.**

      The file Config\PoolsConfig.json contains configuration details.
      There is a separate section for each configured pool. If a pool is listed in this file,
      the specific settings will be taken into account. If not, the built in default values will be used.

      You can set specific options per pool. For example, you can mine NiceHash on the internal wallet and other pools on a valid wallet. This configuration is provided as an example in Config\PoolsConfig-NHInternal.json

      Available options:
         - Wallets[Currency] = Your wallet address for [Currency]; some pools, e.g. HiveOn require wallets in each supported currency
         - UserName = your MPH or ProHashing user name
         - WorkerName = your worker name
         - PricePenaltyFactor = See explanation below
         - Algorithm = List of included or excluded algorithms per pool (see example files)
         - PayoutThreshold[Currency] = pool will allow pyout if this amount is reached

      Usage:
         - Edit Config\PoolsConfig.json
         - Add an entry for the pool you want to customize
            - The name must be the pool base name (omit *24hrs or *Coins), e.g ZergPool (even if you have configured ZergPoolCoins in the pool list)
            - (**careful with json formating ;)**

      Note that the GUI only updates default values (valid for ALL pools unless there is pool specific configuration setting defined in PoolConfig.json). Any other changes need to be done manually.

   PricePenaltyFactor

      When using advanced per pool configuration, it is possible to add a penalty factor for a specific pool. This simply adds as a multiplicator on estimations presented by the pool.

      Example scenario:
         - You feel like a pool is exaggerating its estimations by 10% - Set PricePenaltyFactor to 0.9

   AHashPool/BlockMasters/NLPool/ZergPool/Zpool

      Uses calculations based on 24hr actual and current estimate prices to get a more realistic estimate.
      Includes some trust index based on past 1hr current estimate variation from 24hr.
      AND is NOT sensible to spikes.
      This shows less switching than following current estimate and more switching that following the 24hr actual.
      Better profitability.

   Balances Tracking

      Displays BTC/h and BTC/d as well a estimation of when the pool payment threshold will be reached.
      Supported pools:
         - AHashPool
         - BlockMasters
         - HiveON
         - MiningPoolHub
         - NiceHash (internal & external wallet)
         - NLPool
         - ProHashing
         - ZergPool
         - Zpool
      If mining more than one pool, NemosMiner shows stats for any supported pool.
      Press key 'b' in the console window to show/hide earnings.

   Support for running multiple instances

      **Experimental**
      More than one instance of NemosMiner can run on the same rig
      Each instance must be placed in its own directory
      Miner has to be started prior the launch of the next instance

   Optional miners (Advanced)

      These are closed source and therefore not enabled in NemosMiner by default.
      Use at your own risk.

      For advanced users, check the Optional Miners checkbox on the Config tab to enable these miners.

   CustomMiners (Advanced)

      Users can place any miner.ps1 from miners/optionalminers or custom user created miner.ps1 files in CustomMiners folder 
      Note: Miners in CustomMiners folder are always enabled (to disable a custom miner it must be removed from the CustomMiners folder)

   Algorithm switching log

      Simple algo switching log as csv (switching.log file found in Logs folder).
      You can easily track switching rate.

   Console Display Options

      Use -UIStyle Light or -UIStyle Full in config.json
         Full = Usual display (Default)
         Light = Show only current mining info
      UIStyle automatically switches to Full during benchmarking.
      Press key 's' in the console window to switch UIStyle.

   In session console display toggle

      Press key 'a' in the window to show/hide all avaialable miners 
      Press key 'b' in the window to show/hide pool balances
      Press key 's' in the window to switch between light and full display
      Will toggle display at next refresh

   New version notification (Available since version 3.9.9.10)

      NemosMiner will notify new version availability

***Requirements***

PowerShell Version 7.x is required:

[Windows Powershell 7.3.1 (Recommended)](https://github.com/PowerShell/PowerShell/releases/download/v7.1.3/PowerShell-7.1.3-win-x64.msi)

**Some miners may need 'Visual C+ RunTimes download/extract, run install_all.bat file**

[Visual C+ RunTimes](https://github.com/Minerx117/Visual-C-Runtimes-All-in-One-Sep-2019/releases/download/sep2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)

**Virtual memory settings**

When running multiple cards its recommended to increase Virtual Memory. 64GB is optimal.

**Recommended/optimal Windows Nvidia driver**

[Windows 10 Nvidia driver 461.92](https://us.download.nvidia.com/Windows/461.92/461.92-desktop-win10-64bit-international-dch-whql.exe)

[Windows 7, 8, 8.1 Nvidia driver 461.92](https://international.download.nvidia.com/Windows/461.92/461.92-desktop-win7-64bit-international-whql.exe)

Windows 10 Nvidia driver for RTX3060 = 470.05 Torrent Magnet
magnet:?xt=urn:btih:8453693771195232CE91406C1A3481EBBA315866&dn=470.05-gameready-win-10-dch-64bit-international&tr=http%3a%2f%2fbt1.archive.org%3a6969%2fannounce&tr=http%3a%2f%2fbt2.archive.org%3a6969%2fannounce&ws=https%3a%2f%2farchive.org%2fdownload%2f&ws=http%3a%2f%2fia601501.us.archive.org%2f33%2fitems%2f&ws=%2f33%2fitems%2f

**Recommended/optimal Windows AMD driver**

[Windows 10 AMD GPU Driver 21.2.2](https://drivers.amd.com/drivers/non-whql-radeon-software-adrenalin-2020-21.2.2-win10-64bit-feb11.exe)

   NemosMiner is currently tested on the following Rigs: 

      windows10-1xGTX-1660Super/RYZEN-3700x (Test PC) 

      windows10-9xAMD-5700XT/Octominer (test Rig 1)
      windows8.1-6xRTX-3070/RYZEN-3700x (test Rig 2)
      windows10-6xRTX-3080/RYZEN-3700x (test Rig 3)
      windows10-1xGTX-1060Super/1xRX580-8GB/RX5700/Inteli5-8600K (test Rig 4)
      (users have reported up to 12cards are working, I have not tested myself)
      Some miners do not support more than 9 cards

      CPU miners are tested with AMD Ryzen 3700x & Inteli5-8600K CPUs

*****

Licensed under the GNU General Public License v3.0
Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license.
Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Happy Mining
