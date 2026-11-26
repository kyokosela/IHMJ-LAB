# Ropa, armario, ducha y espejo

Status: En revisión
Assign: Sela (hecho con IA)

Amplía la ficha **UI Wardrobe**.

# 📦 Modelo (en `PlayerManager`)

```gdscript
var outfit : Item              # lo puesto (puede ser la toalla)
var wardrobe : Array[Item]     # lo colgado
signal outfit_changed(item)
```
Cada prenda es un `Item` tipo CLOTH con condiciones `cleanliness` (≤ 50 sucia) y `wetness` (> 30 mojada).

| Función | Qué hace |
|---|---|
| `reset_outfits()` | Ropa de casa puesta, uniforme colgado |
| `wear_clothes(item)` / `wear_towel()` | Cambia ropa y sprite; ropa mojada puede dar Debilitamiento o Estrés |
| `soil_clothes(n)` / `wet_clothes(n)` | Para eventos futuros (nadie las usa aún) |
| `_on_clothes_time(min)` | Con el reloj se ensucia y se seca; sucia = el cuerpo se ensucia más rápido |

`ClothingData` (por prenda): `outfit_id`, texturas de colgada (limpia, sucia, mojada, ambas), render, cambiándose, espejo y
cesta.

# 📘 `WardrobeUI` (`UI/Containers/wardrobe_ui.gd`)

**Exportadas:** `render_rect`, `basket_rect`, `garment_slots` (id → nodo con `Layer`, `Highlight`, `Hit`),
`tutorial_refusals`, `basket_lines`, `uniform_dialog`.

Flujo: abrir con fundido → clic en prenda → cuadro "cambiándose" 1 s → `wear_clothes` → +2 min. `Esc` espera 1 s tras
cambiarse.

# 📘 `ShowerScene` (`UI/Shower/shower_scene.gd`)

Silueta tras la cortina, **dibujada por código** (provisional). `play(esperar_dialogo)`; responde a las señales de Dialogic
`estornudo` y `ducha_fuera`. La abre `bathe.gd`, que además marca la tarea `BATHE`, quita Maloliente, llama
`register_bath` (agua fría en el tutorial) y pone la toalla.

# 📘 `MirrorUI` (`UI/Mirror/mirror_ui.gd`)

| Zona | Acción |
|---|---|
| Cepillo | Cepillarse, una vez al día, 5 min, tarea `TEETH` |
| Espejo | Comentario según el estado (nunca un medidor) |
| Llave | Lavar ropa sucia que lleve en las manos (bloqueado en el tutorial) |

⚠️ El nodo `CupFront` es un recorte del fondo (el vaso va delante del marco). Si cambia el arte hay que volver a recortarlo.

## Sprites

`Resources/SpriteStacks/Mayui/` (casa, toalla, Outfit 1). Las hojas se arman con `Tools/armar_hojas_mayui.ps1`; los pasos
de caminar son **provisionales**.

## Pendiente

Cesta, Outfit 1 como prenda, eventos que ensucian, cabeza del sprite. Pruebas: `Tools/probar_ropa.gd`,
`Tools/probar_espejo.gd`.
