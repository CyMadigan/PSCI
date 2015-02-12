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

function Build-EntityFrameworkMigratePackage {
     <#
    .SYNOPSIS
    Builds a package containing Entity Framework Code First assembly and everything that's required to apply it to a database. 

    .DESCRIPTION
    If $ProjectFile is provided, it will be compiled using msbuild.
    Then dlls available at $MigrationsDir plus Entity Framework dlls plus migrate.exe will be copied to the package at $OutputPath.
    If $OutputPath is not provided, $PackagesPath\$PackageName, where $PackagesPath is taken from global variable.
    The resulting package can be deployed with cmdlet Deploy-EntityFrameworkMigratePackage.

    .PARAMETER PackageName
    Name of the package. It determines OutputPath if it's not provided.

    .PARAMETER MigrationsDir
    Path to the directory containing the compiled migrations. They must already exist if $ProjectFile is not specified.

    .PARAMETER EntityFrameworkDir
    Path to the directory containing Entity Framework dlls.

    .PARAMETER MsBuildOptions
    An object created by New-MsBuildOptions function, which specifies msbuild options.
    If not provided, default msbuild options will be used.

    .PARAMETER ProjectPath
    Path to the project file that will be compiled in order to create migrations assembly (pointed by $MigrationsDir). It can be a msbuild solution or project.

    .PARAMETER OutputPath
    Output path where the package will be created. If not provided, $OutputPath = $PackagesPath\$PackageName, where $PackagesPath is taken from global variable.

    .PARAMETER AddFilesToPackage
    Additional files that will be added to the package (e.g. web.config).

    .PARAMETER RestoreNuGet
    If true and $ProjectFile is provided, 'nuget restore' will be explicitly run before building the project file.

    .LINK
    Deploy-EntityFrameworkMigratePackage
    New-MsBuildOptions

    .EXAMPLE
    Build-EntityFrameworkMigratePackage -PackageName 'EntityFrameworkCodeFirst' -MigrationsDir "EntityFramework\bin\Release" -EntityFrameworkDir "packages\EntityFramework"

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string]
        $MigrationsDir,

        [Parameter(Mandatory=$true)]
        [string]
        $EntityFrameworkDir,

        [Parameter(Mandatory=$false)]
        [PSObject]
        $MsBuildOptions,

        [Parameter(Mandatory=$false)]
        [string]
        $ProjectPath,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputPath,

        [Parameter(Mandatory=$false)]
        [string[]]
        $AddFilesToPackage,

        [Parameter(Mandatory=$false)]
        [switch]
        $RestoreNuGet 
    )

    $configPaths = Get-ConfigurationPaths

    if ($ProjectPath) {
        $ProjectPath = Resolve-PathRelativeToProjectRoot `
                            -Path $ProjectPath `
                            -ErrorMsg "Project file {0} specified in 'ProjectPath' argument does not exist (package '$PackageName'). Tried following absolute path: '{0}'."
    }
    $MigrationsDir = Resolve-PathRelativeToProjectRoot `
                        -Path $MigrationsDir `
                        -ErrorMsg "Directory that should contain migration dlls '$migrationsDir' does not exist (package '$PackageName'). Tried following absolute path: '{0}'."

    $EntityFrameworkDir = Resolve-PathRelativeToProjectRoot `
                             -Path $EntityFrameworkDir `
                             -ErrorMsg "Directory that should contain Entity Framework '$entityFrameworkDir' does not exist (package '$packageName'). Tried following absolute path: '{0}'."

    $OutputPath = Resolve-PathRelativeToProjectRoot `
                            -Path $OutputPath `
                            -DefaultPath (Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName) `
                            -CheckExistence:$false

    if (![string]::IsNullOrEmpty($ProjectPath) -and !(Test-Path -Path $ProjectPath)) {
        Write-Log -Critical "Given project file '$ProjectPath' does not exist for '$PackageName'."
    }
    
    #Check if migrate.exe exists in output folder
    $migrateExePath = Join-Path -Path $MigrationsDir -ChildPath "migrate.exe"

    if (!(Test-Path -Path $migrateExePath)) {
        $migrateExePath = Join-Path -Path $EntityFrameworkDir -ChildPath "tools\migrate.exe"
        if (!(Test-Path -Path $migrateExePath)) {
            Write-Log -Critical "Migrate.exe does not exist at '$migrateExePath' or '$migrationsDir\migrate.exe' (package '$PackageName')."
        }
    }

    $resolvedAddFilesToPackage = @()
    if ($AddFilesToPackage) {
        foreach ($addFileToPackage in $AddFilesToPackage.GetEnumerator()) {
            # SuppressScriptCop - adding small arrays is ok
            $resolvedAddFilesToPackage += Resolve-PathRelativeToProjectRoot -Path ($addFileToPackage.Value) -ErrorMsg "Additional file to package '$addFileToPackage' does not exist (package '$packageName')."
        }
    }

    if (![string]::IsNullOrEmpty($ProjectPath)){
        if ($RestoreNuGet) {
            Write-Log -Info "Restoring nuget packages for package '$PackageName'." -Emphasize
            Start-NugetRestore -ProjectPath $ProjectPath
        }
        Invoke-MsBuild -ProjectPath $ProjectPath -MsBuildOptions $MsBuildOptions
    }

    Write-Log -Info "Packaging '$PackageName'." -Emphasize
    [void](New-Item -Path $OutputPath -ItemType Directory -Force)
    [void](Copy-Item -Path "$migrationsDir\*.dll" -Destination $OutputPath)
    [void](Copy-Item -Path "$migrateExePath" -Destination $OutputPath)
    if ($resolvedAddFilesToPackage) {
        Copy-Item -Path $resolvedAddFilesToPackage -Destination $OutputPath
    }

    $outputFile = Join-Path -Path $OutputPath -ChildPath "$packageName.zip"
    Compress-With7Zip -PathsToCompress "*" -OutputFile $outputFile -WorkingDirectory $OutputPath -ArchiveFormat zip
    Remove-Item -Path "$OutputPath\*" -Exclude "*.zip" -Force

}