#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Install-SpecLite {
    $projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $sourceRoot = Join-Path $projectRoot 'steps'
    $folders = @('speclite-explore', 'speclite-propose', 'speclite-apply', 'speclite-modify', 'speclite-shared')
    $files = @('speclite-explore/SKILL.md', 'speclite-propose/SKILL.md',
        'speclite-apply/SKILL.md', 'speclite-modify/SKILL.md', 'speclite-shared/protocol.md', 'speclite-shared/LICENSE')

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

    Write-Host "SpecLite - proyecto: $projectRoot"
    Write-Host '1) Codex  2) Claude Code  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI'
    [string]$choice = Read-Host 'Agente [1-6]'
    $relative = switch (([string]$choice).Trim()) {
        '1' { '.agents/skills' }
        '2' { '.claude/skills' }
        '3' { '.github/skills' }
        '4' { '.cursor/skills' }
        '5' { '.opencode/skills' }
        '6' { '.qoder/skills' }
        default { throw 'Seleccion invalida; no se instalo nada.' }
    }
    $destination = Join-Path $projectRoot $relative
    Assert-LocalPath $destination
    foreach ($folder in $folders) {
        $target = Join-Path $destination $folder
        Assert-LocalPath $target
        if (Test-Path -LiteralPath $target) { throw "Ya existe $target. No se sobrescribe." }
    }

    foreach ($folder in $folders) {
        [System.IO.Directory]::CreateDirectory((Join-Path $destination $folder)) | Out-Null
    }
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        $target = Join-Path $destination $file
        [System.IO.File]::Copy($source, $target, $false)
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
            throw "Fallo la verificacion: $target. Se conservan los originales."
        }
    }
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

try { Install-SpecLite } catch {
    Write-Error "Instalacion o limpieza incompleta: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
