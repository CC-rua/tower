extends Node2D
class_name MapGem

const GROUP_NAME := "map_gem"
const DEFAULT_ICON_TEXTURE := preload("res://resource/image/icon.svg")
const ATTACH_RADIUS := 64.0
const DAMAGE_TYPE_PHYSICAL := "physical"
const TARGET_POLICY_NEAREST := "nearest"
const DEFAULT_ATTACK_EFFECT_SCENE := preload("res://scenes/battle/effects/gem_attack_effect.tscn")

@export var gem_id := ""
@export var icon_texture: Texture2D = DEFAULT_ICON_TEXTURE
@export var attack_range := 180.0
@export var attack_damage := 25.0
@export var attack_interval := 0.8
@export var damage_type := DAMAGE_TYPE_PHYSICAL
@export var target_policy := TARGET_POLICY_NEAREST
@export var show_attack_range_when_active := true
@export var attack_color := Color(0.45, 0.95, 1.0, 1.0)
@export var attack_effect_scene: PackedScene = DEFAULT_ATTACK_EFFECT_SCENE

# 宝石效果数据，后续可替换为配置行或 Resource。
var effect_data: Variant = null
# 当前安装该宝石的塔基；为空时宝石不执行攻击行为。
var installed_tower: MapTower = null

var _is_dragging := false
var _source_inventory: GemInventoryPanel = null
var _source_slot_index := -1
var _source_tower: MapTower = null
var _highlighted_tower: MapTower = null
var _attack_cooldown := 0.0
var _is_selected := false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


# 继承方法：进入场景树后刷新宝石表现。
func _ready() -> void:
	add_to_group(GROUP_NAME)
	_ensure_sprite()
	_refresh_visual()
	set_process(installed_tower != null)


# 本类方法：初始化宝石数据。
func setup(_gem_id: String = "", _effect_data: Variant = null) -> void:
	gem_id = _gem_id
	effect_data = _effect_data
	_apply_effect_data()
	_refresh_visual()


# 本类方法：获取背包槽位显示用图标。
func get_icon_texture() -> Texture2D:
	return icon_texture


# 本类方法：开始从背包拖拽宝石。
func begin_drag_from_inventory(_inventory: GemInventoryPanel, _slot_index: int) -> void:
	_ensure_sprite()
	_source_inventory = _inventory
	_source_slot_index = _slot_index
	_source_tower = null
	_begin_drag()


# 本类方法：开始从塔位拖拽宝石。
func begin_drag_from_tower(_tower: MapTower) -> void:
	_ensure_sprite()
	_source_inventory = null
	_source_slot_index = -1
	_source_tower = _tower
	_begin_drag()


# 本类方法：进入拖拽状态。
func _begin_drag() -> void:
	deactivate_attack()
	_is_dragging = true
	_is_selected = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	z_index = 100
	global_position = get_global_mouse_position()
	queue_redraw()


# 继承方法：拖拽时跟随鼠标。
func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_global_mouse_position()
		_update_attach_highlight()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_finish_drag()
		return

	if installed_tower == null:
		set_process(false)
		return

	_process_attack(_delta)


# 本类方法：结束拖拽并尝试安装到最近塔位。
func _finish_drag() -> void:
	_is_dragging = false
	set_process(false)
	queue_redraw()

	var _handled := _try_drop_to_inventory()
	if not _handled:
		_handled = _try_drop_to_tower()
	_clear_attach_highlight()

	if not _handled:
		_restore_to_source()

	_source_inventory = null
	_source_slot_index = -1
	_source_tower = null


# 本类方法：激活宝石攻击逻辑，仅在安装到塔基后调用。
func activate_attack(_tower: MapTower) -> void:
	if _tower == null:
		return

	installed_tower = _tower
	_attack_cooldown = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	queue_redraw()


# 本类方法：停用宝石攻击逻辑，卸下或拖拽时调用。
func deactivate_attack() -> void:
	installed_tower = null
	_attack_cooldown = 0.0
	_is_selected = false
	if not _is_dragging:
		set_process(false)
	queue_redraw()


# 本类方法：设置安装态宝石是否被选中，用于显示索敌范围。
func set_selected(_selected: bool) -> void:
	_is_selected = _selected
	queue_redraw()


func is_selected() -> bool:
	return _is_selected


# 本类方法：尝试释放到背包槽位。
func _try_drop_to_inventory() -> bool:
	var _inventory := _find_inventory_under_mouse()
	if _inventory == null:
		return false

	var _target_slot_index := _inventory.get_slot_index_at_global_position(global_position)
	if _target_slot_index < 0:
		return false

	if _source_inventory == _inventory and _source_slot_index >= 0:
		_inventory.place_dragged_gem_at(self, _source_slot_index)
		_inventory.swap_slots(_source_slot_index, _target_slot_index)
		_remove_from_parent()
		return true

	var _old_gem := _inventory.place_dragged_gem_at(self, _target_slot_index)
	_remove_from_parent()

	if _old_gem != null:
		if _source_tower != null:
			_source_tower.attach_gem(_old_gem)
		elif _source_inventory != null and _source_slot_index >= 0:
			_source_inventory.place_dragged_gem_at(_old_gem, _source_slot_index)

	return true


# 本类方法：尝试释放到防御塔，目标已有宝石时执行交换。
func _try_drop_to_tower() -> bool:
	var _tower := _highlighted_tower if _highlighted_tower != null else _find_nearest_tower()
	if _tower == null or _tower == _source_tower:
		return false

	var _old_gem := _tower.replace_gem(self) if _tower.has_gem() else null
	var _attached := true if _old_gem != null else _tower.attach_gem(self)
	if not _attached:
		return false

	if _old_gem != null:
		if _source_tower != null:
			_source_tower.attach_gem(_old_gem)
		elif _source_inventory != null and _source_slot_index >= 0:
			_source_inventory.place_dragged_gem_at(_old_gem, _source_slot_index)

	return true


