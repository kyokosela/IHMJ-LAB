# IHMJ-LAB — "I Hate My Job"

Prototipo personal en Godot 4.6 / GDScript. Simulador de supervivencia laboral
(Mayui: casa, trabajo de oficina, estrés/cordura/energía, economía, diálogos).
Todo el contenido del juego (UI, diálogos, emails) va en **español**.

## META ACTUAL (solo una)
**Tutorial de la mañana jugable de principio a fin:**
despertar -> asearse (ducha) -> uniforme (armario) -> cocinar/comer -> lavarse dientes -> salir.
Diseño: `Docs/Design/Flow de juego.txt`. Hasta cerrar esta meta, NO se amplía nada más
(ni playground, ni minijuegos, ni ciudad, ni contenido narrativo nuevo).

## ESTADO (actualizar al cerrar cada sesión)
- El juego arranca en `Scenes/World/Apartment.tscn` (tutorial de la mañana). Zonas: Apartamento, Lobby, Oficina y
  Comercial; cada una con cámara (zoom 5). Los eventos con diálogo esperan a que Mayui esté en su zona
  (`narrative_event_handler.gd`, tabla `event_zones`). Z interactúa y avanza diálogos. Reloj arriba al centro.
- Diseño unificado y pendiente de revisión de Ramiro: `Docs/Design/SISTEMA_GAMEPLAY.md`. Hoja de ruta F1–F5 en
  `DECISIONES_Y_PENDIENTES.md`; NO empezar una fase sin que Ramiro apruebe las decisiones D# que la tocan.
- Efectos implementados (Paso 1) dentro de `player_manager.gd` según `SISTEMA_EFECTOS.md`. Tras tocar números o efectos hay que
  correr `Tools/probar_efectos.gd` (debe terminar en 0 FALLA). En el juego, **F3** abre/cierra el panel de depuración
  (efectos, cordura, reloj). Pendiente de ese sistema: Desmayo, Desahogo, Suciedad en dos capas, ítems de medicina.
  Paso 2a HECHO: la cocina real (nodo `Kitchen` de `Apartment.tscn`: nevera = almacenamiento de la cocina, tabla de picar, combinar,
  comer con clic derecho/doble clic desde las manos, COOK marcada). Falta del Paso 2: armario real (`ApartamentD.tscn`), marcar
  CLOTHES/TEETH en `TaskManager`, puerta con `task_lists` y retirar `tutorial.gd`. Pendientes del dev: P25–P31 en `DECISIONES_Y_PENDIENTES.md`.
  Diseñados y pendientes de OK: Desmayo por lugar y Sueño acumulado.
- Flujo del juego (2026-11-22): `Tools/probar_flujo.gd` (debe terminar en 0 FALLA) cubre aparición por zona
  (`SpawnPoint.from_zone`), Mayui quieta con UI abierta (`GameManager.modal_count += 1` al abrir y `-= 1` al cerrar),
  diálogos, asistencia, cambio de zona (2 s en total, `ZoneManager.ZONE_FADE_TIME`, con Mayui quieta hasta que aclara) y acciones
  del apartamento. La historia de relleno está APAGADA: `NarrativeEventHandler.story_enabled = false`.
  La traducción de Dialogic está desactivada (los ids de los `.dtl` se repiten entre archivos; no activarla sin ids únicos).
- Existe `Scenes/Playground_Integration.tscn` (herramienta de pruebas, desordenada). Congelada.
- Pendiente menor: 3 `.tres` con UID duplicado (`home_meal`, `ingredients_bag`, `ingredients_unpack`).
- Próximo paso: ver `NEXT.md` si existe.

