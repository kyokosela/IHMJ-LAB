# SpritePreset.gd
extends Resource
class_name SpritePreset

@export var preset_name: String = ""
@export var layers: Dictionary[String, Texture2D] = {}
