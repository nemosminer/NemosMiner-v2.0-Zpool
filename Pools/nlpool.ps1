If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

Try { 
    $Request = Get-Content ((Split-Path -Parent (Get-Item $script:MyInvocation.MyCommand.Path).Directory) + "\Brains\nlpool\nlpool.json") | ConvertFrom-Json
}
Catch { return }

If (-not $Request) { return }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.nlpool.nl"
$PriceField = "Plus_Price"
# $PriceField = "actual_last24h"
# $PriceField = "estimate_current"
 
$Location = "US"

# Placed here for Perf (Disk reads)
$ConfName = If ($Config.PoolsConfig.$Name) { $Name } Else { "default" }
$PoolConf = $Config.PoolsConfig.$ConfName

$Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $PoolHost = $HostSuffix
    $PoolPort = $Request.$_.port
    $PoolAlgorithm = Get-Algorithm $Request.$_.name

    $Divisor = 1000000 * [Double]$Request.$_.mbtc_mh_factor

    switch ($PoolAlgorithm) { 
        "equihash125" { $Divisor *= 2 } #temp fix
        "equihash144" { $Divisor *= 2 } #temp fix
        "equihash192" { $Divisor *= 2 } #temp fix
        "verushash" { $Divisor *= 4 } #temp fix
    }

    $Stat = Set-Stat -Name "$($Name)_$($PoolAlgorithm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor * (1 - ($Request.$_.fees / 100)))

    $PwdCurr = If ($PoolConf.PwdCurrency) { $PoolConf.PwdCurrency } Else { $Config.Passwordcurrency }
    $WorkerName = If ($PoolConf.WorkerName -like "ID=*") { $PoolConf.WorkerName } Else { "ID=$($PoolConf.WorkerName)" }

    If ($PoolConf.Wallet) { 
        [PSCustomObject]@{ 
            Algorithm     = $PoolAlgorithm
            Info          = ""
            Price         = $Stat.Live * $PoolConf.PricePenaltyFactor
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Week_Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $PoolHost
            Port          = $PoolPort
            User          = $PoolConf.Wallet
            Pass          = "$($WorkerName),c=$($PwdCurr)"
            Location      = $Location
            SSL           = $false
        }
    }
}
