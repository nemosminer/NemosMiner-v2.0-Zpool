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
File:           Downloader.ps1
Version:        3.9.9.56
Version date:   04 July 2021
#>

using module .\Includes\Include.psm1

$Variables = $args

$ProgressPreference = "SilentlyContinue"

$Variables.DownloadList | Select-Object | ForEach-Object { 
    $URI = $_.URI
    $Path = $_.Path
    $Searchable = $_.Searchable
 
    If (-not (Test-Path $Path -PathType Leaf)) { 
        Try { 
            Write-Message "Downloader: Initiated download of '$URI'."

            If ($URI -and (Split-Path $URI -Leaf) -eq (Split-Path $Path -Leaf)) { 
                New-Item (Split-Path $Path) -ItemType "Directory" | Out-Null
                Invoke-WebRequest $URI -OutFile $Path -UseBasicParsing -ErrorAction Stop
            }
            Else { 
                Expand-WebRequest $URI $Path -ErrorAction Stop
            }
            Write-Message "Downloader: Installed downloaded miner binary '$($Path)'."
        }
        Catch { 
            Write-Message "Downloader: Searching '$Path' on local computer..."
            $Path_Old = $null

            If ($URI) { Write-Message -Level Warn  "Downloader: Cannot download '$(Split-Path $Path -Leaf)' distributed at '$($URI)'." }
            Else { Write-Message -Level Warn  "Downloader: Cannot download'$(Split-Path $Path -Leaf)'." }
                        
            If ($Searchable) { 
                Write-Message "Downloader: Searching for $(Split-Path $Path -Leaf)."

                $Path_Old = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-ChildItem -Path $_.Root -Include (Split-Path $Path -Leaf) -Recurse -ErrorAction Ignore } | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
                $Path_New = $Path
            }

            If ($Path_Old) { 
                If (Test-Path (Split-Path $Path_New) -PathType Container) { (Split-Path $Path_New) | Remove-Item -Recurse -Force }
                (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                Write-Message -Level Verbose "Downloader: Copied '$($Path)' from local repository '$($PathOld)'."
            }
            Else { 
                If ($URI) { Write-Message -Level Warn "Downloader: Cannot find '$($Path)' distributed at '$($URI)'." }
                Else { Write-Message -Level Warn "Downloader: Cannot find '$($Path)'." }
            }
        }
    }
}

Write-Message "Downloader: All tasks complete."
