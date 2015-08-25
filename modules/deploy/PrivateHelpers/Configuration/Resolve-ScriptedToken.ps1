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

function Resolve-ScriptedToken {
    <#
    .SYNOPSIS
    Resolves token if it is provided as ScriptBlock.

    .PARAMETER ScriptedToken
    Object to resolve if it is a ScriptBlock

    .PARAMETER ResolvedTokens
    Hashtable containing resolved tokens - will be available as $Tokens variable inside the scriptblock.

    .PARAMETER Node
    Value of $Node variable that will be available inside the scriptblock.

    .PARAMETER Environment
    Value of $Environment variable that will be available inside the scriptblock.

    .EXAMPLE
        $credentials = Resolve-ScriptedToken {$Tokens.General.Credentials}

    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [object]
        $ScriptedToken,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$false)]
        [string]
        $Node,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment
    )

    # Add 'NodeName' and 'Tokens' variables
    $NodeName = $Node
    $Tokens = $ResolvedTokens

    $i = 0
    while ($ScriptedToken -is [ScriptBlock] -and $i -lt 20) {
        $ScriptedToken = & $ScriptedToken
        $i++
    }
    if ($i -eq 20) {
        throw 'Too many nested script tokens (more than 20 loops). Ensure you don''t have circular reference in your tokens (e.g. a={ $ResolvedTokens.b }, b={ $ResolvedTokens.a })'
    }

    # suppression for ScriptCop unused variables
    [void]$NodeName
    [void]$Tokens

    return $ScriptedToken
}
