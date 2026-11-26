# Sistema de eventos y partida nueva (cambios IA)

Status: En revisión
Assign: Sela (hecho con IA)

Amplía la ficha **Sistema de eventos lineal/rutas**. `EventManager` y `TimeManager` siguen siendo la base.

# 📘 `GameManager.new_game()` (`Scripts/game_manager.gd`)

La llama el apartamento la primera vez (`game_started`).

1. Limpia el guardado en memoria y el motor de efectos.
2. Reloj a las **06:00** y ropa inicial.
3. Carga la lista de tareas `TUTORIAL_DOOR` y el evento `TUTORIAL`.
4. Crea los eventos por tiempo: Maloliente (24 h), Hambre (6 h), Sueño por vigilia (16 h).
5. Carga **todos** los `.tres` de `Resources/Events/Schedule/`.
6. `_skip_past_events()`: lo programado antes de la hora actual se da por ocurrido, salvo lo que espera una zona.

## 🔒 Bloqueo de entrada

```gdscript
var modal_count : int              # +1 al abrir una pantalla, -1 al cerrarla
func is_input_blocked() -> bool    # hay pantalla abierta o diálogo
signal input_block_changed(blocked)
```

⚠️ Toda pantalla nueva debe sumar al abrir y restar al cerrar (también en `_exit_tree`), o Mayui queda trabada.

# 📘 `NarrativeEventHandler` (autoload)

**Responsabilidad:** convertir un evento activado en algo que pasa, **cuando Mayui está donde toca**.

```gdscript
var event_zones : Dictionary   # evento -> zonas válidas
var event_spots : Dictionary   # evento -> grupo de un Area2D por el que debe pasar
var story_enabled : bool       # false = la historia de relleno no corre
var story_events : Array       # qué cuenta como relleno
```

### Flujo

1. `EventManager.event_activated` → `_on_event_activated`.
2. Si es relleno y `story_enabled == false`, se ignora.
3. `_deliver`: si la zona y el punto sirven, se ejecuta; si no, queda pendiente.
4. Pendientes: se entregan al entrar a la zona (`ZoneManager.zone_ready`) o al pasar por el punto. Al cambiar de día se
   descartan.
5. `_run_event(nombre)`: un `match` con una función por evento.

⚠️ **Añadir un evento exige tocar código** (`match` y quizá `event_zones`), no solo crear el `.tres`.

También reacciona a: renta vencida, despido, faltas, correos enviados y señales de Dialogic. Activa
`Dialogic.Choices.use_input_action` para que `Z` elija opciones. Dice las frases de "Voy tarde" (07:30, 07:40, 07:50).

# 📘 `NarrativeFlags` (autoload)

Diccionario de banderas: `set_flag`, `has_flag`, `clear_flag`, `set_value`, `get_value`. Se guarda en disco.
⚠️ Los nombres son texto libre: un nombre mal escrito no da error, simplemente devuelve `false`.

# ⏱️ Cambio en `TimeManager`

`check_scheduled_times` descarta los horarios cuyo destinatario ya no existe (evitaba errores al cambiar de escena).

## Contenido

28 eventos en `Resources/Events/Schedule/` (7 días de la semana: casero, Veda, Madina, renta, salario, horario laboral,
mercado, arcade). La mayoría son **relleno** a la espera del guion.
