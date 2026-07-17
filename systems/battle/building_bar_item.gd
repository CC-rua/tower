extends Button
class_name BuildingBarItem

signal building_requested(building_id: String)

@export var building_id := "defense_tower"
@export var display_name := "防御塔"
@export var icon_texture: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(128.0, 128.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	expand_icon = true
	icon = icon_texture
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_text = display_name
	focus_mode = Control.FOCUS_NONE
	flat = true
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	building_requested.emit(building_id)
