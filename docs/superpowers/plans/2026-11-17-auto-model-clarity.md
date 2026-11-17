# Auto model: claridad y aislamiento
> Ejecucion: superpowers:executing-plans, en el repositorio indicado por el usuario.
Objetivo aprobado: conservar las seis skills, aclarar opciones y evitar que Zed aplique la delegacion de Codex.
Diseno: conservar marcadores; el protocolo exige coincidencia con el cliente actual antes de cargar delegation.md. Cliente desconocido: flujo normal.
Archivos: ambos instaladores, protocol.md, delegation.md, ambos README y tests/installers.cjs.
Compatibilidad: PowerShell 5.1, Bash 3.2; sin dependencias nuevas ni cambios en las seis skills.
- [x] Agregar regresion Codex Auto -> Zed -> Codex: conservar archivos y exigir guardia por cliente; observar fallo.
- [x] Aclarar menu, herencia y resumen: agente, modo, archivos creados/restaurados/conservados/guardados.
- [x] Actualizar protocolo y documentacion con instrucciones breves compatibles con marcadores antiguos.
- [x] Ejecutar suites PowerShell/Bash, sintaxis y diff; comparar las seis skills contra HEAD y HEAD~1.
Revisar: marcadores antiguos, cliente desconocido, reinstalacion, personalizaciones y desactivacion/reactivacion.
No crear commit ni instalar sobre el repositorio. Casos en tests/.runs/, retirados al terminar.

Verificacion: regresion RED por ausencia de guardia; GREEN en PowerShell y Bash, 13 agentes, ambos adaptadores y contadores. Sintaxis y git diff --check correctos. Seis skills intactas respecto de HEAD y del commit previo. Revision adicional sin hallazgos importantes.
Limite: la guardia es una instruccion del protocolo; no se comprobo obediencia ni modelos en una sesion real.
