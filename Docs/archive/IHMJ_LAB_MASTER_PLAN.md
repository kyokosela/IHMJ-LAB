# IHMJ-LAB — Master Plan de Implementación

**Propósito:** Terminar un prólogo jugable (7 días in-game) en el IHMJ-LAB para testear, balancear y planear. Este documento es la fuente de verdad para ejecutar el trabajo con un asistente IA (Cowork, Claude, etc).

**Repo base:** `kyokosela/IHMJ-LAB` · branch `ai-effects-migration-2026-02-15`
**Engine:** Godot 4.6 · GDScript
**Fecha de generación:** 18 abril 2026

---

## ⚠️ CONTEXTO CRÍTICO — LEER PRIMERO

Este LAB es un prototipo personal de kyokosela (Sela). El dev principal del equipo (Adogg) pidió que no se migre sin consenso y que se respete la estructura del repo principal (`notmomoi/IHMJ`). Por lo tanto:

1. El trabajo aquí es para **TESTEAR y PLANEAR**, no para producción.
2. Cuando se migre, se hará respetando la arquitectura del repo principal (componentes en `game/components/`, managers en `game/_core/managers/`, etc.), no la arquitectura del LAB (managers planos en `Scripts/`).
3. El LAB ya tiene una base muy sólida gracias a dos planes previos: `IMPLEMENTATION_PLAN_v2.md` y `CONTENT_PASS_PLAN.md`. Este plan complementa esos.

---

## 🧭 GUÍA DE MODELOS

| Fase de trabajo | Modelo recomendado | Por qué |
|---|---|---|
| Diseño y arquitectura | Opus 4.x | Decisiones complejas que afectan todo lo demás |
| Código nuevo (managers, sistemas) | Sonnet 4.x | Balance costo/calidad, maneja bien Godot |
| Implementación mecánica (rellenar .tres, crear escenas desde spec) | Haiku 4.5 o Sonnet | Tareas claras sin decisiones |
| Contenido narrativo (diálogos, emails) | Sonnet | Necesita sensibilidad de estilo |
| Testing y balanceo (ajustar números) | Haiku | Iteración rápida |
| Debug complejo | Opus | Cuando algo no compila o hay side effects raros |

**🚨 NOTA SOBRE EL MODELO:** En Cowork el modelo se fija al iniciar la sesión y **no se puede cambiar sobre la marcha**. Cuando una fase requiere un modelo distinto al de la anterior, hay que **cerrar la sesión actual y abrir una nueva** con el modelo correcto. Los puntos de cambio están marcados así a lo largo del plan:

> ⛔ **FIN DE SESIÓN** — Abrir nueva sesión con modelo X antes de continuar. Razón: Y.

Cuando la fase puede continuar con el mismo modelo que la anterior:

> ✅ **CONTINÚA** — Misma sesión (mismo modelo: X).

---

## 📊 ESTADO REAL DEL LAB (auditado 18 abr 2026)

### ✅ Implementado y funcionando (según `CONTINUATION_VALIDATION_2026-02-15.md`)

**Managers (27 scripts en `Scripts/`):**

- `time_manager.gd`, `event_manager.gd`, `save_manager.gd`, `zone_manager.gd`, `game_manager.gd`
- `economy_manager.gd` (144 líneas) — dinero, transacciones, salario, renta, bus
- `attendance_manager.gd` (183 líneas) — clock in/out, ausencias, advertencias
- `relationship_manager.gd` (84 líneas) — 5 niveles con NPCs
- `narrative_flags.gd` — flags booleanos/valores para progresión
- `narrative_event_handler.gd` (194 líneas) — despacha eventos narrativos
- `task_manager.gd`, `bracelet_manager.gd`, `tutorial.gd`, `email_pool_manager.gd`
- `player_manager.gd` (850 líneas) — el más grande, contiene stats, efectos, sleep logic, sanity

**Sistema de efectos (validado):**

