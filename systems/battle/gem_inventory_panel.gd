extends PanelContainer
class_name GemInventoryPanel

const GROUP_NAME := "gem_inventory"

@export var title := "宝石背包"
@export var columns := 3
@export var rows := 6
@export var slot_size := 48
@export var drag_layer_path := NodePath("..")

var _gems: Array[MapGem] = []
var _drag_layer: Node = null

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _grid_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer


# 继承方法：进入场景树后初始化背包槽位。
func _ready() -> void:
	add_to_group(GROUP_NAME)
	_drag_layer = get_node_or_null(drag_layer_path)
	_title_label.text = title
	_build_slots()
	_add_debug_gems()


# 本类方法：设置当前背包中的全部宝石数据。
func set_gems(_new_gems: Array[MapGem]) -> void:
	_ensure_slot_count()
	for _index in range(_gems.size()):
		_gems[_index] = _new_gems[_index] if _index < _new_gems.size() else null
	_refresh_slots()


# 本类方法：尝试向背包中加入一个宝石。
func add_gem(_gem_data: MapGem) -> bool:
	if _gem_data == null:
		return false
	if not has_empty_slot():
		return false

	var _slot_index := get_first_empty_slot_index()
	if _slot_index < 0:
		return false

	_gems[_slot_index] = _gem_data
	_refresh_slots()
	return true


# 本类方法：从指定槽位移除宝石。
func remove_gem_at(_index: int) -> MapGem:
	if _index < 0 or _index >= _gems.size():
		return null

	var _gem := _gems[_index]
	_gems[_index] = null
	_refresh_slots()
	return _gem


# 本类方法：获取指定槽位中的宝石数据。
func get_gem(_index: int) -> MapGem:
	if _index < 0 or _index >= _gems.size():
		return null
	return _gems[_index]


# 本类方法：获取背包容量。
func get_capacity() -> int:
	return max(columns, 0) * max(rows, 0)


# 本类方法：判断背包是否还有空槽位。
func has_empty_slot() -> bool:
	return get_first_empty_slot_index() >= 0


# 本类方法：获取第一个空槽位。
func get_first_empty_slot_index() -> int:
	_ensure_slot_count()
	for _index in range(_gems.size()):
		if _gems[_index] == null:
			return _index
	return -1


# 本类方法：获取鼠标所在的槽位索引。
func get_slot_index_at_global_position(_global_position: Vector2) -> int:
	if _grid_container == null:
		return -1

	for _index in range(_grid_container.get_child_count()):
		var _slot := _grid_container.get_child(_index) as Control
		if _slot == null:
			continue
		if _slot.get_global_rect().has_point(_global_position):
			return _index

	return -1


# 本类方法：将拖拽中的宝石放入指定槽位，必要时返回被替换宝石。
func place_dragged_gem_at(_gem: MapGem, _slot_index: int) -> MapGem:
	_ensure_slot_count()
	if _gem == null or _slot_index < 0 or _slot_index >= _gems.size():
		return _gem

	var _old_gem := _gems[_slot_index]
	_gems[_slot_index] = _gem
	_refresh_slots()
	return _old_gem


# 本类方法：交换两个背包槽位。
func swap_slots(_from_index: int, _to_index: int) -> bool:
	_ensure_slot_count()
	if _from_index < 0 or _from_index >= _gems.size():
		return false
	if _to_index < 0 or _to_index >= _gems.size():
		return false

	var _old_gem := _gems[_to_index]
	_gems[_to_index] = _gems[_from_index]
	_gems[_from_index] = _old_gem
	_refresh_slots()
	return true


# 本类方法：取消背包拖拽，将宝石放回原槽位。
func restore_dragged_gem(_gem: MapGem, _slot_index: int) -> void:
	_ensure_slot_count()
	if _gem == null:
		return

	if _slot_index >= 0 and _slot_index < _gems.size() and _gems[_slot_index] == null:
		_gems[_slot_index] = _gem
	elif has_empty_slot():
		_gems[get_first_empty_slot_index()] = _gem

	if _gem.get_parent() != null:
		_gem.get_parent().remove_child(_gem)
	_refresh_slots()


# 本类方法：创建背包槽位。
func _build_slots() -> void:
	_clear_slots()
	_ensure_slot_count()
	_grid_container.columns = max(columns, 1)

	for _index in range(get_capacity()):
		var _slot := Button.new()
		_slot.name = "Slot_%02d" % _index
		_slot.custom_minimum_size = Vector2(slot_size, slot_size)
		_slot.focus_mode = Control.FOCUS_NONE
		_slot.tooltip_text = "宝石槽 %d" % (_index + 1)
		_slot.gui_input.connect(_on_slot_gui_input.bind(_index))
		_grid_container.add_child(_slot)

	_refresh_slots()


# 本类方法：刷新槽位显示。
func _refresh_slots() -> void:
	if _grid_container == null:
		return

	for _index in range(_grid_container.get_child_count()):
		var _slot := _grid_container.get_child(_index) as Button
		if _slot == null:
			continue

		if _index < _gems.size() and _gems[_index] != null:
			_slot.text = ""
			_slot.icon = _gems[_index].get_icon_texture()
			_slot.expand_icon = true
			_slot.disabled = false
		else:
			_slot.text = ""
			_slot.icon = null
			_slot.disabled = false


# 本类方法：清理已创建的槽位。
func _clear_slots() -> void:
	for _child in _grid_container.get_children():
		_child.queue_free()


# 本类方法：临时添加测试宝石，后续接入真实掉落或初始背包后移除。
func _add_debug_gems() -> void:
	var _gem_a := MapGem.new()
	_gem_a.setup("debug_gem_a")
	add_gem(_gem_a)

	var _gem_b := MapGem.new()
	_gem_b.setup("debug_gem_b")
	add_gem(_gem_b)


# 本类方法：处理槽位输入，按下宝石槽时开始拖拽。
func _on_slot_gui_input(_event: InputEvent, _index: int) -> void:
	var _mouse_event := _event as InputEventMouseButton
	if _mouse_event == null:
		return
	if not _mouse_event.pressed or _mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var _gem := get_gem(_index)
	if _gem == null:
		return

	remove_gem_at(_index)
	if _gem.get_parent() != null:
		_gem.get_parent().remove_child(_gem)

	var _target_layer := _drag_layer if _drag_layer != null else self
	_target_layer.add_child(_gem)
	_gem.global_position = get_global_mouse_position()
	_gem.begin_drag_from_inventory(self, _index)


# 本类方法：确保背包数组长度等于容量。
func _ensure_slot_count() -> void:
	var _capacity := get_capacity()
	while _gems.size() < _capacity:
		_gems.append(null)
	while _gems.size() > _capacity:
		_gems.pop_back()
