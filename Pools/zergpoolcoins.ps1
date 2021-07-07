If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

Try { 
    $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\zergpoolcoins\zergpoolcoins.json") | ConvertFrom-Json
    $CoinsRequest = Invoke-WebRequest "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
}
Catch { return }

If ((-not $Request) -or (-not $CoinsRequest)) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = ".mine.zergpool.com"

$PriceField = "Plus_Price"
#$PriceField = "actual_last24h"
#$PriceField = "estimate_current"
$DivisorMultiplier = 1000000

$ConfName = If ($Config.PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$AllMiningCoins = @()
($CoinsRequest | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) | ForEach-Object { $CoinsRequest.$_ | Add-Member -Force @{Symbol = If ($CoinsRequest.$_.Symbol) { $CoinsRequest.$_.Symbol } Else { $_ } } ; $AllMiningCoins += $CoinsRequest.$_ }

#Uses BrainPlus calculated price
$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name
    # Find best coin for algo
    $TopCoin = $AllMiningCoins | Where-Object { ($_.noautotrade -eq 0) -and ($_.hashrate -gt 0) -and ((Get-Algorithm $_.algo) -eq $PoolAlgorithm) } | Sort-Object -Property @{Expression = { $_.estimate / ($DivisorMultiplier * [Double]$_.mbtc_mh_factor) } } -Descending | Select-Object -first 1

    $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor

    If ((Get-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit") -eq $null) { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }
    Else { $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100))) }

    $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency } Else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    $Locations = "eu", "na", "asia"
    $Locations | ForEach-Object { 
        $Pool_Location = $_
        switch ($Pool_Location) { 
            "eu" { $Location = "EU" }
            "na" { $Location = "US" }
            "asia" { $Location = "JP" }
            default { $Location = "JP" }
        }
        $PoolHost = "$($PoolAlgorithm).$($Pool_Location)$($HostSuffix)"

        If ($PoolConf.Wallet) { 
            [PSCustomObject]@{ 
                Algorithm     = $PoolAlgorithm
                Coin          = $TopCoin.Symbol
                Info          = $TopCoin.Name
                Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
                StablePrice   = $Stat.Week
                MarginOfError = $Stat.Week_Fluctuation
                Protocol      = "stratum+tcp"
                Host          = $PoolHost
                Port          = $PoolPort
                User          = $PoolConf.Wallet
                Pass          = If ($TopCoin.Symbol) { "$($WorkerName),c=$($PwdCurr),mc=$($TopCoin.Symbol)" } Else { "$($WorkerName),c=$($PwdCurr)" }
                Location      = $Location
                SSL           = $false
            }
        }
    }
}
