# Cocina, crafteo e inventario (cambios IA)

Status: En revisión
Assign: Sela (hecho con IA) · sistema original: Ghoko

Amplía las fichas **Inventario**, **Sistema crafteo** y **UI Cocina**. No se crearon clases nuevas: se completaron las
existentes (cada cambio tiene `## Completado:`). Guía de recetas: [`COCINA_Y_OBJETOS.md`](../Design/COCINA_Y_OBJETOS.md).

# 🔧 Errores corregidos en las clases

| Clase | Problema | Arreglo |
|---|---|---|
| `KitchenContainer.execute_simple_craft` | Gastaba la casilla equivocada: comida infinita | Consume cada ingrediente en su casilla |
| `KitchenContainer._setup_slot_structure` | Al volver a la zona borraba lo guardado | No rehace un inventario ya armado |
| `KitchenContainer` (estaciones) | La comida en marcha se perdía al salir | `get_live_resources()` + `_restore_stations()` |
| `ConsumableBehavior.use` | Gastaba usos del `ItemData` compartido | Gasta `item.uses_left` |
| `InventoryContainer.use_item_at` | Miraba los usos compartidos | Mira `uses_left` |
| `InventoryComponent.to_dict/from_dict` | Perdía condiciones y contenido (olla vacía) | Guarda `conditions` y `held` |

# ➕ Añadidos

## `KitchenContainer`

```gdscript
func get_station_time_left(station_id) -> String      # para el botón Esperar
func is_simple_craft_result_free() -> bool
func set_simple_craft_result(item)
func add_item(item) / add_item_by_data(data)          # va al almacenamiento, no a una estación
```
El resultado se queda en la estación (o en la casilla de Combinar) hasta que se saque.

## `Crafts` (grupo *Station*)

| Variable | Para qué |
|---|---|
| `button_text` | Texto del botón cuando toca esa receta ("Vaciar") |
| `active_seconds` | Segundos del dibujo trabajando en recetas instantáneas (agua) |

## `KitchenMultiUI` (`UI/Containers/kitchen_multi_ui.gd`)

- Arte ilustrado: `station_item_props` (olla), `station_active_props` (fuego/agua), `station_content_props` y
  `content_textures` (qué se ve dentro de la olla).
- Dos alacenas (`storage_grid_2`, `storage_first_count`).
- Botón **Esperar** con confirmación (adelanta el reloj hasta que termine).
- `_allow_drop`: cada estación acepta solo lo suyo (`Station.get_rejection_reason`) y Mayui lo dice.
- Estufa vacía: frases `stove_empty_lines`. Frases de la comida instantánea en el tutorial.

## `ContainerUI` / `InventorySlotUI`

- Mayui quieta mientras está abierta; `Esc` cierra.
- Clic derecho o doble clic sobre un objeto de las manos: **usarlo**.
- `drop_filter`, `hide_icon`, `dim_when_locked`; la casilla se redibuja si el objeto cambia.

## Comida y bebida

- `Ingredients`: `meal_kind` (`HOME`/`INSTANT`), `fixed_energy`; **solo se come lo cocinado**; aplica Inapetencia,
  `register_meal` y marca la tarea `COOK`.
- `CoffeeBehavior`: Hiperactividad de 2 h, disparador de Insomnio, alivio de Hipersomnia.
- `ClothBehavior`: `clothing` (arte e id) y tarea `CLOTHES`.
- `ItemData.held_textures` + `Item.get_display_texture()`.

## ⚠️ Cuidado

- Las `Station` son recursos **compartidos**: guardan estado ("ocupada") aunque cambie la escena.
- La cocina no se guarda en disco (solo en memoria entre zonas).
- Prueba: `Tools/probar_crafteos.gd`.
