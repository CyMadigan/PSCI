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

Import-Module -Name "$PSScriptRoot\..\..\..\PSCI.psm1" -Force

Describe -Tag "PSCI.unit" "ServerRole" {
    InModuleScope PSCI.deploy {

        Mock Write-Log { 
            Write-Host "$Message"
            if ($Critical) {
                throw ("Exception: " + $Message)
            }
        }

        function TestFunc { }
        function TestFunc2 { }
        Configuration TestDSC { }
        Configuration TestDSC2 { }
        Configuration TestDSC3 { }

        Context "when used with single role and environment" {
            It "Resolve-ServerRoles: should properly resolve local environment" {
                Initialize-Deployment

                $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

			    Environment Local {
                    ServerConnection Web1 -Nodes @('machine1','machine2') -RemotingCredential $remotingDefaultCredential -PackageDirectory 'c:\dir'
				    ServerRole Web -Configurations @('TestFunc', 'TestDSC')  -RunOn 'machine1' -ServerConnections Web1
			    }

                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations.Name | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.RunOn | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $remotingDefaultCredential
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'c:\dir'
            }

            It "Resolve-ServerRoles: should resolve scripted tokens for Nodes but not for RemotingCredential" {
                Initialize-Deployment

                $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

			    Environment Local {
                    ServerConnection Web1 -Nodes { @('machine1','machine2') } -RemotingCredential { $remotingDefaultCredential }
				    ServerRole Web -Configurations { 'TestFunc' } -ServerConnections { 'Web1' }
			    }

                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations.Name | Should Be 'TestFunc'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential -is [scriptblock] | Should Be $true
            }

             It "Resolve-ServerRoles: should resolve in-place ServerConnection" {
                Initialize-Deployment

                $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

			    Environment Local {   
				    ServerRole Web -Configurations { 'TestFunc' } -ServerConnections (ServerConnection Web1 -Nodes { @('machine1','machine2') } -RemotingCredential { $remotingDefaultCredential })
			    }

                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations.Name | Should Be 'TestFunc'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential -is [scriptblock] | Should Be $true
            }

            It "Resolve-ServerRoles: should fail when Configuration does not exist" {
                Initialize-Deployment

			    Environment Local {
				    ServerRole Web -Configurations @('NotExisting')
			    }

                $fail = $false
                try  {
                    $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}
                } catch { 
                    $fail = $true
                }

                $fail | Should Be $true
            }
        }

        Context "when used with single role and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

		    Environment Default {
			    ServerRole Web -Configurations @('TestFunc') -ServerConnections (ServerConnection machine1 -Nodes machine1 -RemotingCredential $cred)
		    }

		    Environment Local {
			    ServerRole Web -Configurations @('TestFunc', 'TestDSC') -ServerConnections (ServerConnection -Name 'm1' -Nodes @('machine1','machine2'))
		    }

            It "Resolve-ServerRoles: should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $cred
            }

            It "Resolve-ServerRoles: should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'm1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
            }
        }

        Context "when used with multiple roles" {
            Initialize-Deployment

            Environment Default {
			    ServerRole Web -Configurations @('TestFunc') -ServerConnections (ServerConnection machine1 -Nodes machine1)
		    }

		    Environment Local {
			    ServerRole Database -Configurations @('TestDSC') -ServerConnections (ServerConnection machine2 -Nodes machine1)
		    }

            It "Resolve-ServerRoles: should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'
            }

            It "Resolve-ServerRoles: should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Configurations | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'machine2'
            }
        }
        
        Context "when used with multiple rules and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

		    Environment Default {
                ServerConnection WebServers -Nodes @('localhost') -RemotingCredential $cred 
                ServerConnection DatabaseServers -Nodes @('localhost') -RemotingCredential $cred
                ServerConnection SSRSServers -Nodes $null

                ServerRole Web -Configurations TestFunc -ServerConnections WebServers
                ServerRole Database -Configurations 'TestDSC' -ServerConnections DatabaseServers
                ServerRole SSRS -Configurations @('TestFunc') -ServerConnections SSRSServers
                ServerRole NoConf -ServerConnection WebServers
		    }

		    Environment Live {
                ServerConnection WebServers -Nodes @('web01', 'web02') -PackageDirectory 'C:\Deployment' -RemotingMode PSRemoting -RemotingCredential $null
                ServerConnection DatabaseServers -Nodes @('db01') -RemotingMode PSRemoting -Authentication Credssp -RemotingCredential $cred
                ServerConnection SSRSServers -Nodes @('ssrs01') 

                ServerRole Web -Configurations TestFunc2 -RunRemotely
                ServerRole Database -Configurations TestDSC2 -RunRemotely 
		    }

		    Environment LivePerf -BasedOn Live {
                ServerConnection WebServers -PackageDirectory 'C:\Deployment2'
                ServerConnection SSRSServers -Nodes $null

                ServerRole Database -Configurations TestDSC3
                
		    }

            It "Resolve-ServerRoles: should properly resolve Live environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Live -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 3

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be 'TestFunc2'
                $resolvedRoles.Web.RunRemotely | Should Be $true
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('web01', 'web02')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'C:\Deployment'
                
                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Configurations | Should Be 'TestDSC2'
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'db01'
			    $resolvedRoles.Database.ServerConnections.RemotingCredential | Should Be $cred

                $resolvedRoles.SSRS | Should Not Be $null
                $resolvedRoles.SSRS.Configurations | Should Be 'TestFunc'
                $resolvedRoles.SSRS.ServerConnections.Count | Should Be 1
                $resolvedRoles.SSRS.ServerConnections.Nodes | Should Be 'ssrs01'
			    $resolvedRoles.SSRS.ServerConnections.RemotingCredential | Should Be $null
            }

            It "Resolve-ServerRoles: should properly resolve LivePerf environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment LivePerf -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be 'TestFunc2'
                $resolvedRoles.Web.RunRemotely | Should Be $true
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('web01', 'web02')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'C:\Deployment2'
                
                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Configurations | Should Be 'TestDSC3'
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'db01'
			    $resolvedRoles.Database.ServerConnections.RemotingCredential | Should Be $cred
            }
        }

        Context "when used with BasedOn" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes machine1 -RemotingMode WebDeployHandler
                ServerConnection DbServer -Nodes machine2 -BasedOn WebServer
                ServerConnection DbServer2 -Nodes $null -BasedOn WebServer
			    ServerRole Web -Configurations @('TestFunc') -ServerConnections WebServer
                ServerRole Database -Configurations @('TestDSC') -ServerConnections DbServer
                ServerRole Database2 -Configurations @('TestDSC') -ServerConnections DbServer2 # this should be ignored because DbServer2 will have no Nodes
		    }

		    Environment Local {
                ServerConnection DbServer -Nodes machine3 -BasedOn $null
                ServerRole Database2 -Configurations @('TestDSC') -ServerConnections (ServerConnection DbServer4 -BasedOn DbServer)
                ServerRole Database3 -Configurations @('TestDSC') -ServerConnections (ServerConnection DbServer5 -BasedOn DbServer2 -Nodes machine4)
		    }

            It "Resolve-ServerRoles: should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Configurations | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'DbServer'
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'machine2'
                $resolvedRoles.Database.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'
            }

            It "Resolve-ServerRoles: should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 4
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Configurations | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Configurations | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'DbServer'
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'machine3'
                $resolvedRoles.Database.ServerConnections.RemotingMode | Should Be 'PSRemoting'

                $resolvedRoles.Database2 | Should Not Be $null
                $resolvedRoles.Database2.Configurations | Should Be @('TestDSC')
                $resolvedRoles.Database2.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database2.ServerConnections.Name | Should Be 'DbServer4'
                $resolvedRoles.Database2.ServerConnections.Nodes | Should Be 'machine3'
                $resolvedRoles.Database2.ServerConnections.RemotingMode | Should Be 'PSRemoting'

                $resolvedRoles.Database3 | Should Not Be $null
                $resolvedRoles.Database3.Configurations | Should Be @('TestDSC')
                $resolvedRoles.Database3.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database3.ServerConnections.Name | Should Be 'DbServer5'
                $resolvedRoles.Database3.ServerConnections.Nodes | Should Be 'machine4'
                $resolvedRoles.Database3.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'
            }
        }

        Context "when used with invalid BasedOn" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes machine1 -RemotingMode WebDeployHandler
                ServerConnection DbServer -Nodes machine1 -BasedOn Invalid
			    ServerRole Web -Configurations @('TestFunc') -ServerConnections DbServer
		    }

            It "Resolve-ServerRoles: should throw exception" {
                $fail = $false
                try { 
                    $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}
                } catch {
                    $fail = $true
                }

                $fail | Should Be $true
            }
        }

        #TODO: filters and ResolvedTokens
    }
}

