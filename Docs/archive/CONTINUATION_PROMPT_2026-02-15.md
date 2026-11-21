# IHMJ continuation prompt (new machine)

Use this prompt verbatim on the other machine to resume seamlessly:

```text
Continue IHMJ from the latest state on branch `ai-effects-migration-2026-02-15` in repo `IHMJ-LAB`.

Context:
- Godot 4.6 project, sleep/insomnia/effects alignment completed from Notion exports.
- Two core commits were already pushed:
  - feat: align sleep system to design spec (bed types, insomnia trigger, stress reduction)
  - feat: complete INSOMNIA trigger matrix from design doc
- Authoritative rule source is the design docs (strict interpretation; do not assume missing rules).
- Existing non-blocking yellow warnings may still appear in Godot.

What to do first:
1. Pull latest branch and verify clean state.
2. Open `res://Scenes/Playground_Integration.tscn` and run manual validation for:
   - sleep energy table (9h=38, 10h=40)
   - bed modifiers A/B/C
   - under-sleep -> INSOMNIA
   - worked-day STRESS floor logic
   - alarm override flags (`has_alarm_clock`/`has_alarm_phone` + `sleep_alarm_hours_override`)
   - all INSOMNIA triggers (sanity<30 day change, hyperactive stack, coffee @ >=90 energy, SLEEPY III + bad sleep, INSOMNIA+HYPERACTIVE health penalty)
3. Record pass/fail per case and fix only failing cases.
4. Keep unrelated files untouched; do not revert user changes.

Key files:
- `Scripts/player_manager.gd`
- `Scripts/HouseInteracts/bed.gd`
- `Scripts/HouseInteracts/integration_action.gd`
- `Resources/Items/Behaviors/coffee_behavior.gd`
- `SLEEP_ALIGNMENT_AUDIT_2026-02-15.md`
- `AI_MIGRATION_CONTEXT_2026-02-15.md`

Output format expected from you:
- Brief status of repo/branch
- Validation matrix (PASS/FAIL per case)
- Exact fixes applied (if any)
- Commands run and relevant results
- Next recommended action (balance sweep / warning cleanup / PR)
```
