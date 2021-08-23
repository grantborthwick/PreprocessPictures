<#
.SYNOPSIS
Script for sorting out pictures taken on a camera or phone into folders to simplify album creation
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
    [switch]$whatIf
)

$ErrorActionPreference = "Stop"

$outputDir = "$PSScriptRoot\albums"
Get-ChildItem "$PSScriptRoot\DCIM\*CANON\*_*.*" -file | ForEach-Object {
    $date = $_.CreationTime.Date.toString("yyyy.MM.dd")
    $fullDate = $_.CreationTime.ToString("yyyy.MM.ddTHH.mm.ss")
    if (-not $whatIf) {
        if (-not (Test-Path "$outputDir\$date")) {
            $null = mkdir "$outputDir\$date"
        }
    }
    if (-not ($_.Name -match "(.*)_([0-9]*)\.(.*)")) {
        throw "Failed to parse name for $($_.FullName)"
    }

    $prefix = $matches[1]
    $dir = $_.Directory.Name -replace "CANON",""
    $number = $matches[2]
    $extension = $matches[3]
    $newPath = "$outputDir\$date\$fullDate ${prefix}_${dir}_$number.$extension"
    Write-Host "Moving $($_.FullName) to $newPath"
    if (-not $whatIf) {
        Move-Item $_.FullName $newPath
    }
}