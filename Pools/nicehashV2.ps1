If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

Try { 
    $Request = Invoke-WebRequest "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
    $RequestAlgodetails = Invoke-WebRequest "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
    $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm ; $_ | Add-Member -force @{algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Fee = 0.05 #5% FOR EXTERNAL WALLET CHANGE TO 2% If YOU USE INTERNAL
$ConfName = If ($Config.PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$Request.miningAlgorithms | Where-Object { $_.paying -gt 0 } <# algos paying 0 fail stratum #> | ForEach-Object { 
    $Algo = $_.Algorithm
    $NiceHash_Port = $_.algodetails.port
    $NiceHash_Algorithm = Get-Algorithm $_.Algorithm
    $NiceHash_Coin = ""
    $DivisorMultiplier = 1000000000
    $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.marketFactor
    $Divisor = 100000000
    $Stat = Set-Stat -Name "$($Name)_$($NiceHash_Algorithm)_Profit" -Value ([Double]$_.paying / $Divisor * (1 - $Fee))
    $Locations = "eu-west", "usa-west"
    $Locations | ForEach-Object { 
        $NiceHash_Location = $_
        switch ($NiceHash_Location) { 
            "eu-west" { $Location = "EU" }
            "usa-west" { $Location = "US" }
 
        }
        $NiceHash_Host = "$($Algo).$($NiceHash_Location).nicehash.com"
        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=', ''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $false
            }

            [PSCustomObject]@{ 
                Algorithm     = $NiceHash_Algorithm
                Info          = $NiceHash_Coin
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+ssl"
                Host          = $NiceHash_Host
                Port          = $NiceHash_Port
                User          = "$($PoolConf.Wallet).$($PoolConf.WorkerName.Replace('ID=', ''))"
                Pass          = "x"
                Location      = $Location
                SSL           = $true
            }
        }
    }
}
