<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#
.SYNOPSIS
Main PSCI module.

.DESCRIPTION
It initializes some global variables and iterates current directory to include child modules.
#>

if ($PSVersionTable.PSVersion.Major -lt 3) {
    throw "PSCI requires Powershell 3 or 4 (4 is required for DSC). Please install 'Windows Management Framework 4.0' from http://www.microsoft.com/en-us/download/details.aspx?id=40855."
    exit 1
}
Set-StrictMode -Version Latest

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$curDir\PSCI.classes.ps1"
. "$curDir\PSCI.globalObjects.ps1"

Import-Module -Name "$curDir\core\PSCI.core.psm1" -Force -Global

$buildNumber = Get-PSCIBuildNumber -Path $curDir

if (Test-Path -Path "$curDir\modules") {
	$modulesToImport = Get-ChildItem -Path "$curDir\modules\*\*.psm1"

	foreach ($modulePath in $modulesToImport.FullName) {
		# Write-Host -Object ("Importing module {0}" -f $_)
		# 3>$null suppresses warning messages (appearing due to usage of unapproved verbs)
		Import-Module -Name $modulePath -Force -Global 3>$null
	}
	
	Write-Log -Info ("PSCI (build #{0}) started with modules: {1}. Path: '{2}'." -f $buildNumber, ($modulesToImport.Name -replace 'PSCI.(.*).psm1', '$1' -join ", " ), $PSScriptRoot)
}

Export-ModuleMember -Variable `
    PSCIGlobalConfiguration, `
    LogSeverity

