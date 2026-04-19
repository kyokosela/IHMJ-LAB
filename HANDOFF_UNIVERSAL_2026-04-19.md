# IHMJ-LAB — Universal Handoff Document
**Fecha:** 2026-04-19  
**Escrito por:** Claude Opus 4.7 (sesión de auditoría + reorganización)  
**Para:** Cualquier asistente AI (GPT-5.3, Claude, Gemini, Codex, etc.)

> **Este documento es auto-contenido.** No requiere acceso a conversaciones previas. Cualquier modelo de IA con acceso al filesystem puede continuar el trabajo leyéndolo.

---

## CONTEXTO DEL PROYECTO

- **Proyecto:** IHMJ-LAB — Prototipo personal en Godot 4.6 / GDScript
- **Ubicación:** `C:\Dev\Projects\IHMJ-LAB\`
- **Rama actual:** `ai-effects-migration-2026-02-15`
- **Propósito:** Terminar un prólogo jugable de 7 días in-game para testear mecánicas antes de migrar al repo principal (`notmomoi/IHMJ`).
- **Idioma del juego:** Español (toda la UI, diálogos y emails)

**Regla crítica:** No reestructurar a arquitectura de componentes. El LAB mantiene managers planos en `Scripts/`. La migración al repo principal ocurre después y solo con consenso del dev principal (Adogg).

---

## LO QUE YA ESTÁ IMPLEMENTADO (AUDITADO 2026-04-19)

### Fases completas del plan maestro
- **FASE 0:** Validación de estado (reporte en `FASE_0_VALIDATION_REPORT.md`)
- **FASE 1:** Sistema de efectos cerrado (AlarmUI, once-per-day sleep, startup time 08:00)
- **FASE 2:** Escenas del mundo pobladas (Apartment, Lobby, Office, Commercial)
- **FASE 3:** Loop del Día 1 completo (rutina casa → trabajo → dormir)
- **FASE 4:** Narrativa Días 2-4 (Madina dinámica, schedule events, Dialogic)
- **FASE 5:** Evaluación del Viernes conectada a evento `DAY5_EVALUATION`
- **FASE 6:** Arcade minigame + Market shop + escena Commercial
- **FASE 7:** Balancing pass + audio manager con hooks (sin .ogg aún)

### Sistemas core funcionando
- **27 managers planos** en `Scripts/` (time, economy, attendance, player, narrative_flags, etc.)
- **Sistema de efectos:** STRESS, CALM, INSOMNIA (3 niveles), HYPERACTIVE, HUNGER, SLEEPY, SMELLY, ATENTA, HYPERSOMNIA, INAPETENCIA, WEAK, TIRED
- **38 emails narrativos** distribuidos en Días 1-5 (contenido en `Resources/Computer/Apps/Mail/Entries/Narrative/`)
- **25 eventos de schedule** (Día 1-7) en `Resources/Events/Schedule/`
- **Timelines Dialogic** para Mayui, Madina, Veda, Casero en `DialoguePlugin/TIMELINE/`
- **Sleep system con bed types A/B/C** y 5 triggers de INSOMNIA
- **AlarmUI modal** con backdrop y centrado
- **Playground integration scene** para testing manual

---

## PROBLEMA PRINCIPAL RESUELTO EN ESTA SESIÓN

### Síntoma reportado por el usuario
> "Sigue diciéndome que añadió cosas nuevas pero no veo dónde están esas opciones."

### Causa raíz
El modelo anterior trabajó en un **git worktree aislado** (`.claude/worktrees/sleepy-khayyam-df14fa/`) en una rama separada (`claude/sleepy-khayyam-df14fa`). Hizo 11 commits ahí pero **nunca fusionó a la rama principal**. El usuario abría Godot en `C:\Dev\Projects\IHMJ-LAB\` (main) y no veía nada nuevo.

### Solución aplicada
1. Fast-forward merge de `claude/sleepy-khayyam-df14fa` a `ai-effects-migration-2026-02-15` (commit `5f82866`).
2. Reorganización del playground para que las nuevas estaciones sean visibles (commit `0ae60a0`).

### Issues secundarios corregidos
- **WEEKEND ACTIVITIES mal posicionadas:** El modelo anterior agregó Arcade/Market/EatFood en el lado izquierdo del Playground (X=100-620) cuando todas las demás estaciones están en la cuadrícula derecha (X=730-1420). Con zoom 3x y spawn en X=760, quedaban fuera de la vista. **Corregido:** movidas a la misma cuadrícula en Y=580-633.
- **HUD apelmazado:** El TriggerRow tenía 7 botones en un HBoxContainer de ~430px. **Corregido:** dividido en TriggerRow (4 botones de narrativa) + TestRow (3 botones de pruebas) con `size_flags_horizontal=3` para distribución equitativa.

---

## ESTRUCTURA DEL PROYECTO (FILES CLAVE)

```
C:\Dev\Projects\IHMJ-LAB\
├── Scenes\
│   ├── Playground_Integration.tscn   ← ESCENA DE TESTING (abrir esta)
│   ├── playground_integration.gd     ← Script con botones del HUD
│   └── World\
│       ├── Apartment.tscn            ← Casa de Mayui
│       ├── Lobby.tscn                ← Lobby del edificio
│       ├── Office.tscn               ← Oficina (work zone)
│       └── Commercial.tscn           ← Zona comercial (arcade + market)
├── Scripts\
│   ├── game_manager.gd               ← new_game(), load_schedule_events()
│   ├── player_manager.gd             ← 850 líneas, stats + effects + sleep
│   ├── time_manager.gd               ← Time + day progression
│   ├── event_manager.gd              ← EventScheduled + LapseEvent
│   ├── economy_manager.gd            ← money, rent, bus fare, salary
│   ├── attendance_manager.gd         ← clock in/out, absences, warnings
│   ├── audio_manager.gd              ← NUEVO — hooks (.ogg pendientes)
│   ├── narrative_flags.gd            ← Flags booleanos para progresión
│   ├── narrative_event_handler.gd    ← Despacha schedule events
│   └── HouseInteracts\
│       └── integration_action.gd     ← Enum ActionType (50+ acciones)
├── UI\
│   ├── Sleep\AlarmUI.tscn            ← Modal de alarma (FASE 1)
│   ├── Evaluation\evaluation_screen.tscn  ← Viernes (FASE 5)
│   ├── Arcade\arcade.tscn            ← Minigame (FASE 6)
│   └── Market\market.tscn            ← Shop (FASE 6)
├── Resources\
│   ├── Computer\Apps\Mail\Entries\Narrative\   ← 38 emails
│   ├── Events\Schedule\                         ← 25 eventos
│   ├── Events\InitialEvents\                    ← bills, rent, bus, lunch
│   └── Effects\Effects\                         ← STRESS, HUNGER, etc.
├── DialoguePlugin\
│   ├── CHARACTERS\                   ← Mayui, Madina, Veda, Casero (.dch)
│   └── TIMELINE\                     ← Diálogos (.dtl)
├── IHMJ_LAB_MASTER_PLAN.md           ← PLAN MAESTRO (leer primero)
├── CONTENT_PASS_PLAN.md              ← Specs de contenido (§5 = emails)
├── IMPLEMENTATION_PLAN_v2.md         ← Constantes técnicas
├── BALANCING_NOTES.md                ← Notas de balance (FASE 7)
└── HANDOFF_UNIVERSAL_2026-04-19.md   ← ESTE ARCHIVO
```

---

## CÓMO TESTEAR EN GODOT

### Paso 1: Limpiar caché (IMPORTANTE)
Godot cachea escenas `.tscn`. Si cambios recientes no aparecen:
1. Cerrar Godot completamente
2. Borrar carpeta `C:\Dev\Projects\IHMJ-LAB\.godot\` (carpeta oculta)
3. Reabrir Godot
4. Esperar reimport completo

### Paso 2: Abrir escena de testing
- Abrir `Scenes/Playground_Integration.tscn`
- Presionar F6 (o botón "Play Scene")

### Paso 3: UI del playground (panel derecho)
El HUD ahora está organizado en secciones claras:
1. **Status** — Zone, Effects, Stats, Work Task, Time, Economy, Attendance, Email, Events, Flags
2. **MainButtons** — Bootstrap, Refresh, Debug
3. **TimeRow** — DaySpin, TimeInput, ApplyTime, +1hr
4. **AttendanceRow** — Clock In, Clock Out, Mark Absence
5. **EconomyRow** — Add Money, Pay Rent, Check Rent, Bus Fare
6. **FlagRow** — FlagInput, Set Flag, Clear Flag
7. **UIButtons** — Toggle Workspace, Close Workspace, Open Portal, Open Evaluation
8. **SaveRow** — Save Slot, Load Slot
9. **--- NARRATIVA / WARNINGS ---** → Eval Event, M88 Email, Warn 1, Warn 2
10. **--- PRUEBAS RÁPIDAS ---** → Dormir, Arcade, Mercado
11. **--- ESCENARIOS RÁPIDOS ---** → D1, D5 Eval, Finde, Dom

### Paso 4: Mundo del playground (estaciones caminables)
Todas las estaciones están en la cuadrícula X=730-1420. Mueve al personaje con WASD/flechas y presiona E/Space para interactuar.

**Secciones verticales (de arriba a abajo):**
- Y=90: **NARRATIVE** → Casero, Madina
- Y=160: **ZONE TRAVEL** → Apartment, Lobby, Office (S/10), Commercial (S/10)
- Y=230: **APARTMENT ACTIONS** → Bed, Bath, Closet
- Y=300: **PRIMARY AND BASE EFFECTS** → Hunger, Sleepy, Smelly, Stress, Calm, Clear, Insomnia
- Y=370: **UTILITY AND SANITY** → Remove Hunger, Sanity -10, Sanity +10, Remove Calm, +1 Day
- Y=440: **SECONDARY EFFECTS** → Inapetencia, Hipersomnia, Atenta, Remove Inap/Hip/Atenta
- Y=580: **WEEKEND ACTIVITIES** → Arcade, Market, Eat Food ← NUEVO, AHORA VISIBLE

---

## TAREAS PENDIENTES (EN ORDEN DE PRIORIDAD)

### ALTA — Testing runtime
- [ ] Verificar que el Playground carga sin errores en consola
- [ ] Probar el ciclo completo Día 1 → Día 7 usando botones de escenario
- [ ] Confirmar que el AlarmUI modal responde a clicks y Enter
- [ ] Validar que Arcade y Market son jugables (balance +/- dinero, efectos)
- [ ] Grabar evidencia en video si algún modelo lo pide

### MEDIA — Balanceo
- [ ] Jugar prólogo 3 veces con perfiles diferentes (modelo / caótico / neutro)
- [ ] Registrar issues en `BALANCING_NOTES.md`
- [ ] Ajustar constantes según hallazgos:
  - Salario semanal: 1000 Savia (es suficiente?)
  - Renta: 230 Savia (es alcanzable sin gastar todo?)
  - Bus: 10 Savia por viaje (es demasiado?)

### BAJA — Pulido
- [ ] Agregar audio placeholders (.ogg en `Audio/SFX/` — hooks ya existen en `audio_manager.gd`)
- [ ] Scroll en HUD Root si se agregan más features
- [ ] Botón "Reset Day" para testing rápido
- [ ] Revisar si los 38 emails tienen contenido completo (§5 de `CONTENT_PASS_PLAN.md`)

### FUTURO (POST-PROLOGO)
- [ ] Crear `MIGRATION_MAP.md` que mapee cada manager del LAB a destino en repo principal
- [ ] Coordinar con Adogg para migración a `notmomoi/IHMJ`

---

## GUÍA DE MODELOS PARA EL PRÓXIMO TRABAJO

El usuario prefiere usar modelos más caros solo para tareas pesadas. Guía para decidir:

| Tarea | Modelo recomendado | Justificación |
|-------|--------------------|---------------|
| Testing runtime + bug fixes simples | **GPT-5.3 / Claude Haiku** | Iteración rápida, bugs obvios |
| Contenido narrativo (diálogos, emails) | **GPT-5.3 / Claude Sonnet** | Estilo + consistencia de voz |
| Refactor de managers | **Claude Sonnet / GPT-5.3** | Balance costo/calidad |
| Balanceo numérico | **Cualquiera** | Mecánico |
| Debug de side-effects complejos | **Claude Opus / GPT-5.3 Pro** | Razonamiento profundo |
| Arquitectura nueva | **Claude Opus** | Decisiones que afectan todo |

**Regla del usuario:** Opus solo para tareas extremadamente pesadas/complejas. Para lo mecánico, usar GPT-5.3 o Haiku.

---

## COSAS QUE NO DEBES HACER (APRENDIDO EN ESTA SESIÓN)

1. **NO trabajes en git worktrees aislados sin mergear.** Si usas `git worktree`, haz `git merge --ff-only <branch>` a `ai-effects-migration-2026-02-15` al terminar. Mejor aún: trabaja directo en la rama principal.
2. **NO agregues nodos en posiciones aleatorias de las escenas.** El Playground tiene una cuadrícula (X=730-1420, Y=90-580). Respétala.
3. **NO metas más de 5 botones en un solo HBoxContainer.** El panel tiene ~430px. Con más de 4-5 botones, los labels se cortan. Usa `size_flags_horizontal=3`.
4. **NO olvides limpiar `.godot/` si escenas no actualizan.** Es caché.
5. **NO pongas código Claude-specific en handoffs.** El usuario usa varios modelos (GPT-5.3, Codex, Gemini, etc.).
6. **NO asumas que los .dtl existen con nombres exactos.** Siempre verifica con `ls DialoguePlugin/TIMELINE/` antes de llamar `Dialogic.start("nombre")`.
7. **NO modifiques .gd scripts cuando el plan pide solo contenido (.tres).** CONTENT_PASS_PLAN.md §1.4 es explícito en esto.

---

## COMANDOS ÚTILES (BASH / PWSH)

```bash
# Ver estado actual del repo
cd C:/Dev/Projects/IHMJ-LAB
git status
git log --oneline -10

