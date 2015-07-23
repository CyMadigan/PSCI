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

function New-ConnectionParameters {
    <#
    .SYNOPSIS
    Creates an universal connection parameters object that can be conveniently used for opening connections.

    .PARAMETER Nodes
    Names of remote nodes where the connection will be established.

    .PARAMETER RemotingMode
    Defines type of remoting protocol to be used for remote connection.

    .PARAMETER Credential
    A PSCredential object that will be used when opening a remoting session to any of the $Nodes specified.

    .PARAMETER Authentication
    Defines type of authentication that will be used to establish remote conncetion.

    .PARAMETER Port
    Defines the port used for establishing remote connection.

    .PARAMETER Protocol
    Defines the transport protocol used for establishing remote connection (HTTP or HTTPS).

    .PARAMETER CrossDomain
    Should be on when destination nodes are outside current domain.

    .EXAMPLE
    New-ConnectionParameters -Nodes server1
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]
        $Nodes,

        [Parameter(Mandatory=$false)]
        [ValidateSet('PSRemoting', 'WebDeployHandler', 'WebDeployAgentService')]
        [string]
        $RemotingMode = 'PSRemoting',

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential] 
        $Credential,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'Basic', 'NTLM', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [string]
        $Authentication,

        [Parameter(Mandatory=$false)]
        [string]
        $Port,

        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet($null, 'HTTP', 'HTTPS')]
        $Protocol = 'HTTP',

        [Parameter(Mandatory=$false)]
        [switch]
        $CrossDomain
    )

    if ($RemotingMode -eq 'PSRemoting') {
        $psRemotingParams = @{}
        if ($Nodes) {
            $psRemotingParams['ComputerName'] = $Nodes
        }
        if ($Authentication -and $Nodes) {
            $psRemotingParams['Authentication'] = $Authentication
        }

        if ($Credential) {
            $psRemotingParams['Credential'] = $Credential
            # if we have Credentials, we need to have ComputerName (to properly select parameter set in Invoke-Command)
            if (!$Nodes) {
                $psRemotingParams['ComputerName'] = 'localhost'
            }
        }

        if ($Port) {
            $psRemotingParams['Port'] = $Port
        }

        if ($Protocol -eq 'HTTPS') {
            $psRemotingParams['UseSSL'] = $true
            $psRemotingParams['SessionOption'] = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        }

        $cimSessionParams = @{}
        if ($Nodes) {
            $cimSessionParams['ComputerName'] = $Nodes
        }
        if ($Authentication) {
            $cimSessionParams['Authentication'] = $Authentication
        }
        #$params['SkipTestConnection'] = $true

        if ($Credential) {
            $cimSessionParams['Credential'] = $Credential
        }

        if ($Port) {
            $cimSessionParams['Port'] = $Port
        }

        if ($Protocol -eq 'HTTPS') {
            $cimSessionParams['SessionOption'] = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        }
    } else {
         if ($Nodes.Count -ne 1) {
            Write-Log -Critical "Only one node can be specified for RemotingMode = $RemotingMode."
         }
         if ($RemotingMode -eq "WebDeployHandler") {
            if (!$Port) {
		        # default port
                $Port = '8172'
            }
            $url = "https://{0}:{1}/msdeploy.axd" -f $Nodes[0], $Port
        } else {
            if (!$Port) {
		        # default port
                $Port = '80'
            }
            $url = "http://{0}:{1}/MsDeployAgentService" -f $Nodes[0], $Port
        }
        $msDeployDestinationStringParams = @{ Url = $url; Offline = $false }

        if ($Credential) {
            $msDeployDestinationStringParams.Add("UserName", $Credential.UserName)
            $msDeployDestinationStringParams.Add("Password", $Credential.GetNetworkCredential().Password)
        }

        if ($Authentication) {
            $msDeployDestinationStringParams.Add("AuthType", $Authentication)
        }
        $msDeployDestinationString = New-MsDeployDestinationString @msDeployDestinationStringParams
    }

    return @{
        Nodes = @($Nodes)
        NodesAsString = @($Nodes) -join ','
        RemotingMode = $RemotingMode
        Credential = $Credential
        Authentication = $Authentication
        Port = $Port
        Protocol = $Protocol
        CrossDomain = $CrossDomain
        PSSessionParams = $psRemotingParams
        CimSessionParams = $cimSessionParams
        MsDeployDestinationString = $msDeployDestinationString
    }

}