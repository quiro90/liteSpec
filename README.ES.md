# LiteSpec

[English](README.md) | Español

Especificaciones breves y claras para trabajar con agentes de IA consumiendo pocos tokens. LiteSpec divide el trabajo en pasos pequeños con el contexto suficiente para ejecutar y verificar cada uno, sin cargar todo el proyecto en cada lectura.

La documentación generada sigue el mismo objetivo: mínima, organizada por temas y útil para continuar sin reconstruir conversaciones.

## Flujo

1. **Explore:** inspeccionar lo relevante y confirmar objetivo y alcance.
2. **Propose:** preparar `spec.md` como índice y pasos con contexto, tareas y comprobaciones. Un cambio pequeño puede usar un solo archivo.
3. **Apply:** ejecutar los pasos autorizados, revisar, realizar las comprobaciones requeridas e informar pendientes o preparación para Archive.
4. **Archive:** conciliar el mismo spec y las notas existentes con las decisiones finales, verificar consistencia y archivar. Se invoca por separado después de Apply.

Todo lo generado vive en `.litespec/`: cambios activos en `specs/<spec-name>/` (spec.md y pasos), notas temáticas en `docs/` con `index.md` compatible con Obsidian, e historial en `archived/`.

**Modify (durante un cambio activo):** usa `litespec-modify` cuando cambien decisiones o archivos relevantes. Apply también atiende estas revisiones al detectarlas: actualiza solo las especificaciones y pasos afectados, reabre comprobaciones invalidadas y pregunta únicamente por decisiones pendientes. Conserva acuerdos válidos y progreso no afectado; un cambio archivado requiere otro nuevo enlazado.

La documentación permanece en el proyecto, en `.litespec/docs/`; compatibilidad con Obsidian no selecciona un vault externo. El cierre verifica la documentación requerida y los enlaces afectados, e informa las rutas de documentación y archivo. Si no hace falta actualizar documentación, se registra el motivo sin crear notas vacías. Si falta documentación requerida, no se cierra.

Cada `spec.md` registra una política de continuidad (`preserve`, `extend`, `replace` o `new`) y compatibilidad (`required`, `breaking-approved` o `not-applicable`), con una frase que delimita qué conservar, sustituir o migrar. Sirve para código, documentos y otros materiales; las etiquetas no autorizan eliminaciones por sí solas. Se guarda una sola vez, sin repetirla en cada paso.

Antes de archivar se comprueban tareas, aceptación, integración, compatibilidad y documentación. También se exige autorización explícita de archivo, que puede estar concedida previamente; autorizar implementar no basta. Si falta algo, se informa y queda en `spec.md` como `pending-verification` o `pending-confirmation`, con el pendiente y la próxima acción para retomar en otra sesión.

**Verify (opcional):** usa `litespec-verify` para tareas seleccionadas, un paso o todo el cambio activo. Registra evidencia y comprobaciones pendientes sin implementar correcciones ni archivar; Apply sigue verificando su propio trabajo. Usa `litespec-archive` para documentación y cierre; la implementación pendiente impide archivar y se informa sin ejecutarla. Las entregas documentales explícitas siguen en Apply; la consolidación de notas corresponde a Archive.

## Instalar

Copia la carpeta `steps/` completa y el instalador correspondiente en la **raíz del proyecto donde usarás LiteSpec**, uno al lado del otro. No necesitas Python, Node ni descargas adicionales.

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
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` |

Zed Agent requiere un proyecto de confianza y comparte este destino con Codex. Para agentes externos dentro de Zed, elige su propia opción del instalador. ADE usa aquí skills del proyecto, no su directorio interno resources/agent-skills.

Se copian las seis skills y las reglas compartidas. LICENSE permanece en la raíz del repositorio. Las reglas se cargan por necesidad: `protocol.md` para todas las skills, `specification.md` al definir especificaciones, `revision.md` al ajustar cambios, `verification.md` al comprobar resultados `documentation.md` al consolidar notas y `closure.md` al archivar. No se lee toda la carpeta por defecto. Al reinstalar se reemplazan solo los doce archivos enumerados del paquete en las siete carpetas de LiteSpec; se conservan archivos adicionales y otras skills. Los enlaces o conflictos entre archivos y carpetas en el destino detienen la instalación antes del reemplazo.

El instalador crea `.litespec/` vacía si no existe y conserva su contenido si ya existe. El agente crea `specs/`, `docs/` y `archived/` según se necesiten al trabajar; el impacto documental siempre se evalúa antes de cerrar.

Si actualizas una instalación anterior, reemplaza las carpetas `speclite-*` por las nuevas `litespec-*` para evitar skills duplicadas. Conserva los datos de `.liteSpec/` al adoptar el nombre `.litespec/`; en sistemas sensibles a mayúsculas son rutas distintas. El instalador no migra instalaciones anteriores.

Al terminar, `si`, `sí`, `yes` o `y` confirma borrar los archivos fuente instalados y el instalador ejecutado; cualquier otra respuesta los conserva. Solo se eliminan carpetas vacías: archivos adicionales, documentación y código del proyecto se mantienen.

Abre una nueva sesión del agente y pide: **«Usa litespec-explore para [tu cambio]»**. Después continúa con `litespec-propose` y `litespec-apply`; puedes pedir un paso concreto o todos los pendientes. Finaliza con `litespec-archive`. Un pedido explícito y claro puede resolver Explore sin otra confirmación; las preguntas materiales pendientes requieren respuesta. Confirmar solo el alcance no autoriza la implementación.

## Licencia

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Permite usar, modificar y distribuir, incluido uso comercial, conservando el aviso de autoría y la licencia.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