# Ver todas las ramas y worktrees
git branch -a
git worktree list

# Limpiar caché de Godot (si cambios no se ven)
rm -rf C:/Dev/Projects/IHMJ-LAB/.godot

# PowerShell:
# Remove-Item -Recurse -Force C:\Dev\Projects\IHMJ-LAB\.godot

# Ejecutar el juego desde CLI (si Godot está en PATH)
cd C:/Dev/Projects/IHMJ-LAB
godot --path . Scenes/Playground_Integration.tscn

# Verificar contenido de escena sin abrir Godot
grep "node name=" Scenes/Playground_Integration.tscn | head -20

# Listar emails y su día
grep -H "day_available" Resources/Computer/Apps/Mail/Entries/Narrative/*.tres | head -10

# Verificar Dialogic timelines
ls DialoguePlugin/TIMELINE/*.dtl
```

---

## CHECKLIST FINAL PARA DAR POR TERMINADO EL PRÓLOGO

- [ ] Se pueden completar los 7 días sin crashes
- [ ] Todos los efectos se disparan correctamente
- [ ] 3 perfiles de jugador dan resultados diferentes
- [ ] Economía balanceada (posible pero no trivial pagar renta)
- [ ] NPCs dialogan al menos una vez por día cuando aplica
- [ ] Save/Load funciona entre días
- [ ] Los 5 triggers de INSOMNIA son reproducibles
- [ ] Audio placeholders existen (aunque sean silencio)

---

## HISTORIAL DE COMMITS RELEVANTES (últimos 15)

```
0ae60a0 fix(playground): reorganize HUD and weekend stations for visibility
5f82866 chore: handoff document — playground testing fixes (SUPERSEDED)
65c0f6a fix(playground): expand HUD panel to full height + add weekend interactables
227337b feat: Test Arcade and Test Market buttons in playground HUD
c513f7b fix(alarm): make AlarmUI a true modal with backdrop and centered panel
039a091 feat: add scenario quick-start buttons to playground HUD
e97e894 fix: wrap AlarmUI in CanvasLayer so it receives input; add Test Sleep button
f247d2d chore: handoff document — prólogo feature-complete, runtime testing pending
1f1dc53 feat: FASE 7 — audio manager with placeholder hooks
8e2876d feat: FASE 7 — balancing pass
3e52035 feat: FASE 6 — arcade minigame, market shop, Commercial scene interactables
76dd04d feat: FASE 5 — wire Friday evaluation screen to DAY5_EVALUATION event
02e2be7 chore: FASE 4 handoff document (SUPERSEDED)
a4e6f9c feat: FASE 4 — make Madina dialogue dynamic by day
6b4d09d feat: FASE 3 — Day 1 loop complete
```

---

## SI ERES UN MODELO LLEGANDO POR PRIMERA VEZ

**Lee en este orden:**
1. Este archivo (ya lo estás leyendo)
2. `IHMJ_LAB_MASTER_PLAN.md` — plan general y fases
3. `BALANCING_NOTES.md` — estado actual del balance
4. `CONTENT_PASS_PLAN.md` §1.5 — guía de voz de personajes (si vas a tocar contenido narrativo)

**Antes de hacer cualquier cosa, responde al usuario EXACTAMENTE en este formato:**
```
Fase actual: <detectada de git log>
Último commit: <hash + mensaje>
Tareas pendientes detectadas: <1-3 bullets>
Lo que voy a hacer hoy: <1 frase>
```

**No abras archivos extra ni propongas opciones hasta que el usuario diga "adelante" o equivalente.**

**Si detectas que los cambios no se ven en Godot, lo primero es: `rm -rf .godot/` y avisar al usuario.**

---

*Fin del handoff universal. Funciona con GPT-5.3, Claude (cualquier versión), Gemini, Codex y cualquier modelo con filesystem access.*
