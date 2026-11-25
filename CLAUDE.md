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
  comer con clic derecho/doble clic desde las manos, COOK marcada). Su UI ya usa el arte de IHMJ ART (`Assets/UI/Kitchen/`, escena
  `KitchenMultiUI.tscn`: capas de 1900x1080, dos alacenas que abren (12 casillas), olla, fuego, humo y agua; pendientes P37–P44). Comida casera (decisión de Ramiro): bolsa -> tabla -> **Combinar** (olla + ingredientes) -> estufa 45 min -> comer
  desde la olla; regla de lo cocinado del dev: `preparation` no_prepared -> prepared -> cooked. `Tools/probar_crafteos.gd` debe terminar
  en 0 FALLA (nada se duplica ni se pierde, ni al salir de la zona con la estufa cocinando). Pendientes del dev: P25–P31 en `DECISIONES_Y_PENDIENTES.md`.
  Íconos PROVISIONALES (imágenes de Gemini) en `Assets/Items/*.png`, asignados en `texture` / `held_textures` de cada `.tres`
  (`Item.get_display_texture`; el arte real solo reemplaza los PNG con el mismo nombre; P38). Los originales (`Docs/ItemIAgenerated`)
  no van en git.
  Diseñados y pendientes de OK: Desmayo por lugar y Sueño acumulado.
- Prueba de juego de Ramiro (2026-11-24), corregido: lo picado y lo cocinado se queda en su estación y lo combinado en la casilla
  de resultado; la alarma tiene Cancelar/Esc; el ratón funciona en la PC (tapaba un Control del `Player.tscn`) y se quitó la app
  de prueba que borraba a Mayui; Madina responde "..." con la historia apagada; el bus no gasta energía. Segunda ronda: solo se come
  lo cocinado, lo de Combinar se queda al salir y la estufa tiene **Esperar** (avisa y adelanta el reloj). Guía de recetas, objetos y
  estados: `Docs/Design/COCINA_Y_OBJETOS.md`. Guion contra juego: `Docs/Design/TUTORIAL_ESTADO.md` (la mañana tiene guion en Notion
  → DIALOGOS y está a medias; el trabajo no tiene guion). Pendientes P56–P68.
- Puerta y hora del tutorial (2026-11-24): la partida empieza a las **06:00**. La puerta (`MainDoor`, `Scripts/HouseInteracts/exit_door.gd`)
  usa la lista de tareas del dev (`TutorialDoor.tres`: ducha, uniforme, comer, cepillarse) con las frases del guion
  (`Interacts.csv`); el uniforme tiene que estar **puesto** al salir; la primera vez dice "Aquí vamos."; después deja salir directo.
  El arreglo provisional de la puerta en `tutorial.gd` está retirado (queda solo el arranque y "Tengo que ducharme."). El casero pasó a
  las 06:00 (sigue esperando a que Mayui llegue al lobby). `Tools/probar_tutorial.gd` juega la mañana completa (la meta) y debe
  terminar en 0 FALLA. Próximo paso: frases del armario y la cama.
- Ducha (2026-11-24): la primera vez en el tutorial suena `DialoguePlugin/TIMELINE/ducha_tutorial.dtl` (propiedad `dialog` del nodo
  `Shower`, la lanza `bathe.gd`); al insistir, las claves `_TAKE_BATH_*` en su `cooldown_timer_message` (`StringChain` ahora aplica
  `tr()` y vuelve a la primera frase en cada enfriamiento). Faltan transición, silueta y sonido (P70). En las pruebas, pasar los
  diálogos con Z: cerrarlos con `end_timeline` a media frase deja a Dialogic sin avanzar el siguiente.
- Ropa (2026-11-22): `PlayerManager` guarda lo que lleva Mayui (`outfit`) y lo colgado (`wardrobe`); cada prenda es un `Item` tipo CLOTH con `cleanliness` y `wetness`; la ropa se ensucia/seca con el reloj y afecta Suciedad, Debilitamiento y Estrés (números propuestos, P45). La UI del armario es `UI/Containers/wardrobe_ui.tscn` (mouse, 1 s de cambio, 2 min) con el arte de `Assets/UI/Wardrobe/`. Bañarse deja la toalla. Espejo del lavamanos HECHO (`UI/Mirror/mirror_ui.tscn`: cepillo = Cepillarse una vez al día con tarea TEETH, espejo = verse la cara, llave = lavar ropa; el vaso, el tubo y el cepillo van DELANTE del marco, porque el espejo está pegado a la pared (recorte `CupFront`, P51); antes de comer en el tutorial Mayui lo impide; pendientes P49, P51-P53; `Tools/probar_espejo.gd` debe terminar en 0 FALLA). Sprites del mundo de la ropa de casa, la toalla y el Outfit 1 HECHOS (P48; solo cuadros quietos, `Tools/armar_hojas_mayui.ps1` arma las hojas de `Assets/Mayui` desde los `.aseprite` de `Docs`; faltan sus cuadros de caminar, P54, y la cabeza, P55). PENDIENTE: cesta (P47), prenda/ítem del Outfit 1, eventos que ensucian (P46). `Tools/probar_ropa.gd` debe terminar en 0 FALLA.
- Flujo del juego (2026-11-22): `Tools/probar_flujo.gd` (debe terminar en 0 FALLA) cubre aparición por zona
  (`SpawnPoint.from_zone`), Mayui quieta con UI abierta (`GameManager.modal_count += 1` al abrir y `-= 1` al cerrar),
  diálogos, asistencia, cambio de zona (2 s en total, `ZoneManager.ZONE_FADE_TIME`, con Mayui quieta hasta que aclara) y acciones
  del apartamento. La historia de relleno está APAGADA: `NarrativeEventHandler.story_enabled = false`.
  La traducción de Dialogic está desactivada (los ids de los `.dtl` se repiten entre archivos; no activarla sin ids únicos).
- Existe `Scenes/Playground_Integration.tscn` (herramienta de pruebas, desordenada). Congelada.
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
     `Scripts/tutorial.gd` y `Scenes/World/Apartment.tscn` nacieron como placeholder de IA: la puerta ya usa las tareas; falta
     sustituir sus acciones sueltas (`integration_action.gd`) por las del dev.
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
- Pruebas de crafteos de la cocina (nada se duplica ni se pierde, regla de lo cocinado, olla, estufa, persistencia; tarda ~25 s):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_crafteos.gd`
- Pruebas de la ropa y el armario (modelo, efectos, UI; tarda ~15 s):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_ropa.gd`
- Pruebas del espejo del lavamanos y de cepillarse (tarda ~15 s):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_espejo.gd`
- Prueba de la mañana completa del tutorial, de despertar a encontrar al casero:
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_tutorial.gd`
- Si algo no se refleja en Godot: cerrar Godot, borrar la carpeta oculta `.godot/` y reabrir.

## MODELOS (plan Pro, ahorrar tokens)
- Sonnet: trabajo diario (código, arreglos, conectar sistemas).
- Haiku: cambios mecánicos (renombrar, números, textos, llenar `.tres`).
- Opus: solo diseño de estructura o bugs que Sonnet no resuelve en 2 intentos.
- Sesiones cortas y con un objetivo; no releer documentos largos al inicio.
