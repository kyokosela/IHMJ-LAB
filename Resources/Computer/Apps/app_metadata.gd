class_name AppMetadata
extends Resource

@export_category("Content")
@export var app_name: String = "New App"
@export var icon: Texture2D
@export var window_scene: PackedScene
@export var window_size: Vector2i = Vector2i(696, 340)

@export_category("Color")
@export var titlebar_bg_color: Color
@export var titlebar_text_color: Color
