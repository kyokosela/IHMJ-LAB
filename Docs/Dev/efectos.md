# Sistema de efectos (cambios IA)

Status: En revisión
Assign: Sela (hecho con IA)

Amplía la ficha **Sistema de efectos** del equipo. La fuente de verdad de números y reglas es
[`SISTEMA_EFECTOS.md`](../Design/SISTEMA_EFECTOS.md). Los efectos siguen siendo Resources (`Effect`, `EffectLevel`,
`EffectHourControl`, `TemporalEffect`); la **lógica** vive en `PlayerManager`.

# 📘 `PlayerManager` (autoload, `Scripts/player_manager.gd`)

**Responsabilidad:** estadísticas, efectos, cordura, sueño, hábitos del día y ropa puesta.

⚠️ Tiene 1.470 líneas y 110 funciones. Es el archivo más delicado del proyecto (ver [Escalabilidad](escalabilidad.md)).

## 🗺️ Mapa del archivo (por regiones)

| Región | Qué hace |
|---|---|
| `LOGIC` / `EFFECTS API` / `STATS API` | Añadir, quitar y consultar efectos y estadísticas |
| `ACTIONS` | Dormir: alarma, horas mínimas, energía, deuda de sueño |
| `INSOMNIA TRIGGER MATRIX` | Qué dispara el Insomnio |
| `WORK TASK SUCCESS PENALTY` | El Estrés hace fallar tareas del trabajo |
| `PRIMARY EFFECTS` + motor diario | Estrés/Calma, cordura, hábitos, cierre del día y chequeos de la mañana |
| `Ropa puesta` | Ver [Ropa](ropa-ducha-espejo.md) |

## 📦 Estado interno principal

```gdscript
var sanity_value : float = 50.0      # cordura 0..100
var daily : Dictionary               # hábitos de hoy (comidas, baño, juego, pérdida de cordura...)
var internal_levels : Dictionary     # nivel I-III de efectos con un solo icono
var slept_today : bool
var rng                              # azar; las pruebas lo sustituyen
```

## 🔌 Puertas de entrada (lo que llama el resto del juego)

| Función | Cuándo se llama |
|---|---|
| `change_sanity(delta, origen)` | **Única** forma de cambiar la cordura en el juego: amortigua, protege con Calma, tope diario y piso |
| `add_stress_cause(origen)` / `mitigate_stress(n, origen)` | Causas y alivios de Estrés (máx. 2 niveles aliviados por día) |
| `register_meal(tipo, caliente)` | Al comer (`HOME` o `INSTANT`) |
| `register_bath(fria)` / `register_brush()` | Ducha y cepillado |
| `register_gamble(gano)` / `register_street_event()` | Arcade e imprevistos en la calle |
| `apply_timed_hyperactive(origen)` | Hiperactividad de 2 h (café, Atenta, Estrés) |
| `request_sleep(tipo_cama)` | La cama: abre la alarma y después `sleep()` |
| `get_time_cost_with_effects(hora)` / `get_cost_with_effects(stat, valor)` | Costo real de una acción, con topes |
| `get_work_success_rate()` | Probabilidad de acertar en el trabajo según el Estrés |
| `get_debug_report()` | Texto para el panel F3 |

## 🔁 Ciclo del día

1. A medianoche `_close_day()`: evalúa la **rutina saludable** (dinero, comida casera, baño, sueño; jugar es comodín),
   ajusta Calma/Estrés y cordura, y reinicia `daily`.
2. `_run_wake_checks()` (al despertar, o a medianoche si sigue despierta): escala efectos → Estrés/Calma por cordura →
   Insomnio y Atenta → Inapetencia e Hipersomnia → tiradas entre efectos → Debilitamiento.

## 😴 Dormir

`request_sleep` → `AlarmUI` → `sleep(duración, cama)` → fundido → avanza el reloj → `_finish_sleep` (energía, Estrés, deuda de
sueño, Insomnio) → se puede volver a dormir 12 h después.

**Despertador** (D1 y P13; corregido el 2026-11-26):

- Toda partida nueva tiene despertador (bandera `has_alarm_clock`, la pone `GameManager.new_game`).
- La pantalla pregunta a qué **hora** despertar y le pasa a `sleep()` **cuánto** falta para esa hora (`"00:00"` = sin alarma).
  Propone la primera hora en punto en la que Mayui ya habrá descansado (`PlayerManager.get_minimum_sleep(cama)`).
- Menos del mínimo: noche mala e Insomnio. Más del mínimo: despierta sola al cumplirlo (pendiente P97).
- Con Insomnio el despertador solo funciona con probabilidad según la energía y nunca pasa del tope del Insomnio.
- Prueba: `Tools/probar_alarma.gd`.

## Efectos nuevos y cambios en recursos

- Recursos nuevos: `atenta`, `calm`, `hipersomnia`, `inapetencia`, `insomnia`. El resto se ajustó.
- `EffectLevel`: el nivel ahora empieza en 0, `time_cost_per_level`, `days_active` y `level_changed` solo al cambiar.

## ⚠️ Pendiente

- Desmayo por lugar, Desahogo, Suciedad en dos capas (cuerpo/boca) e ítems de medicina: diseñados, sin implementar.
- Casi nada de este estado se **guarda** (ver [Guardado](guardado-hud-debug.md)).
- Prueba: `Tools/probar_efectos.gd` (0 FALLA) y `Tools/simulacion_efectos.gd` si se cambia un número.
