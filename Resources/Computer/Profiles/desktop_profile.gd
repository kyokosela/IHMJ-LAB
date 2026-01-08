class_name DesktopProfile
extends Resource

@export var wallpaper: Texture2D
@export var password: String = ""
@export var installed_apps: Array[AppData]
@export var app_states: Dictionary = {}
