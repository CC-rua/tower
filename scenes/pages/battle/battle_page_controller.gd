extends Control
class_name BattlePageController

const DEFAULT_LEVEL_SCENE := preload("res://scenes/battle/levels/level_001.tscn")

signal level_loaded(level_instance: Node)

@export var default_level_scene: PackedScene = DEFAULT_LEVEL_SCENE
@export var level_root_path := NodePath("LevelRoot")

var _current_level: Node = null


func _enter_tree() -> void:
	_load_default_level()


func get_current_level() -> Node:
	return _current_level


func load_level(level_scene: PackedScene) -> Node:
	if level_scene == null:
		push_error("BattlePageController: level scene is null.")
		return null

	var _level_root := get_node_or_null(level_root_path)
	if _level_root == null:
		push_error("BattlePageController: LevelRoot node is missing.")
		return null

	if is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null

	_current_level = level_scene.instantiate()
	_current_level.name = "CurrentLevel"
	_level_root.add_child(_current_level)
	level_loaded.emit(_current_level)
	return _current_level


func _load_default_level() -> void:
	var _selected_level_scene := load(App.get_selected_battle_level_scene_path()) as PackedScene
	if _selected_level_scene != null:
		load_level(_selected_level_scene)
		return

	load_level(default_level_scene)
