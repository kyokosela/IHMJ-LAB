# Guardado, sonido, HUD y depuración

Status: En revisión
Assign: Sela (hecho con IA)

# 💾 `SaveManager` (cambios)

Además de los `SaveComponent`, **cada manager guarda y carga lo suyo** (`get_save_data` / `load_save_data`); `SaveManager`
solo los junta en un archivo (`user://saves/save_1.res`). Hecho el 2026-11-26; diseño y trampas en
[`GUARDADO.md`](../Design/GUARDADO.md).

## ⏯️ Cuándo se guarda y cómo se carga

- **Solo al despertar de dormir** (`PlayerManager.sleep()` → `GameManager.autosave()`), también tras un desmayo.
- Cargar: `Shift+L` → `GameManager.load_game()`: carga los datos y abre la zona guardada; Mayui aparece en el punto general
  (en su cuarto, junto a la cama). **No hay menú «Continuar»:** abrir el juego empieza una partida nueva.
- `GameManager.save_slot` (ranura) y `autosave_enabled` (las pruebas que duermen lo apagan).

## 📦 Qué guarda cada uno (orden de carga)

| Orden | Quién | Qué |
|---|---|---|
| 1 | `TimeManager` | Día, semana, mes, hora. Se pone **sin avisar** (`_loading`): cargar no cierra el día, ni paga, ni anota faltas |
| 2 | `EventManager` | Si cada evento con hora ya ocurrió, cuáles están en curso y **todos los contadores** con lo que les falta |
| 3 | `PlayerManager` | Estadísticas, efectos con nivel y días, cordura, hábitos del día, sueño, Insomnio, ropa, manos y mochila |
| 4 | `ContainerManager` | La cocina (incluida la que está en pantalla) y si la estufa está cocinando |
| 5 | `TaskManager` | Listas de tareas activas: hecha o no y su espera |
| 6 | `ZoneManager` | Zona y costo creciente de la calle |
| 7 | `NarrativeEventHandler` | Eventos con diálogo que esperan a Mayui y avisos de "Voy tarde" ya dichos |
| 8 | Economía, asistencia, relaciones, banderas, correos | Como antes (asistencia: también falta/salida anticipada de hoy) |

**Contadores:** lo que hace cada uno al cumplirse (una función) no se puede guardar. Al cargar se rehacen vacíos y su dueño
se la devuelve con `EventManager.restore_lapse_callable` (`PlayerManager` y `GameManager`); las esperas de las acciones y
la estufa se reenganchan solas al abrirse la escena.

## 🐞 Corregido tras la prueba de Ramiro (2026-11-26)

Después de pasar por la oficina, `Shift+L` se cortaba: `SCRIPT ERROR: Trying to assign invalid previously freed instance`
en `load_from_disk`. Un `SaveComponent` de la PC de la oficina seguía en la lista tras cerrarse la escena (solo se da de
baja con `queue_free`) y el bucle con tipo abortaba toda la carga. Ahora la carga salta y quita los componentes liberados,
como ya hacía `save_to_disk`. La prueba recorre ese camino con el cambio de zona real y también carga en un **segundo
proceso** (como cerrar y abrir el juego).

## ⚠️ Límites conocidos

- Las frases de la puerta del tutorial y las de cama, armario o nevera (`StringChain`) vuelven a la primera.
- Los `SaveComponent` de `Player.tscn` siguen escribiendo sus datos (incompletos); `PlayerManager` los reemplaza al cargar.
- Probado con `Tools/probar_guardado.gd` sin ventana y jugando (Ramiro, 2026-11-26).

# 🔊 `AudioManager` (autoload)

`play(clave)`, `play_loop(clave)`, `stop_loop(clave)`. Busca `Audio/SFX/<nombre>.ogg` o `.wav`; **si falta, no suena y no
da error**. Hoy no hay archivos: poner el sonido con el nombre esperado lo activa.

Claves: `click`, `coin`, `coin_spend`, `sleep`, `alarm`, `correct`, `wrong`, `shower`, `stomach`, `morning`.

# 🖥️ HUD

- `player_ui.gd`: hora desde el inicio, dinero y día; iconos de efectos por nivel.
- `hands_hud.gd`: **Llevas** (arriba a la izquierda).
- `UI/Sleep/alarm_ui.gd`: hora de **despertar** (propone la primera en punto en la que ya habrá descansado y da la vuelta a
  medianoche), probabilidad de despertar con Insomnio, Cancelar/`Esc`.

# 🐞 Depuración (solo en builds de depuración salvo indicación)

| Tecla | Qué hace |
|---|---|
| `F3` | Panel de efectos, cordura y reloj |
| `Shift+S` / `Shift+L` / `Shift+P` | Guardar, cargar, imprimir guardado |
| `H` / `J` | Teclas de prueba (⚠️ activas siempre) |

`Scenes/Playground_Integration.tscn`: banco de pruebas de abril, desordenado y **congelado**.
