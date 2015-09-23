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

function Resolve-DeploymentPlanSteps {
    <#
    .SYNOPSIS
    Groups deployment plan entries by specified properties.

    .PARAMETER DeploymentPlan
    Deployment plan to group.

    .PARAMETER GroupByConnectionParams
    If true, result will be grouped by ConnectionParams.

    .PARAMETER GroupByRunOnConnectionParamsAndPackage
    If true, result will be grouped by RunOnConnectionParams and PackageDirectory.

    .PARAMETER PreserveOrder
    If true, original order is always preserved, even if it means there will be less entries in each group.

    .EXAMPLE
      $planByRunOn = Group-DeploymentPlan -DeploymentPlan $DeploymentPlan -GroupByRunOnConnectionParamsAndPackage -PreserveOrder
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]
        $DeploymentPlan,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'DSC', 'Functions', 'Adhoc')]
        [string]
        $DeployType = 'All',

        [Parameter(Mandatory=$true)]
        [string]
        $DscOutputPath
    )

    $filteredDeploymentPlan = New-Object -TypeName System.Collections.ArrayList
    $stepCommandMapping = @{}

    # get command for each entry and filter by DeployType
    foreach ($entry in $DeploymentPlan) {
        $stepName = $entry.StepName
        $command = $stepCommandMapping[$stepName]
        if (!$command) {
            $command = Get-Command -Name $stepName -ErrorAction SilentlyContinue
            if (!$command) {
                throw "Invalid Step reference ('$stepName') - Environment '$($entry.Environment)' / ServerRole '$($entry.ServerRole)'. Please ensure there is a DSC configuration or Powershell function named '$stepName'."
            }
            if ($DeployType -eq 'Functions' -and $command.CommandType -eq 'Configuration') {
                continue
            } elseif ($DeployType -eq 'DSC' -and $command.CommandType -ne 'Configuration') {
                continue
            }
            $stepCommandMapping[$entry.StepName] = $command
        }
        $entry.StepType = $command.Type
        [void]($filteredDeploymentPlan.Add($entry))
    }

    # run DSC configurations to create .MOF files
    if (Test-Path -LiteralPath $DscOutputPath) {
        [void](Remove-Item -LiteralPath $DscOutputPath -Force -Recurse)
    }
    $dscEntries = $filteredDeploymentPlan | Where-Object { $_.StepCommandObject.CommandType -eq 'Configuration' }
    foreach ($entry in $dscEntries) {
        if ($entry.IsLocalRun) {
            $dscNode = 'localhost'
        } else {
            $dscNode = $entry.ConnectionParams.Nodes
        }

        if (!$entry.RunOnConnectionParams -and $entry.ConnectionParams.RemotingMode -and $entry.ConnectionParams.RemotingMode -ne 'PSRemoting') {
            throw "Cannot deploy DSC configurations from localhost when RemotingMode is not PSRemoting. Please either change it to PSRemoting or add '-RunRemotely' switch to the ServerRole or StepSettings (Environment '$($entry.Environment)' / ServerRole '$($entry.ServerRole)' / Step '$($entry.StepName)')."
        }

        $mofDir = Invoke-DeploymentStep `
            -StepName $entry.StepName `
            -OutputPath $DscOutputPath `
            -Node $dscNode `
            -Environment $entry.Environment `
            -ResolvedTokens $entry.Tokens `
            -ConnectionParams $entry.ConnectionParams

        if (!(Get-ChildItem -Path $mofDir -Filter "*.mof")) {
            Write-Log -Warn "Mof file has not been generated for step named '$($entry.StepName)' (Environment '$($entry.Environment)' / ServerRole '$($entry.ServerRole)'). Please ensure your configuration definition is correct."
            continue
        }
        $mofDir = Resolve-Path -LiteralPath $mofDir
        $entry.ConfigurationMofDir = $mofDir
    }

    #TODO: search&replace StepName / StepType

    return $filteredDeploymentPlan
}