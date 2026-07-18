extends Control

const LEVEL_OPTIONS := [
	{
		"id": "level_001",
		"title": "关卡 1",
		"description": "当前地图原型关卡",
		"scene_path": "res://scenes/battle/levels/level_001.tscn",
	},
]

@onready var _level_list: VBoxContainer = $MarginContainer/Content/LevelList


func _ready() -> void:
	_build_level_buttons()


func _build_level_buttons() -> void:
	for _child in _level_list.get_children():
		_child.queue_free()

	for _level_data in LEVEL_OPTIONS:
		var _button := Button.new()
		_button.custom_minimum_size = Vector2(0.0, 72.0)
		_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_button.text = "%s\n%s" % [_level_data["title"], _level_data["description"]]
		_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_button.pressed.connect(_on_level_button_pressed.bind(_level_data["scene_path"]))
		_level_list.add_child(_button)


func _on_level_button_pressed(scene_path: String) -> void:
	App.set_selected_battle_level_scene_path(scene_path)
	SceneFlow.go_to_page("battle")


func _on_back_button_pressed() -> void:
	SceneFlow.go_to_page("main_menu")
