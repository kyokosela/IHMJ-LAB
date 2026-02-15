# IMHJ DEVELOPER PLAYGROUND — IMPLEMENTATION PLAN
## Codex 5.3-Ready Technical Specification

**Version:** 1.0  
**Target Engine:** Godot 4.6  
**Scene:** `Scenes/Playground_Integration.tscn`  
**Base Script:** `Scenes/playground_integration.gd`  
**Interaction Script:** `Scripts/HouseInteracts/integration_action.gd`

---

# TABLE OF CONTENTS

1. [Overview](#1-overview)
2. [Phase 1: Zone Stations](#2-phase-1-zone-stations)
3. [Phase 2: Apartment Area](#3-phase-2-apartment-area)
4. [Phase 3: Office Area](#4-phase-3-office-area)
5. [Phase 4: Effect & Status Stations](#5-phase-4-effect--status-stations)
6. [Phase 5: Dialogue & NPC Flows](#6-phase-5-dialogue--npc-flows)
7. [Phase 6: Kitchen & Crafting](#7-phase-6-kitchen--crafting)
8. [Phase 7: Inventory Testing](#8-phase-7-inventory-testing)
9. [Phase 8: Spatial Layout & Polish](#9-phase-8-spatial-layout--polish)
10. [Testing Checklist](#10-testing-checklist)

---

# 1. OVERVIEW

## 1.1 Purpose

The Developer Playground provides a **single scene** where ALL game systems can be tested through:

1. **In-world interactables** (hitbox-based, like the actual game)
2. **Harness panel** (quick dev controls for state manipulation)
3. **Visual feedback** (status display showing all manager states)

## 1.2 Current State

**Completed:**
- Basic scene structure with harness UI panel
- Player spawn point with camera
- Basic interaction stations: PC, Portal, Evaluation, Clock In/Out, Rent, NPCs
- Bootstrap runtime initialization
- Status label showing Time, Economy, Attendance, Emails, Events, Flags

**Remaining:**
- Zone transition interactables with bus cost simulation
- Apartment area (bed, bath, kitchen, inventory containers)
- Office area expansion (full workspace, more NPCs)
- Effect trigger stations (hunger, sleepy, smelly, stress)
- Full NPC dialogue flows with Dialogic integration
- Kitchen/crafting multi-step station
- Inventory drag-drop testing
- Organized spatial layout

## 1.3 Interaction Pattern

All playground interactions use `integration_action.gd` which extends `InteractableAction`:

```gdscript
enum ActionType {
    OPEN_WORKSPACE,      # Opens PC workspace
    OPEN_PORTAL,         # Opens employee portal overlay
    OPEN_EVALUATION,     # Opens Friday evaluation screen
    CLOCK_IN,            # AttendanceManager.clock_in()
    CLOCK_OUT,           # AttendanceManager.clock_out()
    RECORD_ABSENCE,      # AttendanceManager.record_absence()
    PAY_RENT,            # EconomyManager.pay_rent()
    CHECK_RENT,          # EconomyManager.check_rent_due()
    TALK_CASERO,         # Dialogic casero dialogues
    TALK_MADINA,         # Dialogic madina dialogues
    EXECUTE_EVENT,       # EventManager.execute_event(event_name)
    SET_FLAG             # NarrativeFlags.set_flag(flag_name)
}
```

---

# 2. PHASE 1: ZONE STATIONS

**Priority:** HIGH  
**Estimated Effort:** 1-2 hours  
**Dependencies:** None

## 2.1 Zone Transition Interactables

Create four zone transition stations that simulate travel between zones with bus costs.

### 2.1.1 Extend ActionType Enum

**File:** `Scripts/HouseInteracts/integration_action.gd`

**Add to ActionType enum:**

```gdscript
enum ActionType {
    # ... existing types ...
    ZONE_APARTMENT,      # Travel to Apartment zone
    ZONE_LOBBY,          # Travel to Lobby zone
    ZONE_OFFICE,         # Travel to Office zone (costs bus fare)
    ZONE_COMMERCIAL      # Travel to Commercial zone (costs bus fare)
}
```

**Add handling in `custom_execute()`:**

```gdscript
ActionType.ZONE_APARTMENT:
    _simulate_zone_change(ZoneManager.ZONES.APARTMENT)
ActionType.ZONE_LOBBY:
    _simulate_zone_change(ZoneManager.ZONES.LOBBY)
ActionType.ZONE_OFFICE:
    _simulate_zone_change(ZoneManager.ZONES.OFFICE)
ActionType.ZONE_COMMERCIAL:
    _simulate_zone_change(ZoneManager.ZONES.COMMERCIAL)
```

**Add helper function:**

```gdscript
func _simulate_zone_change(zone_id: int) -> void:
    var zone_name := ZoneManager.get_zone_name(zone_id)
    var requires_bus := zone_id in [ZoneManager.ZONES.OFFICE, ZoneManager.ZONES.COMMERCIAL]
    
    if requires_bus:
        if not EconomyManager.can_afford_bus():
            _show_feedback("No tienes para el bus (S/10)")
            return
        EconomyManager.pay_bus()
        _show_feedback("Viajando a %s (pagaste S/10)" % zone_name)
    else:
        _show_feedback("Caminando a %s" % zone_name)
    
    # Update simulated zone (don't actually change scene)
    ZoneManager.current_zone = zone_id
    TimeManager.add_to_current_time("00:15")  # 15 min travel time

func _show_feedback(text: String) -> void:
    var scene := get_tree().current_scene
    if scene != null and scene.has_method("_set_action"):
        scene.call("_set_action", text)
```

### 2.1.2 Add Zone Stations to Scene

**File:** `Scenes/Playground_Integration.tscn`

Add four zone stations in a row:

```
[node name="ZoneApartment" type="Label" parent="."]
offset_left = 730.0
offset_top = 400.0
text = "APARTMENT"

[node name="InteractableAction" type="Area2D" parent="ZoneApartment"]
script = integration_action.gd
action_type = 12  # ZONE_APARTMENT
display_text = "Ir al Apartamento"

[node name="ZoneLobby" type="Label" parent="."]
offset_left = 860.0
offset_top = 400.0
text = "LOBBY"

[node name="InteractableAction" type="Area2D" parent="ZoneLobby"]
action_type = 13  # ZONE_LOBBY
display_text = "Ir al Lobby"

[node name="ZoneOffice" type="Label" parent="."]
offset_left = 990.0
offset_top = 400.0
text = "OFFICE (S/10)"

[node name="InteractableAction" type="Area2D" parent="ZoneOffice"]
action_type = 14  # ZONE_OFFICE
display_text = "Ir a la Oficina"

[node name="ZoneCommercial" type="Label" parent="."]
offset_left = 1120.0
offset_top = 400.0
text = "COMMERCIAL (S/10)"

[node name="InteractableAction" type="Area2D" parent="ZoneCommercial"]
action_type = 15  # ZONE_COMMERCIAL
display_text = "Ir a Zona Comercial"
```

## 2.2 Zone Status Display

**File:** `Scenes/playground_integration.gd`

Update `_refresh_status()` to show current zone:

```gdscript
var zone_name := ZoneManager.get_zone_name(ZoneManager.current_zone)
# Add to status_label.text:
# [b]ZONE[/b]\nCurrent: %s\n
```

---

# 3. PHASE 2: APARTMENT AREA

**Priority:** HIGH  
**Estimated Effort:** 2-3 hours  
**Dependencies:** Phase 1

## 3.1 Bed Station (Sleep)

Simulates the bed interaction from `Scripts/HouseInteracts/bed.gd`.

### 3.1.1 Add ActionType

```gdscript
SLEEP_BED  # Triggers sleep with time skip
```

### 3.1.2 Implementation

```gdscript
ActionType.SLEEP_BED:
    _do_sleep()

func _do_sleep() -> void:
    # Same logic as bed.gd but without scene transition
    var current_time := TimeManager.get_current_time()
    var current_minutes := TimeManager.minutes
    var wake_minutes := TimeManager.get_minutes("06:30")
    
    if current_minutes >= wake_minutes:
        # Sleep until next day 06:30
        TimeManager.julian_day += 1
        TimeManager.set_current_time("06:30")
    else:
        # Sleep until 06:30 same day
        TimeManager.set_current_time("06:30")
    
    # Restore energy
    PlayerManager.reset_stat("ENERGY")
    
    # Clear sleepy effect
    EffectManager.remove_active_effect("SLEEPY")
    
    _show_feedback("Dormiste hasta las 06:30")
```

### 3.1.3 Scene Node

```
[node name="BedStation" type="Label" parent="."]
offset_left = 730.0
offset_top = 470.0
text = "BED (Sleep)"

[node name="InteractableAction" type="Area2D" parent="BedStation"]
action_type = 16  # SLEEP_BED
display_text = "Dormir"
```

## 3.2 Bath Station (Bathe)

Simulates `Scripts/HouseInteracts/bathe.gd`.

### 3.2.1 Add ActionType

```gdscript
BATHE  # Removes smelly effect, uses soap
```

### 3.2.2 Implementation

```gdscript
ActionType.BATHE:
    _do_bathe()

func _do_bathe() -> void:
    # Remove smelly effect
    EffectManager.remove_active_effect("SMELLY")
    
    # Add time cost
    TimeManager.add_to_current_time("00:30")
    
    _show_feedback("Te banaste (30 min)")
```

### 3.2.3 Scene Node

```
[node name="BathStation" type="Label" parent="."]
offset_left = 860.0
offset_top = 470.0
text = "BATH (Bathe)"

[node name="InteractableAction" type="Area2D" parent="BathStation"]
action_type = 17  # BATHE
display_text = "Banarse"
```

## 3.3 Closet Station (Change Clothes)

### 3.3.1 Add ActionType

```gdscript
CHANGE_CLOTHES  # Changes player outfit
```

### 3.3.2 Implementation

```gdscript
ActionType.CHANGE_CLOTHES:
    _do_change_clothes()

func _do_change_clothes() -> void:
    # Cycle through available outfits
    # This would interface with PlayerManager clothing system
    TimeManager.add_to_current_time("00:05")
    _show_feedback("Cambiaste de ropa")
```

---

# 4. PHASE 3: OFFICE AREA

**Priority:** HIGH  
**Estimated Effort:** 2 hours  
**Dependencies:** Phase 1

## 4.1 Full Workspace Station

Already implemented via `OPEN_WORKSPACE` action type. Enhance to show email count.

## 4.2 NPC Stations

### 4.2.1 Veda NPC Station

```gdscript
TALK_VEDA  # Dialogic veda dialogues
```

```gdscript
ActionType.TALK_VEDA:
    if TimeManager.day == 1 and not NarrativeFlags.has_flag("met_veda_day1"):
        Dialogic.start("veda_day1")
    else:
        Dialogic.start("veda_generic")
```

### 4.2.2 Sativa NPC Station

```gdscript
TALK_SATIVA  # Dialogic sativa dialogues
```

```gdscript
ActionType.TALK_SATIVA:
    Dialogic.start("sativa_generic")
```

## 4.3 Time Clock Machine

Visual station for clock in/out - already implemented. Add visual feedback showing work hours status.

---

# 5. PHASE 4: EFFECT & STATUS STATIONS

**Priority:** MEDIUM  
**Estimated Effort:** 2 hours  
**Dependencies:** EffectManager autoload

## 5.1 Effect Trigger Stations

Create stations that manually apply effects for testing.

### 5.1.1 Add ActionTypes

```gdscript
APPLY_HUNGRY,        # Apply hunger effect
APPLY_SLEEPY,        # Apply sleepy effect
APPLY_SMELLY,        # Apply smelly effect
APPLY_STRESS,        # Increase stress
CLEAR_ALL_EFFECTS    # Remove all effects
```

### 5.1.2 Implementation

```gdscript
ActionType.APPLY_HUNGRY:
    EffectManager.apply_effect("HUNGRY")
    _show_feedback("Aplicado: HAMBRE")

ActionType.APPLY_SLEEPY:
    EffectManager.apply_effect("SLEEPY")
    _show_feedback("Aplicado: SOMNOLENCIA")

ActionType.APPLY_SMELLY:
    EffectManager.apply_effect("SMELLY")
    _show_feedback("Aplicado: MAL OLOR")

ActionType.APPLY_STRESS:
    PlayerManager.modify_stat("CORDURA", -10)
    _show_feedback("Estres +10")

ActionType.CLEAR_ALL_EFFECTS:
    EffectManager.clear_all_effects()
    _show_feedback("Efectos eliminados")
```

### 5.1.3 Scene Nodes

Create a row of effect stations:

```
HUNGRY | SLEEPY | SMELLY | STRESS | CLEAR ALL
```

## 5.2 Status Display Enhancement

Update status label to show active effects:

```gdscript
# In _refresh_status():
var active_effects: Array = EffectManager.get_active_effects()
# Add to display:
# [b]EFFECTS[/b]\nActive: %s
```

---

# 6. PHASE 5: DIALOGUE & NPC FLOWS

**Priority:** MEDIUM  
**Estimated Effort:** 2-3 hours  
**Dependencies:** Dialogic plugin, .dtl files

## 6.1 Dialogue Trigger Stations

Create stations for each major dialogue flow.

### 6.1.1 Add ActionTypes

```gdscript
DIALOGUE_CASERO_INTRO,     # casero_intro.dtl
DIALOGUE_CASERO_RENT,      # casero_rent_reminder.dtl
DIALOGUE_MADINA_CAFE,      # madina_cafe_day2.dtl
DIALOGUE_MADINA_M88,       # madina_m88_object.dtl
DIALOGUE_VEDA_DAY1,        # veda_day1.dtl
DIALOGUE_SUNDAY_PREP       # sunday_prep.dtl
```

### 6.1.2 Implementation

```gdscript
ActionType.DIALOGUE_CASERO_INTRO:
    Dialogic.start("casero_intro")
    await Dialogic.timeline_ended
    NarrativeFlags.set_flag("casero_intro_done")

ActionType.DIALOGUE_CASERO_RENT:
    Dialogic.start("casero_rent_reminder")

ActionType.DIALOGUE_MADINA_CAFE:
    Dialogic.start("madina_cafe_day2")
    RelationshipManager.add_points("MADINA", 25)

ActionType.DIALOGUE_MADINA_M88:
    Dialogic.start("madina_m88_object")
    # Player choice in dialogue will set nota_madina flag

ActionType.DIALOGUE_VEDA_DAY1:
    Dialogic.start("veda_day1")
    NarrativeFlags.set_flag("met_veda_day1")

ActionType.DIALOGUE_SUNDAY_PREP:
    Dialogic.start("sunday_prep")
```

### 6.1.3 Scene Layout

Create a "Dialogue Testing" section:

```
CASERO      CASERO      MADINA      MADINA      VEDA        SUNDAY
INTRO       RENT        CAFE        M88         DAY1        PREP
```

---

# 7. PHASE 6: KITCHEN & CRAFTING

**Priority:** MEDIUM  
**Estimated Effort:** 3-4 hours  
**Dependencies:** Kitchen system from ApartamentD.tscn

## 7.1 Kitchen Station Overview

Reference: `Scenes/ApartamentD.tscn` contains kitchen with multiple cooking stations.

### 7.1.1 Add ActionTypes

```gdscript
COOK_INSTANT,        # Cook instant meal (+10 energy, +25% stress)
COOK_HOMEMADE,       # Cook homemade meal (+30 energy, -1 stress)
COOK_START_MULTI,    # Start multi-step cooking
COOK_STEP_NEXT       # Advance cooking step
```

### 7.1.2 Simplified Implementation

For playground, simplify cooking to button presses:

```gdscript
ActionType.COOK_INSTANT:
    if not InventoryManager.has_item("instant_meal"):
        _show_feedback("No tienes comida instantanea")
        return
    InventoryManager.remove_item("instant_meal")
    PlayerManager.modify_stat("ENERGY", 10)
    PlayerManager.modify_stat("CORDURA", -5)  # 25% stress
    TimeManager.add_to_current_time("00:10")
    _show_feedback("Comiste comida instantanea")

ActionType.COOK_HOMEMADE:
    if not InventoryManager.has_item("ingredients"):
        _show_feedback("No tienes ingredientes")
        return
    InventoryManager.remove_item("ingredients")
    PlayerManager.modify_stat("ENERGY", 30)
    PlayerManager.modify_stat("CORDURA", 1)
    TimeManager.add_to_current_time("00:45")
    _show_feedback("Cocinaste comida casera")
```

## 7.2 Item Spawner Station

Spawn test items into inventory:

```gdscript
SPAWN_INSTANT_MEAL,
SPAWN_INGREDIENTS,
SPAWN_SOAP,
SPAWN_MONEY_100
```

```gdscript
ActionType.SPAWN_INSTANT_MEAL:
    InventoryManager.add_item("instant_meal")
    _show_feedback("Agregaste comida instantanea")

ActionType.SPAWN_INGREDIENTS:
    InventoryManager.add_item("ingredients")
    _show_feedback("Agregaste ingredientes")

ActionType.SPAWN_MONEY_100:
    EconomyManager.add_money(100, "DEV_SPAWN")
    _show_feedback("Agregaste S/100")
```

---

# 8. PHASE 7: INVENTORY TESTING

**Priority:** MEDIUM  
**Estimated Effort:** 2 hours  
**Dependencies:** InventoryManager, drag-drop system

## 8.1 Inventory Display Station

Open inventory UI for testing drag-drop:

```gdscript
OPEN_INVENTORY  # Shows inventory panel
```

## 8.2 Container Stations

Create mock containers for item transfer testing:

```gdscript
OPEN_CONTAINER_A,  # Opens container A
OPEN_CONTAINER_B   # Opens container B
```

## 8.3 Item State Testing

Test item state changes (fresh -> stale, clean -> dirty):

```gdscript
ITEM_AGE_TEST,     # Ages items to test staleness
ITEM_USE_TEST      # Uses/consumes an item
```

---

# 9. PHASE 8: SPATIAL LAYOUT & POLISH

**Priority:** LOW  
**Estimated Effort:** 2 hours  
**Dependencies:** All previous phases

## 9.1 Layout Design

Organize playground into logical zones matching game flow:

```
+------------------+------------------+------------------+
|   APARTMENT      |     OFFICE       |   COMMERCIAL     |
|                  |                  |                  |
| [Bed] [Bath]     | [PC] [Portal]    | [Shop] [Arcade]  |
| [Kitchen]        | [Clock In/Out]   | [Food Stand]     |
| [Closet]         | [NPCs: Madina,   |                  |
| [Inventory]      |  Veda, Sativa]   |                  |
|                  | [Evaluation]     |                  |
+------------------+------------------+------------------+
|                    ZONE TRANSITIONS                    |
| [Apartment] [Lobby] [Office S/10] [Commercial S/10]   |
+-------------------------------------------------------+
|                    EFFECT TESTING                      |
| [Hungry] [Sleepy] [Smelly] [Stress] [Clear All]       |
+-------------------------------------------------------+
|                    DIALOGUE TESTING                    |
| [Casero] [Madina] [Veda] [Sativa] [Sunday Prep]       |
+-------------------------------------------------------+
|                    DEV CONTROLS                        |
| [+Time] [+Money] [Set Flag] [Save] [Load] [Bootstrap] |
+-------------------------------------------------------+
```

## 9.2 Visual Enhancements

- Add colored backgrounds to zone areas
- Add icons/sprites to station labels
- Add collision shapes for walkable areas
- Add visual indicators for active states

## 9.3 Status Panel Improvements

Show comprehensive state:
- Current zone with travel costs
- Active effects with icons
- Relationship levels with all NPCs
- Email queue status
- Scheduled events for current day

---

# 10. TESTING CHECKLIST

## 10.1 Economy Tests

- [ ] Start with S/350
- [ ] Add money via harness (+S/100)
- [ ] Pay bus fare (S/10) - should deduct correctly
- [ ] Pay rent (S/230) - should mark as paid
- [ ] Rent warning after missed payment
- [ ] Cannot travel without bus fare

## 10.2 Attendance Tests

- [ ] Clock in before 08:00 - on time
- [ ] Clock in after 08:00 - late penalty
- [ ] Clock out after 17:00 - normal
- [ ] Clock out before 17:00 - early leave penalty
- [ ] Miss work day - absence recorded
- [ ] 4 absences = fired state

## 10.3 Time Tests

- [ ] Time advances with travel
- [ ] Time advances with activities
- [ ] Day change at appropriate time
- [ ] Week change after 7 days
- [ ] Scheduled events trigger at correct times

## 10.4 Effect Tests

- [ ] Apply hunger effect - speed penalty
- [ ] Apply sleepy effect - energy drain
- [ ] Apply smelly effect - relationship penalty
- [ ] Clear effects via bath/sleep
- [ ] Stress accumulation and reduction

## 10.5 Dialogue Tests

- [ ] Casero intro plays once
- [ ] Casero rent reminder after intro
- [ ] Madina cafe day 2 dialogue
- [ ] Madina M88 object with choice
- [ ] Veda day 1 dialogue
- [ ] Sunday preparation dialogue

## 10.6 Email Tests

- [ ] Emails appear based on day
- [ ] Conditional emails require flags
- [ ] Email minigames complete correctly
- [ ] Email completion tracked

## 10.7 Narrative Flag Tests

- [ ] Set flag via harness
- [ ] Clear flag via harness
- [ ] Flags persist after save/load
- [ ] Conditional content responds to flags

## 10.8 Save/Load Tests

- [ ] Save captures all manager states
- [ ] Load restores all manager states
- [ ] Position and scene state preserved

---

# APPENDIX A: COMPLETE ACTIONTYPE ENUM

```gdscript
enum ActionType {
    # Workspace & Apps
    OPEN_WORKSPACE,          # 0
    OPEN_PORTAL,             # 1
    OPEN_EVALUATION,         # 2
    
    # Attendance
    CLOCK_IN,                # 3
    CLOCK_OUT,               # 4
    RECORD_ABSENCE,          # 5
    
    # Economy
    PAY_RENT,                # 6
    CHECK_RENT,              # 7
    
    # NPCs
    TALK_CASERO,             # 8
    TALK_MADINA,             # 9
    TALK_VEDA,               # 10
    TALK_SATIVA,             # 11
    
    # Events & Flags
    EXECUTE_EVENT,           # 12
    SET_FLAG,                # 13
    
    # Zone Travel
    ZONE_APARTMENT,          # 14
    ZONE_LOBBY,              # 15
    ZONE_OFFICE,             # 16
    ZONE_COMMERCIAL,         # 17
    
    # Apartment Actions
    SLEEP_BED,               # 18
    BATHE,                   # 19
    CHANGE_CLOTHES,          # 20
    
    # Effects
    APPLY_HUNGRY,            # 21
    APPLY_SLEEPY,            # 22
    APPLY_SMELLY,            # 23
    APPLY_STRESS,            # 24
    CLEAR_ALL_EFFECTS,       # 25
    
    # Dialogues
    DIALOGUE_CASERO_INTRO,   # 26
    DIALOGUE_CASERO_RENT,    # 27
    DIALOGUE_MADINA_CAFE,    # 28
    DIALOGUE_MADINA_M88,     # 29
    DIALOGUE_VEDA_DAY1,      # 30
    DIALOGUE_SUNDAY_PREP,    # 31
    
    # Kitchen
    COOK_INSTANT,            # 32
    COOK_HOMEMADE,           # 33
    
    # Items
    SPAWN_INSTANT_MEAL,      # 34
    SPAWN_INGREDIENTS,       # 35
    SPAWN_SOAP,              # 36
    SPAWN_MONEY_100,         # 37
    
    # Inventory
    OPEN_INVENTORY,          # 38
    OPEN_CONTAINER_A,        # 39
    OPEN_CONTAINER_B         # 40
}
```

---

# APPENDIX B: FILE MODIFICATION INDEX

| File | Action | Phase |
|------|--------|-------|
| `Scripts/HouseInteracts/integration_action.gd` | MODIFY | 1-7 |
| `Scenes/Playground_Integration.tscn` | MODIFY | 1-8 |
| `Scenes/playground_integration.gd` | MODIFY | 1-8 |

---

# APPENDIX C: ESTIMATED TOTAL EFFORT

| Phase | Description | Hours |
|-------|-------------|-------|
| 1 | Zone Stations | 1-2 |
| 2 | Apartment Area | 2-3 |
| 3 | Office Area | 2 |
| 4 | Effect Stations | 2 |
| 5 | Dialogue Flows | 2-3 |
| 6 | Kitchen/Crafting | 3-4 |
| 7 | Inventory Testing | 2 |
| 8 | Layout & Polish | 2 |
| **Total** | | **16-22 hours** |

---

*Document generated for Codex 5.3 implementation workflow*
