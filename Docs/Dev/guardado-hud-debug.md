# Guardado, sonido, HUD y depuración

Status: En progreso
Assign: Sela (hecho con IA)

# 💾 `SaveManager` (cambios)

Además de los `SaveComponent`, guarda economía, asistencia, relaciones, banderas y correos. Tolera entradas que no son
`ComponentData`.

## ⚠️ El guardado está incompleto

Comprobado guardando y cargando (2026-11-26):

| Dato | ¿Se recupera? |
|---|---|
| Dinero | Sí |
| Día y hora | **No** |
| Cordura, energía y demás estadísticas | **No** |
| Efectos | **No** |
| Ropa | **No** |
| Tareas, eventos en curso, cocina, zona | **No** (no hay código que los guarde) |
| Manos y mochila | Tienen componente de guardado, pero solo escribe lo exportado: se perdería lo que lleva la olla, los usos y las condiciones (visto en el código, sin comprobar) |

No existe botón de guardar ni guardado al dormir: solo las teclas de prueba.

## 📝 Plan (esperando el OK de Ramiro; sin programar)

Cada manager guarda lo suyo y se guarda **solo al despertar de dormir** (§2.3): reloj; Mayui (estadísticas, efectos con su
nivel, sueño, ropa, manos y mochila); cocina; tareas, eventos y contadores en marcha; zona; y lo que ya se guarda. Cargar:
por ahora con `Shift+L` (no hay menú «Continuar»).

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
