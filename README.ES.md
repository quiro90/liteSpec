# LiteSpec

[English](README.md) | Español

Especificaciones breves y claras para trabajar con agentes de IA consumiendo pocos tokens. LiteSpec divide el trabajo en pasos pequeños con el contexto suficiente para ejecutar y verificar cada uno, sin cargar todo el proyecto en cada lectura.

La documentación generada sigue el mismo objetivo: mínima, organizada por temas y útil para continuar sin reconstruir conversaciones.

## Flujo

El instalador ofrece **Clásico** para todos los agentes y **Adaptive** para Claude Code y Codex. En ambos modos cada paso entrega un resultado comprobable. En Adaptive, el principal puede asignar la implementación de un paso Easy a Sonnet o Sol y retoma el control para verificarlo. [Opciones del instalador](#elección-del-modo-en-el-instalador)

1. **Explore:** inspeccionar lo relevante y confirmar objetivo y alcance.
2. **Propose:** preparar `spec.md` como índice y pasos con contexto, tareas y comprobaciones. Un cambio pequeño puede usar un solo archivo.
3. **Apply:** ejecutar los pasos autorizados, revisar, realizar las comprobaciones requeridas e informar pendientes o preparación para Archive.
4. **Archive:** conciliar el mismo spec y las notas existentes con las decisiones finales, verificar consistencia y archivar. Se invoca por separado después de Apply.

Todo lo generado vive en `.litespec/`: cambios activos en `specs/<spec-name>/` (spec.md y pasos), notas temáticas en `docs/` con `index.md` compatible con Obsidian, e historial en `archived/`.

**Modify (durante un cambio activo):** usa `litespec-modify` cuando cambien decisiones o archivos relevantes. Apply también atiende estas revisiones al detectarlas: actualiza solo las especificaciones y pasos afectados, reabre comprobaciones invalidadas y pregunta únicamente por decisiones pendientes. Conserva acuerdos válidos y progreso no afectado; un cambio archivado requiere otro nuevo enlazado.

La documentación permanece en el proyecto, en `.litespec/docs/`; compatibilidad con Obsidian no selecciona un vault externo. Cada paso terminado registra una línea breve `Docs:` (tema destino y hechos durables, o `none`) mientras el trabajo está fresco; Archive consolida esas líneas en notas temáticas pequeñas una sola vez, sin releer todo el cambio. Actualizar la documentación viva pasa a ser tarea de un paso solo si el usuario lo pide u otro trabajo la necesita antes del cierre. El cierre verifica la documentación requerida y los enlaces afectados, e informa las rutas de documentación y archivo. Si no hace falta actualizar documentación, se registra el motivo sin crear notas vacías. Si falta documentación requerida, no se cierra.

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

| Agente | Destino | Adaptativo |
|---|---|:---:|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` | ✅ |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | ✅ |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` | — |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` | — |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` | — |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` | — |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` | — |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` | — |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` | — |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` | — |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` | — |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` | — |
| MiniMax Code | `.minimax/skills/` | — |

Zed Agent requiere un proyecto de confianza y comparte este destino con Codex. Auto model solo se aplica en el cliente indicado por su marcador; Zed mantiene el flujo normal y conserva la configuración de Codex. Para agentes externos dentro de Zed, elige su propia opción del instalador. ADE usa aquí skills del proyecto, no su directorio interno resources/agent-skills.

Se copian las seis skills y las reglas compartidas. LICENSE permanece en la raíz del repositorio. Las reglas se cargan por necesidad: `protocol.md` para todas las skills, `specification.md` al definir especificaciones, `revision.md` al ajustar cambios, `verification.md` al comprobar resultados, `documentation.md` al consolidar notas y `closure.md` al archivar. En Adaptive, `adaptive-plan.md` al clasificar pasos, `adaptive-apply.md` al ejecutarlos y `easy-worker.md` para el ejecutor Easy; `serial.md` solo si existe `.litespec/serial/`. No se lee toda la carpeta por defecto. Al reinstalar se reemplazan solo los archivos enumerados del paquete en las siete carpetas de LiteSpec; se conservan archivos adicionales y otras skills. Los enlaces o conflictos entre archivos y carpetas en el destino detienen la instalación antes del reemplazo.

El instalador crea `.litespec/` vacía si no existe y conserva su contenido si ya existe. El agente crea `specs/`, `docs/` y `archived/` según se necesiten al trabajar; el impacto documental siempre se evalúa antes de cerrar.

Si actualizas una instalación anterior, reemplaza las carpetas `speclite-*` por las nuevas `litespec-*` para evitar skills duplicadas. Conserva los datos de `.liteSpec/` al adoptar el nombre `.litespec/`; en sistemas sensibles a mayúsculas son rutas distintas. El instalador no migra instalaciones anteriores.

Al terminar, `si`, `sí`, `yes` o `y` confirma borrar los archivos fuente instalados y el instalador ejecutado; cualquier otra respuesta los conserva. Solo se eliminan carpetas vacías: archivos adicionales, documentación y código del proyecto se mantienen.

Si ya existe un archivo `.gitignore`, al finalizar se pregunta qué excluir: **y/yes/si/s** agrega el instalador (script ejecutado y carpeta fuente) y las siete carpetas de skills de LiteSpec; **i/ins** agrega solo el instalador; cualquier otra respuesta no modifica nada. Se conservan las reglas existentes y se añaden solo las faltantes. Con Git disponible se reconocen también patrones de exclusión; sin Git se comprueban reglas literales y carpetas padre. No se crea un .gitignore nuevo ni se dejan de versionar archivos ya registrados en Git.

Abre una nueva sesión del agente y pide: **«Usa litespec-explore para [tu cambio]»**. Después continúa con `litespec-propose` y `litespec-apply`; puedes pedir un paso concreto o todos los pendientes. Finaliza con `litespec-archive`. Un pedido explícito y claro puede resolver Explore sin otra confirmación; las preguntas materiales pendientes requieren respuesta. Confirmar solo el alcance no autoriza la implementación.

## Elección del modo en el instalador

En el menú de agentes, Codex y Claude Code ofrecen dos decisiones independientes.

| Pregunta | Opciones |
|---|---|
| Ejecución de pasos | **1 Clásico** (Enter) o **2 Adaptive**. En Adaptive, Easy usa el perfil configurable `litespec-easy`. Enter al crearlo selecciona `gpt-6.2-sol` en Codex o `sonnet` en Claude. |
| Delegación interna de las skills | **1 Desactivada** o **2 Auto model por rol**: roles de solo lectura `search` y `plan` para análisis en cualquier fase. Enter conserva la activación actual; en un proyecto nuevo empieza desactivada. |

Los demás agentes usan Clásico. El instalador conserva los perfiles personalizados al desactivarlos y restaurarlos. Al crear un perfil puedes configurar modelo y esfuerzo. Abre una sesión nueva para cargarlo. El antiguo rol `implement` queda retirado: cualquier ejecución para Codex o Claude Code lo mueve a `.litespec/disabled-agents/` y regenera un marcador de activación antiguo; la delegación de implementación pertenece solo a Adaptive.

Explore registra los contratos, patrones y ejemplos de aceptación. Propose agrupa código, pruebas y documentación que entregan el mismo resultado. En Adaptive asigna dificultad residual, responsable y revisión focalizada cuando corresponde. Apply completa las fases pendientes si se invoca directamente y despacha un paso Easy delegable a la vez. Verify comprueba alcance, evidencia vigente y fronteras de riesgo, incluso si se invoca por separado.

Para comparar los modos, parte de la misma revisión con los mismos requisitos, controles y configuración de roles. Cuenta desde Explore hasta la aceptación final. Compara cuota del principal por cambio aceptado, tiempo, correcciones y regresiones. Cada paso Adaptive registra `Executed:` (executor, principal o executor-then-principal) y su número de correcciones. Si el cliente oculta el consumo por modelo, deja ese dato como desconocido.

**Un solo SPEC activo por proyecto (opcional).** Crea el directorio `.litespec/serial/` antes de iniciar sesiones en esa copia del proyecto. El primer principal adquiere el turno durante su invocación. Si hay competencia, la otra sesión informa y cede. Cuando el principal devuelve el control, otra sesión puede retomar el SPEC activo. Para abrir uno nuevo hay que archivar el anterior. Tras una interrupción, consulta la nota de propietario y confirma que todos los ejecutores se detuvieron antes de retirar manualmente `.litespec/serial/busy/`. Para desactivar la opción, quita el directorio serial vacío cuando no haya actividad.

### Reconfigurar perfiles

Edita cada perfil en `.codex/agents/` o `.claude/agents/`. Define `model` y un esfuerzo compatible mediante `model_reasoning_effort` (Codex) o `effort` (Claude). Los campos omitidos usan los valores predeterminados del cliente. Claude también acepta `model: inherit`. El perfil Adaptive `litespec-easy` usa los mismos campos; para desactivar Adaptive manualmente, muévelo a `.litespec/disabled-agents/codex/` o `.litespec/disabled-agents/claude/`.

Para cambiar de modo, ejecuta el instalador para el mismo cliente. Si lo borraste, copia un paquete nuevo. Para desactivar los roles manualmente, mueve el marcador instalado `litespec-shared/delegation-active.md` y los dos perfiles que enumera a `.litespec/disabled-agents/codex/` o `.litespec/disabled-agents/claude/`. Para reactivarlos, devuelve cada archivo a su ubicación original. Si hay copias activas y guardadas del mismo archivo, resuelve el duplicado antes del cambio. Después abre una sesión nueva.

## Licencia

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Permite usar, modificar y distribuir, incluido uso comercial, conservando el aviso de autoría y la licencia.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
