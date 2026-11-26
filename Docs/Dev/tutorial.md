# Tutorial de la mañana

Status: En progreso
Assign: Sela (hecho con IA)

El tutorial completo es **una semana jugable**; hoy existe solo la primera mañana, en la casa y el edificio.

# 🔁 Flujo

```
new_game() ─► despertar (Maloliente + Hambre, "Tengo que ducharme.")
   └► ducha ─► armario (uniforme) ─► comer ─► cepillarse ─► puerta ─► pasillo ─► recepción (casero) ─► calle
```

# 📦 Piezas

| Pieza | Archivo |
|---|---|
| Lista de tareas `TUTORIAL_DOOR` (BATHE, CLOTHES, COOK, TEETH) | `Resources/Task/Tutorial/TutorialDoor.tres` |
| Arranque | `Scripts/tutorial.gd` (raíz del apartamento) |
| Puerta y condición "mañana del tutorial" | `Scripts/HouseInteracts/exit_door.gd` |
| Lista y ayudas en pantalla | `UI/Tutorial/tutorial_hud.gd` |
| "Llevas" (manos y mochila) | `UI/PLAYERUI/hands_hud.gd` |
| Frases | `Textfiles/Interact/Interacts.csv`, `DialoguePlugin/TIMELINE/` |

## Quién marca cada tarea

| Tarea | La marca |
|---|---|
| BATHE | `bathe.gd` |
| CLOTHES | `cloth_behavior.gd` y `exit_door.gd` (exige el uniforme **puesto**) |
| COOK | `ingredients.gd` al comer |
| TEETH | `mirror_ui.gd` |

## ⚠️ Deuda conocida

"¿Sigue la mañana del tutorial?" está escrito de **dos formas**:

- Por bandera `tutorial_door_done`: `ExitDoor.in_tutorial_morning()`, copiada además en `integration_action.gd`,
  `wardrobe_ui.gd` y `narrative_event_handler.gd`.
- Por lista terminada: `bathe.gd`, `mirror_ui.gd` e `integration_action._tutorial_needs_meal`.

Hoy no produce errores, pero al ampliar el tutorial hay que dejar **una sola función**.

## Pruebas

`probar_tutorial.gd` (la mañana completa), `probar_voy_tarde.gd`, `jugar_manana.gd` (teclas y ratón como una persona) y
`probar_torpe.gd`. Guion contra juego: [`TUTORIAL_ESTADO.md`](../Design/TUTORIAL_ESTADO.md).
