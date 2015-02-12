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

function New-Zip {
	<#
	.SYNOPSIS
		Compress file/directory to a zip file.

    .PARAMETER Path
		The path that will be compressed.

	.PARAMETER OutputFile
		The output zip file path.
       
    .PARAMETER Exclude
        Exclude mask.

    .PARAMETER CompressionLevel
        Compression level.

    .PARAMETER Try7zip
        If this flag is on, 7zip is tried first, and .NET libraries are used only if 7zip is not installed.
        If zip is created using .NET libraries it sometimes causes issues - e.g. for MsDeploy (always deletes everything and readds if such .zip is used) or DSC (can't unzip).
        7zip will not be used if passing more than one Path.

	.EXAMPLE
		New-Zip -Path 'C:\test' -OutputPath 'C:\test.zip'

	.EXAMPLE
		New-Zip -Path 'C:\test' -OutputPath 'C:\test.zip' -Exclude 'test.sql'

	#>
	[CmdletBinding()]
    [OutputType([void])]
	param(
		[Parameter(Mandatory=$true)]
		[string[]]
		$Path,

		[Parameter(Mandatory=$true)]
        [string]
		$OutputFile,

        [Parameter(Mandatory=$false)]
        [string[]]
		$Exclude,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Fastest', 'NoCompression', 'Optimal')]
        [string]
        $CompressionLevel = 'Optimal',

        [Parameter(Mandatory=$false)]
        [switch]
        $Try7Zip
	)

    if ($Try7Zip -and $Path.Count -eq 1) {
        $pathTo7Zip = Get-PathTo7Zip
        if ($pathTo7Zip) {
            if ($CompressionLevel -eq 'NoCompression') {
                $7zipCompressionLevel = 'copy'
            } elseif ($CompressionLevel -eq 'Fastest') {
                $7zipCompressionLevel = 'fast'
            } else {
                $7zipCompressionLevel = 'good'
            }
            if (Test-Path -Path $Path[0] -PathType Leaf) {
                $7zipPath = $Path[0]
            } else {
                $7zipPath = '*'
            }
            Compress-With7Zip -PathsToCompress $7zipPath -OutputFile $OutputFile -ExcludeFileNames $Exclude -WorkingDirectory $Path[0] -CompressionLevel $7zipCompressionLevel
            return
        } else {
            Write-Log -_Debug '7-Zip not installed - falling back to .NET. Note msdeploy sync will be slower.'
        }
    }

    try {        
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $fileMode = [System.IO.FileMode]::Create
        $fileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $OutputFile, $fileMode
        $zipArchiveMode = [System.IO.Compression.ZipArchiveMode]::Create
        $zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $fileStream, $zipArchiveMode
    
        Write-Log -Info "Creating archive '$OutputFile'"

        $items = Get-FlatFileList -Path $Path -Exclude $Exclude
        foreach ($item in $items) {
            [void]([System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $item.FullName, $item.RelativePath, $CompressionLevel))
        }
    } finally {
        if ($zipArchive) {
            $zipArchive.Dispose()
        }
        if ($fileStream) {
            $fileStream.Dispose()
        }
        Pop-Location
    }
    
}