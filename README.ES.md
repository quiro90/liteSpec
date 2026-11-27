# LiteSpec

[English](README.md) | Español

Especificaciones breves y claras para trabajar con agentes de IA consumiendo pocos tokens. LiteSpec divide el trabajo en pasos pequeños con el contexto suficiente para ejecutar y verificar cada uno, sin cargar todo el proyecto en cada lectura.

La documentación generada sigue el mismo objetivo: mínima, organizada por temas y útil para continuar sin reconstruir conversaciones.

> **Experimental.** LiteSpec en su conjunto es experimental: el flujo, Adaptive, la delegación por roles y el instalador pueden cambiar entre versiones y no están validados en todos los clientes. Revisa las specs, los cambios y las comprobaciones que produzca el agente antes de confiar en ellos.

## Compilar y publicar

### Requisitos previos

- Go 1.25 o posterior para compilar desde el código fuente.
- PowerShell 7.3 o posterior (`pwsh`) para generar los paquetes de distribución.

### Compilar para tu sistema

Ejecuta estas comprobaciones desde la raíz del repositorio.

```text
go test ./...
go vet ./...
```

En Windows, ejecuta `go build -o litespec.exe .`. En macOS y Linux, ejecuta `go build -o litespec .`.

Una compilación directa con `go build` usa la versión declarada en `main.go`. El script de empaquetado guarda en el binario la versión indicada con `-Version`. GitHub Actions usa el tag de la versión.

La compilación incluye en el ejecutable estos archivos de `lite.spec.steps/` mediante `go:embed`.

- `lite.spec.steps/litespec-*/SKILL.md` para las definiciones de las skills.
- `lite.spec.steps/litespec-shared/*.md` para las reglas compartidas.

Si cambias el nombre de la carpeta fuente, actualiza la directiva `go:embed` en `main.go` y `sourceTree` en `install.go`. Si mueves un archivo del paquete fuera de esos patrones, actualiza la directiva. Vuelve a compilar después de editar una skill o una regla para que el ejecutable incluya los cambios.

### Empaquetar para distribuir

Desde la raíz del repositorio, ejecuta el comando de empaquetado con `go` en el `PATH`.

```powershell
pwsh -File scripts/package.ps1 -Version v0.1.0
```

El script compila seis binarios con `CGO_ENABLED=0` e incorpora la versión indicada, que puedes consultar con `litespec --version`. Por defecto genera los archivos en `dist/`. Usa `-OutputDirectory` para elegir otra carpeta.

| Plataforma | Arquitecturas | Formato |
|---|---|---|
| Windows | x64, ARM64 | `.zip` |
| macOS | x64, ARM64 | `.tar.gz` |
| Linux | x64, ARM64 | `.tar.gz` |

Cada paquete contiene el ejecutable, `LICENSE` y `THIRD_PARTY_LICENSES.txt`. `SHA256SUMS.txt` contiene las sumas de comprobación de los seis paquetes.

### Publicar una versión

Usa un tag de versión con formato `vX.Y.Z` y un sufijo opcional para versiones preliminares, como `-rc.1`. Créalo en el commit que quieras publicar y súbelo a GitHub.

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions ejecuta `go test` y `go vet` en Windows, macOS y Linux. Si pasan todas las comprobaciones, usa el mismo script de empaquetado y sube los paquetes y sus sumas a GitHub Releases. Los tags con un sufijo como `-rc.1` se publican como versiones preliminares.

## Flujo