- STRESS 3 niveles con penalty de trabajo (-10/-25/-50%)
- CALM 3 niveles
- INSOMNIA 3 niveles con 5 triggers (sanity<30, hyperactive chain, coffee+energy, sleepy III, under-sleep)
- HYPERACTIVE, HUNGER, SLEEPY, SMELLY, ATENTA
- Bed types A/B/C con modifiers de tiempo y energía
- Alarm override con flags temporales

**Contenido existente:**

- 38 emails narrativos en `Resources/Computer/Apps/Mail/Entries/Narrative/`
- 20+ eventos de schedule en `Resources/Events/Schedule/` (day1-day6)
- Escenas: `Playground_Integration.tscn`, `Playground.tscn`, `ApartamentC.tscn`, `ApartamentD.tscn`
- Dialogic integrado

### 🟡 Parcialmente implementado

- Sleep system: código listo, UI de selección de horas con alarma pendiente
- Playground Integration: scene base existe, faltan zonas específicas y algunas estaciones
- `tutorial.gd` existe pero necesita conectar con el flujo real

### 🔴 Pendientes críticos (del `AI_MIGRATION_CONTEXT`)

1. Alarm-clock suppression UI bajo insomnio
2. Full balancing pass (multiplicadores, probabilidades)
3. Validación runtime en Godot (los tests hasta ahora son code-path inspection)

---

## 🎯 OBJETIVO DEL PRÓLOGO JUGABLE

Un loop de 7 días in-game donde puedas:

- **Día 1 (Lunes):** Despertar → rutina casa (ducha, armario, cocina) → ir al trabajo → mail minigames → pausa almuerzo → trabajo tarde → volver → dormir
- **Día 2-4:** Variantes con eventos narrativos (casero, Madina, Veda)
- **Día 5 (Viernes):** Evaluación + pago semanal
- **Día 6 (Sábado):** Día libre — arcade, compras
- **Día 7 (Domingo):** Preparación de siguiente semana

Con efectos activos, economía funcional, NPCs dialogando, y eventos narrativos disparándose correctamente.

---

## 📋 PLAN DE EJECUCIÓN POR FASES

### FASE 0 — Validación del estado actual

> 🟢 **INICIO** — Abrir la sesión con **Haiku 4.5** (son tareas mecánicas de verificación).

**Objetivo:** Confirmar que todo lo que está en los docs realmente funciona en runtime antes de añadir nada nuevo.

**Tareas:**

- **0.1.** Abrir Godot 4.6, cargar el proyecto del LAB, esperar reimport completo.
- **0.2.** Ejecutar `Scenes/Playground_Integration.tscn` y verificar:
  - No hay errores en consola al arranque
  - El HUD de estado muestra Time, Economy, Attendance, Emails, Events, Flags
  - Jugador spawnea con 350 Savia
  - TimeManager arranca a las 8:00 AM
- **0.3.** Probar cada interactable existente en el playground:
  - Clock In/Out (AttendanceManager)
  - Pay Rent (EconomyManager)
  - Talk Casero / Talk Madina (Dialogic)
  - Open Workspace (PC con mail app)
  - Set Flag, Execute Event
- **0.4.** Hacer un `sleep()` completo: verificar que consume horas, da energía según tabla, aplica stress reduction correctamente.
- **0.5.** Disparar cada uno de los 5 triggers de INSOMNIA manualmente y verificar que se activa.

**Entregable:** Un archivo `FASE_0_VALIDATION_REPORT.md` con estado PASS/FAIL de cada punto. Si algo falla, lo arreglamos antes de avanzar.

---

### FASE 1 — Cerrar gaps del sistema de efectos

> ⛔ **FIN DE SESIÓN** — Abrir nueva sesión con **Sonnet 4.x**. Razón: código con cierta complejidad.

**Objetivo:** Completar los "Known Gaps" del `AI_MIGRATION_CONTEXT.md` antes de añadir contenido.

