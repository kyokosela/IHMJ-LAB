# Sistema de interacción y puertas (cambios IA)

Status: En revisión
Assign: Sela (hecho con IA)

Amplía la ficha **Sistema de interaccion** del equipo.

# 📘 `Interactable` (cambios)

## 📤 Variables nuevas

| Variable | Tipo | Para qué |
|---|---|---|
| `push_to_use` | bool | Puertas: son sólidas y se usan **caminando contra ellas** (sin `Z`) |
| `mark_offset` | Vector2 | Dónde va el punto sobre el objeto |

- `display_text` ya no muestra un cartel: si no está vacío, sale un **punto difuminado** sobre el objeto (`_add_mark`).
- No se interactúa con diálogo o pantalla abierta (`GameManager.is_input_blocked()`).
- "Estar delante" se anota siempre, aunque la acción esté ocupada (antes quedaba pegada).

# 📘 `InteractableAction` (cambios)

- El tiempo se calcula con `PlayerManager.get_time_cost_with_effects` (con topes).
- `_process_action_stress_risk()`: la Hipersomnia puede causar Estrés en cualquier acción.
- El **cooldown sobrevive** a salir y volver a la zona; la cadena de frases se reinicia en cada cooldown.
- Una tarea sin frases ya no abre un cuadro vacío.

# 📘 Puertas

- `sceneChanger.push_to_use` + `pushed(quien)`; si no, cambia de zona al pisarlo.
- `MovementComponent._notify_push`: cuando una casilla está bloqueada, avisa una vez por empujón al nodo que tenga
  `pushed()`.

# 📘 Acciones de la casa (`Scripts/HouseInteracts/`)

Todas heredan de `InteractableAction` y usan `check_events()` para bloquear y `custom_execute()` para actuar.

| Script | Qué hace |
|---|---|
| `exit_door.gd` | Puerta principal: exige la rutina del tutorial y el uniforme puesto. Define `in_tutorial_morning()` |
| `balcony_door.gd` | En la mañana del tutorial solo habla; después lleva al balcón |
| `bathe.gd` | Ducha (ver [Ropa y ducha](ropa-ducha-espejo.md)) |
| `bed.gd` | `PlayerManager.request_sleep` |
| `calendar.gd` | Lee en orden los diálogos de `readings` |
| `desk.gd` | Comer sentada en el escritorio |
| `home_kitchen.gd` | La cocina no se abre antes de ducharse ni en toalla |
| `morning_light.gd` | Oscuridad de la primera mañana (es un `Node2D`, no una acción) |

# ⚠️ `integration_action.gd` (provisional)

Un solo script con un `enum ActionType` de **51 acciones**: unas del juego y muchas trampas de prueba (aplicar efectos,
sumar dinero, avanzar día).

| Usado en el juego real | Acción |
|---|---|
| Cama · Armario (apartamento) | `SLEEP_BED` · `CHANGE_CLOTHES` |
| Lavamanos (baño) | `OPEN_MIRROR` |
| Arcade · Mercado (comercial) | `OPEN_ARCADE` · `OPEN_MARKET` |
| Oficina | `CLOCK_IN` · `CLOCK_OUT` · `OPEN_WORKSPACE` · `TALK_MADINA` |

**Plan:** una acción pequeña por archivo (como las de arriba) y dejar las trampas solo en el playground.
`PAY_RENT` no está conectado a ninguna escena real: hoy **no se puede pagar la renta** jugando.

## Otros arreglos

- `InteractableContainer`: los ítems iniciales solo la primera vez; reutilizable.
- `Task.get_message`: agotadas las frases se repite la última. `Task.display_name` nuevo (lista en pantalla).
- `StringChain`: aplica `tr()`, modo ORDER desde la primera, `reset()`.
- `InteractionComponent`: no falla al abrir la escena en el editor.
