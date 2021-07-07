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
File:           GetMinerData.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module ".\Include.psm1"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String]$MinerAPI,
    [Parameter(Mandatory = $true)]
    [String]$MinerJSON # Must be JSON, workaround for 'InvalidOperation: Unable to find type [Miner].'
)

# Load miner API file
. ".\Includes\MinerAPIs\$($MinerAPI).ps1"

Try { 

    $Miner = ($MinerJSON | ConvertFrom-Json) -as $MinerAPI

    While ($true) { 
        $NextLoop = (Get-Date).AddSeconds($Miner.DataCollectInterval)
        $Miner.GetMinerData()
        While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 200 }
    }
}
Catch { 
    Return $Error[0]
}
