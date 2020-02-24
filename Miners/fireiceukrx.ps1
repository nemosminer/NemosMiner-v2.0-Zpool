If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\cpu-FireIce104\xmr-stak-rx.exe"
$Uri = "https://github.com/fireice-uk/xmr-stak/releases/download/1.0.4-rx/xmr-stak-rx-win64-1.0.4.7z"
$Commands = [PSCustomObject]@{ 
    #"randomxmonero" = "randomx" #Randomxmonero
    #"randomx"       = "randomx" #Randomxmonero 
    #"randomarq"     = "arqma" #randomARQ
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    ([PSCustomObject]@{ 
            pool_list       = @(
                [PSCustomObject]@{ 
                    pool_address    = "$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
                    wallet_address  = "$($Pools.$Algo.User)"
                    pool_password   = "$($Pools.$Algo.Pass)"
                    use_nicehash    = $true
                    use_tls         = "$($Pools.$Algo.SSL)"
                    tls_fingerprint = ""
                    pool_weight     = 1
                    rig_id          = ""
                }
            )
            currency        = $Commands.$_
            call_timeout    = 10
            retry_time      = 10
            giveup_limit    = 0
            verbose_level   = 3
            print_motd      = $true
            h_print_time    = 60
            aes_override    = $null
            use_slow_memory = "warn"
            tls_secure_algo = $true
            daemon_mode     = $false
            flush_stdout    = $false
            output_file     = ""
            httpd_port      = $Port
            http_login      = ""
            http_pass       = ""
            prefer_ipv4     = $true
        } | ConvertTo-Json -Depth 10
    ) -replace "^{" -replace "}$" | Set-Content "$(Split-Path $Path)\$($Pools.$Algo.Name)_$($Pools.$Algo)_$($Pools.$Algo.User)_CPU.txt" -Force -ErrorAction SilentlyContinue
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "-C $($Pools.$Algo.Name)_$($Pools.$Algo)_$($Pools.$Algo.User)_CPU.txt --noAMD --noNVIDIA -i $($Variables.CPUMinerAPITCPPort)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day } #recompiled 0% Dev fee
        API       = "fireice"
        Port      = $Variables.CPUMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
