<#
Copyright (c) 2018-2019 Nemo & MrPlus

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

# Try running this script as:  http://localhost:3999/scripts/demo.ps1?message=Hello%20World!

param($Parameters)
Write-Output $Parameters.message