# 本类方法：释放失败时回到拖拽来源。
func _restore_to_source() -> void:
	if _source_tower != null:
		_source_tower.attach_gem(self)
	elif _source_inventory != null:
		_source_inventory.restore_dragged_gem(self, _source_slot_index)
	else:
		_remove_from_parent()


# 本类方法：查找鼠标附近最近塔位。
func _find_nearest_tower() -> MapTower:
	var _nearest_tower: MapTower = null
	var _nearest_distance := ATTACH_RADIUS

	for _node in get_tree().get_nodes_in_group(MapTower.GROUP_NAME):
		var _tower := _node as MapTower
		if _tower == null:
			continue

		var _distance := global_position.distance_to(_tower.global_position)
		if _distance <= _nearest_distance:
			_nearest_tower = _tower
			_nearest_distance = _distance

	return _nearest_tower


# 本类方法：拖拽时高亮当前会吸附的塔位。
func _update_attach_highlight() -> void:
	var _tower := _find_nearest_tower()
	if _tower == _highlighted_tower:
		return

	_clear_attach_highlight()
	_highlighted_tower = _tower
	if _highlighted_tower != null:
		_highlighted_tower.set_attach_highlight(true)


# 本类方法：清除吸附目标高亮。
func _clear_attach_highlight() -> void:
	if _highlighted_tower != null:
		_highlighted_tower.set_attach_highlight(false)
	_highlighted_tower = null


# 本类方法：查找鼠标所在的宝石背包。
func _find_inventory_under_mouse() -> GemInventoryPanel:
	for _node in get_tree().get_nodes_in_group(GemInventoryPanel.GROUP_NAME):
		var _inventory := _node as GemInventoryPanel
		if _inventory != null and _inventory.get_global_rect().has_point(global_position):
			return _inventory
	return null


# 本类方法：从当前父节点移除。
func _remove_from_parent() -> void:
	deactivate_attack()
	if get_parent() != null:
		get_parent().remove_child(self)


# 本类方法：刷新宝石精灵图。
func _refresh_visual() -> void:
	_ensure_sprite()
	if _sprite == null:
		return

	_sprite.texture = icon_texture


# 本类方法：确保动态创建的宝石也有可见精灵。
func _ensure_sprite() -> void:
	if _sprite != null:
		return

	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		return

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)


# 继承方法：拖拽或选中时显示当前宝石的索敌范围。
func _draw() -> void:
	if not show_attack_range_when_active:
		return
	if not _is_dragging and not _is_selected:
		return

	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.4, 0.75, 1.0, 0.35), 2.0)


# 本类方法：根据冷却时间索敌并攻击。
func _process_attack(_delta: float) -> void:
	_attack_cooldown = max(_attack_cooldown - _delta, 0.0)
	if _attack_cooldown > 0.0:
		return

	var _target := _find_target()
	if _target == null:
		return

	_attack_target(_target)
	_attack_cooldown = max(attack_interval, 0.01)


# 本类方法：查找索敌范围内的目标。
func _find_target() -> BattleEnemy:
	var _best_target: BattleEnemy = null
	var _best_distance := attack_range

	for _node in get_tree().get_nodes_in_group(BattleEnemy.GROUP_NAME):
		var _enemy := _node as BattleEnemy
		if _enemy == null or _enemy.is_dead or _enemy.is_queued_for_deletion():
			continue

		var _distance := global_position.distance_to(_enemy.global_position)
		if _distance > attack_range:
			continue

		if _best_target == null or _distance < _best_distance:
			_best_target = _enemy
			_best_distance = _distance

	return _best_target


# 本类方法：对目标造成伤害。
func _attack_target(_target: BattleEnemy) -> void:
	if _target == null:
		return

	_spawn_attack_effect(_target)
	_target.take_damage(attack_damage, damage_type, installed_tower)


# 本类方法：播放宝石攻击命中特效。
func _spawn_attack_effect(_target: BattleEnemy) -> void:
	if attack_effect_scene == null:
		return

	var _effect := attack_effect_scene.instantiate() as GemAttackEffect
	if _effect == null:
		return

	var _effect_parent := _find_attack_effect_parent()
	if _effect_parent == null:
		_effect.queue_free()
		return

	_effect_parent.add_child(_effect)
	_effect.play(global_position, _target.global_position, attack_color)


# 本类方法：查找攻击特效挂载节点，优先挂到当前关卡的 MapObjects 层。
func _find_attack_effect_parent() -> Node:
	var _node: Node = self
	while _node != null:
		if _node.name == "MapObjects":
			return _node
		_node = _node.get_parent()

	return get_tree().current_scene


# 本类方法：从临时效果数据中读取攻击属性。
func _apply_effect_data() -> void:
	if typeof(effect_data) != TYPE_DICTIONARY:
		return

	var _effect_dict: Dictionary = effect_data
	attack_range = float(_effect_dict.get("attack_range", attack_range))
	attack_damage = float(_effect_dict.get("attack_damage", attack_damage))
	attack_interval = float(_effect_dict.get("attack_interval", attack_interval))
	damage_type = str(_effect_dict.get("damage_type", damage_type))
	target_policy = str(_effect_dict.get("target_policy", target_policy))
	if typeof(_effect_dict.get("attack_color")) == TYPE_COLOR:
		attack_color = _effect_dict.get("attack_color")
