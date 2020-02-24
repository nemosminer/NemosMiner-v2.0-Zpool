. ..\includes\include.ps1

Write-Host "System Version: $([System.Environment]::OSVersion.Version)"
Write-Host "Powershell version: $($PSVersionTable.PSVersion)"

$VCR2013x86 = Get-WmiObject Win32_Product  -Filter "Name LIKE '%Microsoft Visual C++ 2013 x86%'"
$VCR2013x64 = Get-WmiObject Win32_Product  -Filter "Name LIKE '%Microsoft Visual C++ 2013 x64%'"

$VCR2015x86 = Get-WmiObject Win32_Product  -Filter "Name LIKE '%Microsoft Visual C++ 2015 x86%'"
$VCR2015x64 = Get-WmiObject Win32_Product  -Filter "Name LIKE '%Microsoft Visual C++ 2015 x64%'"

If ($VCR2013x86.count -lt 1) {
    Write-Host -F Red "FAILED - Microsoft Visual C++ 2013 x86"
    Write-Host -F Yellow "    Please install from: https://www.microsoft.com/en-gb/download/details.aspx?id=40784"
}
else {
    Write-Host -F Green "OK - Microsoft Visual C++ 2013 x86"
}

If ($VCR2013x64.count -lt 1) {
    Write-Host -F Red "FAILED - Microsoft Visual C++ 2013 x64"
    Write-Host -F Yellow "    Please install from: https://www.microsoft.com/en-gb/download/details.aspx?id=40784"
}
else {
    Write-Host -F Green "OK - Microsoft Visual C++ 2013 x64"
}

If ($VCR2015x86.count -lt 1) {
    Write-Host -F Red "FAILED - Microsoft Visual C++ 2015 x86"
    Write-Host -F Yellow "    Please install from: https://www.microsoft.com/en-us/download/details.aspx?id=48145"
}
else {
    Write-Host -F Green "OK - Microsoft Visual C++ 2015 x86"
}

If ($VCR2015x64.count -lt 1) {
    Write-Host -F Red "FAILED - Microsoft Visual C++ 2015 x64"
    Write-Host -F Yellow "    Please install from: https://www.microsoft.com/en-us/download/details.aspx?id=48145"
}
else {
    Write-Host -F Green "OK - Microsoft Visual C++ 2015 x64"
}

if ([version](GetNVIDIADriverVersion) -lt [version]"416.34") {
    Write-Host -F Red "Please update NVIDIA drivers"
}
else {
    Write-Host -F Green "OK - NVIDIA driver version. $([version](GetNVIDIADriverVersion))"
}

Pause
