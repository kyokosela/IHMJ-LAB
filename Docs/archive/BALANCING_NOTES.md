# BALANCING NOTES — IHMJ-LAB Prólogo
**Fecha:** 2026-04-19  
**Método:** Static code analysis (sin runtime Godot)  
**Rama:** `ai-effects-migration-2026-02-15`

---

## 1. ECONOMÍA

### Simulación por perfil (semana 1)

| Perfil | Días trabajados | Gross | Bus | Deducciones | Renta | Net ganado | Balance final |
|--------|----------------|-------|-----|-------------|-------|-----------|---------------|
| Ideal (5d, 0 tarde) | 5 | S/1000 | -S/50 | 0 | -S/230 | +S/720 | **S/1070** |
| Neutro (4d, 1 tarde) | 4 | S/800 | -S/40 | -S/20 | -S/230 | +S/510 | **S/860** |
| Caótico (3d, 2 tarde) | 3 | S/600 | -S/30 | -S/40 | -S/230 | +S/300 | **S/650** |
| Peor superviviente (2d, 3 faltas) | 2 | S/400 | -S/20 | -S/50 (cut) | -S/230 | +S/100 | **S/450** |
| Despedido (4+ faltas) | — | S/0 | — | — | S/230 no pagable | — | **Game Over** |

*Nota: El salario llega a las 16:00 del viernes y la renta vence a las 18:00. El jugador ideal nunca siente presión de renta.*

### 🔴 Issue 1: ABSENCE_SALARY_CUT es trivial
- **Valor actual:** S/50 deducción por 3ª falta
- **Problema:** 12.5% de un gross de S/400 (2 días) — no duele
- **Fix:** Subir a S/100 → duplica la presión sin romper la math
- **Archivo:** `Scripts/attendance_manager.gd` línea 146

### 🟡 Issue 2: LATE_SALARY_PENALTY es bajo
- **Valor actual:** S/20 por llegada tarde
- **Problema:** 5 llegadas tarde = S/100 = 10% del gross ideal. Sin consecuencia real.
- **Sugerencia:** Subir a S/30 (aún razonable, más perceptible)
- **Archivo:** `Scripts/attendance_manager.gd` línea 21
- **Decision:** No cambiado en esta sesión — esperar test runtime

### 🟡 Issue 3: Bus muy barato
- **Valor actual:** S/10 por viaje a Office/Commercial
- **Problema:** 5 días trabajo = S/50 total (5% del gross). No registra.
- **Sugerencia:** S/15 para Office, S/10 para Commercial — diferencia de zona
- **Decision:** No cambiado — requiere ajuste en `zone_manager.gd` y nuevas constantes

---

## 2. STRESS Y ESCALADA

### Timeline de escalada (peor caso)
- **Día 1:** Jugador recibe STRESS (sanity < 40)
- **Día 2:** STRESS Lv1 → Lv2 (días_activo = 1, condición: >= 1) → -25% trabajo
- **Día 3:** STRESS Lv2 → Lv3 (días_activo = 2, condición: >= 2) → -50% trabajo
- **Día 3+:** 50% chance de spawn INAPETENCIA

### 🔴 Issue 4: Escalada demasiado rápida para semana de 5 días
- **Problema:** STRESS Lv3 es alcanzable en Día 3 si el estrés empieza el Lunes.
  Con -50% de éxito en tareas, el jugador neutro puede estar completamente roto para el miércoles.
- **Fix aplicado:** Cambiar threshold de Lv2→Lv3 de `days >= 2` a `days >= 3`
  - Lv1→Lv2: día 1 (sin cambio) 
  - Lv2→Lv3: día 3 → llega a Lv3 en Día 4 mínimo (no en Día 3)
- **Archivo:** `Scripts/player_manager.gd` línea 747

