extends Node2D
class_name GemAttackEffect

@export var duration := 0.18
@export var beam_width := 4.0
@export var glow_width := 12.0
@export var hit_radius := 18.0
@export var default_color := Color(0.45, 0.95, 1.0, 1.0)

@onready var _beam_glow: Line2D = $BeamGlow
@onready var _beam_core: Line2D = $BeamCore
@onready var _muzzle_ring: Line2D = $MuzzleRing
@onready var _hit_ring: Line2D = $HitRing


# 本类方法：播放一次宝石攻击特效，播放结束后自动移除。
func play(from_position: Vector2, to_position: Vector2, attack_color: Color = default_color) -> void:
	global_position = from_position

	var local_target := to_position - from_position
	_setup_beam(local_target, attack_color)
	_setup_ring(_muzzle_ring, Vector2.ZERO, hit_radius * 0.45, attack_color)
	_setup_ring(_hit_ring, local_target, hit_radius, attack_color)
	_play_tween()


# 本类方法：便捷生成并挂到指定父节点。
static func spawn(parent: Node, from_position: Vector2, to_position: Vector2, attack_color := Color(0.45, 0.95, 1.0, 1.0)) -> GemAttackEffect:
	if parent == null:
		return null

	var scene := load("res://scenes/battle/effects/gem_attack_effect.tscn") as PackedScene
	if scene == null:
		return null

	var effect := scene.instantiate() as GemAttackEffect
	if effect == null:
		return null

	parent.add_child(effect)
	effect.play(from_position, to_position, attack_color)
	return effect


func _setup_beam(local_target: Vector2, attack_color: Color) -> void:
	_beam_glow.points = PackedVector2Array([Vector2.ZERO, local_target])
	_beam_glow.width = glow_width
	_beam_glow.default_color = Color(attack_color.r, attack_color.g, attack_color.b, 0.28)

	_beam_core.points = PackedVector2Array([Vector2.ZERO, local_target])
	_beam_core.width = beam_width
	_beam_core.default_color = attack_color


func _setup_ring(ring: Line2D, ring_position: Vector2, radius: float, attack_color: Color) -> void:
	ring.position = ring_position
	ring.points = _make_circle_points(radius, 32)
	ring.default_color = attack_color
	ring.modulate = Color.WHITE
	ring.scale = Vector2.ONE


func _make_circle_points(radius: float, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _play_tween() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_beam_core, "modulate:a", 0.0, duration)
	tween.tween_property(_beam_glow, "modulate:a", 0.0, duration)
	tween.tween_property(_muzzle_ring, "scale", Vector2(1.8, 1.8), duration)
	tween.tween_property(_muzzle_ring, "modulate:a", 0.0, duration)
	tween.tween_property(_hit_ring, "scale", Vector2(1.7, 1.7), duration)
	tween.tween_property(_hit_ring, "modulate:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
