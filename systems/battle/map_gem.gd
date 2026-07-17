extends Node2D
class_name MapGem

const DEFAULT_ICON_TEXTURE := preload("res://resource/image/icon.svg")
const ATTACH_RADIUS := 64.0

@export var gem_id := ""
@export var icon_texture: Texture2D = DEFAULT_ICON_TEXTURE

# 宝石效果数据，后续可替换为配置行或 Resource。
var effect_data: Variant = null

var _is_dragging := false
var _source_inventory: GemInventoryPanel = null
var _source_slot_index := -1
var _source_tower: MapTower = null
var _highlighted_tower: MapTower = null

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


# 继承方法：进入场景树后刷新宝石表现。
func _ready() -> void:
	_ensure_sprite()
	_refresh_visual()


# 本类方法：初始化宝石数据。
func setup(_gem_id: String = "", _effect_data: Variant = null) -> void:
	gem_id = _gem_id
	effect_data = _effect_data
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
	_is_dragging = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	z_index = 100
	global_position = get_global_mouse_position()


# 继承方法：拖拽时跟随鼠标。
func _process(_delta: float) -> void:
	if not _is_dragging:
		return

	global_position = get_global_mouse_position()
	_update_attach_highlight()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag()


# 本类方法：结束拖拽并尝试安装到最近塔位。
func _finish_drag() -> void:
	_is_dragging = false
	set_process(false)

	var _handled := _try_drop_to_inventory()
	if not _handled:
		_handled = _try_drop_to_tower()
	_clear_attach_highlight()

	if not _handled:
		_restore_to_source()

	_source_inventory = null
	_source_slot_index = -1
	_source_tower = null


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
