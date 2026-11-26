# IHMJ-LAB — "I Hate My Job"

Prototipo personal en Godot 4.6 / GDScript. Simulador de supervivencia laboral
(Mayui: casa, trabajo de oficina, estrés/cordura/energía, economía, diálogos).
Todo el contenido del juego (UI, diálogos, emails) va en **español**.

## META ACTUAL (solo una)
**El tutorial es una SEMANA jugable** que muestre lo que se podrá hacer en el juego (Ramiro, 2026-11-26): un borrador para
que el equipo se inspire mientras Ramiro avanza la historia. **Todavía no está hecho.**
- ✅ **Bloque de la casa** (cimientos y lo necesario del tutorial, 2026-11-26): la primera mañana, despertar -> asearse ->
  uniforme -> cocinar/comer -> lavarse dientes -> salir -> casero. Diseño: `Docs/Design/Flow de juego.txt`.
- **Siguiente bloque: por acordar con Ramiro.** Mientras no esté acordado, solo arreglos de lo ya hecho: no se amplía nada
  más (ni playground, ni minijuegos, ni ciudad, ni contenido narrativo nuevo).

## ESTADO (actualizar al cerrar cada sesión)
- **Diseño en curso: la oficina y la savia** (2026-11-26, sin programar): `Docs/Design/OFICINA_BORRADOR.md` (P96).
- **Documentación para los devs** en `Docs/Dev/` (formato de sus fichas del Notion; índice `00-cambios-ia.md`). Al cambiar
  un sistema, actualizar su ficha. Pendiente de publicar en Notion.
- **Errores confirmados sin arreglar** (`Docs/Dev/escalabilidad.md`): el guardado solo recupera el dinero; la paga del
  viernes se pierde (800 en vez de 1000); la alarma no despierta a la hora elegida.
- El juego arranca en `Scenes/World/Apartment.tscn` (tutorial de la mañana). Zonas: Apartamento, Baño, Balcón, Pasillo,
  Recepción (`Lobby`), Oficina y Comercial; cada una con cámara (zoom 5). Apartamento, Baño y Balcón son la casa
  (`ZoneManager.is_home`). Dentro del edificio de Mayui (casa, pasillo y recepción, `HOME_BUILDING`) cambiar de zona no cuesta
  tiempo ni energía: solo la calle (regla de Ramiro, 2026-11-25). Los eventos con diálogo esperan a que Mayui esté en su zona
  (`narrative_event_handler.gd`, tabla `event_zones`). Z interactúa y avanza diálogos; puertas y escaleras se usan caminando
  contra ellas (`push_to_use`). Reloj arriba al centro.
- Segunda prueba de Ramiro (2026-11-25, tras el pasillo), hecho: estufa que se cancelaba al salir de la zona
  (`ContainerManager` sostiene las estaciones, `get_live_resources`), calendario pegado en el escritorio, punto sobre lo
  usable en vez del cartel, estornudo dentro de la ducha y salir mirando abajo, lavamanos coherente, escritorio, cocina
  (estaciones por tipo, sin cuadros, alacenas más grandes), transición del armario, 4 puertas, recepción con rejilla. La
  renta vence el viernes y el dinero inicial es 350. Pendientes de Ramiro: P83–P87. Sin subir a GitHub hasta que lo revise.
- Tercera ronda (2026-11-25): puerta del baño sobre la esquina; puertas del edificio al fondo de su hueco; punto pequeño y
  difuminado; frase del calendario; **comida instantánea** (`instant_box`/`instant_meal`, receta
  `Crafts/Kitchen/InstantMeal`, estufa 5 min; P25).
- Cuarta ronda (2026-11-26): en casa queda **solo una comida instantánea** y la olla, **sin bolsas de ingredientes**
  (decisión de Ramiro; P88 cerrado). La comida casera sigue en el sistema; las pruebas ponen bolsas cuando las necesitan.
  Anotado para después: comprar comida en la zona comercial (P90) y plato contra olla (P91).
