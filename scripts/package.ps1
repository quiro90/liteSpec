#Requires -Version 7.3
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$')]
    [string]$Version,

    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../dist')
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

function Write-DependencyNotices($OutputPath) {
    $format = '{{with .Module}}{{if not .Main}}{{.Path}} {{.Version}}|{{.Dir}}{{end}}{{end}}'
    $modules = @(go list -buildvcs=false -deps -f $format . | Where-Object { $_ } | Sort-Object -Unique)
    $modules += "Go toolchain|$(go env GOROOT)"
    $notices = foreach ($module in $modules) {
        $name, $directory = $module -split '\|', 2
        foreach ($file in (Get-ChildItem -LiteralPath $directory -File | Where-Object Name -Match '^(LICENSE|COPYING|NOTICE|PATENTS)([.-]|$)' | Sort-Object Name)) {
            "===== $name / $($file.Name) ====="
            (Get-Content -LiteralPath $file.FullName -Raw).TrimEnd()
            ''
        }
    }
    [System.IO.File]::WriteAllText($OutputPath, ($notices -join "`n") + "`n")
}

function Write-UnixArchive($Archive, $Binary, $Files) {
    $archiveStream = [System.IO.File]::Create($Archive)
    try {
        $gzip = [System.IO.Compression.GZipStream]::new($archiveStream, [System.IO.Compression.CompressionLevel]::Optimal, $true)
        try {
            $writer = [System.Formats.Tar.TarWriter]::new($gzip, [System.Formats.Tar.TarEntryFormat]::Ustar, $true)
            try {
                foreach ($file in $Files) {
                    $entry = [System.Formats.Tar.UstarTarEntry]::new('RegularFile', (Split-Path -Leaf $file))
                    $entry.Mode = if ($file -eq $Binary) {
                        [System.IO.UnixFileMode]'UserRead, UserWrite, UserExecute, GroupRead, GroupExecute, OtherRead, OtherExecute'
                    } else {
                        [System.IO.UnixFileMode]'UserRead, UserWrite, GroupRead, OtherRead'
                    }
                    $entry.DataStream = [System.IO.File]::OpenRead($file)
                    try { $writer.WriteEntry($entry) } finally { $entry.DataStream.Dispose() }
                }
            } finally {
                $writer.Dispose()
            }
        } finally {
            $gzip.Dispose()
        }
    } finally {
        $archiveStream.Dispose()
    }
}

$output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
$repo = Split-Path -Parent $PSScriptRoot
$targets = @{
    windows = @('amd64', 'arm64')
    darwin = @('amd64', 'arm64')
    linux = @('amd64', 'arm64')
}
$archives = @()
$savedEnvironment = @{
    CGO_ENABLED = $env:CGO_ENABLED
    GOOS = $env:GOOS
    GOARCH = $env:GOARCH
}
$stage = [System.IO.Directory]::CreateTempSubdirectory('litespec-package-').FullName
$license = Join-Path $stage 'LICENSE'
$notices = Join-Path $stage 'THIRD_PARTY_LICENSES.txt'
$manifest = Join-Path $stage 'SHA256SUMS.txt'
Push-Location -LiteralPath $repo
try {
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination $license
    $env:CGO_ENABLED = '0'
    foreach ($platform in @('windows', 'darwin', 'linux')) {
        $env:GOOS = $platform
        $binaryName = if ($platform -eq 'windows') { 'litespec.exe' } else { 'litespec' }
        $binary = Join-Path $stage $binaryName
        foreach ($arch in $targets[$platform]) {
            $env:GOARCH = $arch
            go build -trimpath -buildvcs=false -ldflags "-s -w -X main.version=$Version" -o $binary .
            Write-DependencyNotices $notices
            $name = "litespec-$Version-$platform-$arch"
            $extension = if ($platform -eq 'windows') { 'zip' } else { 'tar.gz' }
            $archive = Join-Path $stage "$name.$extension"
            $archives += $archive
            $contents = @($binary, $license, $notices)
            if ($platform -eq 'windows') {
                Compress-Archive -LiteralPath $contents -DestinationPath $archive -Force
            } else {
                Write-UnixArchive $archive $binary $contents
            }
        }
        Remove-Item -LiteralPath $binary
    }
    $checksums = foreach ($archive in $archives) {
        $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $(Split-Path -Leaf $archive)"
    }
    [System.IO.File]::WriteAllText($manifest, ($checksums -join "`n") + "`n")
    foreach ($asset in ($archives + $manifest)) {
        [System.IO.File]::Move($asset, (Join-Path $output (Split-Path -Leaf $asset)), $true)
    }
    Write-Host "LiteSpec $Version empaquetado en $output"
} finally {
    Pop-Location
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
    $stagedFiles = $archives + @($manifest, $license, $notices, (Join-Path $stage 'litespec'), (Join-Path $stage 'litespec.exe'))
    foreach ($file in $stagedFiles) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
    }
    [System.IO.Directory]::Delete($stage)
}
