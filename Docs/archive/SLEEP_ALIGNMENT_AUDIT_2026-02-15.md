# Sleep Alignment Audit (2026-02-15)

## Scope

- Design source reviewed:
  - `C:\Users\Sela\Downloads\ExportBlock-0cc15f43-da8d-4190-91e4-7a9db1a7d7ee-Part-1\Ficha de acciones 2d92b120aae4807b87dff407ca4a5513.md`
- Current implementation reviewed:
  - `Scripts/player_manager.gd`
  - `Scripts/HouseInteracts/bed.gd`
  - `Scripts/HouseInteracts/integration_action.gd`
  - `Scenes/Playground_Integration.tscn`
  - `Scenes/Playground.tscn`

## Design Rules (Sleep)

- Minimum mandatory sleep by energy at sleep time:
  - 1-15%: 10h
  - 16-30%: 9h
  - 31-50%: 8h
  - 51-70%: 7h
  - 71-100%: 6h
- Bed types affect required sleep time:
  - Type A: -1h
  - Type B: -30m
  - Type C: 0h
- Bed types affect effective energy result:
  - Type A: +10%
  - Type B: +5%
  - Type C: +0%
- Energy base by hours slept:
  - 1h: 5, 2h: 8, 3h: 10, 4h: 12, 5h: 15, 6h: 20, 7h: 30, 8h: 35, 9h: 38, 10h: 40
- Stress from sleeping:
  - Base: -8%
  - Extra by bed type: A -6%, B -2%, C 0%
- Restrictions:
  - Once per day
  - Requires object in inventory
  - Sleep cannot reduce stress below 20% if player worked that day
  - If minimum proportional hours are not met, apply INSOMNIA
- Alarm note:
  - If player has alarm-capable item, player can choose sleep hours with wake chance based on energy

## Current Implementation Snapshot

- Sleep is executed via `PlayerManager.sleep()` from bed interactions.
- Minimum sleep hours mapping exists and matches thresholds (10/9/8/7/6).
- Energy gain is computed with:
  - `base_energy_for_minimum_hours * (actual_sleep/minimum_sleep)`
- Current base energy table:
  - 1h:5, 2h:8, 3h:10, 4h:12, 5h:15, 6h:20, 7h:30, 8h:35, 9h:40, 10h:42
- INSOMNIA current behavior:
  - Triggered by low sanity (`sanity < 30`) on day change if not active
  - Sleep while INSOMNIA active is capped by random level ranges
  - Proper sleep streak can remove INSOMNIA (2 proper sleeps)
- No alarm hour-selection implementation found in sleep action path.

## Alignment Results

### Matches

- Minimum sleep threshold bands exist and match the design table ranges.
- INSOMNIA has level-based sleep caps and recovery tracking (already integrated).

### Mismatches (Critical)

- INSOMNIA trigger source differs:
  - Design: from under-sleeping minimum proportional hours.
  - Current: primarily sanity-driven auto trigger.
- Sleep stress logic missing:
  - Design requires stress reduction + floor at 20% if worked.
  - Current sleep path does not modify stress.

### Mismatches (High)

- Bed type modifiers are not implemented in runtime sleep pipeline.
- Once-per-day sleep restriction is not globally enforced in code path.
- Inventory prerequisite for sleep is not enforced in current sleep function path.
- Alarm-based hour-choice + wake chance system not implemented in current sleep flow.

### Mismatches (Medium)

- Energy table differs at high hours:
  - Design: 9h=38, 10h=40
  - Current: 9h=40, 10h=42
- Energy formula model differs from design wording/examples.

## Confirmations Needed Before Patch

1. Canonical trigger rule for INSOMNIA:
   - A) Only under-sleep trigger (design strict)
   - B) Under-sleep + sanity trigger (hybrid)
2. For "worked that day" stress floor rule, what should be authoritative:
   - A) Clocked in
   - B) Completed shift
   - C) Any work task completed
3. Bed type source of truth:
   - A) Equipped item
   - B) Bed interactable metadata
   - C) Room/furniture definition
4. Final energy table confirmation:
   - A) Keep design caps (9h=38, 10h=40)
   - B) Keep current values (9h=40, 10h=42)

## Implementation Status (2026-02-15)

### Completed

1. INSOMNIA trigger changed to under-sleep-based (strict design).
2. Bed-type modifiers wired (A/B/C time reduction + energy effectiveness).
3. Energy table aligned to design (9h=38, 10h=40).
4. Stress reduction on sleep: deterministic level reduction with worked-day floor.
5. Alarm hour override gated by temporary flags (`has_alarm_clock`, `has_alarm_phone`).
6. Headless validation passes.

### Deferred (Lower Priority / Requires UI or Item System Work)

- Once-per-day sleep restriction (can be scene-configured via cooldown).
- Inventory prerequisite for sleep (requires alarm/bed item IDs to be defined).
- Alarm wake-chance-by-energy (requires UI flow for hour selection + wake failure handling).

### Files Changed

- `Scripts/player_manager.gd`
- `Scripts/HouseInteracts/bed.gd`
- `Scripts/HouseInteracts/integration_action.gd`

### How to Test Alarm Override (Temporary)

```gdscript
NarrativeFlags.set_flag("has_alarm_clock", true)
NarrativeFlags.set_value("sleep_alarm_hours_override", "05:00")
PlayerManager.sleep()  # Will attempt 5h sleep if alarm flag is set
```
