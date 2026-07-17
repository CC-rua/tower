extends Node
class_name EnemyController

const DEFAULT_ENEMY_SCENE := preload("res://scenes/battle/enemy/black_flesh_enemy.tscn")

@export var battle_map_controller_path := NodePath("../BattleMapController")
@export var enemy_root_path := NodePath("../MapObjects/Enemies")
@export var enemy_scene: PackedScene = DEFAULT_ENEMY_SCENE
@export var test_spawn_count := 2
@export var test_spawn_interval := 0.6

var _battle_map_controller: BattleMapController = null
var _enemy_root: Node = null
var _spawned_test_enemies := false


func _ready() -> void:
	_battle_map_controller = get_node_or_null(battle_map_controller_path) as BattleMapController
	_enemy_root = get_node_or_null(enemy_root_path)

	if _battle_map_controller == null:
		push_error("EnemyController: BattleMapController node is missing.")
		return

	if _battle_map_controller.map_model != null:
		_on_map_loaded(_battle_map_controller.map_model)
	else:
		_battle_map_controller.map_loaded.connect(_on_map_loaded, CONNECT_ONE_SHOT)


func spawn_enemy(_route_id: String) -> BattleEnemy:
	if enemy_scene == null:
		push_error("EnemyController: enemy scene is null.")
		return null

	var _route_points := _battle_map_controller.get_route_world_points(_route_id)
	if _route_points.is_empty():
		push_warning("EnemyController: route is empty: %s." % _route_id)
		return null

	var _enemy := enemy_scene.instantiate() as BattleEnemy
	if _enemy == null:
		push_error("EnemyController: enemy scene must inherit BattleEnemy.")
		return null

	_get_enemy_root().add_child(_enemy)
	_enemy.setup_route(_route_id, _route_points)
	_enemy.route_finished.connect(_on_enemy_route_finished)
	return _enemy


func spawn_test_enemies() -> void:
	if _spawned_test_enemies:
		return
	_spawned_test_enemies = true

	var _route_ids := _battle_map_controller.get_route_ids()
	if _route_ids.is_empty():
		push_warning("EnemyController: no marker routes configured, test enemies were not spawned.")
		return

	for _index in range(test_spawn_count):
		if _index > 0 and test_spawn_interval > 0.0:
			await get_tree().create_timer(test_spawn_interval).timeout
		spawn_enemy(_route_ids[0])


func _on_map_loaded(_map_model: BattleMapModel) -> void:
	spawn_test_enemies()


func _on_enemy_route_finished(_enemy: BattleEnemy) -> void:
	pass


func _get_enemy_root() -> Node:
	if _enemy_root == null:
		_enemy_root = self
	return _enemy_root
