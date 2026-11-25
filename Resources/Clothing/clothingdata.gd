extends Resource
class_name ClothingData
## Arte de una prenda para las UI (armario, espejo del lavamanos). Cada prenda es un ItemData tipo CLOTH cuyo ClothBehavior
## apunta a este recurso (`clothing`).

@export var item_name: String = ""
@export var outfit_id: String = ""  ## "home", "work", "outfit1" o "towel"

@export_group("Clothes Textures")
@export var clean: Texture2D
@export var dirty: Texture2D
@export var wet: Texture2D
@export var wet_dirty: Texture2D
@export var selection: Texture2D  ## resaltado al pasar el mouse por la prenda colgada

@export_group("Mayui Renders")
@export var render: Texture2D  ## Mayui con esta ropa (lado izquierdo del armario)
@export var render_changing: Texture2D  ## cuadro "cambiandose" (1.5 s) antes de mostrar el render

@export_group("Mirror (lavamanos)")
@export var mirror: Texture2D  ## Mayui de pie frente al espejo
@export var mirror_alt: Texture2D  ## Mayui cepillandose

@export_group("Basket Textures")
@export var empty: Texture2D
@export var full: Texture2D
@export var empty_selection: Texture2D
@export var full_selection: Texture2D

## Textura de la prenda colgada segun su estado (limpia, sucia, mojada o mojada y sucia).
func get_hanger_texture(is_dirty: bool, is_wet: bool) -> Texture2D:
	if is_wet and is_dirty: return wet_dirty
	if is_wet: return wet
	if is_dirty: return dirty
	return clean