El instalador ofrece **Clásico** para todos los agentes y **Adaptive experimental** para Codex, Claude Code, GitHub Copilot, Cursor, OpenCode, Gemini CLI y Qwen Code. Adaptive está en una etapa inicial de pruebas en todos los clientes compatibles. En ambos modos cada paso entrega un resultado comprobable. En Adaptive, el principal separa el trabajo comprobable por partes, delega los pasos fáciles y medios y verifica los resultados. [Opciones del instalador](#elección-del-modo-en-el-instalador)

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

Descarga el paquete de tu sistema y arquitectura desde [GitHub Releases](https://github.com/quiro90/liteSpec/releases), extráelo una vez y guarda el ejecutable donde te resulte cómodo. En los nombres de descarga, `darwin` corresponde a macOS, `amd64` a x64 y `arm64` a ARM64 (incluido Apple Silicon). El binario trae todas las skills y funciona sin conexión. Para usarlo no hace falta instalar Go, Node ni Python.

Abre una terminal en la raíz del proyecto y ejecuta LiteSpec. Por ejemplo, en Windows:

```powershell
& "C:\herramientas\litespec.exe"
```

En Linux o macOS:

```bash
~/bin/litespec
```

Usa la ruta donde guardaste el ejecutable. Si lo agregas al `PATH`, basta con `litespec`. Para usar opciones del instalador, escribe el subcomando `init`. Por ejemplo, `litespec init --project "ruta al proyecto"` instala en otra carpeta. Para consultar la versión, usa `litespec --version`.

En una terminal interactiva, elige primero español o inglés. En el menú de agentes, usa ↑ y ↓ para moverte, **Espacio** para marcar o desmarcar, **Enter** para confirmar y **Esc** para cancelar. Ejecuta `litespec init --lang es` o `litespec init --lang en` para saltar la elección de idioma. Con entrada redirigida o `litespec init --plain`, escribe un número o varios separados por comas, como `1,2,4`.

Antes del menú de agentes, el instalador muestra la versión del ejecutable en uso y las carpetas del proyecto que ya contienen skills de LiteSpec. Si eliges un agente que usa una de esas carpetas, el instalador actualiza los archivos del paquete y ajusta los perfiles de LiteSpec de ese agente según tus opciones. Se conservan los archivos adicionales y los datos de `.litespec/`.

Puedes instalar LiteSpec para varios agentes en una sola pasada. El instalador pide el modo y la configuración de cada agente que ofrezca esas opciones. La instalación es local al proyecto:

| Agente | Destino | Adaptativo |
|---|---|:---:|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` | ✅ exp. |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | ✅ exp. |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` | ✅ exp. |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` | ✅ exp. |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` | ✅ exp. |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` | — |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` | ✅ exp. |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` | ✅ exp. |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` | — |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` | — |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` | — |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` | — |
| MiniMax Code | `.minimax/skills/` | — |

Zed Agent requiere un proyecto de confianza y comparte este destino con Codex. Auto model solo se aplica en el cliente indicado por su marcador; Zed mantiene el flujo normal y conserva la configuración de Codex. Para agentes externos dentro de Zed, elige su propia opción del instalador. ADE usa aquí skills del proyecto, no su directorio interno resources/agent-skills.

Se copian las seis skills y las reglas compartidas. LICENSE permanece en la raíz del repositorio. Las reglas se cargan por necesidad: `protocol.md` para todas las skills, `specification.md` al definir especificaciones, `revision.md` al ajustar cambios, `verification.md` al comprobar resultados, `documentation.md` al consolidar notas y `closure.md` al archivar. En Adaptive, `adaptive-plan.md` al clasificar pasos, `adaptive-apply.md` al ejecutarlos y `executor.md` para los ejecutores fáciles y medios; `serial.md` solo si existe `.litespec/serial/`. No se lee toda la carpeta por defecto. Al reinstalar se reemplazan solo los archivos enumerados del paquete en las siete carpetas de LiteSpec; se conservan archivos adicionales y otras skills. Los enlaces o conflictos entre archivos y carpetas en el destino detienen la instalación antes del reemplazo.

El instalador crea `.litespec/` vacía si no existe y conserva su contenido si ya existe. El agente crea `specs/`, `docs/` y `archived/` según se necesiten al trabajar; el impacto documental siempre se evalúa antes de cerrar.

Si ya existe un `.gitignore`, al terminar la instalación verás una sola pregunta para excluir las skills de LiteSpec que acabas de instalar. Si el ejecutable está en la raíz del proyecto, puedes excluir solo las skills, solo el ejecutable o ambos. Enter conserva el archivo. Se mantienen las reglas existentes y el estado de los archivos ya versionados. Puedes reutilizar el mismo binario en otros proyectos.

Abre una nueva sesión del agente y pide: **«Usa litespec-explore para [tu cambio]»**. Después continúa con `litespec-propose` y `litespec-apply`; puedes pedir un paso concreto o todos los pendientes. Finaliza con `litespec-archive`. Un pedido explícito y claro puede resolver Explore sin otra confirmación; las preguntas materiales pendientes requieren respuesta. Confirmar solo el alcance no autoriza la implementación.

## Elección del modo en el instalador

En el menú de agentes, Codex y Claude Code ofrecen dos decisiones independientes.

| Pregunta | Opciones |
|---|---|
| Ejecución de pasos | **1 Clásico** (Enter) o **2 Adaptive experimental**. En Adaptive, los pasos `easy` son mecánicos y los `medium` implementan lógica con comportamiento, interfaces y comprobaciones definidos. El principal resuelve los pasos `hard` cuando queda por decidir el comportamiento, una interfaz o la estrategia. |
| Delegación interna de las skills | **1 Desactivada** o **2 Auto model por rol**. El principal redacta las specs y puede delegar la indexación, el análisis acotado y la investigación compleja a roles de solo lectura. Enter conserva la activación actual. En un proyecto nuevo empieza desactivada. |

Qoder CLI, Cline, Devin Local, ADE, Zed y MiniMax Code usan Clásico. Cada ejecución del instalador regenera los archivos de configuración de las opciones elegidas y borra los que dejaron de elegirse; solo toca esos archivos exactos, así que sus ediciones manuales se reemplazan y los demás agentes se conservan. Modelo y esfuerzo se preguntan en cada ejecución. Abre una sesión nueva para cargarlos.

**Adaptive experimental (GitHub Copilot, Cursor, OpenCode, Gemini CLI, Qwen Code).** Estos clientes ofrecen un único ejecutor (`litespec-executor`) para los pasos fáciles y medios, y el marcador `litespec-shared/adaptive-active.md` indica qué cliente lo invoca. Clásico elimina el ejecutor y el marcador. Enter elige `flash` en Gemini CLI, `composer-2.5[]` en Cursor y `anthropic/claude-haiku-4-5` en OpenCode con un proveedor Anthropic disponible. En GitHub Copilot y Qwen Code, Enter usa el modelo del cliente. En Cursor, OpenCode y Gemini CLI, escribe `inherit` para usar el modelo de la sesión. Copilot usa el nombre visible en VS Code y el identificador en Copilot CLI. La disponibilidad de modelos y la delegación dependen del cliente.

Explore registra los contratos, patrones y ejemplos de aceptación. Propose agrupa código, pruebas y documentación que entregan el mismo resultado. En Adaptive cada paso indica un nivel, por ejemplo `Execution: medium`, y una revisión focalizada si corresponde. Separa los resultados comprobables y enlaza los pasos que dependen de ellos. Una vez resuelta una decisión difícil, vuelve a clasificar la implementación pendiente. Apply completa las fases pendientes si se invoca directamente y despacha un paso delegable a la vez. Verify comprueba alcance, evidencia vigente y fronteras de riesgo, incluso si se invoca por separado.

Para comparar los modos, parte de la misma revisión con los mismos requisitos, controles y configuración de roles. Cuenta desde Explore hasta la aceptación final. Compara cuota del principal por cambio aceptado, tiempo, correcciones y regresiones. Cada paso Adaptive registra `Executed:` (executor, principal o executor-then-principal) y su número de correcciones. Si el cliente oculta el consumo por modelo, deja ese dato como desconocido.

**Un solo SPEC activo por proyecto (opcional).** Crea el directorio `.litespec/serial/` antes de iniciar sesiones en esa copia del proyecto. El primer principal adquiere el turno durante su invocación. Si hay competencia, la otra sesión informa y cede. Cuando el principal devuelve el control, otra sesión puede retomar el SPEC activo. Para abrir uno nuevo hay que archivar el anterior. Tras una interrupción, consulta la nota de propietario y confirma que todos los ejecutores se detuvieron antes de retirar manualmente `.litespec/serial/busy/`. Para desactivar la opción, quita el directorio serial vacío cuando no haya actividad.

### Reconfigurar perfiles

En la instalación, Enter acepta el modelo que aparece junto a cada perfil.

| Modo y perfil | Codex | Claude Code |
|---|---|---|
| Adaptive · Fácil (`easy`) | `gpt-6-luna` | `haiku` |
| Adaptive · Medio (`medium`) | `gpt-6.2-sol` | `sonnet` |
| Auto model · Indexación (`search`) | `gpt-6-luna` | `haiku` |
| Auto model · Análisis acotado (`plan`) | `gpt-6.2-sol` | `sonnet` |
| Auto model · Investigación compleja (`research`) | `gpt-6.2-astra` | `opus` |

Para la sesión principal, el instalador sugiere Astra u Opus, porque el principal explora, redacta las specs, resuelve los pasos difíciles y verifica a los ejecutores. Elige el modelo principal en el cliente. Cada perfil tiene esfuerzo predeterminado `medium`. Puedes escribir otro nivel compatible, como `high`, o `inherit` en cualquiera de los dos campos para que el cliente resuelva el modelo o el esfuerzo. Las versiones detrás de los alias de Claude Code dependen del proveedor.

Edita cada perfil en `.codex/agents/` o `.claude/agents/`. Define `model` y un esfuerzo compatible mediante `model_reasoning_effort` (Codex) o `effort` (Claude). Los campos omitidos usan los valores predeterminados del cliente. Claude también acepta `model: inherit`. Para desactivar Adaptive manualmente en Codex o Claude Code, borra los perfiles `litespec-easy` y `litespec-medium`. Al reinstalar se eliminan el perfil retirado `litespec-very-easy`, el nombre anterior `litespec-easy` del ejecutor único y `easy-worker.md`. Ejecutar de nuevo el instalador regenera estos perfiles y reemplaza las ediciones manuales.

Para cambiar de modo, ejecuta el instalador para el mismo cliente. Para desactivar los roles manualmente, borra el marcador instalado `litespec-shared/delegation-active.md` y los perfiles que enumera. Después abre una sesión nueva.

## Numeración de versiones

LiteSpec usa el formato `vMAYOR.MENOR.PARCHE`.

- **Parche** sube con cambios de interfaz y ajustes pequeños.
- **Menor** sube con cambios medianos en la especificación o cuando el parche ya llegó a `999`.
- **Mayor** sube con un cambio de gran alcance en LiteSpec o cuando la versión menor ya llegó a `999`.

Al subir la versión menor, el parche vuelve a `0` (`v0.1.999` → `v0.2.0`). Al subir la versión mayor, ambos vuelven a `0` (`v0.999.0` → `v1.0.0`).

## Licencia

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Permite usar, modificar y distribuir, incluido uso comercial, conservando el aviso de autoría y la licencia.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
