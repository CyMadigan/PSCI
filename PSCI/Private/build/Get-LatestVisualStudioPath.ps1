<#
The MIT License (MIT)

Copyright (c) 2018 Objectivity Bespoke Software Specialists

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

function Get-LatestVisualStudioPath {
    <#
    .SYNOPSIS
    Gets the path to the latest version of Visual Studio

    .DESCRIPTION
    If VS cannot be found, returns null.

    .EXAMPLE
    Get-LatestVisualStudioPath
    Get-LatestVisualStudioPath -Version '2015'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        [ValidateSet('', '2017', '2015', '2013', '2012', '2010')]
        $Version
    )

    $baseVsDir = Get-ProgramFilesx86Path

    # check if VS2017 is installed with vswhere
    $vswherePath = Join-Path -Path $baseVsDir -ChildPath "Microsoft Visual Studio\Installer\vswhere.exe"
    if(Test-Path $vswherePath) {
        $path = $vswherePath
    } else {
        # download vswhere from NuGet
        $configPaths = Get-ConfigurationPaths
        $nugetPackagesPath = $configPaths.DeployScriptsPath + '\packages'
        Install-NugetPackage -PackageId vswhere -OutputDirectory $nugetPackagesPath -ExcludeVersionInOutput
        $path = "$nugetPackagesPath\vswhere\tools\vswhere.exe"
    }

    $commonArguments = @("-products", "*",
                         "-requires", "Microsoft.Component.MSBuild",
                         "-property", "installationPath"
    )
    if($Version) {
        $vsVersion = [float] (Map-VisualStudioYearToVersion -Year $Version)
        $versionCurrent = $vsVersion.ToString("0.0", [cultureinfo]::InvariantCulture)
        $versionNext = ($vsVersion + 1).ToString("0.0", [cultureinfo]::InvariantCulture)
        $range = "[$versionCurrent, $versionNext)"
        $arguments = $commonArguments + @("-version", $range)
    } else{
        $arguments = $commonArguments + @("-latest")
    }

    $vsPath = & $path $arguments

    if(!$vsPath) {
        # fallback to older versions
        $wildcard = "$baseVsDir\Microsoft Visual Studio*"
        $vsDirs = Get-ChildItem -Path $wildcard -Directory | Sort-Object -Descending
        if (!$vsDirs) {
            throw "Cannot find Visual Studio directory at '$wildcard'. You probably don't have 'Microsoft SQL Server Data Tools - Business Intelligence for Visual Studio'. Please install it and try again."
        }
        $vsPath = $vsDirs[0].FullName
    }

    return $vsPath
}