**Tareas:**

- **1.1. Alarm UI bajo insomnio** — Cuando el jugador tiene INSOMNIA y pone alarma, mostrar UI que:
  - Pida la hora deseada
  - Muestre wake chance basado en energía (según la tabla de diseño)
  - Si la alarma falla, el jugador duerme hasta el cap aleatorio del nivel de insomnio
  - Archivo afectado: `Scripts/player_manager.gd` (método `sleep()`) + nueva UI en `UI/Sleep/`
- **1.2. Once-per-day sleep restriction** — Enforce en `player_manager.gd::sleep()`:
  - Usar un flag `slept_today` que resetea en `TimeManager.day_changed`
  - Si está activo, bed interaction devuelve mensaje "No necesitas dormir más hoy"
- **1.3. Inventory prerequisite for sleep** — Si no tiene cama-item en inventario, no puede dormir:
  - Por ahora, asumir siempre cama básica (tipo C). Item de cama como mejora vendrá después.
- **1.4. Balancing pass inicial** — Ejecutar el Playground durante 1 día completo y registrar:
  - ¿La energía se siente bien al llegar al trabajo (~50-60)?
  - ¿El stress sube demasiado rápido con mail minigames?
  - ¿La renta de 230 Savia es alcanzable con salario de 1000/semana?

**Entregable:** Commit: `feat: close effects system gaps (alarm UI, once-per-day, balancing pass)`

---

### FASE 2 — Zonas y transiciones

> ✅ **CONTINÚA** — Misma sesión (mismo modelo: Sonnet 4.x).

**Objetivo:** Que el jugador pueda moverse entre Apartamento → Calle → Empresa con costo de bus.

**Tareas:**

- **2.1.** Crear escena `Scenes/World/Street.tscn` (calle básica):
  - Spawn points para Apto y Empresa
  - Bus stop como interactable
  - Visual placeholder (rectángulos, no assets todavía)
- **2.2.** Configurar ZoneManager para las 3 zonas:
  - `APTO`, `STREET`, `OFFICE`
  - Costo bus APTO↔OFFICE = 10 Savia (constante existente)
  - Caminar APTO↔STREET gratis
- **2.3.** Integrar con EconomyManager — cuando tome el bus, descontar 10 Savia o bloquear si no tiene.
- **2.4.** Crear `Scenes/World/Office.tscn` (oficina básica):
  - Spawn entrada
  - Escritorio de Mayui (trigger de PC)
  - Recepción con NPC Madina
  - Puerta a zona de Veda (por ahora cerrada)

**Entregable:** Un jugable donde puedas salir de casa, caminar a la parada, tomar el bus, entrar a la oficina y sentarte en tu escritorio.

---

### FASE 3 — Loop diario básico (Día 1 completo)

> ✅ **CONTINÚA** — Misma sesión (mismo modelo: Sonnet 4.x).

**Objetivo:** Que el Día 1 sea jugable de inicio a fin con narrativa, mecánicas y consecuencias.

**Tareas:**

- **3.1.** Conectar `tutorial.gd` con el flujo real:
  - Al iniciar partida nueva, tutorial guía al jugador paso a paso
  - Usa `NarrativeFlags` para trackear pasos (despertó, se duchó, comió, etc.)
- **3.2.** Interactables de Apartamento (usar el patrón de `integration_action.gd`):
  - Cama: sleep action
  - Ducha: aplica SMELLY→CLEAN, consume tiempo
  - Armario: cambiar outfit (ya existe sistema de ropa)
  - Nevera: obtener comida instantánea o ingredientes
  - Estufa: cocinar (ya existe sistema de crafting)
  - Lavamanos: cepillarse, lavar ropa
  - Puerta: trigger salida + check de rutina completa
- **3.3.** Eventos de Día 1:
  - `day1_alarm.tres` → dispara intro narrativa
  - `day1_casero.tres` → casero en la puerta al salir (primera vez)
  - `day1_veda.tres` → Veda aparece en la oficina (presentación)
