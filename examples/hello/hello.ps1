Import-Module '..\..\PSCI\PSCI.psd1' -Force

Environment Default { 
    ServerConnection LocalServer -Nodes localhost
    ServerRole Web -Steps 'MyDSC','MyFunction' -ServerConnection LocalServer
}

function MyFunction {
    param ($NodeName, $Environment, $Tokens)

    Write-Host "Hello from $NodeName / env $Environment"
}

Configuration MyDSC {
    param ($NodeName, $Environment, $Tokens)
    
    Node $NodeName {
        Log Message {
            Message = "Hello from $NodeName / env $Environment"
        }
    }
}

Start-Deployment -Environment Default -NoConfigFiles