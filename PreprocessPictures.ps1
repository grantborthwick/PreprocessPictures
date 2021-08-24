<#
.SYNOPSIS
Script for sorting out pictures taken on a camera or phone into folders to simplify album creation
.DESCRIPTION
Place this script in the root of your SD Card for your camera and run it (right click -> Run with PowerShell to process the pictures currently on the card)
If the format of your pictures is different, or this is your first time, try running it with -whatIf, or create a backup beforehand.
.EXAMPLE
PreprocessPictures.ps1 -whatIf
.EXAMPLE
PreprocessPictures.ps1
.EXAMPLE
PreprocessPictures.ps1 -inputDir "C:\OneDrive\Pictures\Camera Roll" -outputDir "C:\OneDrive\Pictures\albums"
.LINK
https://github.com/grantborthwick/PreprocessPictures/blob/master/PreprocessPictures.ps1
.LICENSE
MIT License

Copyright (c) 2021 Grant Borthwick

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
[CmdletBinding()]
param(
    # The input directories - change these where you're using this script to set up defaults
    [string[]]$inputDir = "$PSScriptRoot\DCIM\Camera\*_*.*", "$PSScriptRoot\DCIM\*CANON\*_*.*"
    
    # The output album directory - change these where you're using this script to set up defaults
    [string]$outputDir = "$PSScriptRoot\albums"
    
    # Whether to run the script actions in whatIf mode
    [switch]$whatIf
)

$ErrorActionPreference = "Stop"

$outputDir = $outputDir
Get-ChildItem $inputDir -file | ForEach-Object {
    $dateTime = if ($_.LastWriteTime -lt $_.CreationTime) { $_.LastWriteTime } else { $_.CreationTime }
    $date = $dateTime.Date.ToString("yyyy.MM.dd")
    $fullDate = $dateTime.ToString("yyyy.MM.ddTHH.mm.ss")
    
    # unix timecode
    if ($_.Name -match "[0-9]{13}") {
        # See https://michlstechblog.info/blog/powershell-convert-unix-timestamp-to-datetime/
        $dateTime = [DateTime]::new(1970, 1,1) + [System.TimeSpan]::FromMilliseconds($matches[0])
        $date = $dateTime.ToString("yyyy.MM.dd")
        $fullDate = $dateTime.ToString("yyyy.MM.ddTHH.mm.ss")
        $newPath = "$outputDir\$date\$fullDate $($_.Name)"
    }
    # file name time from a camera
    elseif ($_.Name -match "(.*)_([0-9]*_?[0-9]*)\.(.*)") {
        $prefix = $matches[1]
        $number = $matches[2]
        $extension = $matches[3]
        $dir = $_.Directory.Name -replace "((CANON)|(Camera))",""
        $newPath = "$outputDir\$date\$fullDate ${prefix}_${dir}_$number.$extension"
    }
    elseif ($_.Name -match "([0-9]{4})([0-9]{2})([0-9]{2})[-_]([0-9]{2})([0-9]{2})([0-9]{2})") {
        $dateTime = [DateTime]::new($matches[1], $matches[2], $matches[3], $matches[4], $matches[5], $matches[6])
        $date = $dateTime.ToString("yyyy.MM.dd")
        $fullDate = $dateTime.ToString("yyyy.MM.ddTHH.mm.ss")
        $newPath = "$outputDir\$date\$fullDate $($_.Name)"
    }
    else {
        Write-Host "Failed to parse name for $($_.FullName)" -ForegroundColor Red -BackgroundColor Black
        return
    }
    
    if (-not $whatIf) {
        if (-not (Test-Path "$outputDir\$date")) {
            $null = mkdir "$outputDir\$date"
        }
    }
    
    Write-Host "Moving $($_.FullName) to $newPath"
    Move-Item $_.FullName $newPath -whatIf:$whatIf
}