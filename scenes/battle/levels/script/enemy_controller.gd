extends Node
class_name EnemyController

const DEFAULT_ENEMY_SCENE := preload("res://scenes/battle/enemy/black_flesh_enemy.tscn")

signal battle_started
signal battle_finished
signal wave_started(wave_number: int, total_waves: int)
signal wave_progress_changed(wave_number: int, remaining_enemy_count: int)
signal enemy_killed_rewarded(enemy: BattleEnemy, gold_amount: int)

@export var battle_map_controller_path := NodePath("../BattleMapController")
@export var economy_controller_path := NodePath("../BattleEconomyController")
@export var enemy_root_path := NodePath("../MapObjects/Enemies")
@export var enemy_scene: PackedScene = DEFAULT_ENEMY_SCENE
@export var time_between_waves := 6.0
@export var wave_definitions: Array = [
	{"route_id": "route_001", "enemy_count": 3, "spawn_interval": 0.8},
	{"route_id": "route_001", "enemy_count": 5, "spawn_interval": 0.7},
	{"route_id": "route_001", "enemy_count": 7, "spawn_interval": 0.6}
]

var _battle_map_controller: BattleMapController = null
var _economy_controller: BattleEconomyController = null
var _enemy_root: Node = null
var _active_enemies: Array[BattleEnemy] = []
var _battle_has_started := false
var _battle_is_finished := false
var _pending_wave_index := 0
var _current_wave_index := -1
var _remaining_spawns_in_wave := 0
var _spawn_interval_remaining := 0.0
var _wave_cooldown_remaining := 0.0
var _current_wave_route_id := ""
var _is_spawning_wave := false


