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
This file defines two entities:
1) Environments, which are containers for server roles. 
Environments can inherit from one another by using -BasedOn parameter. If no -BasedOn in specified, environment will inherit from 'Default' environment.
ServerRoles 'go down' from parent to child environments, but any ServerRole parameter can be overriden in child environment.

2) ServerRoles, defining which computers belong to which ServerRoles, and which configurations are to be deployed to which ServerRoles.
By default configurations are run locally, but this behavior can be modified by using -RunOn / -RunOnCurrentNode parameters.
For ServerRole examples, see .EXAMPLES section in PSCI\deployment\Configuration\ConfigElements\ServerRole.ps1.
#>

# Default environment, parent for all others
Environment Default {
    ServerRole WebServer -Configurations @('WebServerProvision')
	ServerRole DatabaseServer -Configurations @('DatabaseServerDeploy') 

    ServerRole RemotingTestPSRemoting -Configurations @('RemotingTest') -RunOnCurrentNode -RemotingCredential { $Tokens.Credentials.RemotingCredential }
    ServerRole RemotingTestPSRemotingCredSSP -Configurations @('RemotingTest') -RunOnCurrentNode -RemotingCredential { $Tokens.Credentials.RemotingCredential } -Authentication CredSSP -Protocol HTTPS
    ServerRole RemotingTestMSDeploy -Configurations @('RemotingTest') -RunOnCurrentNode -RemotingCredential { $Tokens.Credentials.RemotingCredential } -RemotingMode WebDeployHandler
}

Environment Local {
    ServerRole WebServer -Nodes { $Tokens.Topology.Node }
	ServerRole DatabaseServer -Nodes { $Tokens.Topology.Node }
}

Environment Dev { 
    ServerRole WebServer -Nodes { $Tokens.Topology.Node }
	ServerRole DatabaseServer -Nodes { $Tokens.Topology.Node }

    ServerRole RemotingTestPSRemoting -Nodes { $Tokens.Topology.Node }
    ServerRole RemotingTestPSRemotingCredSSP -Nodes { $Tokens.Topology.Node } -CrossDomain
    ServerRole RemotingTestMSDeploy -Nodes { $Tokens.Topology.Node }
}
