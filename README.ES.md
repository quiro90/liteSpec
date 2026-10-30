# SpecLite

[English](README.md) | Español

Especificaciones breves y claras para trabajar con agentes de IA consumiendo pocos tokens. SpecLite divide el trabajo en pasos pequeños con el contexto suficiente para ejecutar y verificar cada uno, sin cargar todo el proyecto en cada lectura.

La documentación generada sigue el mismo objetivo: mínima, organizada por temas y útil para continuar sin reconstruir conversaciones.

## Flujo

1. **Explore:** inspeccionar lo relevante y confirmar objetivo y alcance.
2. **Propose:** preparar `spec.md` como índice y pasos con contexto, tareas y comprobaciones. Un cambio pequeño puede usar un solo archivo.
3. **Apply:** ejecutar los pasos autorizados, verificar, actualizar documentación y archivar.

Todo lo generado vive en `.liteSpec/`: cambios activos, notas temáticas en `docs/` con `index.md` compatible con Obsidian, e historial en `archived/`.

## Instalar

Copia la carpeta `steps/` completa y el instalador correspondiente en la **raíz del proyecto donde usarás SpecLite**, uno al lado del otro. No necesitas Python, Node ni descargas adicionales.

**Windows — PowerShell:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

**Linux / macOS — Bash:**

```bash
bash ./install.sh
```

Elige el agente (no el modelo). La instalación es local al proyecto:

| Agente | Destino |
|---|---|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` |

Se copian las tres skills, el protocolo compartido y la licencia. Si ya existe alguna carpeta de SpecLite en el destino, se cancela sin sobrescribir: revísala antes de reinstalar. Las demás skills se conservan.

Al terminar, `si`, `sí`, `yes` o `y` confirma borrar los archivos fuente instalados y el instalador ejecutado; cualquier otra respuesta los conserva. Solo se eliminan carpetas vacías: archivos adicionales, documentación y código del proyecto se mantienen.

Abre una nueva sesión del agente y pide: **«Usa speclite-explore para [tu cambio]»**. Después continúa con `speclite-propose` y `speclite-apply`; puedes pedir un paso concreto o todos los pendientes. Confirmar el alcance no autoriza automáticamente la implementación.

## Licencia

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Permite usar, modificar y distribuir, incluido uso comercial, conservando el aviso de autoría y la licencia.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