func _ready() -> void:
	_battle_map_controller = get_node_or_null(battle_map_controller_path) as BattleMapController
	_economy_controller = get_node_or_null(economy_controller_path) as BattleEconomyController
	_enemy_root = get_node_or_null(enemy_root_path)
	set_process(true)

	if _battle_map_controller == null:
		push_error("EnemyController: BattleMapController node is missing.")
		return

	if _battle_map_controller.map_model != null:
		_on_map_loaded(_battle_map_controller.map_model)
	else:
		_battle_map_controller.map_loaded.connect(_on_map_loaded, CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if not _battle_has_started or _battle_is_finished:
		return

	if _is_spawning_wave:
		_process_wave_spawning(delta)
		return

	if _pending_wave_index >= get_total_wave_count():
		if _active_enemies.is_empty():
			_finish_battle()
		return

	if _wave_cooldown_remaining > 0.0:
		_wave_cooldown_remaining = max(_wave_cooldown_remaining - delta, 0.0)
		if _wave_cooldown_remaining > 0.0:
			return

	_start_next_wave()


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
	_enemy.set_meta("wave_index", _current_wave_index)
	_enemy.route_finished.connect(_on_enemy_route_finished)
	_enemy.died.connect(_on_enemy_died)
	_enemy.tree_exited.connect(_on_enemy_tree_exited.bind(_enemy))
	_active_enemies.append(_enemy)
	_emit_wave_progress_changed()
	return _enemy


func destroy_enemy(_enemy: BattleEnemy) -> void:
	if _enemy == null:
		return

	_active_enemies.erase(_enemy)
	if is_instance_valid(_enemy):
		_enemy.queue_free()
	_emit_wave_progress_changed()


func start_battle() -> bool:
	if _battle_map_controller == null or _battle_is_finished or _battle_has_started:
		return false
	if wave_definitions.is_empty():
		push_warning("EnemyController: wave definitions are empty.")
		return false

	_battle_has_started = true
	_wave_cooldown_remaining = 0.0
	battle_started.emit()
	_start_next_wave()
	return true


func trigger_next_wave_now() -> bool:
	if not _battle_has_started or _battle_is_finished:
		return false
	if _is_spawning_wave:
		return false
	if _pending_wave_index >= get_total_wave_count():
		return false

	_wave_cooldown_remaining = 0.0
	_start_next_wave()
	return true


func has_battle_started() -> bool:
	return _battle_has_started


func is_battle_finished() -> bool:
	return _battle_is_finished


func get_total_wave_count() -> int:
	return wave_definitions.size()


func get_current_wave_number() -> int:
	return _current_wave_index + 1 if _current_wave_index >= 0 else 0


func get_remaining_enemy_count_in_current_wave() -> int:
	var _active_count := 0
	for _enemy in _active_enemies:
		if _enemy != null and int(_enemy.get_meta("wave_index", -1)) == _current_wave_index:
			_active_count += 1
	return _remaining_spawns_in_wave + _active_count


func can_trigger_next_wave_now() -> bool:
	return _battle_has_started and not _battle_is_finished and not _is_spawning_wave and _pending_wave_index < get_total_wave_count()


func get_next_wave_cooldown_remaining() -> float:
	return max(_wave_cooldown_remaining, 0.0)


func _start_next_wave() -> void:
	if _pending_wave_index >= get_total_wave_count():
		return

	var _wave_data: Dictionary = _get_wave_definition(_pending_wave_index)
	_current_wave_index = _pending_wave_index
	_pending_wave_index += 1
	_current_wave_route_id = str(_wave_data.get("route_id", ""))
	_remaining_spawns_in_wave = max(int(_wave_data.get("enemy_count", 0)), 0)
	_spawn_interval_remaining = 0.0
	_is_spawning_wave = _remaining_spawns_in_wave > 0
	wave_started.emit(get_current_wave_number(), get_total_wave_count())
	_emit_wave_progress_changed()

	if not _is_spawning_wave:
		_on_wave_spawn_completed()


func _process_wave_spawning(delta: float) -> void:
	if _remaining_spawns_in_wave <= 0:
		_on_wave_spawn_completed()
		return

	_spawn_interval_remaining -= delta
	if _spawn_interval_remaining > 0.0:
		return

	var _spawned_enemy := spawn_enemy(_current_wave_route_id)
	if _spawned_enemy == null:
		_spawn_interval_remaining = 0.2
		return

	_remaining_spawns_in_wave -= 1
	_emit_wave_progress_changed()
	if _remaining_spawns_in_wave <= 0:
		_on_wave_spawn_completed()
		return

	var _wave_data: Dictionary = _get_wave_definition(_current_wave_index)
	_spawn_interval_remaining = max(float(_wave_data.get("spawn_interval", 0.6)), 0.01)


func _on_wave_spawn_completed() -> void:
	_is_spawning_wave = false
	_spawn_interval_remaining = 0.0
	if _pending_wave_index < get_total_wave_count():
		_wave_cooldown_remaining = max(time_between_waves, 0.0)
	elif _active_enemies.is_empty():
		_finish_battle()


func _finish_battle() -> void:
	if _battle_is_finished:
		return

	_battle_is_finished = true
	_is_spawning_wave = false
	_wave_cooldown_remaining = 0.0
	battle_finished.emit()


func _get_wave_definition(_wave_index: int) -> Dictionary:
	if _wave_index < 0 or _wave_index >= wave_definitions.size():
		return {}
	var _wave_data: Variant = wave_definitions[_wave_index]
	return _wave_data if _wave_data is Dictionary else {}


func _emit_wave_progress_changed() -> void:
	wave_progress_changed.emit(get_current_wave_number(), get_remaining_enemy_count_in_current_wave())


func _on_map_loaded(_map_model: BattleMapModel) -> void:
	pass


func _on_enemy_route_finished(_enemy: BattleEnemy) -> void:
	destroy_enemy(_enemy)
	if _battle_has_started and _pending_wave_index >= get_total_wave_count() and not _is_spawning_wave and _active_enemies.is_empty():
		_finish_battle()


# 信号处理方法：敌人被防御塔击杀时清理活动列表。
func _on_enemy_died(_enemy: BattleEnemy) -> void:
	_active_enemies.erase(_enemy)
	_grant_enemy_kill_reward(_enemy)
	_emit_wave_progress_changed()
	if _battle_has_started and _pending_wave_index >= get_total_wave_count() and not _is_spawning_wave and _active_enemies.is_empty():
		_finish_battle()


# 信号处理方法：敌人因任意原因离开场景树时清理活动列表。
func _on_enemy_tree_exited(_enemy: BattleEnemy) -> void:
	_active_enemies.erase(_enemy)
	_emit_wave_progress_changed()


func _get_enemy_root() -> Node:
	if _enemy_root == null:
		_enemy_root = self
	return _enemy_root


func _grant_enemy_kill_reward(_enemy: BattleEnemy) -> void:
	if _enemy == null:
		return

	var _gold_reward: int = max(_enemy.kill_reward_gold, 0)
	if _gold_reward <= 0:
		return

	if _economy_controller != null:
		_economy_controller.add_gold(_gold_reward)
	enemy_killed_rewarded.emit(_enemy, _gold_reward)
