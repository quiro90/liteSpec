#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Install-LiteSpec {
    $projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $sourceRoot = Join-Path $projectRoot 'liste.spec.steps'
    $folders = @('litespec-explore', 'litespec-propose', 'litespec-apply', 'litespec-modify', 'litespec-verify', 'litespec-archive', 'litespec-shared')
    $files = @('litespec-explore/SKILL.md', 'litespec-propose/SKILL.md',
        'litespec-apply/SKILL.md', 'litespec-modify/SKILL.md', 'litespec-verify/SKILL.md', 'litespec-archive/SKILL.md',
        'litespec-shared/serial.md', 'litespec-shared/adaptive-plan.md', 'litespec-shared/adaptive-apply.md', 'litespec-shared/easy-worker.md', 'litespec-shared/protocol.md', 'litespec-shared/delegation.md',
        'litespec-shared/specification.md', 'litespec-shared/revision.md',
        'litespec-shared/documentation.md', 'litespec-shared/closure.md', 'litespec-shared/verification.md')

    # Compare the small packaged skill files using the runtime shared by PS 5.1 and 7.
    function Get-PackageDigest([string]$Path) {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { return [Convert]::ToBase64String($sha.ComputeHash([IO.File]::ReadAllBytes($Path))) }
        finally { $sha.Dispose() }
    }

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

    function Update-GitIgnore {
        $ignorePath = Join-Path $projectRoot '.gitignore'
        if (-not (Test-Path -LiteralPath $ignorePath -PathType Leaf)) { return }
        Assert-LocalPath $ignorePath
        Write-Host 'Se encontró un archivo .gitignore.'
        [string]$ignoreAnswer = Read-Host '¿Añadir el instalador (script y carpeta fuente) y las skills de LiteSpec? [y/yes/si/s] Ambos | [i/ins] Solo instalador | [otra respuesta] No'
        $ignoreAnswer = $ignoreAnswer.Trim().ToLowerInvariant()
        if ($ignoreAnswer -notin @('y', 'yes', 'si', 'sí', 's', 'i', 'ins')) { return }
        $entries = @([System.IO.Path]::GetFileName($PSCommandPath), 'liste.spec.steps/')
        if ($ignoreAnswer -notin @('i', 'ins')) {
            foreach ($skillFolder in $folders) { $entries += "$relative/$skillFolder/" }
        }
        $existing = [System.IO.File]::ReadAllText($ignorePath)
        $lines = $existing -split '\r?\n'
        $additions = @()
        $gitAvailable = $null -ne (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)
        foreach ($entry in $entries) {
            $ignored = $false
            $gitStatus = 128
            if ($gitAvailable) {
                $oldPreference = $ErrorActionPreference
                try {
                    $ErrorActionPreference = 'Continue'
                    & git -C $projectRoot check-ignore --no-index -q -- $entry 2>$null
                    $gitStatus = $LASTEXITCODE
                } finally { $ErrorActionPreference = $oldPreference }
            }
            if ($gitStatus -eq 0) { continue }
            if ($gitStatus -ne 1) {
                # Without Git/repository, recognize literal rules and parent directories.
                foreach ($line in $lines) {
                    $rule = $line.TrimEnd([char]13)
                    if (-not $rule -or $rule.StartsWith('#')) { continue }
                    $negated = $rule.StartsWith('!')
                    if ($negated) { $rule = $rule.Substring(1) }
                    $rule = $rule.TrimStart('/').TrimEnd('/')
                    if ($rule -and ($entry.TrimEnd('/') -ceq $rule -or $entry.StartsWith($rule + '/', [System.StringComparison]::Ordinal))) { $ignored = -not $negated }
                }
                if ($ignored) { continue }
            }
            $additions += '/' + $entry
        }
        if ($additions.Count) {
            $newline = if ($existing.Contains("`r`n")) { "`r`n" } else { "`n" }
            $prefix = if ($existing.Length -and -not $existing.EndsWith("`n")) { $newline } else { '' }
            Assert-LocalPath $ignorePath
            [System.IO.File]::AppendAllText($ignorePath, $prefix + ($additions -join $newline) + $newline, (New-Object System.Text.UTF8Encoding($false)))
        }
        Write-Host ".gitignore: $($additions.Count) reglas añadidas; se conserva el contenido existente."
    }

    Assert-LocalPath $PSCommandPath
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        Assert-LocalPath $source
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Falta: $source" }
    }

    Write-Host "LiteSpec - proyecto: $projectRoot"
    Write-Host '1) Codex [Clasico/Adaptive]  2) Claude Code [Clasico/Adaptive]  3) GitHub Copilot [Clasico/Adaptive exp.]  4) Cursor [Clasico/Adaptive exp.]  5) OpenCode [Clasico/Adaptive exp.]  6) Qoder CLI  7) Gemini CLI [Clasico/Adaptive exp.]  8) Qwen Code [Clasico/Adaptive exp.]  9) Cline  10) Devin Local  11) ADE  12) Zed  13) MiniMax Code'
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
    $legacyMarker = $null
    $agentNames = @('Codex', 'Claude Code', 'GitHub Copilot', 'Cursor', 'OpenCode', 'Qoder CLI', 'Gemini CLI', 'Qwen Code', 'Cline', 'Devin Local', 'ADE', 'Zed', 'MiniMax Code')
    $agentName = $agentNames[[int]$choice.Trim() - 1]
    $modeLabel = 'Clasico'
    $enable = $false
    $created = 0; $restored = 0; $preserved = 0; $savedCount = 0
    if ($choice.Trim() -in @('1', '2')) {
        Write-Host 'Ejecucion de pasos: 1) Clasico [predeterminado]  2) Adaptive - delegar pasos Easy'
        [string]$mode = Read-Host 'Modo [1]'
        if ($mode.Trim() -notin @('', '1', '2')) { throw 'Modo invalido.' }
        $adaptive = $mode.Trim() -eq '2'
        Write-Host 'Delegacion interna de las skills: 1) Desactivada  2) Auto model por rol'
        $roleDefault = if (Test-Path -LiteralPath (Join-Path $destination 'litespec-shared/delegation-active.md') -PathType Leaf) { '2' } else { '1' }
        [string]$roleChoice = Read-Host "Roles [$roleDefault]"
        if (-not $roleChoice.Trim()) { $roleChoice = $roleDefault }
        if ($roleChoice.Trim() -notin @('1','2')) { throw 'Opcion de roles invalida.' }
        $roleMode = $roleChoice.Trim() -eq '2'
        $enable = $roleMode
        if ($adaptive) { $modeLabel = 'Adaptive' }
        if ($roleMode) { $modeLabel += ' + Auto model' }
        $adapter = if ($choice.Trim() -eq '1') { 'codex' } else { 'claude' }
        $extension = if ($adapter -eq 'codex') { 'toml' } else { 'md' }
        $agentRoot = Join-Path $projectRoot ".$adapter/agents"
        $disabledRoot = Join-Path $dataRoot "disabled-agents/$adapter"
        # Remove the marker first when disabling and install it last when enabling.
        # The retired implement role is only ever moved out of the active directory.
        $roles = if ($enable) { @('implement', 'search', 'plan', '') } else { @('', 'implement', 'search', 'plan') }
        $roles += 'easy'
        foreach ($role in $roles) {
            $enable = if ($role -eq 'easy') { $adaptive } elseif ($role -eq 'implement') { $false } else { $roleMode }
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
                if ($hasActive) { $nativeFiles += @{ Path = $saved; Source = $active; Restore = $false } }
                continue
            }
            # A marker from an older release names the retired implement role: regenerate it.
            if (-not $role) {
                foreach ($path in @($active, $saved)) {
                    if ((Test-Path -LiteralPath $path -PathType Leaf) -and ([System.IO.File]::ReadAllText($path) -match 'litespec-implement')) { $legacyMarker = $path }
                }
            }
            if ($hasActive -and $legacyMarker -ne $active) {
                $preserved++
                Write-Host "Se conserva: $active"
                continue
            }
            if ($hasSaved -and $legacyMarker -ne $saved) {
                $nativeFiles += @{ Path = $active; Source = $saved; Restore = $true }
                continue
            }
            if (-not $role) {
                $content = "# Experimental - native delegation enabled`nAdapter: $adapter. Use litespec-search and litespec-plan when useful under delegation.md. Native definitions: .$adapter/agents/litespec-{search,plan}.$extension. Model/effort support is not validated by installation. On failure inform and continue with current agent within authorization. No guaranteed token savings.`n"
            } else {
                $defaultModel = if ($role -ne 'easy') { '' } elseif ($adapter -eq 'codex') { 'gpt-6.2-sol' } else { 'sonnet' }
                [string]$model = Read-Host "$role - modelo [$defaultModel]"
                if (-not $model.Trim()) { $model = $defaultModel }
                $model = $model.Trim()
                if ($model -and $model -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$') { throw 'Identificador de modelo invalido.' }
                [string]$effort = Read-Host "$role - esfuerzo compatible"
                $effort = $effort.Trim()
                $allowed = if ($adapter -eq 'codex') { @('', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max', 'ultra') } else { @('', 'low', 'medium', 'high', 'xhigh', 'max') }
                if ($effort -notin $allowed) { throw 'Esfuerzo invalido. Compatibilidad depende del modelo y cliente.' }
                $description = switch ($role) {
                    'easy' { 'Execute only the Easy step explicitly assigned by the LiteSpec parent.' }
                    'search' { 'Gather concrete evidence with paths and lines; do not edit or decide scope.' }
                    'plan' { 'Analyze evidence and return a proposal; do not edit or implement.' }
                }
                if ($role -eq 'easy') {
                    $instructions = "Follow $relative/litespec-shared/easy-worker.md for the assigned step. Do not delegate."
                } else {
                    $instructions = "$description Read applicable AGENTS.md and $relative/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work."
                }
                if ($adapter -eq 'codex') {
                    $content = "name = `"litespec-$role`"`ndescription = `"$description`"`ndeveloper_instructions = `"$instructions`"`n"
                    if ($model) { $content += "model = `"$model`"`n" }
                    if ($effort) { $content += "model_reasoning_effort = `"$effort`"`n" }
                } else {
                    $content = "---`nname: litespec-$role`ndescription: $description`n"
                    if ($model) { $content += "model: '$model'`n" }
                    if ($effort) { $content += "effort: $effort`n" }
                    if ($role -ne 'easy') { $content += "tools: Read, Grep, Glob`n" }
                    $content += "---`n`n$instructions`n"
                }
            }
            $nativeFiles += @{ Path = $active; Content = $content }
        }
    } elseif ($choice.Trim() -in @('3', '4', '5', '7', '8')) {
        # Experimental Adaptive for other clients: an Easy worker plus a marker naming this client.
        # Codex and Claude Code keep their own branch above, unchanged.
        Write-Host 'Ejecucion de pasos: 1) Clasico [predeterminado]  2) Adaptive experimental - delegar pasos Easy'
        [string]$mode = Read-Host 'Modo [1]'
        if ($mode.Trim() -notin @('', '1', '2')) { throw 'Modo invalido.' }
        $adaptive = $mode.Trim() -eq '2'
        if ($adaptive) { $modeLabel = 'Adaptive experimental' }
        $spec = @{
            '3' = @('copilot', '.github/agents', 'litespec-easy.agent.md', 'through the native subagent or custom-agent delegation of the current surface (VS Code, Copilot CLI or other)')
            '4' = @('cursor', '.cursor/agents', 'litespec-easy.md', 'through native subagent delegation')
            '5' = @('opencode', '.opencode/agents', 'litespec-easy.md', 'through native subagent delegation')
            '7' = @('gemini', '.gemini/agents', 'litespec-easy.md', 'through its native subagent tool')
            '8' = @('qwen', '.qwen/agents', 'litespec-easy.md', 'through native subagent delegation')
        }[$choice.Trim()]
        $adapter = $spec[0]; $agentDir = $spec[1]; $easyFile = $spec[2]; $invoke = $spec[3]
        $agentRoot = Join-Path $projectRoot $agentDir
        $disabledRoot = Join-Path $dataRoot "disabled-agents/$adapter"
        # Install the worker before the marker; remove the marker before the worker.
        $targets = @(
            @{ Name = $easyFile; Active = (Join-Path $agentRoot $easyFile) },
            @{ Name = 'adaptive-active.md'; Active = (Join-Path $destination 'litespec-shared/adaptive-active.md') }
        )
        if (-not $adaptive) { [array]::Reverse($targets) }
        foreach ($target in $targets) {
            $name = $target.Name
            $active = $target.Active
            if (-not $adaptive -and -not (Get-Item -LiteralPath $active -Force -ErrorAction SilentlyContinue)) { continue }
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
            if (-not $adaptive) {
                if ($hasActive) { $nativeFiles += @{ Path = $saved; Source = $active; Restore = $false } }
                continue
            }
            if ($hasActive) {
                $preserved++
                Write-Host "Se conserva: $active"
                continue
            }
            if ($hasSaved) {
                $nativeFiles += @{ Path = $active; Source = $saved; Restore = $true }
                continue
            }
            if ($name -eq 'adaptive-active.md') {
                $content = "# Experimental - Adaptive execution enabled`nClient: $agentName. Easy worker: $agentDir/$easyFile. Only $agentName uses this marker; any other client ignores it and the Adaptive rules. Invoke the litespec-easy subagent $invoke. Model support is not validated by installation; if the worker is unavailable, follow adaptive-apply.md.`n"
            } else {
                if ($adapter -eq 'copilot') { Write-Host 'Copilot: VS Code usa nombres como "Claude Sonnet 4.5 (copilot)"; Copilot CLI usa IDs como "claude-sonnet-4.5".' }
                [string]$model = Read-Host 'easy - modelo [vacio = predeterminado del cliente]'
                $model = $model.Trim()
                $pattern = switch ($adapter) {
                    'copilot'  { '^[a-zA-Z0-9][a-zA-Z0-9 ._:/()-]*$' }
                    'cursor'   { '^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(\[([a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+(,[a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+)*)?\])?$' }
                    'opencode' { '^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(#[a-zA-Z0-9][a-zA-Z0-9._-]*)?$' }
                    default    { '^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$' }
                }
                if ($model -and $model -notmatch $pattern) { throw 'Identificador de modelo invalido.' }
                $description = 'Execute only the Easy step explicitly assigned by the LiteSpec parent.'
                $content = "---`n"
                if ($adapter -ne 'opencode') { $content += "name: litespec-easy`n" }
                $content += "description: $description`n"
                if ($adapter -eq 'opencode') { $content += "mode: subagent`n" }
                if ($adapter -eq 'gemini') { $content += "kind: local`n" }
                if ($model) { $content += "model: '$model'`n" }
                $content += "---`n`nFollow $relative/litespec-shared/easy-worker.md for the assigned step. Do not delegate.`n"
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
        if ((Get-PackageDigest $source) -cne (Get-PackageDigest $target)) {
            throw "Fallo la verificacion: $target. Se conservan los originales."
        }
    }
    [System.IO.Directory]::CreateDirectory($dataRoot) | Out-Null
    if ($legacyMarker) { Assert-LocalPath $legacyMarker; Remove-Item -LiteralPath $legacyMarker }
    foreach ($native in $nativeFiles) {
        Assert-LocalPath $native.Path
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $native.Path)) | Out-Null
        if ($native.ContainsKey('Source')) {
            Assert-LocalPath $native.Source
            [System.IO.File]::Move($native.Source, $native.Path)
            if ($native.Restore) { $restored++ } else { $savedCount++ }
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
    if ($modeLabel -ne 'Clasico') { Write-Host "Configuracion: $agentRoot. Modelos no comprobados en ejecucion; confirma su carga en el cliente." }
    Write-Host 'Abre una nueva sesion del agente para aplicar el modo.'
    [string]$answer = Read-Host 'Borrar fuentes de liste.spec.steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]'
    if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -notmatch '^(si|s\u00ed|yes|y)$') { Update-GitIgnore; return }

    # Delete only verified package files; preserve anything added by the user.
    foreach ($file in $files) {
        $source = Join-Path $sourceRoot $file
        $target = Join-Path $destination $file
        Assert-LocalPath $source
        Assert-LocalPath $target
        if ((Get-PackageDigest $source) -cne (Get-PackageDigest $target)) {
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
    Update-GitIgnore
}

try { Install-LiteSpec } catch {
    Write-Error "Instalacion o limpieza incompleta: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