## REGLAS
1. Pasos pequeños: una cosa por vez, verificarla corriendo Godot, y recién ahí un commit.
2. Nunca declarar algo "terminado" sin haber ejecutado el juego o la comprobación.
3. Mantener la arquitectura actual: managers planos en `Scripts/`, autoloads en `project.godot`.
   No reestructurar a componentes (la migración al repo principal es futura y requiere consenso).
   **RESPETAR EL SISTEMA ACTUAL (acordado con Ramiro): ajustar la lógica DENTRO de lo que existe, no construir en paralelo.**
   - Efectos = Resources (`Effect`, `EffectLevel`, `EffectHourControl`, `TemporalEffect`) + lógica en `player_manager.gd`.
     Los 12 efectos y sus imágenes están hechos a mano: NO crear efectos nuevos ni renombrar. Arte por nivel solo existe
     para Estrés, Calma e Insomnio (3 iconos); el resto tiene un solo icono (sus niveles, si los hay, son internos).
   - Acciones = `InteractableAction` (`time_cost`, `stat_req_list`, `cooldown_time`, `task_lists`, mensajes): la "ficha"
     ya existe como propiedades; se configuran en el Inspector de cada escena. Hijas reales: `bathe.gd`, `bed.gd`, etc.
   - Tutorial = `TaskManager` + `TaskList` (`Resources/Task/Tutorial/TutorialDoor.tres`) + evento `TUTORIAL`.
     `Scripts/tutorial.gd` y `Scenes/World/Apartment.tscn` son un placeholder de IA con banderas propias: deben sustituirse.
   - Para ver los efectos en juego: `UI/Debug/debug_panel.tscn` (ya muestra cordura, efectos, día y hora); ampliarlo, no duplicarlo.
   - **Cocina, almacenamiento e ítems = sistema de un dev (Ghoko), ya hecho: seguirlo ESTRICTAMENTE, con sus reglas.** No crear código
     nuevo: solo completar o complementar lo que falta con cambios mínimos DENTRO de sus clases (`InteractableContainer`,
     `KitchenContainer`, `ContainerUI`, `InventorySlotUI`, behaviors, `Station`, `Crafts`). Las herramientas son los `.tres` y las escenas (lo que se configura en el Inspector).
4. **Fuente de verdad de los EFECTOS: `Docs/Design/SISTEMA_EFECTOS.md`** (validado con `Tools/simulacion_efectos.gd`;
   si se cambia un número, correr la simulación). **Del resto del gameplay: `Docs/Design/SISTEMA_GAMEPLAY.md`** (decisiones D# y pendientes P# en
   `Docs/Design/DECISIONES_Y_PENDIENTES.md`). El código se alinea a ese documento, no al revés. Si algo no está
   definido, NO inventar: anotarlo como pendiente y preguntar. `Docs/AMBIGUITIES.md` es histórico (lo generó una IA).
5. No modificar `.gd` cuando la tarea es solo contenido (`.tres`, `.dtl`, textos).
6. Verificar que existen los `.dtl` (`DialoguePlugin/TIMELINE/`) antes de llamar `Dialogic.start()`.
7. No usar git worktrees aislados; trabajar en la rama activa del repo.
8. Documentos históricos de IA (planes, handoffs) están en `Docs/archive/`: NO leerlos salvo
   que la tarea lo pida expresamente. Son largos y se contradicen entre sí.
9. Para el usuario: explicar sin jerga, pedir una sola cosa por vez.

## ENTORNO (Windows)
- Godot 4.6: `D:\Tools\Godot-4.6\Godot_v4.6-stable_win64.exe` (consola: `..._console.exe`)
- Git: `C:\Program Files\Git\cmd\git.exe` (puede no estar en PATH).
- Remoto: github.com/kyokosela/IHMJ-LAB
- Verificar sin abrir el editor (PowerShell, desde el proyecto):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . --import`
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . --quit-after 600`
  Buscar líneas `SCRIPT ERROR` / `ERROR`. Ruido conocido e ignorable: aviso del dock "EditorView" de Dialogic.
- Pruebas automáticas de efectos (reloj y cambio de día reales; imprime `FALLA` por cada error y al final el total):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_efectos.gd`
- Pruebas del flujo del juego (zonas, UI, diálogos, asistencia, apartamento; tarda ~40 s):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_flujo.gd`
- Si algo no se refleja en Godot: cerrar Godot, borrar la carpeta oculta `.godot/` y reabrir.

## MODELOS (plan Pro, ahorrar tokens)
- Sonnet: trabajo diario (código, arreglos, conectar sistemas).
- Haiku: cambios mecánicos (renombrar, números, textos, llenar `.tres`).
- Opus: solo diseño de estructura o bugs que Sonnet no resuelve en 2 intentos.
- Sesiones cortas y con un objetivo; no releer documentos largos al inicio.
