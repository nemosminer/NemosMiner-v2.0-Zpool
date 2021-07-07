# NemosMiner

NemosMiner Monitors mining pools in real-time in order to find the most profitable Algo

Updated 29 November 2020

[![Github All Releases](https://img.shields.io/github/downloads/nemosminer/Nemosminer/total.svg)](https://github.com/nemosminer/Nemosminer/releases) +
[![Github All Releases](https://img.shields.io/github/downloads/Minerx117/Nemosminer/total.svg)](https://github.com/Minerx117/Nemosminer/releases)
[![GitHub release](https://img.shields.io/github/release/Minerx117/Nemosminer/all.svg)](https://github.com/Minerx117/NemosMiner/releases)
[![GitHub Release Date](https://img.shields.io/github/release-date-pre/Minerx117/NemosMiner.svg)](https://github.com/Minerx117/NemosMiner/releases)
[![GitHub license](https://img.shields.io/github/license/Minerx117/Nemosminer.svg)](https://github.com/Minerx117/NemosMiner/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/nemosminer/Nemosminer.svg)](https://github.com/nemosminer/Nemosminer/stargazers) +
[![GitHub stars](https://img.shields.io/github/stars/Minerx117/Nemosminer.svg)](https://github.com/Minerx117/Nemosminer/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/nemosminer/Nemosminer.svg)](https://github.com/nemosminer/Nemosminer/network)

Copyright (c) 2018-2020 Nemo, MrPlus & UselessGuru

This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Updated/Maintained by Nemo/Minerx117

with alot of Help From MrPlusGH, grantemsley & UselessGuru without them NemosMiner would not be possible

NemosMiner was based on MultiPoolMiner which can be found here: https://github.com/MultiPoolMiner/MultiPoolMiner
NemosMiner is currently based on NPlusMiner which can be found here: https://github.com/MrPlusGH/NPlusMiner
 
*****

	 GUI and easy configuration
	 Auto Benchmarks Each algo to get optimal speeds 
	 Fully automated 
	 Auto Downloads Miners
	 Auto Updates
	 Monitoring

*****

Easy configuration, easy start:

      Run NemosMiner.bat
      1. Config tab
      2. Set your Wallet address and Username
      3. Select your pool 
      4. Save Config
      5. Start
      
      note: 2. you only need to change Username if you are using Miningpoolhub
      
     Algo selection / removal
  
      +algo for algo selection
      -algo for algo removal

      If "+" Used, all selected algo have to be listed
      If "Minus" Used, all algo selected but exluded ones.

      Do not combine + and - for the same algo

     Examples:
     Algo list = -x16r
     Will mine anything but x16r

     Algo list = -x16r,-bcd
     Will mine anything but x16r and bcd

     Algo list = +x16r
     Will mine only x16r

     Algo list = +x16r,+bcd
     Will mine only x16r and BCD

     Algo list blank
     Will mine anything
  
  Pools variants

      24hr - uses last 24hour Actual API too request profit (no estimates or advanced calculations)
	 
      normal - uses advanced calculations to reduce uneeded switching
	 
      coins - uses advanced calculations, mines only top paying coin in Algo (ZergPool Only)
	 
  
  Developer/Contributors Donation: 
  list and wallets is publicly available at: https://nemosminer.com/data/devlist.json
     
    Donation Fee = 0.9%
    There is 13 minute per day default donation (0.9%),
    which can be increased or decreased in the config tab, 
    please help support the great team behind NemosMiner by leaving mining donations turned on
    We want to stay completely transparent on the way fees are managed in the product.
    Fees cycle occurs once every 24 hours for the selected amount of time (13 minutes).
    The first donation sequence occurs 1 hour after miners are started.
    If Interval is set higher than the donation time, the interval will prime.
    Example for default parameters:
    Miners started at 10, First donation cycle runs at 11 until 11:13, Next donation cycle occurs 24 hours after.
    All donation time and addresses are recorded in the logs folder.
   
NemosMiner Monitoring Server : https://nemosminer.com

     Keep tabs on all your mining rigs from one place
     You can now optionally monitor all your workers remotely, both in the GUI and via https://nemosminer.com  
     Monitoring setup instructions https://nemosminer.com/setup.php 

   
   GUI
   
      Since version 3.0 NemosMiner has a GUI making it easy to configure and run.
	  Relies on config files. No need to edit bat files. Simply run NemosMiner.bat 
	  Set the config on the config tab, save, close, run NemosMiner.bat

   Pause mining
   
      Ability to pause miners while keeping other jobs running (pause button)
      This will stop mining activity
      BrainPlus will still run in the background avoiding the learning phase on resume
      EarningTracker will still run in the background avoiding the learning phase on resume

   prerun
   
      Ability to run a batch prior switching to a specific algo.
      For example, can be used to set per algo OC via nvidiaInspector
      Simply create a file named <AlgoName>.bat in prerun folder
      If <AlgoName>.bat does not exist, will try to launch prerun/default.bat
      Use overclock with caution

   Per pools config (Advanced)
   
        - **This is for advanced users. Do not use if you do not know what you are doing.**
        - You can now set specific options per pool. For example, you can mine NiceHash on the internal wallet and other pools on a valid wallet. This configuration is provided as an example in Config\PoolsConfig-NHInternal.json
          - Available options
            - Wallet = your wallet address
            - UserName = your MPH user name
            - WorkerName = your worker name
            - PricePenaltyFactor = See explanation below
	    - Algorithm = List of included or excluded Aglo on pool (see example files)
          - Usage
            - The file Config\PoolsConfig.json contains per pool configuration details. If a pool is listed in this file,
	    the specific settings will be taken into account. If not, the setting for the entry name default will be used.
	    **Do not delete the default entry.**
            - Edit Config\PoolsConfig.json
            - Add an entry for the pool you want to customize
              - The name must be the NemosMiner name for the pool. ie. for ahashpool, if you use Plus. The name is ahashpoolplus.
              - (**careful with json formating ;)**)
              - Best way is to duplicate the default entry
        - Note that the GUI only updates the default entry. Any other changes need to be done manualy

   PricePenaltyFactor

        - When using advanced per pool configuration, it is possible to add a penalty factor for a specific pool. This simply adds as a multiplicator on estimations presented by the pool.
        - Example scenario
          - You feel like a pool is exaggerating his estimations by 10% - Set PricePenaltyFactor to 0.9

  zergpool/zergpoolcoins/nlpool/ahashpool/zpool/blazepool/blockmasters
   
      Uses calculations based on 24hractual and currentestimate prices to get a more realistic estimate.
      Includes some trust index based on past 1hr currentestimate variation from 24hr.
      AND is NOT sensible to spikes.
      This shows less switching than following Current Estimate and more switching that following the 24hr Actual.
      Better profitability.

   Earnings Tracking
   
      Displays BTC/H and BTC/D as well a estimation of when the pool payment threshold will be reached.
      Supported pools:
            ahashpool
            zpool
            nicehash
            miningpoolhub (partial)
      If mining more that one pools, shows stats for any supported pool
      Press key e in the console window to show/hide earnings

   Support running multiple instances
   
      **Experimental**
      More than one instance of NemosMiner can run on the same rig
      Each instance must be placed in it's own directory
      Miner has to be started prior the launch of the next instance

   Optional miners (Advanced)
   
      Some miners are not enabled by default in NemosMiner for a variety of reasons:
       
              These are closed source and therefore not enabled in NemosMiner by default.
              Use at your own risk.
 
      For advanced users, check the Optional Miners checkbox on the Config tab to enable these miners.
      
   CustomMiners (Advanced)
      
      Users can place any miner.ps1 from miners/optionalminers or custom user created miner.ps1 files, in CustomMiners folder 
      leaving miners and optionalminers disabled in config will enable CustomMiners folder 

   Algo switching log
   
      Simple algo switching log in csv switching.log file found in Logs folder.
      You can easily track switching rate.

   Console Display Options
   
      Use -UIStyle Light or -UIStyle Full in config.json
            Full = Usual display (Default)
            Light = Show only currently mining info
      UIStyle automaticaly swtiches to Full during benchmarking.

   In session console display toggle
   
      Press key s in the window to switch between light and full display
      Press key e in the window to show/hide earnings 
      Will toggle display at next refresh

   New version notification
   
      NemosMiner will notify new version availability
 
If you have Windows 7, 8, or 8.1, please update PowerShell (Version 7.x is highly recommeded): 

[update PowerShell](https://github.com/PowerShell/PowerShell/releases)

Some miners may need 'Visual C+ RunTimes download/extract, run install_all.bat file

[Visual C+ RunTimes](https://github.com/Minerx117/Visual-C-Runtimes-All-in-One-Sep-2019/releases/download/sep2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)

running multiple cards its recommended to increase Virtual Memory 64gb is optimal

[recommended/optimal Windows 10 Nvidia driver 461.92](https://us.download.nvidia.com/Windows/461.92/461.92-desktop-win10-64bit-international-dch-whql.exe)

[recommended/optimal Windows 7, 8, 8.1 Nvidia driver 461.92](https://international.download.nvidia.com/Windows/461.92/461.92-desktop-win7-64bit-international-whql.exe)

recommended/optimal Windows 10 Nvidia driver for RTX3060 = 470.05 Torrent Magnet

magnet:?xt=urn:btih:8453693771195232CE91406C1A3481EBBA315866&dn=470.05-gameready-win-10-dch-64bit-international&tr=http%3a%2f%2fbt1.archive.org%3a6969%2fannounce&tr=http%3a%2f%2fbt2.archive.org%3a6969%2fannounce&ws=https%3a%2f%2farchive.org%2fdownload%2f&ws=http%3a%2f%2fia601501.us.archive.org%2f33%2fitems%2f&ws=%2f33%2fitems%2f

[recommended/optimal Windows 10 AMD GPU Driver 21.2.2](https://drivers.amd.com/drivers/non-whql-radeon-software-adrenalin-2020-21.2.2-win10-64bit-feb11.exe)

   NemosMiner is currently tested on the following Rigs: 

      windows10-1xGTX-2080/RYZEN-1700 (Test PC) 

      windows10-9xAMD-5700XT/Octominer (test Rig 1)
      windows7-6xRTX-3070/RYZEN-3700x (test Rig 2)
      windows10-6xRTX-3080/RYZEN-3700x (test Rig 3)
      (users have reported up to 12cards are working, I have not tested myself)
      Some miners do not support more than 9 cards

      CPU miners are tested with AMD Ryzen 1700 & 3700x CPU's

*****

Licensed under the GNU General Public License v3.0
Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license.
Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Happy Mining
