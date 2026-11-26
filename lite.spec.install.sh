#!/usr/bin/env bash
# Compatible with Bash 3.2 (macOS) and newer; no external runtime required.
set -euo pipefail

main() {
    if [[ -L "${BASH_SOURCE[0]}" ]]; then
        printf '%s\n' 'No ejecutes el instalador mediante un enlace simbolico.' >&2
        return 1
    fi
    local project_root script_path source_root choice relative destination data_root answer file folder path
    project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    script_path="$project_root/$(basename -- "${BASH_SOURCE[0]}")"
    source_root="$project_root/liste.spec.steps"
    local folders=(litespec-explore litespec-propose litespec-apply litespec-modify litespec-verify litespec-archive litespec-shared)
    local files=(litespec-explore/SKILL.md litespec-propose/SKILL.md
        litespec-apply/SKILL.md litespec-modify/SKILL.md litespec-verify/SKILL.md litespec-archive/SKILL.md
        litespec-shared/serial.md litespec-shared/adaptive-plan.md litespec-shared/adaptive-apply.md litespec-shared/easy-worker.md
        litespec-shared/protocol.md litespec-shared/delegation.md
        litespec-shared/specification.md litespec-shared/revision.md
        litespec-shared/documentation.md litespec-shared/closure.md litespec-shared/verification.md)

    assert_local_path() {
        local current=$1
        case "$current" in
            "$project_root"/*) ;;
            *) printf 'Ruta fuera del proyecto: %s\n' "$current" >&2; return 1 ;;
        esac
        while [[ "$current" != "$project_root" ]]; do
            if [[ -L "$current" ]]; then
                printf 'No se admiten enlaces simbolicos: %s\n' "$current" >&2
                return 1
            fi
            if [[ "$current" != "$1" && -e "$current" && ! -d "$current" ]]; then
                printf 'No es una carpeta: %s\n' "$current" >&2
                return 1
            fi
            current=$(dirname -- "$current")
        done
    }

    update_gitignore() {
        local ignore_path="$project_root/.gitignore" ignore_answer entry line rule negated ignored git_status
        local existing last_char newline=$'\n' addition_count=0
        local entries=() additions=('')
        [[ -f "$ignore_path" ]] || return 0
        assert_local_path "$ignore_path"
        printf '%s\n' 'Se encontró un archivo .gitignore.'
        read -r -p '¿Añadir el instalador (script y carpeta fuente) y las skills de LiteSpec? [y/yes/si/s] Ambos | [i/ins] Solo instalador | [otra respuesta] No: ' ignore_answer || ignore_answer=''
        case "$ignore_answer" in
            [yY]|[yY][eE][sS]|[sS][iI]|[sS][íÍ]|[sS]) entries=("$(basename -- "$script_path")" 'liste.spec.steps/');
                for folder in "${folders[@]}"; do entries+=("$relative/$folder/"); done ;;
            [iI]|[iI][nN][sS]) entries=("$(basename -- "$script_path")" 'liste.spec.steps/') ;;
            *) return 0 ;;
        esac
        existing=$(cat -- "$ignore_path"; printf x) # Keep final newlines for CRLF detection.
        [[ "$existing" != *$'\r\n'* ]] || newline=$'\r\n'
        for entry in "${entries[@]}"; do
            git_status=128
            if command -v git >/dev/null 2>&1; then
                if git -C "$project_root" check-ignore --no-index -q -- "$entry" 2>/dev/null; then git_status=0; else git_status=$?; fi
            fi
            [[ "$git_status" != 0 ]] || continue
            if [[ "$git_status" != 1 ]]; then
                # Without Git/repository, recognize literal rules and parent directories.
                ignored=false
                while IFS= read -r line || [[ -n "$line" ]]; do
                    rule=${line%$'\r'}
                    [[ -n "$rule" && "$rule" != \#* ]] || continue
                    negated=false
                    if [[ "$rule" == \!* ]]; then negated=true; rule=${rule#\!}; fi
                    rule=${rule#/}; rule=${rule%/}
                    if [[ -n "$rule" && ( "${entry%/}" == "$rule" || "$entry" == "$rule/"* ) ]]; then
                        if [[ "$negated" == true ]]; then ignored=false; else ignored=true; fi
                    fi
                done < "$ignore_path"
                [[ "$ignored" != true ]] || continue
            fi
            additions+=("/$entry")
            addition_count=$((addition_count+1))
        done
        if [[ "$addition_count" != 0 ]]; then
            assert_local_path "$ignore_path"
            # Preserve existing bytes, including files without a final newline.
            last_char=$(tail -c 1 -- "$ignore_path"; printf x)
            if [[ -s "$ignore_path" && "$last_char" != $'\nx' ]]; then printf '%s' "$newline" >> "$ignore_path"; fi
            for ((i=1; i<${#additions[@]}; i++)); do printf '%s%s' "${additions[$i]}" "$newline" >> "$ignore_path"; done
        fi
        printf '.gitignore: %s reglas añadidas; se conserva el contenido existente.\n' "$addition_count"
    }

    for file in "${files[@]}"; do
        assert_local_path "$source_root/$file"
        if [[ ! -f "$source_root/$file" ]]; then
            printf 'Falta: %s\n' "$source_root/$file" >&2
            return 1
        fi
    done
    printf 'LiteSpec - proyecto: %s\n' "$project_root"
    printf '%s\n' '1) Codex [Clasico/Adaptive]  2) Claude Code [Clasico/Adaptive]  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI  7) Gemini CLI  8) Qwen Code  9) Cline  10) Devin Local  11) ADE  12) Zed  13) MiniMax Code'
    read -r -p 'Agente [1-13]: ' choice || return 1
    case "$choice" in
        1) relative=.agents/skills ;;
        2) relative=.claude/skills ;;
        3) relative=.github/skills ;;
        4) relative=.cursor/skills ;;
        5) relative=.opencode/skills ;;
        6) relative=.qoder/skills ;;
        7) relative=.gemini/skills ;;
        8) relative=.qwen/skills ;;
        9) relative=.cline/skills ;;
        10) relative=.devin/skills ;;
        11) relative=.ade/skills ;;
        12) relative=.agents/skills ;;
        13) relative=.minimax/skills ;;
        *) printf '%s\n' 'Seleccion invalida; no se instalo nada.' >&2; return 1 ;;
    esac
    destination="$project_root/$relative"
    assert_local_path "$destination"
    for folder in "${folders[@]}"; do
        assert_local_path "$destination/$folder"
        if [[ -e "$destination/$folder" && ! -d "$destination/$folder" ]]; then
            printf 'No es una carpeta: %s\n' "$destination/$folder" >&2
            return 1
        fi
    done
    # Preflight every known file before replacing anything; preserve all extras.
    for file in "${files[@]}"; do
        assert_local_path "$destination/$file"
        if [[ -e "$destination/$file" && ! -f "$destination/$file" ]]; then
            printf 'No es un archivo: %s\n' "$destination/$file" >&2
            return 1
        fi
    done
    data_root="$project_root/.litespec"
    assert_local_path "$data_root"
    if [[ -e "$data_root" && ! -d "$data_root" ]]; then
        printf 'No es una carpeta: %s\n' "$data_root" >&2
        return 1
    fi
    # Collect optional files in memory; validate all paths before writing.
    # A sentinel avoids empty-array nounset behavior in older Bash releases.
    local native_paths=('') native_contents=('') native_sources=('') roles=() legacy_marker=''
    local mode adapter extension agent_root disabled_root role name model effort description instructions content active saved i
    local agent_names=('Codex' 'Claude Code' 'GitHub Copilot' 'Cursor' 'OpenCode' 'Qoder CLI' 'Gemini CLI' 'Qwen Code' 'Cline' 'Devin Local' 'ADE' 'Zed' 'MiniMax Code')
    local agent_name=${agent_names[$((choice-1))]} mode_label=Clasico
    local created=0 restored=0 preserved=0 saved_count=0
    if [[ "$choice" == 1 || "$choice" == 2 ]]; then
        printf '%s\n' 'Ejecucion de pasos: 1) Clasico [predeterminado]  2) Adaptive - delegar pasos Easy'
        read -r -p 'Modo [1]: ' mode || return 1
        local role_mode=0 adaptive=0 enable default_model role_choice role_default=1
        case "$mode" in ''|1) ;; 2) adaptive=1; mode_label=Adaptive ;; *) printf '%s\n' 'Modo invalido.' >&2; return 1 ;; esac
        printf '%s\n' 'Delegacion interna de las skills: 1) Desactivada  2) Auto model por rol'
        if [[ -f "$destination/litespec-shared/delegation-active.md" ]]; then role_default=2; fi
        read -r -p "Roles [$role_default]: " role_choice || return 1
        case "${role_choice:-$role_default}" in 1) ;; 2) role_mode=1; mode_label+=' + Auto model' ;; *) printf '%s\n' 'Opcion de roles invalida.' >&2; return 1 ;; esac
        if [[ "$choice" == 1 ]]; then adapter=codex; extension=toml; else adapter=claude; extension=md; fi
        agent_root="$project_root/.$adapter/agents"
        disabled_root="$data_root/disabled-agents/$adapter"
        # Remove the marker first when disabling and install it last when enabling.
        # The retired implement role is only ever moved out of the active directory.
        if [[ "$role_mode" == 1 ]]; then roles=(implement search plan ''); else roles=('' implement search plan); fi
        roles+=(easy)
        for role in "${roles[@]}"; do
            enable=$role_mode
            if [[ "$role" == easy ]]; then enable=$adaptive; fi
            if [[ "$role" == implement ]]; then enable=0; fi
            if [[ -n "$role" ]]; then
                name="litespec-$role.$extension"
                active="$agent_root/$name"
            else
                name=delegation-active.md
                active="$destination/litespec-shared/$name"
            fi
            if [[ "$enable" != 1 && ! -e "$active" && ! -L "$active" ]]; then
                continue
            fi
            saved="$disabled_root/$name"
            for path in "$active" "$saved"; do
                assert_local_path "$path"
                if [[ -e "$path" && ! -f "$path" ]]; then
                    printf 'No es un archivo: %s\n' "$path" >&2
                    return 1
                fi
            done
            if [[ -e "$active" && -e "$saved" ]]; then
                printf 'Existen ambas configuraciones: %s y %s. Revisa cual conservar.\n' "$active" "$saved" >&2
                return 1
            fi
            if [[ "$enable" != 1 ]]; then
                if [[ -e "$active" ]]; then
                    native_paths+=("$saved")
                    native_sources+=("$active")
                    native_contents+=('')
                fi
                continue
            fi
            # A marker from an older release names the retired implement role: regenerate it.
            if [[ -z "$role" ]]; then
                for path in "$active" "$saved"; do
                    if [[ -f "$path" ]] && grep -q 'litespec-implement' -- "$path"; then legacy_marker=$path; fi
                done
            fi
            if [[ -e "$active" && "$legacy_marker" != "$active" ]]; then
                preserved=$((preserved+1))
                printf 'Se conserva: %s\n' "$active"
                continue
            fi
            if [[ -e "$saved" && "$legacy_marker" != "$saved" ]]; then
                native_paths+=("$active")
                native_sources+=("$saved")
                native_contents+=('')
                continue
            fi
            if [[ -z "$role" ]]; then
                content=$'# Experimental - native delegation enabled\n'"Adapter: $adapter. Use litespec-search and litespec-plan when useful under delegation.md. Native definitions: .$adapter/agents/litespec-{search,plan}.$extension. Model/effort support is not validated by installation. On failure inform and continue with current agent within authorization. No guaranteed token savings."$'\n'
            else
                default_model=''
                if [[ "$role" == easy ]]; then
                    if [[ "$adapter" == codex ]]; then default_model=gpt-6.2-sol; else default_model=sonnet; fi
                fi
                read -r -p "$role - modelo [$default_model]: " model || return 1
                model=${model:-$default_model}
                if [[ -n "$model" && ! "$model" =~ ^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$ ]]; then printf '%s\n' 'Identificador de modelo invalido.' >&2; return 1; fi
                read -r -p "$role - esfuerzo compatible: " effort || return 1
                case "$effort" in
                    ''|low|medium|high|xhigh|max) ;;
                    minimal|ultra) if [[ "$adapter" != codex ]]; then printf '%s\n' 'Esfuerzo invalido.' >&2; return 1; fi ;;
                    *) printf '%s\n' 'Esfuerzo invalido. Compatibilidad depende del modelo y cliente.' >&2; return 1 ;;
                esac
                case "$role" in
                    easy) description='Execute only the Easy step explicitly assigned by the LiteSpec parent.' ;;
                    search) description='Gather concrete evidence with paths and lines; do not edit or decide scope.' ;;
                    plan) description='Analyze evidence and return a proposal; do not edit or implement.' ;;
                esac
                if [[ "$role" == easy ]]; then
                    instructions="Follow $relative/litespec-shared/easy-worker.md for the assigned step. Do not delegate."
                else
                    instructions="$description Read applicable AGENTS.md and $relative/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work."
                fi
                if [[ "$adapter" == codex ]]; then
                    content="name = \"litespec-$role\""$'\n'"description = \"$description\""$'\n'"developer_instructions = \"$instructions\""$'\n'
                    if [[ -n "$model" ]]; then content+="model = \"$model\""$'\n'; fi
                    if [[ -n "$effort" ]]; then content+="model_reasoning_effort = \"$effort\""$'\n'; fi
                else
                    content=$'---\n'"name: litespec-$role"$'\n'"description: $description"$'\n'
                    if [[ -n "$model" ]]; then content+="model: '$model'"$'\n'; fi
                    if [[ -n "$effort" ]]; then content+="effort: $effort"$'\n'; fi
                    if [[ "$role" != easy ]]; then content+=$'tools: Read, Grep, Glob\n'; fi
                    content+=$'---\n\n'"$instructions"$'\n'
                fi
            fi
            native_paths+=("$active")
            native_sources+=('')
            native_contents+=("$content")
        done
    fi
    mkdir -p -- "$destination"
    for folder in "${folders[@]}"; do mkdir -p -- "$destination/$folder"; done
    for file in "${files[@]}"; do
        assert_local_path "$destination/$file"
        if [[ -f "$destination/$file" ]]; then rm -- "$destination/$file"; fi
        cp -- "$source_root/$file" "$destination/$file"
        cmp -s -- "$source_root/$file" "$destination/$file"
    done
    mkdir -p -- "$data_root"
    if [[ -n "$legacy_marker" ]]; then assert_local_path "$legacy_marker"; rm -- "$legacy_marker"; fi
    for ((i=1; i<${#native_paths[@]}; i++)); do
        path=${native_paths[$i]}
        assert_local_path "$path"
        mkdir -p -- "$(dirname -- "$path")"
        if [[ -n "${native_sources[$i]}" ]]; then
            assert_local_path "${native_sources[$i]}"
            mv -n -- "${native_sources[$i]}" "$path"
            if [[ -e "${native_sources[$i]}" || ! -f "$path" ]]; then
                printf 'No se pudo mover la configuracion a %s\n' "$path" >&2
                return 1
            fi
            if [[ "$path" != "$disabled_root/"* ]]; then restored=$((restored+1)); else saved_count=$((saved_count+1)); fi
            continue
        fi
        (set -o noclobber; printf '%s' "${native_contents[$i]}" > "$path")
        if ! printf '%s' "${native_contents[$i]}" | cmp -s - "$path"; then printf 'Fallo la verificacion: %s\n' "$path" >&2; return 1; fi
        created=$((created+1))
    done
    printf 'Agente: %s | Modo: %s\n' "$agent_name" "$mode_label"
    printf 'Skills copiadas y verificadas en %s.\n' "$destination"
    printf 'Archivos de configuracion: creados=%s; restaurados=%s; conservados=%s; guardados=%s.\n' "$created" "$restored" "$preserved" "$saved_count"
    if [[ "$choice" == 12 ]]; then printf '%s\n' 'Zed usa el flujo normal; cualquier configuracion de Codex se conserva y solo aplica en Codex.'; fi
    if [[ "$mode_label" != Clasico ]]; then printf 'Configuracion: %s. Modelos no comprobados en ejecucion; confirma su carga en el cliente.\n' "$agent_root"; fi
    printf '%s\n' 'Abre una nueva sesion del agente para aplicar el modo.'
    read -r -p 'Borrar fuentes de liste.spec.steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]: ' answer || answer=''
    case "$answer" in
        [sS][iI]|[sS][íÍ]|[yY][eE][sS]|[yY]) ;;
        *) update_gitignore; return 0 ;;
    esac

    # Delete only verified package files; rmdir preserves nonempty folders.
    for file in "${files[@]}"; do
        assert_local_path "$source_root/$file"
        assert_local_path "$destination/$file"
        if ! cmp -s -- "$source_root/$file" "$destination/$file"; then
            printf 'El archivo cambio; se cancela la limpieza: %s\n' "$source_root/$file" >&2
            return 1
        fi
    done
    for file in "${files[@]}"; do rm -- "$source_root/$file"; done
    for folder in "${folders[@]}"; do rmdir -- "$source_root/$folder" 2>/dev/null || true; done
    rmdir -- "$source_root" 2>/dev/null || true
    assert_local_path "$script_path"
    rm -- "$script_path"
    printf '%s\n' 'Limpieza terminada. Se conservaron los archivos adicionales, si los habia.'
    update_gitignore
}

# Parse the entire function before execution so deleting this script is safe.
main "$@"
