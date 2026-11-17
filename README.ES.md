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

Copia la carpeta `liste.spec.steps/` completa y el instalador correspondiente en la **raíz del proyecto donde usarás LiteSpec**, uno al lado del otro. No necesitas Python, Node ni descargas adicionales.

**Windows — PowerShell:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\lite.spec.install.ps1
```

**Linux / macOS — Bash:**

```bash
bash ./lite.spec.install.sh
```

Elige el agente. Codex y Claude Code ofrecen luego configurar modelos de forma opcional. La instalación es local al proyecto:

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
| MiniMax Code | `.minimax/skills/` |

Zed Agent requiere un proyecto de confianza y comparte este destino con Codex. Auto model solo se aplica en el cliente indicado por su marcador; Zed mantiene el flujo normal y conserva la configuración de Codex. Para agentes externos dentro de Zed, elige su propia opción del instalador. ADE usa aquí skills del proyecto, no su directorio interno resources/agent-skills.

Se copian las seis skills y las reglas compartidas. LICENSE permanece en la raíz del repositorio. Las reglas se cargan por necesidad: `protocol.md` para todas las skills, `specification.md` al definir especificaciones, `revision.md` al ajustar cambios, `verification.md` al comprobar resultados `documentation.md` al consolidar notas y `closure.md` al archivar. No se lee toda la carpeta por defecto. Al reinstalar se reemplazan solo los trece archivos enumerados del paquete en las siete carpetas de LiteSpec; se conservan archivos adicionales y otras skills. Los enlaces o conflictos entre archivos y carpetas en el destino detienen la instalación antes del reemplazo.

El instalador crea `.litespec/` vacía si no existe y conserva su contenido si ya existe. El agente crea `specs/`, `docs/` y `archived/` según se necesiten al trabajar; el impacto documental siempre se evalúa antes de cerrar.

Si actualizas una instalación anterior, reemplaza las carpetas `speclite-*` por las nuevas `litespec-*` para evitar skills duplicadas. Conserva los datos de `.liteSpec/` al adoptar el nombre `.litespec/`; en sistemas sensibles a mayúsculas son rutas distintas. El instalador no migra instalaciones anteriores.

Al terminar, `si`, `sí`, `yes` o `y` confirma borrar los archivos fuente instalados y el instalador ejecutado; cualquier otra respuesta los conserva. Solo se eliminan carpetas vacías: archivos adicionales, documentación y código del proyecto se mantienen.

Si ya existe un archivo `.gitignore`, al finalizar se pregunta qué excluir: **y/yes/si/s** agrega el instalador (script ejecutado y carpeta fuente) y las siete carpetas de skills de LiteSpec; **i/ins** agrega solo el instalador; cualquier otra respuesta no modifica nada. Se conservan las reglas existentes y se añaden solo las faltantes. Con Git disponible se reconocen también patrones de exclusión; sin Git se comprueban reglas literales y carpetas padre. No se crea un .gitignore nuevo ni se dejan de versionar archivos ya registrados en Git.

Abre una nueva sesión del agente y pide: **«Usa litespec-explore para [tu cambio]»**. Después continúa con `litespec-propose` y `litespec-apply`; puedes pedir un paso concreto o todos los pendientes. Finaliza con `litespec-archive`. Un pedido explícito y claro puede resolver Explore sin otra confirmación; las preguntas materiales pendientes requieren respuesta. Confirmar solo el alcance no autoriza la implementación.

**Auto model (experimental, Codex y Claude Code)** es opcional cada vez que ejecutas el instalador. La opción predeterminada es **Normal — sin delegación de LiteSpec**. **Auto model experimental — modelos por rol** configura modelos por responsabilidad; no los selecciona automáticamente según la dificultad. Elige Auto model para delegar búsqueda, análisis e implementación a subagentes nativos con su propia configuración de modelo. Delegar puede aumentar el consumo de tokens.

Al elegir Auto model, el instalador muestra ejemplos de modelo y esfuerzo para tareas fáciles, medias y pesadas en Codex y Claude Code. Usa la columna de tu agente como punto de partida. Para cada rol puedes ingresar un modelo y esfuerzo compatibles; Enter usa la herencia o el valor predeterminado del cliente. El instalador valida el formato, no la disponibilidad ni la compatibilidad del modelo en tu cuenta o versión. Codex crea archivos en `.codex/agents/`; Claude en `.claude/agents/`. La instalación es local al proyecto y funciona con el soporte nativo del cliente. Abre una nueva sesión y comprueba que se cargaron los agentes y modelos.

Para apagar Auto model, vuelve a ejecutar el instalador para el mismo agente y elige **Normal**. LiteSpec mueve sus subagentes y el marcador de activación a `.litespec/disabled-agents/<adaptador>/` (`codex` o `claude`). Si vuelves a elegir **Auto model**, se restauran los modelos y niveles de esfuerzo guardados. Puedes editar directamente los archivos de cada rol. Si borraste el instalador y las fuentes, copia un paquete nuevo para reinstalar. La guía instalada `litespec-shared/delegation.md` sigue disponible para cambios manuales.

El resumen final indica agente, modo y archivos de configuración creados, restaurados, conservados o guardados. Verificar la instalación de archivos no comprueba los modelos en ejecución.

Solo se delegan trabajos acotados cuando aporta valor, con un trabajador a la vez. Ante fallos se informa y se continúa con el agente actual dentro del alcance autorizado. Las instrucciones superiores, permisos, overrides y fallbacks nativos siguen aplicando.

## Licencia

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Permite usar, modificar y distribuir, incluido uso comercial, conservando el aviso de autoría y la licencia.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
