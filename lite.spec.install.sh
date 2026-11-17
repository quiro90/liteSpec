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

    for file in "${files[@]}"; do
        assert_local_path "$source_root/$file"
        if [[ ! -f "$source_root/$file" ]]; then
            printf 'Falta: %s\n' "$source_root/$file" >&2
            return 1
        fi
    done
    printf 'LiteSpec - proyecto: %s\n' "$project_root"
    printf '%s\n' '1) Codex  2) Claude Code  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI  7) Gemini CLI  8) Qwen Code  9) Cline  10) Devin Local  11) ADE  12) Zed  13) MiniMax Code'
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
    local native_paths=('') native_contents=('') native_sources=('') roles=()
    local mode adapter extension agent_root disabled_root role name model effort description instructions content active saved i
    if [[ "$choice" == 1 || "$choice" == 2 ]]; then
        printf '%s\n' '1) Normal [predeterminado, desactiva Auto model]  2) Activar Auto model (experimental)' 'Auto model delega tareas a subagentes nativos y puede aumentar el consumo de tokens.'
        read -r -p 'Opcion [1]: ' mode || mode=''
        case "$mode" in ''|1|2) ;; *) printf '%s\n' 'Opcion invalida; no se instalo nada.' >&2; return 1 ;; esac
        if [[ "$mode" == 2 ]]; then
            printf '%s\n' \
                'Ejemplos por dificultad (modelo / esfuerzo, segun disponibilidad)' \
                '  Facil (buscar archivos)        | Codex: gpt-6-luna / medium   | Claude Code: haiku / medium' \
                '  Media (plan o cambio acotado)   | Codex: gpt-6.1-sol / medium  | Claude Code: sonnet / medium' \
                '  Pesada (depuracion compleja)   | Codex: gpt-6-astra / medium  | Claude Code: opus / medium' \
                'Usa la columna de tu agente. Enter deja el campo con la herencia o el valor nativo.'
        fi
        if [[ "$choice" == 1 ]]; then adapter=codex; extension=toml; else adapter=claude; extension=md; fi
        agent_root="$project_root/.$adapter/agents"
        disabled_root="$data_root/disabled-agents/$adapter"
        # Remove the marker first when disabling and install it last when enabling.
        if [[ "$mode" == 2 ]]; then roles=(search plan implement ''); else roles=('' search plan implement); fi
        for role in "${roles[@]}"; do
            if [[ -n "$role" ]]; then
                name="litespec-$role.$extension"
                active="$agent_root/$name"
            else
                name=delegation-active.md
                active="$destination/litespec-shared/$name"
            fi
            if [[ "$mode" != 2 && ! -e "$active" && ! -L "$active" ]]; then
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
            if [[ "$mode" != 2 ]]; then
                if [[ -e "$active" ]]; then
                    native_paths+=("$saved")
                    native_sources+=("$active")
                    native_contents+=('')
                fi
                continue
            fi
            if [[ -e "$active" ]]; then
                printf 'Se conserva: %s\n' "$active"
                continue
            fi
            if [[ -e "$saved" ]]; then
                native_paths+=("$active")
                native_sources+=("$saved")
                native_contents+=('')
                continue
            fi
            if [[ -z "$role" ]]; then
                content=$'# Experimental - native delegation enabled\n'"Adapter: $adapter. Use litespec-search, litespec-plan and litespec-implement when useful under delegation.md. Native definitions: .$adapter/agents/litespec-{search,plan,implement}.$extension. Model/effort support is not validated by installation. On failure inform and continue with current agent within authorization. No guaranteed token savings."$'\n'
            else
                read -r -p "$role - modelo (Enter para usar la herencia nativa): " model || return 1
                if [[ -n "$model" && ! "$model" =~ ^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$ ]]; then printf '%s\n' 'Identificador de modelo invalido.' >&2; return 1; fi
                read -r -p "$role - esfuerzo compatible (vacio: herencia/default nativo): " effort || return 1
                case "$effort" in
                    ''|low|medium|high|xhigh|max) ;;
                    minimal|ultra) if [[ "$adapter" != codex ]]; then printf '%s\n' 'Esfuerzo invalido.' >&2; return 1; fi ;;
                    *) printf '%s\n' 'Esfuerzo invalido. Compatibilidad depende del modelo y cliente.' >&2; return 1 ;;
                esac
                case "$role" in
                    search) description='Gather concrete evidence with paths and lines; do not edit or decide scope.' ;;
                    plan) description='Analyze evidence and return a proposal; do not edit or implement.' ;;
                    implement) description='Implement only authorized bounded work and verify its results.' ;;
                esac
                instructions="$description Read applicable AGENTS.md and $relative/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work."
                if [[ "$adapter" == codex ]]; then
                    content="name = \"litespec-$role\""$'\n'"description = \"$description\""$'\n'"developer_instructions = \"$instructions\""$'\n'
                    if [[ -n "$model" ]]; then content+="model = \"$model\""$'\n'; fi
                    if [[ -n "$effort" ]]; then content+="model_reasoning_effort = \"$effort\""$'\n'; fi
                else
                    content=$'---\n'"name: litespec-$role"$'\n'"description: $description"$'\n'
                    if [[ -n "$model" ]]; then content+="model: '$model'"$'\n'; fi
                    if [[ -n "$effort" ]]; then content+="effort: $effort"$'\n'; fi
                    if [[ "$role" != implement ]]; then content+=$'tools: Read, Grep, Glob\n'; fi
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
            continue
        fi
        (set -o noclobber; printf '%s' "${native_contents[$i]}" > "$path")
        if ! printf '%s' "${native_contents[$i]}" | cmp -s - "$path"; then printf 'Fallo la verificacion: %s\n' "$path" >&2; return 1; fi
    done
    printf 'Instalado y verificado en %s. Abre una nueva sesion del agente.\n' "$destination"
    read -r -p 'Borrar fuentes de liste.spec.steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]: ' answer || answer=''
    case "$answer" in
        [sS][iI]|[sS][íÍ]|[yY][eE][sS]|[yY]) ;;
        *) return 0 ;;
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
}

# Parse the entire function before execution so deleting this script is safe.
main "$@"
