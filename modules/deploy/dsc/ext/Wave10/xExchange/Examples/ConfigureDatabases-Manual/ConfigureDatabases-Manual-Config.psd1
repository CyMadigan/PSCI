@{
    AllNodes = @(
		#Settings under 'NodeName = *' apply to all nodes.
        @{
            NodeName        = '*'

            #CertificateFile and Thumbprint are used for securing credentials. See:
            #http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx
            
        }

		#Individual target nodes are defined next
        @{
            NodeName        = 'e15-1'

            #Configure the databases whose primary copies will reside on this server
            PrimaryDBList = @{
                DB1 = @{Name = 'DB1'; EdbFilePath = 'C:\ExchangeDatabases\DB1\DB1.db\DB1.edb'; LogFolderPath = 'C:\ExchangeDatabases\DB1\DB1.log'};
                DB3 = @{Name = 'DB3'; EdbFilePath = 'C:\ExchangeDatabases\DB3\DB3.db\DB3.edb'; LogFolderPath = 'C:\ExchangeDatabases\DB3\DB3.log'}
            }

            #Configure the copies next.
            CopyDBList    = @{
                DB2 = @{Name = 'DB2'; ActivationPreference = 2; ReplayLagTime = '00:00:00'};
                DB4 = @{Name = 'DB4'; ActivationPreference = 2; ReplayLagTime = '00:00:00'}
            }
        }

        @{
            NodeName        = 'e15-2'

            PrimaryDBList = @{
                DB1 = @{Name = 'DB1'; EdbFilePath = 'C:\ExchangeDatabases\DB1\DB1.db\DB1.edb'; LogFolderPath = 'C:\ExchangeDatabases\DB1\DB1.log'};
                DB3 = @{Name = 'DB3'; EdbFilePath = 'C:\ExchangeDatabases\DB3\DB3.db\DB3.edb'; LogFolderPath = 'C:\ExchangeDatabases\DB3\DB3.log'}
            }

            CopyDBList    = @{
                DB2 = @{Name = 'DB2'; ActivationPreference = 2; ReplayLagTime = '00:00:00'};
                DB4 = @{Name = 'DB4'; ActivationPreference = 2; ReplayLagTime = '00:00:00'}
            }
        }

        @{
            NodeName        = 'e15-3'

            #Configure just copies for this node
            CopyDBList    = @{
                DB1 = @{Name = 'DB1'; ActivationPreference = 3; ReplayLagTime = '00:00:00'};
                DB2 = @{Name = 'DB2'; ActivationPreference = 4; ReplayLagTime = '7.00:00:00'};
                DB3 = @{Name = 'DB3'; ActivationPreference = 3; ReplayLagTime = '00:00:00'};
                DB4 = @{Name = 'DB4'; ActivationPreference = 4; ReplayLagTime = '7.00:00:00'}
            }
        }

        @{
            NodeName        = 'e15-4'

            #Configure just copies for this node
            CopyDBList    = @{
                DB1 = @{Name = 'DB1'; ActivationPreference = 4; ReplayLagTime = '7.00:00:00'};
                DB2 = @{Name = 'DB2'; ActivationPreference = 3; ReplayLagTime = '00:00:00'};
                DB3 = @{Name = 'DB3'; ActivationPreference = 4; ReplayLagTime = '7.00:00:00'};
                DB4 = @{Name = 'DB4'; ActivationPreference = 3; ReplayLagTime = '00:00:00'}
            }
        }
    );
}