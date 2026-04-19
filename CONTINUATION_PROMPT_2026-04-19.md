# CONTINUATION PROMPT — FASE 4 (Dias 2-4)
**Date:** 2026-04-19  
**Session completed by:** Claude Haiku 4.5  
**Handoff to:** Claude Sonnet 4.6 (for narrative content work)

---

## CURRENT STATUS

**Phase:** FASE 4 — Días 2-4 (narrativa creciente)  
**Last commit:** `a4e6f9c` — "feat: FASE 4 — make Madina dialogue dynamic by day"  
**Branch:** `ai-effects-migration-2026-02-15`  
**Model for this work:** ⛔ **REQUIRES SONNET** (voice consistency)

---

## WHAT WAS COMPLETED THIS SESSION

### ✅ Task 4.1 — Verify schedule events load
- **Status:** VERIFIED ✓
- **Evidence:** 
  - `Scripts/game_manager.gd::_load_schedule_events()` loads all `.tres` files from `Resources/Events/Schedule/` at game startup
  - 11 schedule events exist for Days 2-4, each with proper `day` and `time` config
  - EventManager loads them into the event stack (no trigger until time/day arrives)

### ✅ Task 4.2 — Verify Dialogic timelines exist
- **Status:** VERIFIED ✓
- **Timelines found in `DialoguePlugin/TIMELINE/`:**
  - `madina_cafe_day2.dtl` — Initial Madina lunch (rejection or acceptance)
  - `madina_tension.dtl` — Day 3 escalation
  - `madina_warning.dtl` — Day 4+ fallback
  - `casero_intro.dtl`, `casero_rent_reminder.dtl`, `veda_day1.dtl`, `veda_stare.dtl` ✓

### ✅ Task 4.3 (Part A) — Verify email distribution
- **Status:** VERIFIED ✓
- **Distribution:** Day 1: 4, Day 2: 7, Day 3: 8, Day 4: 11, Day 5: 8, Days 6-7: 0
- **Next step:** Fill all 38 emails with content per `CONTENT_PASS_PLAN.md` §5

### ✅ CODE CHANGE — Dynamic Madina dialogue
- **File:** `Scripts/HouseInteracts/integration_action.gd`
- **Change:** Line 130 now calls `_talk_madina()` (method added at end of file)
- **Behavior:** Day 2 → madina_cafe_day2, Day 3 → madina_tension, Day 4+ → madina_warning

---

## WHAT'S PENDING

### 🔴 Task 4.3 (Part B) — Email content expansion (38 files)

**What to do:**
1. For each file in `Resources/Computer/Apps/Mail/Entries/Narrative/` (email_01.tres through email_38.tres):
   - Update `sender`, `subject`, `content` fields
   - Use exact text from `CONTENT_PASS_PLAN.md` §5
   - Keep character voices consistent (see table below)

**Character voices (from `CONTENT_PASS_PLAN.md` §1.5):**
- **Veda:** Fría, precisa | Sin saludos. Una idea/correo. Firma: — V.
- **Madina:** Cálida, nerviosa | Erratas, "!!", "...". La única humana.
- **Casero:** Gruñón, directo | Viejo, sin paciencia. Tono neutral→pasivo-agresivo.
- **RRHH:** Robótico | Legal, impersonal. Pies de página auto-conscientes.
- **Sistema/Piso 2/Sativa:** [See CONTENT_PASS_PLAN.md for full details]

**Why Sonnet:** Voice consistency is subtle and important. Character email tone mismatch would feel jarring.

---

## GIT STATE

- **Branch:** `ai-effects-migration-2026-02-15`
- **Last commit:** `a4e6f9c` (dynamic Madina dialogue)
- **Ahead of origin:** 6 commits
- **Working tree:** Clean (except worktree submodule warning, ignore it)

---

## NEXT STEP FOR SECONDARY CLAUDE

1. **Confirm you're Sonnet 4.6** (master plan requires it for voice work)
2. **Read in this order:**
   - This document
   - `IHMJ_LAB_MASTER_PLAN.md` (overview)
   - `CONTENT_PASS_PLAN.md` §5 (all 38 email specs)
3. **Fill 38 email files** with content from §5 (mechanical copy + voice validation)
4. **Commit:**
   ```
   feat: FASE 4 — fill email content for all 38 emails (Days 1-5)
   ```
5. **FASE 4 is then complete** — move to FASE 5 (Viernes evaluation screen)

---

## REFERENCE DOCS

- `IHMJ_LAB_MASTER_PLAN.md` — phases, model guidance, overall plan
- `CONTENT_PASS_PLAN.md` — character voices, all 38 email specs, timeline specs
- `IMPLEMENTATION_PLAN_v2.md` — technical constants
