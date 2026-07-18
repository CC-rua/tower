extends CharacterBody2D
class_name BattleEnemy

signal route_finished(enemy: BattleEnemy)

@export var max_health := 100.0
@export var move_speed := 80.0

var health := 100.0
var route_points: Array[Vector2] = []
var route_id := ""

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _route_index := 0


func _ready() -> void:
	health = max_health


func _physics_process(_delta: float) -> void:
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


func setup_route(_route_id: String, _route_points: Array[Vector2]) -> void:
	route_id = _route_id
	route_points = _route_points.duplicate()
	_route_index = 0
	if not route_points.is_empty():
		global_position = route_points[0]
		_route_index = 1


func take_damage(_damage: float) -> void:
	health = max(health - _damage, 0.0)
	if health <= 0.0:
		queue_free()


func _finish_route() -> void:
	velocity = Vector2.ZERO
	route_finished.emit(self)


func _update_walk_animation(_move_velocity: Vector2) -> void:
	if _animated_sprite == null:
		return

	if absf(_move_velocity.x) > absf(_move_velocity.y):
		_animated_sprite.play("walk_right" if _move_velocity.x > 0.0 else "walk_left")
	else:
		_animated_sprite.play("walk_down" if _move_velocity.y > 0.0 else "walk_up")
