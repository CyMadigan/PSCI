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

function Map-VisualStudioYearToVersion {
    <#
    .SYNOPSIS
    Gets the underlaying version of Visual Studio based on year.

    .EXAMPLE
    Map-VisualStudioYearToVersion -Year 2017
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]
        $Year
    )

    $vsVersionMap = @{ `
        2008 = "9.0"; `
        2010 = "10.0"; `
        2012 = "11.0"; `
        2013 = "12.0"; `
        2015 = "14.0"; `
        2017 = "15.0"
    }

    if(!$vsVersionMap.ContainsKey($Year)){
        throw "Specified Visual Studio year ($Year) is not supported yet!"
    }

    return $vsVersionMap[$Year]
}