- **3.4.** Jornada laboral Día 1:
  - Clock in a las 8:00
  - 3-4 mail minigames (usar los existentes: trivia, typing, classification, differences)
  - Lunch break 13:00-14:00
  - Clock out 17:00
  - Retorno a casa → dormir

**Entregable:** Sesión de juego completa Día 1 grabada como evidencia (recording de Godot).

---

### FASE 4 — Días 2-4 (narrativa creciente)

> ⛔ **FIN DE SESIÓN** — Abrir nueva sesión con **Haiku** para tareas mecánicas de copiar-pegar contenido. Si a mitad de fase toca modificar lógica, cerrar y abrir otra con **Sonnet**.

**Objetivo:** Los días intermedios escalan la tensión: renta se acerca, Veda se pone estricta, Madina confiesa cosas.

**Tareas:**

- **4.1.** Cargar todos los eventos de schedule existentes (`Resources/Events/Schedule/day2_*` a `day4_*`) y verificar que el `EventManager` los registra correctamente al cargar partida.
- **4.2.** Verificar Dialogic timelines (ver `CONTENT_PASS_PLAN.md` sección 3):
  - `madina_cafe_day2.dtl`
  - `madina_tension_day3.dtl`
  - `casero_rent_reminder_day4.dtl`
  - `veda_stare_day4.dtl`

  Si no existen, crearlos siguiendo el formato del CONTENT_PASS_PLAN.
- **4.3.** Email content expansion — Los 38 emails ya están como `.tres` pero probablemente sin contenido completo. Llenar con el texto del documento maestro.

> ⛔ **FIN DE SESIÓN para contenido narrativo** — Abrir nueva sesión con **Sonnet** para que el estilo de voz de cada personaje (ver tabla en `CONTENT_PASS_PLAN.md` §1.5) se mantenga.

**Entregable:** Días 2, 3 y 4 jugables con narrativa y progresión de tensión funcionando.

---

### FASE 5 — Día 5 (Viernes — Evaluación y pago)

> ⛔ **FIN DE SESIÓN** — Abrir nueva sesión con **Sonnet 4.x**. Razón: hay lógica nueva de evaluación. (Si vienes de la parte narrativa de Fase 4 ya estás en Sonnet → entonces es `✅ CONTINÚA`.)

**Objetivo:** El día crítico donde Mayui recibe evaluación, pago y posiblemente la oportunidad de desalojo si no pagó renta.

**Tareas:**

- **5.1.** Crear `UI/Evaluation/EvaluationScreen.tscn` (ver `CONTENT_PASS_PLAN.md` Fase 5):
  - Muestra performance de la semana: emails completados, ausencias, tareas extra
  - Calcula si obtiene "token de ascenso"
  - Resultado visible al jugador
- **5.2.** Activar `day5_evaluation.tres` al clock_out del viernes.
- **5.3.** Salary payment — EconomyManager ya tiene `pay_salary()`, solo verificar que se dispare en `day5_salary.tres`.
- **5.4.** Rent due check — Si no pagó renta para el viernes, disparar `casero_rent_warning_1.dtl`.

**Entregable:** Evaluación semanal funcional con salario, tokens y warnings.

---

### FASE 6 — Días 6-7 (Fin de semana)

> ⚠️ **DECIDE** — Elige **Haiku** o **Sonnet** dependiendo de la complejidad. Si cambias respecto a la fase anterior, cierra la sesión y abre una nueva.

**Objetivo:** Días libres con actividades opcionales que afectan stats/relaciones.

**Tareas:**

- **6.1. Arcade** (del `day6_arcade.tres`) — minijuego de gambling simple:
  - Input: Savia
  - Output: 2x Savia o 0
  - Reduce stress ganar, aumenta stress perder
