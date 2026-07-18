extends Node2D
class_name MapTower

const GROUP_NAME := "map_tower"
const SOURCE_PRESET := "preset"
const SOURCE_PLAYER := "player"
const CLICK_RADIUS := 32.0
const DRAG_START_DISTANCE := 8.0

@export var tower_id := ""
@export var origin_cell := Vector2i.ZERO
@export var size_in_cells := Vector2i.ONE
@export var source := SOURCE_PRESET

# 宝石提供攻击、减速等效果；为空时该对象就是一个塔基。
var gem_data: MapGem = null
var _is_pending_gem_drag := false
var _pending_drag_start_position := Vector2.ZERO

@onready var _base_sprite: Sprite2D = get_node_or_null("BaseSprite") as Sprite2D
@onready var _gem_socket: Node2D = get_node_or_null("GemSocket") as Node2D


# 继承方法：进入场景树后登记塔位分组，供宝石拖拽查找。
func _ready() -> void:
	add_to_group(GROUP_NAME)
	set_process(false)


# 继承方法：监听宝石拖拽阈值，区分单击选择和拖动卸下。
func _process(_delta: float) -> void:
	if not _is_pending_gem_drag:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_pending_gem_drag = false
		set_process(false)
		return
	if _pending_drag_start_position.distance_to(get_global_mouse_position()) < DRAG_START_DISTANCE:
		return

	_is_pending_gem_drag = false
	set_process(false)
	_begin_drag_gem()


# 继承方法：右键卸下宝石，左键单击选中，左键拖动已安装宝石。
func _input(_event: InputEvent) -> void:
	var _mouse_event := _event as InputEventMouseButton
	if _mouse_event == null:
		return
	if not has_gem() and not _is_pending_gem_drag:
		return

	var _is_inside_click_radius := global_position.distance_to(get_global_mouse_position()) <= CLICK_RADIUS
	if _mouse_event.pressed and not _is_inside_click_radius:
		if _mouse_event.button_index == MOUSE_BUTTON_LEFT and _find_gem_tower_under_mouse() == null:
			_clear_selected_gems()
		return

	if _mouse_event.button_index == MOUSE_BUTTON_RIGHT and _mouse_event.pressed:
		_cancel_pending_gem_drag()
		_try_detach_gem_to_inventory()
	elif _mouse_event.button_index == MOUSE_BUTTON_LEFT and _mouse_event.pressed:
		_select_gem()
		_is_pending_gem_drag = true
		_pending_drag_start_position = get_global_mouse_position()
		set_process(true)
	elif _mouse_event.button_index == MOUSE_BUTTON_LEFT and not _mouse_event.pressed and _is_pending_gem_drag:
		_cancel_pending_gem_drag()
		_select_gem()
	else:
		return

	get_viewport().set_input_as_handled()


# 本类方法：初始化地图塔位数据。
func setup(_origin_cell: Vector2i, _source: String = SOURCE_PLAYER, _tower_id: String = "") -> void:
	origin_cell = _origin_cell
	source = _source
	tower_id = _tower_id


# 本类方法：获取该塔位占用的全部逻辑格。
func get_occupied_cells() -> Array[Vector2i]:
	var _cells: Array[Vector2i] = []
	var _safe_size := Vector2i(max(size_in_cells.x, 1), max(size_in_cells.y, 1))

	for _x in range(_safe_size.x):
		for _y in range(_safe_size.y):
			_cells.append(origin_cell + Vector2i(_x, _y))

	return _cells


# 本类方法：判断当前是否已安装宝石。
func has_gem() -> bool:
	return gem_data != null


# 本类方法：安装宝石，使塔基成为具备效果的防御塔。
func attach_gem(_gem_data: MapGem) -> bool:
	if _gem_data == null or has_gem():
		return false

	set_attach_highlight(false)
	gem_data = _gem_data
	if _gem_socket != null:
		if _gem_data.get_parent() != null:
			_gem_data.get_parent().remove_child(_gem_data)
		_gem_socket.add_child(_gem_data)
		_gem_data.position = Vector2.ZERO
		_gem_data.z_index = 1
		_gem_data.activate_attack(self)

	return true


# 本类方法：移除宝石，使防御塔退回塔基状态。
func detach_gem() -> MapGem:
	var _old_gem_data := gem_data
	if _old_gem_data != null:
		_old_gem_data.deactivate_attack()
	if _old_gem_data != null and _old_gem_data.get_parent() == _gem_socket:
		_gem_socket.remove_child(_old_gem_data)
	gem_data = null
	return _old_gem_data


# 本类方法：替换当前宝石，并返回被替换的旧宝石。
func replace_gem(_gem_data: MapGem) -> MapGem:
	var _old_gem := detach_gem()
	attach_gem(_gem_data)
	return _old_gem


# 本类方法：设置宝石拖拽吸附高亮。
func set_attach_highlight(_enabled: bool) -> void:
	if _base_sprite == null:
		return

	_base_sprite.modulate = Color(1.35, 1.25, 0.65, 1.0) if _enabled else Color.WHITE


# 本类方法：尝试将宝石卸下并放回背包。
func _try_detach_gem_to_inventory() -> bool:
	var _inventory := _find_inventory()
	if _inventory == null or not _inventory.has_empty_slot():
		push_warning("MapTower: cannot detach gem, inventory has no empty slot.")
		return false

	var _gem := detach_gem()
	if _gem == null:
		return false

	if _inventory.add_gem(_gem):
		return true

	attach_gem(_gem)
	return false


# 本类方法：选中当前塔位宝石，并取消其它宝石的范围显示。
func _select_gem() -> void:
	if gem_data == null:
		return

	_clear_selected_gems()
	gem_data.set_selected(true)


# 本类方法：清除所有已安装宝石的选中状态。
func _clear_selected_gems() -> void:
	for _node in get_tree().get_nodes_in_group(MapGem.GROUP_NAME):
		var _gem := _node as MapGem
		if _gem != null:
			_gem.set_selected(false)


# 本类方法：查找鼠标下方是否存在已安装宝石的塔基。
func _find_gem_tower_under_mouse() -> MapTower:
	for _node in get_tree().get_nodes_in_group(GROUP_NAME):
		var _tower := _node as MapTower
		if _tower == null or not _tower.has_gem():
			continue
		if _tower.global_position.distance_to(get_global_mouse_position()) <= CLICK_RADIUS:
			return _tower
	return null


# 本类方法：取消待拖拽状态。
func _cancel_pending_gem_drag() -> void:
	_is_pending_gem_drag = false
	set_process(false)


# 本类方法：开始拖拽当前塔位上的宝石。
func _begin_drag_gem() -> void:
	var _gem := detach_gem()
	if _gem == null:
		return

	var _inventory := _find_inventory()
	var _drag_layer := _inventory.get_drag_layer() if _inventory != null else get_tree().current_scene
	_drag_layer.add_child(_gem)
	_gem.global_position = get_global_mouse_position()
	_gem.begin_drag_from_tower(self)


# 本类方法：查找当前战斗界面的宝石背包。
func _find_inventory() -> GemInventoryPanel:
	for _node in get_tree().get_nodes_in_group(GemInventoryPanel.GROUP_NAME):
		var _inventory := _node as GemInventoryPanel
		if _inventory != null:
			return _inventory
	return null
