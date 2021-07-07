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
File:           NiceHash External.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -Index 0
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$Url = "https://www.nicehash.com/my/miner/$Wallet"
$Key = $Config.NicehashAPIKey
$OrganizationID = $Config.NicehashOrganizationID
$Secret = $Config.NicehashAPISecret

Function Get-NiceHashRequest {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$EndPoint = "", 
        [Parameter(Mandatory = $true)]
        [String]$Method = "",
        [Parameter(Mandatory = $true)]
        [String]$Key = "",
        [Parameter(Mandatory = $true)]
        [String]$OrganizationID = "",
        [Parameter(Mandatory = $true)]
        [String]$Secret = ""
    )

    $Uuid = [string]([guid]::NewGuid())
    $Timestamp = ([DateTimeOffset](Get-Date).ToUniversalTime()).ToUnixTimeMilliseconds()

    $Str = "$Key`0$Timestamp`0$Uuid`0`0$Organizationid`0`0$($Method.ToUpper())`0$Endpoint`0extendedResponse=true"
    $Sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA256")
    $Sha.Key = [System.Text.Encoding]::UTF8.Getbytes($Secret)
    $Sign = [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${str})))
    $Headers = [Hashtable]@{
        "X-Time"            = $Timestamp
        "X-Nonce"           = $Uuid
        "X-Organization-Id" = $OrganizationId
        "X-Auth"            = "$($Key):$(($Sign -replace '\-').ToLower())"
        "Cache-Control"     = "no-cache"
    }
    Return Invoke-RestMethod "https://api2.nicehash.com$($EndPoint)?extendedResponse=true" -TimeoutSec 5 -ErrorAction Stop -Method $Method -Headers $Headers
}

$RetryCount = 3
$RetryDelay = 10

While (-not ($APIResponse) -and $RetryCount -gt 0 -and $Config.NicehashAPIKey -and $Config.NicehashAPISecret -and $Config.NicehashOrganizationID) { 
    $RetryCount--
    Try {
        $Method = "GET"
        $EndPoint = "/main/api/v2/accounting/account2/BTC/"

        $APIResponse = Get-NiceHashRequest -EndPoint $EndPoint -Method $Method -Key $Key -OrganizationID $OrganizationID -Secret $Secret

        If ($Config.LogBalanceAPIResponse -eq $true) { 
            $APIResponse | Add-Member DateTime ((Get-Date).ToUniversalTime()) -Force
            $APIResponse | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$($Name).json"
        }

        If ($APIResponse.active) { 
            [PSCustomObject]@{ 
                DateTime   = (Get-Date).ToUniversalTime()
                Pool       = $Name
                Currency   = $PayoutCurrency
                Wallet     = $Wallet
                Pending    = [Double]($APIResponse.pending)
                Balance    = [Double]($APIResponse.available)
                Unpaid     = [Double]($APIResponse.totalBalance)
                Withdrawal = [Double]($APIResponse.pendingDetails.withdrawal)
                #Total      = [Double]($APIResponse.pendingDetails.totalBalance)
                Url        = $Url
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }
}