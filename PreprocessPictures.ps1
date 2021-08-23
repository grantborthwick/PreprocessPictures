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
    [switch]$whatIf,
    [string[]]$inputDir = "$PSScriptRoot\DCIM\Camera\*_*.*", "$PSScriptRoot\DCIM\*CANON\*_*.*"
    [string]$outputDir = "$PSScriptRoot\albums"
)

$ErrorActionPreference = "Stop"

$outputDir = $outputDir
Get-ChildItem $inputDir -file | ForEach-Object {
    $date = $_.CreationTime.Date.toString("yyyy.MM.dd")
    $fullDate = $_.CreationTime.ToString("yyyy.MM.ddTHH.mm.ss")
    if (-not $whatIf) {
        if (-not (Test-Path "$outputDir\$date")) {
            $null = mkdir "$outputDir\$date"
        }
    }
    if ($_.Name -notmatch "(.*)_([0-9]*_?[0-9]*)\.(.*)") {
        throw "Failed to parse name for $($_.FullName)"
    }

    $prefix = $matches[1]
    $dir = $_.Directory.Name -replace "CANON",""
    $number = $matches[2]
    $extension = $matches[3]
    $newPath = "$outputDir\$date\$fullDate ${prefix}_${dir}_$number.$extension"
    Write-Host "Moving $($_.FullName) to $newPath"
    Move-Item $_.FullName $newPath -whatIf:$whatIf
}