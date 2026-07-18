extends CharacterBody2D
class_name BattleEnemy

signal route_finished(enemy: BattleEnemy)
signal died(enemy: BattleEnemy)
signal damaged(enemy: BattleEnemy, damage: float, source: Node)

const GROUP_NAME := "battle_enemy"
const DAMAGE_TYPE_PHYSICAL := "physical"
const DAMAGE_TYPE_MAGICAL := "magical"
const DAMAGE_TYPE_TRUE := "true"

@export var max_health := 100.0
@export var defense := 0.0
@export var move_speed := 80.0
@export var damage := 1.0
@export var kill_reward_gold := 10

var health := 100.0
var route_points: Array[Vector2] = []
var route_id := ""
var is_dead := false

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar

var _route_index := 0


# 继承方法：进入场景树后初始化生命值并登记敌人分组。
func _ready() -> void:
	add_to_group(GROUP_NAME)
	health = max_health
	_refresh_health_bar()


# 继承方法：沿路线移动敌人。
func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	if route_points.is_empty() or _route_index >= route_points.size():
		velocity = Vector2.ZERO
		return

	var _target := route_points[_route_index]
	var _to_target := _target - global_position
	if _to_target.length() <= 2.0:
		_route_index += 1
		if _route_index >= route_points.size():
			_finish_route()
		return

	velocity = _to_target.normalized() * move_speed
	_update_walk_animation(velocity)
	move_and_slide()


# 本类方法：初始化敌人行走路线。
func setup_route(_route_id: String, _route_points: Array[Vector2]) -> void:
	route_id = _route_id
	route_points = _route_points.duplicate()
	_route_index = 0
	if not route_points.is_empty():
		global_position = route_points[0]
		_route_index = 1


# 本类方法：初始化怪物基础属性。
func setup_stats(_max_health: float, _defense: float, _move_speed: float, _damage: float, _kill_reward_gold: int = kill_reward_gold) -> void:
	max_health = max(_max_health, 1.0)
	defense = max(_defense, 0.0)
	move_speed = max(_move_speed, 0.0)
	damage = max(_damage, 0.0)
	kill_reward_gold = max(_kill_reward_gold, 0)
	health = max_health
	_refresh_health_bar()


# 本类方法：从配置字典初始化怪物基础属性，便于后续接入表格数据。
func setup_stats_from_data(_data: Dictionary) -> void:
	setup_stats(
		float(_data.get("max_health", max_health)),
		float(_data.get("defense", defense)),
		float(_data.get("move_speed", move_speed)),
		float(_data.get("damage", damage)),
		int(_data.get("kill_reward_gold", kill_reward_gold))
	)


# 本类方法：获取怪物当前战斗属性快照。
func get_stats() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"defense": defense,
		"move_speed": move_speed,
		"damage": damage,
		"kill_reward_gold": kill_reward_gold
	}


# 本类方法：承受伤害，生命归零时死亡并移除。
func take_damage(_attack_damage: float, _damage_type: String = DAMAGE_TYPE_PHYSICAL, _source: Node = null) -> float:
	if is_dead:
		return 0.0

	var _final_damage: float = calculate_damage(_attack_damage, _damage_type, _source)
	if _final_damage <= 0.0:
		return 0.0

	health = max(health - _final_damage, 0.0)
	_refresh_health_bar()
	damaged.emit(self, _final_damage, _source)
	if health <= 0.0:
		die()

	return _final_damage


# 本类方法：预留伤害计算接口，后续可接入防御塔属性、攻击类型、护甲/抗性等规则。
func calculate_damage(_attack_damage: float, _damage_type: String = DAMAGE_TYPE_PHYSICAL, _source: Node = null) -> float:
	var _base_damage: float = max(_attack_damage, 0.0)
	if _base_damage <= 0.0:
		return 0.0

	match _damage_type:
		DAMAGE_TYPE_TRUE:
			return _base_damage
		DAMAGE_TYPE_MAGICAL:
			return max(_base_damage - defense, 1.0)
		DAMAGE_TYPE_PHYSICAL:
			return max(_base_damage - defense, 1.0)
		_:
			return max(_base_damage - defense, 1.0)


# 本类方法：怪物死亡并从场景移除。
func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	_refresh_health_bar()
	died.emit(self)
	queue_free()


# 本类方法：刷新生命条数值，仅在生命不满且未死亡时显示。
func _refresh_health_bar() -> void:
	if _health_bar == null:
		_health_bar = get_node_or_null("HealthBar") as ProgressBar
	if _health_bar == null:
		return

	_health_bar.max_value = max(max_health, 1.0)
	_health_bar.value = clamp(health, 0.0, max_health)
	_health_bar.visible = not is_dead and health > 0.0 and health < max_health


# 本类方法：敌人抵达路线终点。
func _finish_route() -> void:
	if is_dead:
		return

	velocity = Vector2.ZERO
	route_finished.emit(self)


# 本类方法：根据移动方向刷新行走动画。
func _update_walk_animation(_move_velocity: Vector2) -> void:
	if _animated_sprite == null:
		return

	if absf(_move_velocity.x) > absf(_move_velocity.y):
		_animated_sprite.play("walk_right" if _move_velocity.x > 0.0 else "walk_left")
	else:
		_animated_sprite.play("walk_down" if _move_velocity.y > 0.0 else "walk_up")
