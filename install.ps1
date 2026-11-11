#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Install-LiteSpec {
    $projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $sourceRoot = Join-Path $projectRoot 'steps'
    $folders = @('litespec-explore', 'litespec-propose', 'litespec-apply', 'litespec-modify', 'litespec-verify', 'litespec-archive', 'litespec-shared')
    $files = @('litespec-explore/SKILL.md', 'litespec-propose/SKILL.md',
        'litespec-apply/SKILL.md', 'litespec-modify/SKILL.md', 'litespec-verify/SKILL.md', 'litespec-archive/SKILL.md',
        'litespec-shared/protocol.md',
        'litespec-shared/specification.md', 'litespec-shared/revision.md',
        'litespec-shared/documentation.md', 'litespec-shared/closure.md', 'litespec-shared/verification.md')

    # Check every existing component; never follow junctions or symbolic links.
    function Assert-LocalPath([string]$Path) {
        $full = [System.IO.Path]::GetFullPath($Path)
        $prefix = $projectRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Ruta fuera del proyecto: $full"
        }
        $current = $full
        while ($current -and $current -ne $projectRoot) {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
            if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
                throw "No se admiten enlaces/junctions: $current"
            }
            $current = Split-Path -Parent $current
        }
    }

    Assert-LocalPath $PSCommandPath
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        Assert-LocalPath $source
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Falta: $source" }
    }

    Write-Host "LiteSpec - proyecto: $projectRoot"
    Write-Host '1) Codex  2) Claude Code  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI  7) Gemini CLI  8) Qwen Code  9) Cline  10) Devin Local  11) ADE  12) Zed  13) Minimax Code'
    [string]$choice = Read-Host 'Agente [1-12]'
    $relative = switch (([string]$choice).Trim()) {
        '1' { '.agents/skills' }
        '2' { '.claude/skills' }
        '3' { '.github/skills' }
        '4' { '.cursor/skills' }
        '5' { '.opencode/skills' }
        '6' { '.qoder/skills' }
        '7' { '.gemini/skills' }
        '8' { '.qwen/skills' }
        '9' { '.cline/skills' }
        '10' { '.devin/skills' }
        '11' { '.ade/skills' }
        '12' { '.agents/skills' }
        '13' { '.minimax/skills'}
        default { throw 'Seleccion invalida; no se instalo nada.' }
    }
    $destination = Join-Path $projectRoot $relative
    Assert-LocalPath $destination
    foreach ($folder in $folders) {
        $target = Join-Path $destination $folder
        Assert-LocalPath $target
        if ((Test-Path -LiteralPath $target) -and -not (Test-Path -LiteralPath $target -PathType Container)) {
            throw "No es una carpeta: $target"
        }
    }
    # Preflight every known file before replacing anything; preserve all extras.
    foreach ($file in $files) {
        $target = Join-Path $destination $file
        Assert-LocalPath $target
        if ((Test-Path -LiteralPath $target) -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
            throw "No es un archivo: $target"
        }
    }

    $dataRoot = Join-Path $projectRoot '.litespec'
    Assert-LocalPath $dataRoot
    if ((Test-Path -LiteralPath $dataRoot) -and -not (Test-Path -LiteralPath $dataRoot -PathType Container)) {
        throw "No es una carpeta: $dataRoot"
    }

    foreach ($folder in $folders) {
        [System.IO.Directory]::CreateDirectory((Join-Path $destination $folder)) | Out-Null
    }
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        $target = Join-Path $destination $file
        Assert-LocalPath $target
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target }
        [System.IO.File]::Copy($source, $target, $false)
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
            throw "Fallo la verificacion: $target. Se conservan los originales."
        }
    }
    [System.IO.Directory]::CreateDirectory($dataRoot) | Out-Null
    Write-Host "Instalado y verificado en $destination. Abre una nueva sesion del agente."
    [string]$answer = Read-Host 'Borrar fuentes de steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]'
    if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -notmatch '^(si|s\u00ed|yes|y)$') { return }

    # Delete only verified package files; preserve anything added by the user.
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        $target = Join-Path $destination $file
        Assert-LocalPath $source
        Assert-LocalPath $target
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
            throw "El archivo cambio; se cancela la limpieza: $source"
        }
    }
    foreach ($file in $files) { Remove-Item -LiteralPath (Join-Path $sourceRoot $file) }
    foreach ($folder in $folders) {
        $path = Join-Path $sourceRoot $folder
        if (@(Get-ChildItem -LiteralPath $path -Force).Count -eq 0) {
            [System.IO.Directory]::Delete($path)
        }
    }
    if (@(Get-ChildItem -LiteralPath $sourceRoot -Force).Count -eq 0) {
        [System.IO.Directory]::Delete($sourceRoot)
    }
    Assert-LocalPath $PSCommandPath
    Remove-Item -LiteralPath $PSCommandPath
    Write-Host 'Limpieza terminada. Se conservaron los archivos adicionales, si los habia.'
}

try { Install-LiteSpec } catch {
    Write-Error "Instalacion o limpieza incompleta: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