- Quinta ronda (2026-11-26), fregadero: la olla queda dentro de la pila (`SinkFront`, recorte del fondo), se ve lo que lleva
  (`station_content_props` / `content_textures`; PNG provisionales de `Tools/contenido_olla_provisional.ps1`), al usar cae
  el agua 1 s (`Crafts.active_seconds`) y el botón dice **Vaciar** si hay algo dentro (`Crafts.button_text`; lo de dentro se
  bota). P92. En toalla la cocina no se abre en la mañana del tutorial (`home_kitchen.gd`, `towel_messages`: "Necesito
  ponerme algo.", la frase de la puerta; P93).
- Sexta ronda (2026-11-26): la puerta del baño va en un hueco como las del pasillo, en el cuarto y en el baño; arriba a la
  izquierda sale **Llevas** (`UI/PLAYERUI/hands_hud.gd`: manos y mochila, de arriba hacia abajo, escondida con pantallas); el
  casero espera a que Mayui pase frente a la recepción (`NarrativeEventHandler.event_spots` + Area2D `FrenteRecepcion` en
  `Lobby.tscn`). P94–P95.
- **Edificio cerrado por ahora** (Ramiro, 2026-11-26): lo que falta dentro es arte/sonido o fases posteriores. La calle y el
  trabajo necesitan su guion del Bloque 1-2 (P68).
- Pasos de caminar PROVISIONALES de casa/toalla/Outfit 1 (`Tools/pasos_provisionales.ps1`, desde el cuadro quieto; el arte
  real se pega en las mismas hojas, P54). El escritorio permite comer ahí (P27) y el fregadero vacía la olla (P81).
- Pasillo y recepción (2026-11-25, según los planos de Ramiro): `Hallway.tscn` (zona 6; escaleras y puertas M-21 a M-24)
  y `Lobby.tscn` (piso 1; recepción con rejilla, mantenimiento, casero, puerta a la calle en bus). La puerta de casa lleva al
  pasillo. Fondos provisionales en `Assets/Building/` (P80); falta hablar/pagar en la recepción (P87). La puerta del
  tutorial repite el aviso en vez de quedarse muda (`task.gd`, P69); Z también elige en las preguntas
  (`Dialogic.Choices.use_input_action`, P82); la estufa vacía tiene frases (`stove_empty_lines` en `KitchenMultiUI.tscn`); la ducha muestra la silueta tras la cortina (`UI/Shower/`, señales `estornudo` y `ducha_fuera` en
  `ducha_tutorial.dtl`, P70).
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
  terminar en 0 FALLA. La cama tampoco deja volver a dormir en esa mañana (mismo `check_events`, frases `_BED_*`). "Voy tarde" a
  las 07:30/07:40/07:50 con eventos con hora (`DAY1_VOY_TARDE_*`, `narrative_event_handler.gd`; P73); `Tools/probar_voy_tarde.gd`.
  Lo que queda del guion de la mañana necesita arte u objetos nuevos (balcón, calendario, nevera, comida instantánea, escritorio):
  antes, prueba de juego de Ramiro.
- Armario del tutorial (2026-11-24): antes de ducharse no se abre (`check_events` en `integration_action.gd`, `event_messages` del
  nodo `Wardrobe`); en la mañana del tutorial (hasta la bandera `tutorial_door_done`) la pijama no se pone; al ponerse el uniforme
  ya duchada suena `armario_uniforme.dtl`; la cesta habla si hay ropa sucia. Frases en `wardrobe_ui.tscn` (StringChain en modo
  ORDER: en orden y la última se repite). Los diálogos van en la capa 10 (`test_style.tres`) para verse sobre las pantallas.
  Pendientes P71 (ropa sucia) y P72 (casual).
- Ducha (2026-11-24): la primera vez en el tutorial suena `DialoguePlugin/TIMELINE/ducha_tutorial.dtl` (propiedad `dialog` del nodo
  `Shower`, la lanza `bathe.gd`); al insistir, las claves `_TAKE_BATH_*` en su `cooldown_timer_message` (`StringChain` ahora aplica
  `tr()` y vuelve a la primera frase en cada enfriamiento). Falta sonido y el dibujo real (P70). En las pruebas, pasar los
  diálogos con Z: cerrarlos con `end_timeline` a media frase deja a Dialogic sin avanzar el siguiente.
- Ropa (2026-11-22): `PlayerManager` guarda lo que lleva Mayui (`outfit`) y lo colgado (`wardrobe`); cada prenda es un `Item` tipo CLOTH con `cleanliness` y `wetness`; la ropa se ensucia/seca con el reloj y afecta Suciedad, Debilitamiento y Estrés (números propuestos, P45). La UI del armario es `UI/Containers/wardrobe_ui.tscn` (mouse, 1 s de cambio, 2 min) con el arte de `Assets/UI/Wardrobe/`. Bañarse deja la toalla. Espejo del lavamanos HECHO (`UI/Mirror/mirror_ui.tscn`: cepillo = Cepillarse una vez al día con tarea TEETH, espejo = verse la cara, llave = lavar ropa; el vaso, el tubo y el cepillo van DELANTE del marco, porque el espejo está pegado a la pared (recorte `CupFront`, P51); antes de comer en el tutorial Mayui lo impide; pendientes P49, P51-P53; `Tools/probar_espejo.gd` debe terminar en 0 FALLA). Sprites del mundo de la ropa de casa, la toalla y el Outfit 1 HECHOS (P48; solo cuadros quietos, `Tools/armar_hojas_mayui.ps1` arma las hojas de `Assets/Mayui` desde los `.aseprite` de `Docs`; faltan sus cuadros de caminar, P54, y la cabeza, P55). PENDIENTE: cesta (P47), prenda/ítem del Outfit 1, eventos que ensucian (P46). `Tools/probar_ropa.gd` debe terminar en 0 FALLA.
- Flujo del juego (2026-11-22): `Tools/probar_flujo.gd` (debe terminar en 0 FALLA) cubre aparición por zona
  (`SpawnPoint.from_zone`), Mayui quieta con UI abierta (`GameManager.modal_count += 1` al abrir y `-= 1` al cerrar),
  diálogos, asistencia, cambio de zona (2 s en total, `ZoneManager.ZONE_FADE_TIME`, con Mayui quieta hasta que aclara) y acciones
  del apartamento. La historia de relleno está APAGADA: `NarrativeEventHandler.story_enabled = false`.
  La traducción de Dialogic está desactivada (los ids de los `.dtl` se repiten entre archivos; no activarla sin ids únicos).
- Cuarto de Mayui (2026-11-25, forma aprobada por Ramiro: **L invertida**): fondo provisional
  `Assets/Apartment/cuarto_provisional.png` (recortado de la captura del tileset), paredes en el nodo `Paredes`, muebles
  provisionales de colores **sólidos**, puerta principal en un hueco de la pared (caminando contra ella) y cámara fija con
  el cuarto entero en pantalla. Mayui despierta junto a la cama. Si se mueve un mueble, actualizar su plano en
  `Tools/probar_cuarto.gd` y correrla (P74).
- Baño (2026-11-25): escena aparte `Scenes/World/Bathroom.tscn` (puerta `sceneChanger` a la izquierda de la entrada) con la
  ducha (`Shower`, antes en el cuarto), el lavamanos (`Sink`) y `UILayer/MirrorUI`. Fondo `Assets/Apartment/bano_provisional.png`
  y cortina `cortina_ducha.png`, recortada del tileset del equipo (P75).
- Balcón (2026-11-25): escena `Scenes/World/Balcony.tscn` con tendedero (sin mecánica); la puerta de abajo
  (`balcony_door.gd`) en la mañana del tutorial solo dice tus frases y después lleva al balcón. "¿Sigue la mañana del
  tutorial?" = `exit_door.gd` → `in_tutorial_morning()` (P76).
- Frases del cuarto (2026-11-25, DIALOGOS): nevera antes de ducharse (`home_kitchen.gd`: no abre la cocina), calendario
  (`calendar.gd` + `calendario_1/2.dtl`) y escritorio después de comer (`desk.gd`) (P77).
- Arranque del tutorial (2026-11-25, Bloque 1-1 y Flow): Mayui despierta con Maloliente y Hambre (`tutorial.gd`), cuarto
  a oscuras con luz del balcón (nodo `Madrugada`) y ayudas en `UI/Tutorial/tutorial_hud.tscn` (dentro de `PlayerUI`): lista
  de tareas (`Task.display_name`), cómo moverse/usar y ratón en cocina y espejo (grupo `tutorial_mouse_ui`). Todo se apaga al
  salir la primera vez (P78).
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
- Prueba del "Voy tarde" (reloj pasadas las 7:30):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_voy_tarde.gd`
- Prueba de la casa y el edificio (cuarto, baño, balcón, pasillo y recepción: paredes, muebles, puertas, frases y caminar
  con las teclas hasta cada cosa; ~2,5 min):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_cuarto.gd`
- Jugar la mañana entera como una persona (teclas, clics y arrastres de ratón; ~1 min; agregar `-- <carpeta>` sin
  `--headless` para guardar fotos):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/jugar_manana.gd`
- El "jugador torpe" (insiste en todo, desordena la cocina al azar y comprueba que nada se pierde y que aún se puede
  terminar; ~4 min; `-- <acciones> <semillas...>` para más combinaciones):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_torpe.gd`
- Teclas y clics al azar por la casa y el edificio (busca atascos y paredes atravesadas; ~5 min):
  `& "D:\Tools\Godot-4.6\Godot_v4.6-stable_win64_console.exe" --headless --path . -s res://Tools/probar_mono.gd`
  En las pruebas, los diálogos de Dialogic solo reciben teclas con `Input.parse_input_event` (`root.push_input` no los avanza).
- Si algo no se refleja en Godot: cerrar Godot, borrar la carpeta oculta `.godot/` y reabrir.

## MODELOS (plan Pro, ahorrar tokens)
- Sonnet: trabajo diario (código, arreglos, conectar sistemas).
- Haiku: cambios mecánicos (renombrar, números, textos, llenar `.tres`).
- Opus: solo diseño de estructura o bugs que Sonnet no resuelve en 2 intentos.
- Sesiones cortas y con un objetivo; no releer documentos largos al inicio.
