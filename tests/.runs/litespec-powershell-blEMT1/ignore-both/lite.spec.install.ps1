#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Install-LiteSpec {
    $projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $sourceRoot = Join-Path $projectRoot 'liste.spec.steps'
    $folders = @('litespec-explore', 'litespec-propose', 'litespec-apply', 'litespec-modify', 'litespec-verify', 'litespec-archive', 'litespec-shared')
    $files = @('litespec-explore/SKILL.md', 'litespec-propose/SKILL.md',
        'litespec-apply/SKILL.md', 'litespec-modify/SKILL.md', 'litespec-verify/SKILL.md', 'litespec-archive/SKILL.md',
        'litespec-shared/protocol.md', 'litespec-shared/delegation.md',
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
            if ($item -and $current -ne $full -and -not $item.PSIsContainer) {
                throw "No es una carpeta: $current"
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
    Write-Host '1) Codex  2) Claude Code  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI  7) Gemini CLI  8) Qwen Code  9) Cline  10) Devin Local  11) ADE  12) Zed  13) MiniMax Code'
    [string]$choice = Read-Host 'Agente [1-13]'
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
        '13' { '.minimax/skills' }
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

    # Collect and validate optional configuration before writing anything.
    $nativeFiles = @()
    $agentNames = @('Codex', 'Claude Code', 'GitHub Copilot', 'Cursor', 'OpenCode', 'Qoder CLI', 'Gemini CLI', 'Qwen Code', 'Cline', 'Devin Local', 'ADE', 'Zed', 'MiniMax Code')
    $agentName = $agentNames[[int]$choice.Trim() - 1]
    $modeLabel = 'Normal'
    $enable = $false
    $created = 0; $restored = 0; $preserved = 0; $savedCount = 0
    if ($choice.Trim() -in @('1', '2')) {
        Write-Host '1) Normal - sin delegacion de LiteSpec [predeterminado]  2) Auto model experimental - modelos por rol'
        Write-Host 'Normal desactiva Auto model para este agente. Auto model puede aumentar el consumo de tokens.'
        [string]$mode = Read-Host 'Opcion [1]'
        if ($mode.Trim() -notin @('', '1', '2')) { throw 'Opcion invalida; no se instalo nada.' }
        $enable = $mode.Trim() -eq '2'
        if ($enable) {
            $modeLabel = 'Auto model experimental - modelos por rol'
            Write-Host 'Ejemplos por dificultad (modelo / esfuerzo, segun disponibilidad)'
            Write-Host '  Facil (buscar archivos)        | Codex: gpt-6-luna / medium   | Claude Code: haiku / medium'
            Write-Host '  Media (plan o cambio acotado)   | Codex: gpt-6.1-sol / medium  | Claude Code: sonnet / medium'
            Write-Host '  Pesada (depuracion compleja)   | Codex: gpt-6-astra / medium  | Claude Code: opus / medium'
            Write-Host 'Usa la columna de tu agente. Enter usa la herencia/default del cliente; no elige modelos por dificultad.'
        }
        $adapter = if ($choice.Trim() -eq '1') { 'codex' } else { 'claude' }
        $extension = if ($adapter -eq 'codex') { 'toml' } else { 'md' }
        $agentRoot = Join-Path $projectRoot ".$adapter/agents"
        $disabledRoot = Join-Path $dataRoot "disabled-agents/$adapter"
        # Remove the marker first when disabling and install it last when enabling.
        $roles = if ($enable) { @('search', 'plan', 'implement', '') } else { @('', 'search', 'plan', 'implement') }
        foreach ($role in $roles) {
            if ($role) {
                $name = "litespec-$role.$extension"
                $active = Join-Path $agentRoot $name
            } else {
                $name = 'delegation-active.md'
                $active = Join-Path $destination "litespec-shared/$name"
            }
            if (-not $enable -and -not (Get-Item -LiteralPath $active -Force -ErrorAction SilentlyContinue)) {
                continue
            }
            $saved = Join-Path $disabledRoot $name
            foreach ($path in @($active, $saved)) {
                Assert-LocalPath $path
                if ((Test-Path -LiteralPath $path) -and -not (Test-Path -LiteralPath $path -PathType Leaf)) {
                    throw "No es un archivo: $path"
                }
            }
            $hasActive = Test-Path -LiteralPath $active
            $hasSaved = Test-Path -LiteralPath $saved
            if ($hasActive -and $hasSaved) { throw "Existen ambas configuraciones: $active y $saved. Revisa cual conservar." }
            if (-not $enable) {
                if ($hasActive) { $nativeFiles += @{ Path = $saved; Source = $active } }
                continue
            }
            if ($hasActive) {
                $preserved++
                Write-Host "Se conserva: $active"
                continue
            }
            if ($hasSaved) {
                $nativeFiles += @{ Path = $active; Source = $saved }
                continue
            }
            if (-not $role) {
                $content = "# Experimental - native delegation enabled`nAdapter: $adapter. Use litespec-search, litespec-plan and litespec-implement when useful under delegation.md. Native definitions: .$adapter/agents/litespec-{search,plan,implement}.$extension. Model/effort support is not validated by installation. On failure inform and continue with current agent within authorization. No guaranteed token savings.`n"
            } else {
                [string]$model = Read-Host "$role - modelo"
                $model = $model.Trim()
                if ($model -and $model -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$') { throw 'Identificador de modelo invalido.' }
                [string]$effort = Read-Host "$role - esfuerzo compatible"
                $effort = $effort.Trim()
                $allowed = if ($adapter -eq 'codex') { @('', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max', 'ultra') } else { @('', 'low', 'medium', 'high', 'xhigh', 'max') }
                if ($effort -notin $allowed) { throw 'Esfuerzo invalido. Compatibilidad depende del modelo y cliente.' }
                $description = switch ($role) {
                    'search' { 'Gather concrete evidence with paths and lines; do not edit or decide scope.' }
                    'plan' { 'Analyze evidence and return a proposal; do not edit or implement.' }
                    'implement' { 'Implement only authorized bounded work and verify its results.' }
                }
                $instructions = "$description Read applicable AGENTS.md and $relative/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work."
                if ($adapter -eq 'codex') {
                    $content = "name = `"litespec-$role`"`ndescription = `"$description`"`ndeveloper_instructions = `"$instructions`"`n"
                    if ($model) { $content += "model = `"$model`"`n" }
                    if ($effort) { $content += "model_reasoning_effort = `"$effort`"`n" }
                } else {
                    $content = "---`nname: litespec-$role`ndescription: $description`n"
                    if ($model) { $content += "model: '$model'`n" }
                    if ($effort) { $content += "effort: $effort`n" }
                    if ($role -ne 'implement') { $content += "tools: Read, Grep, Glob`n" }
                    $content += "---`n`n$instructions`n"
                }
            }
            $nativeFiles += @{ Path = $active; Content = $content }
        }
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
    foreach ($native in $nativeFiles) {
        Assert-LocalPath $native.Path
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $native.Path)) | Out-Null
        if ($native.ContainsKey('Source')) {
            Assert-LocalPath $native.Source
            [System.IO.File]::Move($native.Source, $native.Path)
            if ($enable) { $restored++ } else { $savedCount++ }
            continue
        }
        $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($native.Content)
        $stream = [System.IO.File]::Open($native.Path, [System.IO.FileMode]::CreateNew)
        try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
        if ([System.IO.File]::ReadAllText($native.Path) -cne $native.Content) { throw "Fallo la verificacion: $($native.Path)" }
        $created++
    }
    Write-Host "Agente: $agentName | Modo: $modeLabel"
    Write-Host "Skills copiadas y verificadas en $destination."
    Write-Host "Archivos de configuracion: creados=$created; restaurados=$restored; conservados=$preserved; guardados=$savedCount."
    if ($choice.Trim() -eq '12') { Write-Host 'Zed usa el flujo normal; cualquier configuracion de Codex se conserva y solo aplica en Codex.' }
    if ($enable) { Write-Host "Configuracion: $agentRoot. Modelos no comprobados en ejecucion; confirma su carga en el cliente." }
    Write-Host 'Abre una nueva sesion del agente para aplicar el modo.'
    [string]$answer = Read-Host 'Borrar fuentes de liste.spec.steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]'
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
