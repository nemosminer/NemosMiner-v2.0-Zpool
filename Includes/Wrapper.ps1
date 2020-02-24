param(
    [Parameter(Mandatory = $true)]
    [Int]$ControllerProcessID,
    [Parameter(Mandatory = $true)]
    [String]$Id,
    [Parameter(Mandatory = $true)]
    [String]$FilePath,
    [Parameter(Mandatory = $false)]
    [String]$ArgumentList = "",
    [Parameter(Mandatory = $false)]
    [String]$WorkingDirectory = ""
)

# Force Culture to en-US
$culture = [System.Globalization.CultureInfo]::CreateSpecificCulture("en-US")
$culture.NumberFormat.NumberDecimalSeparator = "."
$culture.NumberFormat.NumberGroupSeparator = ","
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture

Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

. ..\Includes\include.ps1

0 | Set-Content "..\Logs\energi.txt"

$PowerShell = [PowerShell]::Create()
if ($WorkingDirectory -ne "") { $PowerShell.AddScript("Set-Location '$WorkingDirectory'") | Out-Null }
$Command = ". '$FilePath'"
if ($ArgumentList -ne "") { $Command += " $ArgumentList" }
$PowerShell.AddScript("$Command 2>&1 | Write-Verbose -Verbose") | Out-Null
$Result = $PowerShell.BeginInvoke()

Write-Host "energiminer v2.2.1" -BackgroundColor Yellow -ForegroundColor Black

do {
    Start-Sleep -Seconds 1

    $PowerShell.Streams.Verbose.ReadAll() | ForEach-Object {
        $Param = @{ }
        if ($Command -like '*energiminer.exe*') { $Param.NoNewLine = $true }
        Write-Host $_ @Param

        $HashRate = 0
        if (
            $_ -match "Speed\s([0-9.,]+)\s?([kmgtp]?h/s)" -or # EnergiMiner
            $_ -match "Accepted.*\s([0-9.,]+)\s([kmgtp]?h/s)" -or # lyclMiner
            $false
        ) {
            $HashRate = [decimal]($Matches[1] -replace ',', '.')
            $Units = $Matches[2]

            if ($HashRate -gt 0) {
                "`nHashRate Detected: $HashRate $Units" | Write-Host -BackgroundColor Yellow -ForegroundColor Black

                $HashRate *= switch ($Units) {
                    "kh/s" { 1e3 }
                    "mh/s" { 1e6 }
                    "gh/s" { 1e9 }
                    "th/s" { 1e12 }
                    "ph/s" { 1e15 }
                    Default { 1 }
                }
                $HashRate -replace ',', '.' | Set-Content "..\Logs\energi.txt"
            }
        }
    }
    if (-not (Get-Process | Where-Object Id -EQ $ControllerProcessID)) { $PowerShell.Stop() | Out-Null }
} until($Result.IsCompleted)

Remove-Item "..\Logs\energi.txt" -ErrorAction Ignore