- **6.2. Market/tienda** — comprar comida, jabón, ropa con los precios existentes en constantes.
- **6.3. Domingo — preparación** — Dialogic timeline `sunday_week_preparation.dtl` resume la semana y prepara la siguiente.

**Entregable:** Prólogo completo jugable (7 días).

---

### FASE 7 — Balancing final y polish

> ⛔ **FIN DE SESIÓN** — Abrir nueva sesión con **Haiku** para iteración numérica rápida. Si hay que refactorizar sistemas, cerrar y abrir otra con **Sonnet/Opus**.

**Tareas:**

- **7.1.** Jugar el prólogo completo 3 veces con perfiles diferentes:
  - Jugador "modelo": hace todo correctamente → debería llegar al viernes con token
  - Jugador "caótico": salta rutinas, llega tarde → debería perder trabajo o renta
  - Jugador "neutro": mix de ambos → resultado intermedio
- **7.2.** Registrar todos los balancing issues en un `BALANCING_NOTES.md`.
- **7.3.** Ajustar constantes en `IMPLEMENTATION_PLAN_v2.md` §1 según hallazgos.
- **7.4. Audio placeholders** — SFX mínimos: click UI, steps, sleep transition, alarm. No necesita ser buena música, solo debe existir.

---

## 🧪 CHECKLIST FINAL DE "JUGABLE"

Antes de dar el prólogo por terminado:

- [ ] Se puede completar los 7 días sin crashes
- [ ] Todos los efectos (STRESS, CALM, INSOMNIA, SLEEPY, HUNGER, SMELLY, HYPERACTIVE, ATENTA) se disparan correctamente
- [ ] Los 3 perfiles de jugador dan resultados diferentes y coherentes
- [ ] La economía es balanceada: posible pero no trivial pagar renta
- [ ] Los NPCs tienen al menos un diálogo por día cuando aplica
- [ ] Save/Load funciona entre días
- [ ] Los 5 triggers de INSOMNIA se pueden reproducir en gameplay real (no solo harness)

---

## 📝 PROMPT DE ARRANQUE PARA COWORK

En Cowork, cada "New task" abre una sesión nueva y el contexto anterior NO se acarrea. Por eso este prompt obliga dos cosas clave: **leer el handoff más reciente al empezar** y **dejar uno nuevo antes de cerrar**.

Copia y pega esto al iniciar una sesión de Cowork:

