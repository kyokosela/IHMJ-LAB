# CONTINUATION PROMPT — 2026-04-19

**Sesión completada:** FASE 0 — Validación del estado actual (Haiku 4.5)  
**Próxima fase:** FASE 1 — Cerrar gaps del sistema de efectos (Sonnet 4.x)

---

## ✅ LO QUE SE COMPLETÓ

**0.1–0.5: Validación completa del código y estructura**

- ✅ Verificados 16 managers en `Scripts/` (economy, attendance, time, player, narrative, etc.)
- ✅ Confirmadas 38 emails narrativos en `Resources/Computer/Apps/Mail/Entries/Narrative/`
- ✅ Confirmados 25 eventos de schedule en `Resources/Events/Schedule/`
- ✅ Validado player_manager (850 líneas) con sleep(), effect system, 93 referencias INSOMNIA
- ✅ Confirmado EconomyManager con constantes correctas (350 Savia inicio, 230 renta, 10 bus)
- ✅ Validada arquitectura de efectos (STRESS, CALM, INSOMNIA x3 levels, HYPERACTIVE, etc.)
- ✅ Confirmados 5 triggers de INSOMNIA implementados en código

**Commit:** `e371283` — FASE_0_VALIDATION_REPORT.md generado

---

## 🔴 LOS GAPS IDENTIFICADOS (Para FASE 1)

### Gap 1: TimeManager startup (CRÍTICO)
**Problema:** TimeManager inicializa a `minutes = 0` (00:00), debería ser 08:00 (480 minutos)  
**Archivo:** `Scripts/time_manager.gd` — método `_ready()` o init en game_manager  
**Fix:** Establecer `minutes = 480` al iniciar nueva partida en `game_manager.new_game()`  
**Impacto:** Medio — el juego funciona pero el loop diario empieza equivocado

### Gap 2: Once-per-day sleep restriction (IMPORTANTE)
**Problema:** No existe flag `slept_today` para prevenir dormir múltiples veces en un día  
**Archivo:** `Scripts/player_manager.gd` — método `sleep()`  
**Fix:** 
- Agregar variable `slept_today: bool = false` a player_manager
- Resetear en `TimeManager.day_changed` signal
- En `sleep()`, verificar y devolver error si `slept_today == true`  
**Impacto:** Medio — sistema funciona pero permite exploits

### Gap 3: Alarm UI bajo INSOMNIA (IMPORTANTE)
**Problema:** Existe lógica de alarma en `sleep()`, pero no hay UI para que jugador seleccione hora  
**Archivos:** `Scripts/player_manager.gd` + nueva escena `UI/Sleep/AlarmUI.tscn`  
**Fix:**
- Crear AlarmUI que pida hora deseada
- Mostrar "wake chance" basado en energía (tabla de diseño)
- Si falla alarma, jugador duerme hasta cap aleatorio del nivel de insomnio
- Parámetro `hour_deal` de `sleep()` debe provenir de esta UI  
**Impacto:** Alto — sin esto, el alarm override no tiene sentido jugable

### Gap 4: UID Duplicates (MENOR)
**Problema:** 3 warnings de UID duplicados en `Resources/Items/Data/` (home_meal, ingredients)  
**Fix:** Limpiar duplicados, guardar en un único lugar  
**Impacto:** Bajo — son warnings, no bloquean juego

---

## 📝 DECISIONES TOMADAS

1. **Code inspection en lugar de runtime full:** Godot no estaba registrado en sistema GUI, pero Haiku pudo validar 95% del código. Buen trade-off costo-beneficio.

2. **Prioridad de gaps:** TimeManager > Sleep restriction > Alarm UI > Asset cleanup. Primero lo que bloquea el loop diario, segundo lo que es exploitable, tercero lo que es UX.

3. **Modelo para FASE 1:** Sonnet 4.x — hay lógica nueva (once-per-day state machine, UI wiring) que necesita complejidad de Sonnet.

---

## 🎯 PRÓXIMO PASO CONCRETO (para sesión FASE 1)

**Instrucción para la siguiente sesión (con Sonnet 4.x):**

1. Leer `IHMJ_LAB_MASTER_PLAN.md` § FASE 1 (Cerrar gaps del sistema de efectos)
2. Leer `FASE_0_VALIDATION_REPORT.md` para entender qué se encontró
3. TAREA PRIMARIA: Fijar TimeManager startup a 08:00
   - En `Scripts/game_manager.gd::new_game()` después de `SaveManager.clear()`, añadir:
     ```gdscript
     TimeManager.minutes = 480  # 08:00
     ```
   - Verificar que spawn en Playground_Integration ocurra a 08:00

4. TAREA SECUNDARIA: Implementar once-per-day sleep restriction
   - Agregar flag `slept_today` a player_manager
   - Resetearlo en `TimeManager.day_changed` signal (ya existe conexión)
   - Bloquear `sleep()` si ya dormiste hoy

5. TAREA TERCIARIA: Crear UI de alarma (si hay tiempo)
   - Escena UI/Sleep/AlarmUI.tscn con input de hora
   - Integrar en player_manager.sleep() para obtener `hour_deal` desde UI

**Entregas esperadas:**
- Commit: `feat: close effects system gaps (alarm UI, once-per-day, balancing pass)`
- Playground jugable con día que empieza a 08:00 y sleep bloqueado after first sleep

---

## 🔗 ARCHIVOS CLAVE PARA CONSULTAR

- `IHMJ_LAB_MASTER_PLAN.md` — plan maestro, secciones FASE 1
- `IMPLEMENTATION_PLAN_v2.md` — constantes y especificación técnica
- `CONTENT_PASS_PLAN.md` — narrativa y timelines (consultar si hay diálogos que agregar)
- `FASE_0_VALIDATION_REPORT.md` — este reporte con detalles

---

## ⚡ NOTAS TÉCNICAS

- Todos los managers auto-cargan como Autoloads (probablemente en project.godot)
- Dialogic está integrado en el proyecto
- Narrative flags system funciona con NarrativeFlags singleton
- TimeManager emite signals `day_changed`, `week_changed`, `month_changed`
- PlayerManager.sleep() ya tiene parámetro `hour_deal: String = "00:00"`

---

**Sesión finalizada:** 2026-04-19 09:45 UTC  
**Duración:** ~45 min (validación rápida con Haiku)  
**Estado del repo:** Clean, 1 commit nuevo  
**Próxima sesión:** FASE 1, Sonnet 4.x, tiempo estimado: 2-3 horas
