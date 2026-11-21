# IMHJ AI Migration Context (2026-02-15)

This file is a handoff/context snapshot so you can continue on a stronger PC without losing the current implementation direction.

## 1) Current Goal

Stabilize and finalize the core effects gameplay loop (STRESS/CALM + secondary effects + work penalties), validate behavior against the Notion design export, and prepare for production integration.

Primary design reference used in this session:

- `C:\Users\Ramirex\Downloads\142b236e-89fc-41b2-80f6-f60777d6d037_ExportBlock-7a5e463c-395e-412b-9462-f76834a306db\ExportBlock-7a5e463c-395e-412b-9462-f76834a306db-Part-1\Diseño de Gameplay 2d22b120aae480cd877af234c8413a36.md`

## 2) High-Impact Work Completed In This Session

### A. Work-task penalty from STRESS

Implemented STRESS success penalty hooks for work/mail minigames:

- STRESS Lv1: -10% success
- STRESS Lv2: -25% success
- STRESS Lv3: -50% success

Core API added in `Scripts/player_manager.gd`:

- `get_work_success_rate()`
- `roll_work_task_success()`
- `get_work_failure_chance()`

Mail event integration:

- `Resources/Computer/Apps/Mail/Events/mail_event.gd`
- `Resources/Computer/Apps/Mail/Events/trivia_event.gd`
- `Resources/Computer/Apps/Mail/Events/typing_event.gd`
- `Resources/Computer/Apps/Mail/Events/classification_event.gd`
- `Resources/Computer/Apps/Mail/Events/differences_event.gd`

### B. Workspace + Mail UI stabilization

Reworked mail behavior away from physics/collision stack issues (falling/overlap/reset on resize):

- New simple mail item UI:
  - `Prefabs/Workspace/Computer/Apps/Mail/UI/MailItem/mail_item_simple.gd`
  - `Prefabs/Workspace/Computer/Apps/Mail/UI/MailItem/MailItemSimple.tscn`
- Inbox converted to scroll/list behavior:
  - `Prefabs/Workspace/Computer/Apps/Mail/inbox.gd`
- Mail app spawn/selection/completed-state logic updated:
  - `Prefabs/Workspace/Computer/Apps/Mail/mail.gd`
  - `Prefabs/Workspace/Computer/Apps/Mail/Mail.tscn`

Window sizing support for apps:

- Added configurable app window size:
  - `Resources/Computer/Apps/app_metadata.gd` (`window_size`)
- Base window now applies metadata-driven content/window sizing:
  - `Prefabs/Workspace/Computer/UI/base_window.gd`
- Mail app metadata now uses larger window:
  - `Resources/Computer/Apps/CreatedApps/Mail.tres`

### C. INSOMNIA 3-level system wiring (Notion-aligned baseline)

INSOMNIA was converted from hour-control to level-based effect and integrated into sleep logic:

- `Resources/Effects/Effects/insomnia.tres` now uses `EffectLevel` with 3 levels/icons.
- New effect localization keys added:
  - `Textfiles/Effects/effects.csv`

Core insomnia logic added in `Scripts/player_manager.gd`:

- Auto trigger path (baseline): sanity `< 30` can activate insomnia.
- Sleep cap per insomnia level (randomized hours):
  - Lv1: 4h–7h
  - Lv2: 2h–6h
  - Lv3: 0h–3h
- Poor sleep tracking and level escalation (bad sleep streak conditions).
- Proper sleep streak mitigation path (2 proper sleeps removes insomnia).
- Existing `ATENTA` progression remains tied to insomnia duration (2 days active).

## 3) Effect Asset Wiring / Cleanup Done

- Hunger icon wired to `hungerrr`:
  - `Resources/Effects/Effects/hunger.tres`
- Hyperactive icon rewired to existing `energized2`:
  - `Resources/Effects/Effects/hyperactive.tres`
- Smelly now has icon:
  - `Resources/Effects/Effects/smelly.tres`

Note: assets were intentionally cleaned by user; current references were adjusted to existing files.

## 4) Known Gaps / Consistency Checks Still Pending

These are important before calling effects system final:

1. INSOMNIA extra triggers from Notion are not fully implemented yet:
   - Hyperactive chain trigger(s)
   - Coffee trigger at high energy
   - Other trigger combinations listed in design table
2. Alarm-clock suppression behavior under insomnia is not fully wired.
3. Potential design conflict to resolve:
   - Current logic includes opposite-primary grant behavior in primary system,
   - Notion mentions Stress III full mitigation may grant INSOMNIA.
   - Need one final authoritative rule.
4. Full balancing pass still needed across all effect multipliers/chances.

## 5) Suggested Next Tasks (Priority Order)

1. Complete INSOMNIA trigger matrix from Notion (all activation conditions).
2. Add/verify alarm override logic in sleep interactions.
3. Run effect-by-effect validation checklist in Playground and core flows.
4. Final balancing sweep (time multipliers, spawn probabilities, mitigation rates).

## 6) Migration To New PC (Fast Resume)

### Option A: Copy entire project folder (fastest)

1. Copy `C:\Dev\Projects\IMHJ` to new PC.
2. Open with same Godot version used here.
3. Let `.godot` cache reimport.
4. Continue from this context file.

### Option B: Move to personal GitHub repo snapshot

From the project root on current machine (recommended flow):

1. Create a new private repo on GitHub (empty).
2. Add remote and push a dedicated branch snapshot.

Suggested commands:

```bash
git remote add personal <YOUR_NEW_PRIVATE_REPO_URL>
git checkout -b ai-effects-migration-2026-02-15
git add -A
git commit -m "snapshot: effects/mail/insomnia migration context"
git push -u personal ai-effects-migration-2026-02-15
```

If this repo already has many unrelated local changes, create a zip backup first as a safety checkpoint.

## 7) Important Notes For Next Model/Session

- This repository is in a dirty state with many pre-existing changes and untracked files.
- Do not assume every modified file belongs to this session only.
- Treat effect logic changes as gameplay-critical; verify before broad refactors.
- Use this file as canonical handoff context for the next machine.
