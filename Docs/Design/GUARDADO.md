# Guardado: plan aprobado y lo que hay que saber antes de programarlo

**Estado (2026-11-26):** aprobado por Ramiro con la condición de programarlo **con Opus**. Sin empezar.

## Qué pidió y aprobó Ramiro
Se guarda **solo, al despertar de dormir** (`SISTEMA_GAMEPLAY.md` §2.3):
1. Día, semana y hora.
2. Mayui: energía, salud, cordura, efectos con su nivel, sueño, ropa, manos y mochila.
3. La cocina y lo que se esté cocinando.
4. Tareas del tutorial, eventos y contadores en marcha (hambre, espera de la ducha…) y la zona.
5. Lo que ya se guarda: dinero, asistencia, relaciones, banderas y correos.

Para cargar, por ahora solo `Shift+L` (teclas de prueba). **No hay menú «Continuar»** ni carga sola al abrir el juego.

## Cómo trabajar
- Cada manager guarda y carga lo suyo (`get_save_data` / `load_save_data`, como economía y asistencia); `SaveManager` solo
  junta. Sin reestructurar (reglas en `CLAUDE.md`).
- Primero una comprobación que falle (`Tools/probar_guardado.gd`), luego el código; todas las pruebas de `Tools/` en
  **0 FALLA** y commit local, sin push.
- La prueba debe cargar **como al abrir el juego** (después de `new_game()`), no solo en la misma partida.
- Al terminar: `Docs/Dev/guardado-hud-debug.md`, `escalabilidad.md`, `efectos.md`, `pruebas.md` y ESTADO de `CLAUDE.md`.

## Qué guarda cada parte (visto en el código; casi nada probado corriendo)

| Dónde | Estado que hay que recuperar |
|---|---|
| `TimeManager` | `julian_day`, `day`, `week`, `month`, `year`, `minutes`; `triggered` de cada `ScheduleConfig` en `scheduled_times` |
| `PlayerManager` | Estadísticas; `effects` (cuáles, `level`, `days_active`, `time` del Sueño); `sanity_value`, `sanity_floor`, `daily`, `internal_levels`, `_internal_days`, contadores de sueño, Insomnio, Hiperactividad y Atenta, `hour_debt`, `slept_today`, `primary_reached_lv3`, `tired_actions`, `hungry_energy_log`, `last_night_proper`, `last_routine_full`, `proper_nights_in_row`; ropa (`outfit`, `wardrobe`, `_wet_minutes`) |
| `PlayerInventoryContainer` | Casillas y tamaño de mochila |
| `ContainerManager` | `container_states` (inventarios y hora) y estaciones de la cocina (`is_locked`, `active_craft_event`, `locked_slot_indices`) |
| `EventManager` | Eventos activos (`stack_active_events`, p. ej. `TUTORIAL`) y contadores `LapseEvent` (`timer_count`, duración, `auto_restart`) |
| `TaskManager` | Listas activas; por tarea `task_done`, `message_index`, `cooldown`, `is_cooldown` |
| `ZoneManager` | Zona actual y anterior, costo creciente de viajar; Mayui despierta junto a la cama |
| `NarrativeEventHandler` | `_late_said` y eventos pendientes (`_pending`, caducan al cambiar de día) |
| `AttendanceManager` | Ya guarda; faltan `absence_recorded_today`, `left_early_today`, `current_day_on_time` |

## Trampas
1. **Asignar el reloj dispara cosas** (faltas, cierre del día, chequeos de la mañana, eventos): cargar sin señales.
2. **Asignar estadísticas y `add_effect` tienen efectos secundarios** (energía ≥90 da Hiperactividad, energía 0 llama a
   `sleep()`, primarios opuestos, Insomnio, contadores nuevos): restaurar sin pasar por ellos y avisar al HUD.
3. **Los contadores llevan funciones enganchadas**, que no se guardan: cada dueño debe recrear las suyas. `PlayerManager`
   (`SLEPT_TODAY_RESET`, `REMOVE_WEAK_AUTOMATICALLY`, `TIMED_ATENTA`, `TIMED_HYPERACTIVE`), `GameManager.new_game`
   (`AUTO_SMELLY_LAPSE`, `AUTO_HUNGER_LAPSE`, `AUTO_SLEEPY_LAPSE`), cocina (`CRAFT_*`, la retoma
   `KitchenContainer._restore_stations`) y esperas de acciones (`*_COOLDOWN`, `InteractableAction._ready` se reengancha).
4. **El componente de guardado del jugador solo escribe lo exportado:** `Item` pierde usos, condiciones y contenido.
   Usar `InventoryComponent.to_dict/from_dict` (ya lo usa la cocina) y revisar los dos `SaveComponent` de `Player.tscn`.
5. `PlayerInventoryContainer._setup_inventory` **vacía las casillas**: restaurar después, con la mochila primero.
6. La cocina entrega su estado al salir de la zona: al guardar hay que pedirlo a los contenedores que estén en pantalla.
7. `SaveManager.load_from_disk` usa `load()`, que puede devolver el archivo **ya en memoria**: cargar ignorando la caché.
8. `new_game()` crea eventos y contadores: al cargar hay que reemplazarlos, no sumarlos.

## No mezclar
La tarjeta «Arreglar la semana de trabajo» toca `attendance_manager.gd` y `time_manager.gd`: hacerla **después**.
