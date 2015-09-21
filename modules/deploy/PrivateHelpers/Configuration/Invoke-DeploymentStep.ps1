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

function Invoke-DeploymentStep {
    <#
    .SYNOPSIS
    Invokes a DSC configuration or function.

    .DESCRIPTION
    It passes the parameters through to the DSC configuration/function if it expects them.
    Returns path to the generated .MOF file if StepName is a DSC configuration or empty string if it's a function.

    .PARAMETER StepName
    Name of the DSC configuration or function to invoke.

    .PARAMETER OutputPath
    Base output path for MOF files that will be generated - only relevent if StepName is a DSC configuration.
    A specific folder structure will be created for the StepName / Node.

    .PARAMETER Node
    Name of the node - will be passed as 'NodeName' to the configuration.

    .PARAMETER Environment
    Environment name - will be passed as 'Environment' to the configuration.

    .PARAMETER ResolvedTokens
    Tokens resolved for the node/environment - will be passed as 'Tokens' to the configuration.

    .PARAMETER ConnectionParams
    Connection parameters as defined in server roles (object created by [[New-ConnectionParameters]]).

    .EXAMPLE
    $mofDir = Invoke-DeploymentStep -StepName $StepName -OutputPath $DscOutputPath -Node $Node -Environment $Environment -ResolvedTokens $resolvedTokens

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $StepName,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Node,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $ResolvedTokens,

        [Parameter(Mandatory=$true)]
        [object]
        $ConnectionParams
    )  

    $stepCommand = Get-Command -Name $StepName

    $expr = "$StepName"
    if ($stepCommand.Parameters.ContainsKey("nodeName")) {
        $expr += " -NodeName `"$Node`""
    }

    if ($stepCommand.Parameters.ContainsKey("environment")) {
        $expr += " -Environment `"$Environment`""
    }

    if ($stepCommand.Parameters.ContainsKey("tokens")) {
        $expr += ' -Tokens $ResolvedTokens'
    }

    if ($stepCommand.Parameters.ContainsKey("connectionParams")) {
        $expr += ' -ConnectionParams $ConnectionParams'
    }

    if ($stepCommand.Parameters.ContainsKey("packagesPath")) {
        $packagesPath = (Get-ConfigurationPaths).PackagesPath
        $expr += ' -PackagesPath `"$packagesPath`"'
    }

    if ($stepCommand.CommandType -eq "Configuration") {
        # Set PSDscAllowPlainTextPassword to $true in order to pass credentials into dsc configuration. It will be stored as plain text in a .mof file.
        # The better way is to use certificate and its thumbprint to decrypt the credentials on the target node.
        $configurationData = "@{ AllNodes = @( @{  NodeName = `"$Node`"; PSDscAllowPlainTextPassword = `$true }) }"

        $dir = Join-Path -Path $OutputPath -ChildPath $Node
        $dir = Join-Path -Path $dir -ChildPath $StepName

        $expr += " -OutputPath `"$dir`" -ConfigurationData $configurationData"
        Write-Log -Info "Running custom configuration: $expr"
        [void](Invoke-Expression -Command $expr)
        return $dir
    } elseif ($stepCommand.CommandType -eq "Function") {
        Write-Log -Info "Running custom function: $expr"
        ([void](Invoke-Expression -Command $expr))
        return ""
    } else {
        throw "Command '$StepName' is of unsupported type: $($stepCommand.commandType)"
    }  
}
