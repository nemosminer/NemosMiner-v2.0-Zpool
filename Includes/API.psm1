<#
Copyright (c) 2018-2020 Nemo & MrPlus

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
File:           API.psm1
version:        3.8.1.3
version date:   12 November 2019
#>

Function Start-APIServer { 
    Param(
        [Parameter(Mandatory = $false)]
        [Int]$Port = 3990
    )

    $Variables | Add-Member APIVersion 0.1

    # Setup flags for controlling script execution
    # $Variables.Stop = $false
    # $Variables.Pause = $false
    # $Variables.Port = $Port

    # Setup runspace to launch the API webserver in a separate thread
    $newRunspace = [runspacefactory]::CreateRunspace()
    $newRunspace.Open()

    Get-Variable -Scope Global | ForEach-Object { 
        try { $newRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value) }
        catch { }
    }

    $APIserver = [PowerShell]::Create().AddScript(
        { 
            # Set the starting directory
            Set-Location (Split-Path $MyInvocation.MyCommand.Path)
            $BasePath = "$PWD\web"

            # List of possible mime types for files
            $MIMETypes = @{ 
                ".js"   = "application/x-javascript"
                ".html" = "text/html"
                ".htm"  = "text/html"
                ".json" = "application/json"
                ".css"  = "text/css"
                ".txt"  = "text/plain"
                ".ico"  = "image/x-icon"
                ".ps1"  = "text/html" # ps1 files get executed, assume their response is html
            }

            # Setup the listener
            $Server = New-Object System.Net.HttpListener
            # Listening on anything other than localhost requires admin privileges
            $Server.Prefixes.Add("http://localhost:3999/")
            $Server.Start()

            While ($Server.IsListening) { 
                $Context = $Server.GetContext()
                $Request = $Context.Request
                $URL = $Request.Url.OriginalString

                # Determine the requested resource and parse query strings
                $Path = $Request.Url.LocalPath
                $Path >> .\Logs\API.log

                # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
                $Parameters = @{ }
                $Request.Url.Query -replace "\?", "" -split '&' | Foreach-Object { 
                    $Key, $Value = $_ -split '='
                    # Decode any url escaped characters in the key and value
                    $Key = [URI]::UnescapeDataString($Key)
                    $Value = [URI]::UnescapeDataString($Value)
                    if ($Key -and $Value) { 
                        $Parameters.$Key = $Value
                    }
                }

                # Create a new response and the defaults for associated settings
                $Response = $Context.Response
                $ContentType = "application/json"
                $StatusCode = 200
                $Data = ""

                # Set the proper content type, status code and data for each resource
                Switch ($Path -Split '\.' | Select-Object -Index 0) { 
                    "/activeminerprograms" { 
                        $Data = $Variables.ActiveMinerPrograms | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/apiversion" { 
                        $Data = $Variables.APIVersion | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/brainjobs" { 
                        $Data = $Variables.BrainJobs | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/config" { 
                        $Data = $Config | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/earnings" { 
                        $Data = $Variables.earnings | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/earningstrackerjobs" { 
                        $Data = $Variables.EarningsTrackerJobs | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/miners" { 
                        $Data = $Variables.miners | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/poolsconfig" { 
                        $Data = $Config.PoolsConfig | ConvertTo-Json -Depth 10
                        Break
                    }
                    "/variables" { 
                        if ($Path -match "^.+\..+$") {
                            $Data = $Variables.(($Path -split '\.' | Select-Object -Skip 1) -join '.') | ConvertTo-Json -Depth 10
                        }
                        else {
                            $Data = $Variables | ConvertTo-Json -Depth 10
                        }
                        break
                    }
                    default { 
                        # Set index page
                        if ($Path -eq "/") { 
                            $Path = "/index.html"
                        }

                        # Check if there is a file with the requested path
                        $Filename = $BasePath + $Path
                        if (Test-Path $Filename -PathType Leaf -ErrorAction SilentlyContinue) { 
                            # If the file is a powershell script, execute it and return the output. A $Parameters parameter is sent built from the query string
                            # Otherwise, just return the contents of the file
                            $File = Get-ChildItem $Filename

                            if ($File.Extension -eq ".ps1") { 
                                $Data = & $File.FullName -Parameters $Parameters
                            }
                            else { 
                                $Data = Get-Content $Filename -Raw

                                # Process server side includes for html files
                                # Includes are in the traditional '<!-- #include file="/path/filename.html" -->' format used by many web servers
                                if ($File.Extension -eq ".html") { 
                                    $IncludeRegex = [regex]'<!-- *#include *file="(.*)" *-->'
                                    $IncludeRegex.Matches($Data) | Foreach-Object { 
                                        $IncludeFile = $BasePath + '/' + $_.Groups[1].Value
                                        if (Test-Path $IncludeFile -PathType Leaf) { 
                                            $IncludeData = Get-Content $IncludeFile -Raw
                                            $Data = $Data -replace $_.Value, $IncludeData
                                        }
                                    }
                                }
                            }

                            # Set content type based on file extension
                            if ($MIMETypes.ContainsKey($File.Extension)) { 
                                $ContentType = $MIMETypes[$File.Extension]
                            }
                            else { 
                                # If it's an unrecognized file type, prompt for download
                                $ContentType = "application/octet-stream"
                            }
                        }
                        else { 
                            $StatusCode = 404
                            $ContentType = "text/html"
                            $Data = "URI '$Path' is not a valid resource."
                        }
                    }
                }

                # If $Data is null, the API will just return whatever data was in the previous request.  Instead, show an error
                # This happens if the script just started and hasn't filled all the properties in yet. 
                if ($Data -eq $null) { 
                    $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
                }

                # Send the response
                $Response.Headers.Add("Content-Type", $ContentType)
                $Response.StatusCode = $StatusCode
                $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $Response.ContentLength64 = $ResponseBuffer.Length
                $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                $Response.Close()

            }
            # Only gets here if something is wrong and the server couldn't start or stops listening
            $Server.Stop()
            $Server.Close()
        }
    ) #end of $APIserver

    $APIserver.Runspace = $newRunspace
    $APIhandle = $APIserver.BeginInvoke()
}