```
IHMJ-LAB — arranque de sesión. Proyecto Godot 4.6 / GDScript en
C:\Dev\Projects\IHMJ-LAB.

PASO 0 — SANITY CHECK DEL PROMPT (hazlo ANTES de leer nada):
Si en este prompt ves literalmente `[N]`, `[Sonnet/Haiku/Opus]`,
`[tarea específica del plan]` o cualquier otro texto entre corchetes
sin rellenar, DETENTE. No abras archivos. Respóndeme exactamente:
"Olvidaste rellenar los placeholders: <lista>. Rellénalos y mándame
el prompt de nuevo." y no hagas nada más hasta que te lo reenvíe.

PASO 1 — LEER (en este orden, sólo si el PASO 0 pasó):
1. `IHMJ_LAB_MASTER_PLAN.md` en la raíz del proyecto (plan maestro).
2. El `CONTINUATION_PROMPT_YYYY-MM-DD.md` con la fecha MÁS RECIENTE
   en la raíz. Si no existe ninguno, es la primera sesión de trabajo
   real sobre este plan — dímelo explícitamente.
3. Otros docs (`IMPLEMENTATION_PLAN_v2.md`, `CONTENT_PASS_PLAN.md`,
   `AI_MIGRATION_CONTEXT_*.md`, etc.) sólo si la tarea de hoy los pide.

PASO 2 — CONFIRMAR ESTADO (OBLIGATORIO antes de tocar nada más):
Respóndeme EXACTAMENTE en este formato, sin añadir preguntas:

    Fase actual: <FASE N>
    Última sesión completó: <1-2 bullets>
    Pendiente de arrastre: <1-2 bullets, o "nada">
    Lo que voy a hacer hoy: <1 frase concreta con archivos>
    Modelo correcto para esta tarea según plan: <Haiku/Sonnet/Opus>
    Coincide con el modelo de esta sesión: <Sí / No — si no, aviso FIN DE SESIÓN>

Hasta que yo te escriba "ok, adelante", NO abras archivos extra,
NO propongas opciones, NO me preguntes "¿cómo procedemos?" ni
"¿en qué fase querés empezar?". Tu único output permitido después
de leer es ese bloque de confirmación.

CONTEXTO DE ESTA SESIÓN (rellenar antes de enviar):
- Fase objetivo: FASE [N]
- Modelo de esta sesión: [Sonnet / Haiku / Opus]
- Tarea concreta: [tarea específica del plan]

En Cowork el modelo NO se puede cambiar sobre la marcha. Si llegamos
a un FIN DE SESIÓN (cambio de modelo), avísame para cerrar y abrir
sesión nueva con el modelo correcto.

REGLAS DE CÓDIGO:
1. Arquitectura del LAB: managers planos en `Scripts/`, NO la de
   componentes del repo principal (`notmomoi/IHMJ`).
2. Todo en español (UI, diálogos, emails).
3. No romper los tests en `CONTINUATION_VALIDATION_2026-02-15.md`.
4. Constantes siempre desde `IMPLEMENTATION_PLAN_v2.md` §1.

CIERRE DE SESIÓN — cuando lleguemos a un FIN DE SESIÓN, a un buen
punto de corte, o yo te diga "vamos a cerrar", genera el archivo:

    C:\Dev\Projects\IHMJ-LAB\CONTINUATION_PROMPT_YYYY-MM-DD.md

con la fecha de hoy y con estas secciones:
- Fase y subtarea en la que estábamos.
- Lo que se completó (archivos tocados, commits).
- Lo que quedó a medias (archivo, línea, qué falta).
- Decisiones tomadas y por qué (para que la siguiente sesión no re-debata).
- Bugs / issues pendientes.
- Próximo paso concreto (instrucción clara que la siguiente sesión
  pueda ejecutar sin pensar).
- Modelo recomendado para la siguiente sesión.

Sobrescribe si ya existe uno con la fecha de hoy. Enséñame el contenido
antes de guardarlo para que lo revise.
```

---

## 🔗 DOCUMENTOS DE REFERENCIA

Están todos en el root del LAB:

| Archivo | Para qué |
|---|---|
| `IMPLEMENTATION_PLAN_v2.md` | Spec técnico completo, constantes, autoloads |
| `CONTENT_PASS_PLAN.md` | Contenido narrativo: diálogos, timelines, emails |
| `PLAYGROUND_IMPLEMENTATION_PLAN.md` | Cómo está organizado el playground de testing |
| `AI_MIGRATION_CONTEXT_2026-02-15.md` | Contexto de qué se hizo en la última sesión |
| `CONTINUATION_VALIDATION_2026-02-15.md` | Tests pasados al 15 feb 2026 |
| `SLEEP_ALIGNMENT_AUDIT_2026-02-15.md` | Detalles del sistema de dormir |

---

## ⚡ NOTA SOBRE MIGRACIÓN FUTURA AL REPO PRINCIPAL

Cuando Adogg tenga tiempo y el prólogo del LAB esté validado:

1. Crear documento `MIGRATION_MAP.md` que mapee cada manager del LAB a su destino en el repo principal.
2. Los managers del LAB (`economy_manager.gd` etc.) probablemente se reorganicen como componentes en `game/components/` o managers en `game/_core/managers/` siguiendo el patrón del repo principal.
3. Los `.tres` resources y escenas pueden migrarse casi tal cual.
4. No hacer esto hasta tener visto bueno de Adogg.

---

*Fin del plan. Suerte.*
