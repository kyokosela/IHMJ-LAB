class_name AppData
extends Resource

@export_category("Content")
@export var app_name: String = "New App"
@export var icon: Texture2D
@export var window_scene: PackedScene
@export var session_script: Script = null

@export_category("Color")
@export var titlebar_bg_color: Color
@export var titlebar_text_color: Color
