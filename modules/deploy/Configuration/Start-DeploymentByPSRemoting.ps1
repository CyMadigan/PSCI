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

function Start-DeploymentByPSRemoting {
    <#
    .SYNOPSIS
    Runs the actual deployment basing on the deployment plan on a remote server by using powershell remoting.

    .PARAMETER Environment
    Name of the environment where the packages will be deployed.

    .PARAMETER ServerRole
    Name of the the server role that will be deployed.

    .PARAMETER RunOnConnectionParams
    Connection parameters created by New-ConnectionParameters function.

    .PARAMETER PackageDirectory
    Defines location on remote machine where deployment package will be copied to.

    .PARAMETER RequiredPackages
    List of packages that will be copied to the remote server.

    .PARAMETER CopyPackages
    If true then packages will be copied to the remote server. If false then deployment assumes that packages are already there.

    .PARAMETER DeployType
    Deployment type:
    All       - deploy everything according to configuration files (= Provision + Deploy)
    Provision - deploy only DSC configurations
    Deploy    - deploy only non-DSC configurations
    Adhoc     - override configurations and nodes with $ConfigurationsFilter and $NodesFilter (they don't have to be defined in ServerRoles - useful for adhoc deployments)

    .PARAMETER NodesFilter
    List of Nodes where configurations have to be deployed - can be used if you don't want to deploy to all nodes defined in the configuration files.
    If not set, configurations will be deployed to all nodes according to the ServerRoles defined in the configuration files.

    .PARAMETER ConfigurationsFilter
    List of Configurations to deploy - can be used if you don't want to deploy all configurations defined in the configuration files.
    If not set, configurations will be deployed according to the ServerRoles defined in the configuration files.

    .PARAMETER TokensOverride
    A list of tokens to override. Token defined in the configuration files will be overrided with values specified in this array 
    (tokens will be matched by name, ignoring categories).

    .EXAMPLE
    Start-DeploymentByPSRemoting -Environment $Environment -ServerRole $ServerRole -CopyTo "C:\test" -RunOnConnectionParams (New-ConnectionParameters -Nodes localhost -RemotingMode PSRemoting)
    
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $Environment,

        [Parameter(Mandatory=$true)]
        [string[]]
        $ServerRole,

        [Parameter(Mandatory=$true)]
        [object]
        $RunOnConnectionParams,

        [Parameter(Mandatory=$true)]
        [string]
        $PackageDirectory,

        [Parameter(Mandatory=$false)]
        [string[]]
        $RequiredPackages,

        [Parameter(Mandatory=$false)]
        [switch]
        $CopyPackages = $false,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Provision', 'Deploy', 'Adhoc')]
	    [string]
	    $DeployType = 'All',

        [Parameter(Mandatory=$false)]
        [string[]]
        $NodesFilter,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ConfigurationsFilter,

        [Parameter(Mandatory=$false)]
        [hashtable]
        $TokensOverride
    )

    # TODO: this need review
    if ($RunOnConnectionParams.Authentication -ieq "Credssp") {
        if ((Get-Item WSMan:\LocalHost\Client\Auth\CredSSP).Value -ne "true") {
            Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
        }
        if ($RunOnConnectionParams.CrossDomain) {
            Enable-FreshCredNtlmOnlyDelegation
        }
    }

    if ($CopyPackages) {
        $configPaths = Get-ConfigurationPaths
        $includePackages = Get-IncludePackageList -AllPackagesPath $configPaths.PackagesPath -RequiredPackages $RequiredPackages
        [void](Copy-FilesToRemoteServer -Path $configPaths.PackagesPath -Destination $PackageDirectory -ConnectionParams $RunOnConnectionParams -Include $includePackages -ClearDestination)
    }

    $deployScript = ".\DeployScripts\deploy.ps1 -Environment '{0}' -ServerRolesFilter '{1}' -DeployType $DeployType" `
                    -f ($Environment -join "','"), ($ServerRole -join "','")
    
    if ($NodesFilter) {
        $deployScript += " -NodesFilter '{0}'" -f ($NodesFilter -join "','")
    }
    if ($ConfigurationsFilter) {
        $deployScript += " -ConfigurationsFilter '{0}'" -f ($ConfigurationsFilter -join "','")
    }
    if ($TokensOverride) {
       $tokensOverrideString = Convert-HashtableToString -Hashtable $TokensOverride
       $deployScript += " -TokensOverride {0}" -f $tokensOverrideString
    }

    $scriptBlock = {
        param(
            [string]
            $PackageDirectory,

            [string]
            $DeployScript,

            [string]
            $RemotingMode
        )

        Set-Location -Path $PackageDirectory
        $Global:PSCIRemotingMode = $RemotingMode
        Invoke-Expression -Command "& $DeployScript"
    }

    Write-Log -Info "Running `"$deployScript`" using $($RunOnConnectionParams.RemotingMode) on `"$($RunOnConnectionParams.NodesAsString)`""
    $psSessionParams = $RunOnConnectionParams.PSSessionParams
    $success = Invoke-Command @psSessionParams -ScriptBlock $scriptBlock -ArgumentList $PackageDirectory, $deployScript, $RunOnConnectionParams.RemotingMode
    if (!$success) {
        Write-Log -Critical 'Remote invocation failed.'
    }
}
