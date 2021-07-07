If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-ccminermtp132\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer-2/releases/download/1.3.2/ccminermtp132.7z"
$Commands = [PSCustomObject]@{ 
      "mtp" = " -d $($Config.SelGPUCC) -a mtp -i 21" # memeroy allocation error when running 7 or more GPU's work well with upto 6 GPU's 
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "mtp" -and $Pools.$Algo.Host -like "*nicehash*") { return }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://mtp.na.mine.zergpool.com:3000 -u $($Pools.$Algo.User) --no-donation -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
