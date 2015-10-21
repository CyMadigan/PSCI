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

function New-SqlDatabase {
    <# 
    .SYNOPSIS 
    Creates a new SQL Server database with default settings and simple recovery mode.

    .DESCRIPTION 
    Creates database using New-SqlDatabase.sql script with default settings.

    .PARAMETER ConnectionString
    Connection string

    .PARAMETER DatabaseName
    Database name - if not specified, Initial Catalog from ConnectionString will be used.

    .PARAMETER Credential
    Credential to impersonate in Integrated Security mode.

    .PARAMETER QueryTimeoutInSeconds
    Query timeout

    .EXAMPLE
    New-SqlDatabase -DatabaseName "MyDb" -ConnectionString "data source=localhost;integrated security=True"
    #> 

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)] 
        [string]
        $ConnectionString,

        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName, 

        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $Credential,

        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds

    )

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "New-SqlDatabase.sql"

    if (!$DatabaseName) { 
        $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
        $DatabaseName = $csb.InitialCatalog
    }
    if (!$DatabaseName) {
        throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
    }

    $parameters = @{ "DatabaseName" = $databaseName }
    [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -Credential $Credential -QueryTimeoutInSeconds $QueryTimeoutInSeconds -DatabaseName '')
}