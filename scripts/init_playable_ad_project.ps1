[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationRoot
)

$ErrorActionPreference = 'Stop'

function Test-ProjectName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    if ($Name -eq '.' -or $Name -eq '..') {
        return $false
    }

    if ($Name.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        return $false
    }

    if ($Name.Contains([System.IO.Path]::DirectorySeparatorChar) -or
        $Name.Contains([System.IO.Path]::AltDirectorySeparatorChar)) {
        return $false
    }

    return $true
}

if (-not (Test-ProjectName -Name $ProjectName)) {
    throw "ProjectName must be one valid directory name, not a path."
}

if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
    throw "DestinationRoot must be an existing directory: $DestinationRoot"
}

$resolvedRoot = (Resolve-Path -LiteralPath $DestinationRoot).Path
$targetPath = Join-Path -Path $resolvedRoot -ChildPath $ProjectName

if (Test-Path -LiteralPath $targetPath) {
    throw "Refusing to overwrite or merge the existing target: $targetPath"
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path -Path $skillRoot -ChildPath 'assets\project-template'

if (-not (Test-Path -LiteralPath $templateRoot -PathType Container)) {
    throw "Project template is missing: $templateRoot"
}

$expectedTemplateFiles = Get-ChildItem -LiteralPath $templateRoot -Recurse -File | ForEach-Object {
    $_.FullName.Substring($templateRoot.Length).TrimStart('\', '/')
}

$requiredDirectories = @(
    'docs\references',
    'assets\inbox',
    'assets\images',
    'assets\audio',
    'assets\video',
    'assets\fonts',
    'src',
    'tests',
    'tools'
)

$createdTarget = $false
try {
    New-Item -ItemType Directory -Path $targetPath | Out-Null
    $createdTarget = $true

    Get-ChildItem -LiteralPath $templateRoot -Recurse -Force | ForEach-Object {
        $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart('\', '/')
        $destination = Join-Path -Path $targetPath -ChildPath $relativePath

        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
        }
        else {
            $destinationParent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $destinationParent)) {
                New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
            }
            Copy-Item -LiteralPath $_.FullName -Destination $destination
        }
    }

    foreach ($relativeDirectory in $requiredDirectories) {
        $directoryPath = Join-Path -Path $targetPath -ChildPath $relativeDirectory
        if (-not (Test-Path -LiteralPath $directoryPath)) {
            New-Item -ItemType Directory -Path $directoryPath | Out-Null
        }
    }

    $tokens = @{
        '{{PROJECT_NAME}}' = $ProjectName
        '{{CREATED_DATE}}' = (Get-Date -Format 'yyyy-MM-dd')
    }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)

    Get-ChildItem -LiteralPath $targetPath -Recurse -File | Where-Object {
        $_.Extension -in @('.md', '.yaml', '.yml', '.json', '.txt')
    } | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        foreach ($token in $tokens.Keys) {
            $content = $content.Replace($token, $tokens[$token])
        }
        [System.IO.File]::WriteAllText($_.FullName, $content, $utf8Bom)
    }

    foreach ($relativeFile in $expectedTemplateFiles) {
        $filePath = Join-Path -Path $targetPath -ChildPath $relativeFile
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            throw "Initialization verification failed; missing file: $filePath"
        }
    }

    foreach ($relativeDirectory in $requiredDirectories) {
        $directoryPath = Join-Path -Path $targetPath -ChildPath $relativeDirectory
        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            throw "Initialization verification failed; missing directory: $directoryPath"
        }
    }
}
catch {
    if ($createdTarget -and (Test-Path -LiteralPath $targetPath)) {
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }
    throw
}

Write-Output "PROJECT_PATH=$targetPath"
Write-Output "STATUS=initialized"
Write-Output "NEXT=Add source briefs to docs\references and supplied assets to assets\inbox only with user approval."