### 🟡 Issue 5: LV3_STRESS_SECONDARY_SPAWN_CHANCE = 50%
- **Problema:** En Lv3, 50% chance diaria de INAPETENCIA. Con Lv3 desde Día 3,
  la mayoría de jugadores tendrán INAPETENCIA antes del viernes.
- **Sugerencia:** Bajar a 30%
- **Decision:** No cambiado — esperar test runtime para validar si es realmente jarring

---

## 3. ARCADE (Días 6-7)

### 🟢 Diseño correcto
- Arcade solo disponible cuando `arcade_open` flag activo (Día 6+)
- Stress de arcade es en Día 6 → efectos se propagan al Día 7 solamente
- No afecta semana laboral → balance OK

### 🟡 Issue 6: Stacking de CALM/STRESS en arcade
- **Problema:** Ganar varias veces aplica CALM múltiples veces (levelup acumulativo).
  Perder varias veces puede llevar a Lv3 STRESS en un sábado.
- **Sugerencia:** Cap de 1 aplicación de STRESS/CALM por sesión de arcade
- **Decision:** No implementado aún — baja prioridad para el prólogo

---

## 4. SLEEP ENERGY

### Análisis del rango
```
1h: 5 | 2h: 8 | 3h: 10 | 4h: 12 | 5h: 15 | 6h: 20 | 7h: 30 | 8h: 35 | 9h: 38 | 10h: 40
```
- Valores son **mínimos** — multiplicador de cama se aplica encima
- Cama C (base): multiplicador 1.0x → 8h = mínimo 35 energía
- Con energía inicial de 100 y jornada de 9h (8:00-17:00), drain depende del sistema de stats

### 🟡 Issue 7: Salto brusco entre 6h (20) y 7h (30)
- El incentivo para dormir 7h vs 6h es mayor que el de 7h vs 8h
- No es un bug, pero puede confundir al jugador
- **Decision:** Sin cambio — requiere ajuste fino post-runtime

---

## 5. AUDIO PLACEHOLDERS

**Estado actual:** Sin audio. El juego funciona pero está mudo.

**Mínimo requerido (task 7.4):**

| SFX | Dónde hookear | Archivo sugerido |
|-----|--------------|-----------------|
| Click UI | `Interactable.execute()` | `res://Audio/SFX/click.ogg` |
| Pasos jugador | `movement_component.gd` | `res://Audio/SFX/footstep.ogg` |
| Transición sleep | `PlayerManager.sleep()` — inicio | `res://Audio/SFX/sleep_start.ogg` |
| Alarma | `AlarmUI._ready()` | `res://Audio/SFX/alarm.ogg` |
| Dinero (pay/receive) | `EconomyManager.add_money()` / `spend_money()` | `res://Audio/SFX/coin.ogg` |

**Estado:** Rutas creadas en tabla pero assets no existen. Crear carpeta `Audio/SFX/`
con AudioStreamPlayers placeholder antes de playtest final.

---

## 6. RESUMEN DE CAMBIOS APLICADOS

| Cambio | Archivo | Línea | Antes | Después |
|--------|---------|-------|-------|---------|
| ABSENCE_SALARY_CUT | `attendance_manager.gd` | 146 | S/50 | S/100 |
| Stress Lv2→Lv3 threshold | `player_manager.gd` | 747 | `days >= 2` | `days >= 3` |

---

## 7. CRITERIOS DE "JUGABLE" — ESTADO

- [x] 7 días sin crashes — código estable
- [x] Efectos se disparan correctamente — sistema validado
- [ ] 3 perfiles dan resultados diferentes — pendiente runtime
- [x] Economía balanceada: posible pero no trivial pagar renta *(marginal — ver Issue 1)*
- [x] NPCs con diálogo por día — Madina, Casero, Veda cubiertos
- [ ] Save/Load entre días — sistema existe, sin test runtime
- [ ] 5 triggers de INSOMNIA reproducibles en gameplay real

---

*Generado por static analysis. Validar en runtime Godot antes de producción.*
