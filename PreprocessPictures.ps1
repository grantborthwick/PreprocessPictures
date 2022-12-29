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
    [string[]]$inputDir,
    
    # The output album directory - change these where you're using this script to set up defaults
    [string]$outputDir,
    
    # Whether to run the script actions in whatIf mode
    [switch]$whatIf,

    # Skips auto-updating this script
    [switch]$skipUpdate,

    # Allow the script to fallback to the file date when it can't parse the date from the file, which isn't always accurate
    [switch]$fallbackToFileDate,
    
    # Threshold for flattening the folders that have this many pictures or fewer. Removes these folders and puts the files into the root of the output folder.
    [int]$flattenThreshold = -1
)

$ErrorActionPreference = "Stop"

# $PSScriptRoot isn't always populating in the param default values, so populating the defaults here
if (-not $PsBoundParameters.ContainsKey("inputDir")) {
    $inputDir = @(
        "$PSScriptRoot\*_*",
        "$PSScriptRoot\DCIM\Camera\*_*",
        "$PSScriptRoot\DCIM\*CANON\*_*",
        "$PSScriptRoot\DCIM\*RICOH\*_*"
    )
}
if (-not $PsBoundParameters.ContainsKey("outputDir")) {
    $outputDir = "$PSScriptRoot\albums"
}

# auto-update
if ((-not $skipUpdate) -and (-not (Test-Path "$PSScriptRoot\.git"))) {
    $updated = $false
    $url = "https://raw.githubusercontent.com/grantborthwick/PreprocessPictures/master/$($MyInvocation.MyCommand.Name)"
    try {
        Write-Host "Checking for an update from $url"
        $content = ((((Invoke-RestMethod $url -Headers @{ "Cache-Control" = "no-cache" })) -split "`n") -replace "`r","" -join "`n").Trim()
        $oldContent = ((Get-Content $MyInvocation.MyCommand.Path -Raw) -replace "`r","" -join "`n").Trim()
        if ($content -ne $oldContent) {
            Write-Host "Updating $($MyInvocation.MyCommand.Path) from $url"
            [System.IO.File]::WriteAllText($MyInvocation.MyCommand.Path, $content, [System.Text.UTF8Encoding]::new($false))
            $updated = $true
        }
    } catch {
        Write-Host "Failed to update $($MyInvocation.MyCommand.Path) from $url | $_"
    }
    if ($updated) {
        & $MyInvocation.MyCommand.Path -inputDir $inputDir -outputDir $outputDir -whatIf:$whatIf -skipUpdate
    }
}

Write-Host "Checking $inputDir"
Get-ChildItem $inputDir -file -ErrorAction SilentlyContinue | ForEach-Object {
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
        $dir = if ($_.FullName -match "DCIM") {
            $directoryName = $_.Directory.Name -replace "((CANON)|(Camera)|(RICOH))",""
            "_$directoryName"
        }
        $newPath = "$outputDir\$date\$fullDate ${prefix}${dir}_$number.$extension"
    }
    elseif ($_.Name -match "([0-9]{4})([0-9]{2})([0-9]{2})[-_]([0-9]{2})([0-9]{2})([0-9]{2})") {
        $dateTime = [DateTime]::new($matches[1], $matches[2], $matches[3], $matches[4], $matches[5], $matches[6])
        $date = $dateTime.ToString("yyyy.MM.dd")
        $fullDate = $dateTime.ToString("yyyy.MM.ddTHH.mm.ss")
        $newPath = "$outputDir\$date\$fullDate $($_.Name)"
    }
    elseif (-not $fallbackToFileDate) {
        Write-Host "Failed to parse name for $($_.FullName). Re-run with -fallbackToFileDate to fall back to file date properties" -ForegroundColor Red -BackgroundColor Black
        return
    } else {
        $item = Get-Item $_.FullName
        $earliestDate = @($item.CreationTime, $item.LastWriteTime) | Where-Object {
            ($_.ToUniversalTime() -le [DateTime]::UtcNow) -and
            ($_.Year -gt 1970)
        } | Sort-Object | Select-Object -First 1
        if ($null -eq $earliestDate) {
            Write-Host "Failed to parse name for $($_.FullName)" -ForegroundColor Red -BackgroundColor Black
            return
        }
        $dateTime = $earliestDate
        $date = $dateTime.ToString("yyyy.MM.dd")
        $fullDate = $dateTime.ToString("yyyy.MM.ddTHH.mm.ss")
        $newPath = "$outputDir\$date\$fullDate $($_.Name)"
    }
    
    if (-not $whatIf) {
        if (-not (Test-Path "$outputDir\$date")) {
            $null = mkdir "$outputDir\$date"
        }
    }
    
    Write-Host "Moving $($_.FullName) to $newPath"
    Move-Item $_.FullName $newPath -whatIf:$whatIf
}

if ($flattenThreshold -gt 0) {
    Get-ChildItem $outputDir -directory | ForEach-Object {
        [array]$files = Get-ChildItem $_.FullName
        if ($files.Count -le $flattenThreshold) {
            $files | ForEach-Object {
                $newPath = "$outputDir\$($_.Name)"
                Write-Host "Moving $($_.FullName) to $newPath"
                Move-Item $_.FullName $newPath -whatIf:$whatIf
            }
            Remove-Item $_.FullName -whatIf:$whatIf
        }
    }
}
