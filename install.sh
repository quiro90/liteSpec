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
    source_root="$project_root/steps"
    local folders=(litespec-explore litespec-propose litespec-apply litespec-modify litespec-verify litespec-archive litespec-shared)
    local files=(litespec-explore/SKILL.md litespec-propose/SKILL.md
        litespec-apply/SKILL.md litespec-modify/SKILL.md litespec-verify/SKILL.md litespec-archive/SKILL.md
        litespec-shared/protocol.md
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
    printf '%s\n' '1) Codex  2) Claude Code  3) GitHub Copilot  4) Cursor  5) OpenCode  6) Qoder CLI  7) Gemini CLI  8) Qwen Code  9) Cline  10) Devin Local  11) ADE  12) Zed  13) Minimax Code'
    read -r -p 'Agente [1-12]: ' choice || return 1
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
    mkdir -p -- "$destination"
    for folder in "${folders[@]}"; do mkdir -p -- "$destination/$folder"; done
    for file in "${files[@]}"; do
        assert_local_path "$destination/$file"
        if [[ -f "$destination/$file" ]]; then rm -- "$destination/$file"; fi
        cp -- "$source_root/$file" "$destination/$file"
        cmp -s -- "$source_root/$file" "$destination/$file"
    done
    mkdir -p -- "$data_root"
    printf 'Instalado y verificado en %s. Abre una nueva sesion del agente.\n' "$destination"
    read -r -p 'Borrar fuentes de steps/ e instalador ejecutado? [si/yes/y; otra respuesta conserva]: ' answer || answer=''
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
