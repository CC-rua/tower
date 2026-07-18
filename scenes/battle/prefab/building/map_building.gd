extends Node2D
class_name MapBuilding

const GROUP_NAME := "map_building"
const TYPE_TOWER := "tower"
const TYPE_ECONOMY := "economy"
const TYPE_STORAGE := "storage"
const TYPE_GEM_PRODUCER := "gem_producer"
const TYPE_GEM_CRAFTER := "gem_crafter"
const SLOT_MODIFIER := "modifier"
const GEM_DRAG_START_DISTANCE := 8.0
const GEM_SLOT_CLICK_RADIUS := 24.0

@export var building_id := ""
@export var building_type := TYPE_TOWER
@export var building_level := 1
@export var origin_cell := Vector2i.ZERO
@export var size_in_cells := Vector2i.ONE
@export var component_types: Array[String] = []
@export var show_status_label := true
@export var status_label_offset := Vector2(0.0, -78.0)

var gem_slots := {}
var runtime_data := {}
var _status_label: Label = null
var _is_pending_socketed_gem_drag := false
var _pending_socketed_gem_slot_id := ""
var _pending_socketed_gem_start_position := Vector2.ZERO


func _ready() -> void:
	add_to_group(GROUP_NAME)
	_ensure_default_gem_slots()
	_ensure_status_label()


func setup_building(
	_origin_cell: Vector2i,
	_building_type: String = TYPE_TOWER,
	_building_id: String = "",
	_building_level: int = 1
) -> void:
	origin_cell = _origin_cell
	building_type = _building_type
	building_id = _building_id
	building_level = max(_building_level, 1)
	_ensure_default_gem_slots()


func get_occupied_cells() -> Array[Vector2i]:
	var _cells: Array[Vector2i] = []
	var _safe_size := Vector2i(max(size_in_cells.x, 1), max(size_in_cells.y, 1))

	for _x in range(_safe_size.x):
		for _y in range(_safe_size.y):
			_cells.append(origin_cell + Vector2i(_x, _y))

	return _cells


func add_gem_slot(_slot: BuildingGemSlot) -> bool:
	if _slot == null or _slot.slot_id.is_empty():
		return false

	gem_slots[_slot.slot_id] = _slot
	return true


func add_gem_slot_from_data(_slot_data: Dictionary) -> bool:
	var _slot := BuildingGemSlot.new()
	var _slot_id: String = str(_slot_data.get("slot_id", ""))
	var _slot_type: String = str(_slot_data.get("slot_type", BuildingGemSlot.SLOT_TYPE_MODIFIER))
	var _socket_path: NodePath = NodePath(str(_slot_data.get("socket_path", "")))
	_slot.setup(
		_slot_id,
		_slot_type,
		_socket_path
	)
	_slot.can_insert = bool(_slot_data.get("can_insert", true))
	_slot.can_remove = bool(_slot_data.get("can_remove", true))

	var _accepted_traits: Array = []
	var _accepted_traits_data: Variant = _slot_data.get("accepted_traits", [])
	if typeof(_accepted_traits_data) == TYPE_ARRAY:
		_accepted_traits = _accepted_traits_data as Array
	_slot.accepted_traits.clear()
	for _trait_id in _accepted_traits:
		_slot.accepted_traits.append(str(_trait_id))

	return add_gem_slot(_slot)


func has_gem_slot(_slot_id: String) -> bool:
	return gem_slots.has(_slot_id)


func get_gem_slot(_slot_id: String) -> BuildingGemSlot:
	return gem_slots.get(_slot_id) as BuildingGemSlot


func can_accept_gem(_gem: MapGem, _slot_id: String = "") -> bool:
	var _slot := _find_accept_slot(_gem, _slot_id)
	return _slot != null


func attach_gem_to_slot(_gem: MapGem, _slot_id: String = "") -> bool:
	var _slot := _find_accept_slot(_gem, _slot_id)
	if _slot == null:
		return false
	if not _slot.set_gem(_gem):
		return false

	_mount_gem_to_slot(_gem, _slot)
	_on_gem_slot_changed(_slot)
	return true


func place_gem_in_empty_slot(_gem: MapGem, _slot_id: String) -> bool:
	var _slot := get_gem_slot(_slot_id)
	if _slot == null or _gem == null or _slot.gem != null:
		return false

	_slot.gem = _gem
	_mount_gem_to_slot(_gem, _slot)
	_on_gem_slot_changed(_slot)
	return true


func detach_gem_from_slot(_slot_id: String) -> MapGem:
	var _slot := get_gem_slot(_slot_id)
	if _slot == null:
		return null

	var _gem := _slot.take_gem()
	if _gem == null:
		return null

	if _gem.get_parent() != null:
		_gem.get_parent().remove_child(_gem)
	_on_gem_slot_changed(_slot)
	return _gem


func detach_gem_instance(_gem: MapGem) -> MapGem:
	var _slot_id := get_slot_id_for_gem(_gem)
	return detach_gem_from_slot(_slot_id) if not _slot_id.is_empty() else null


func get_slot_id_for_gem(_gem: MapGem) -> String:
	if _gem == null:
		return ""

	for _slot_id in gem_slots.keys():
		var _slot := get_gem_slot(str(_slot_id))
		if _slot != null and _slot.gem == _gem:
			return _slot.slot_id
	return ""


func get_first_insertable_slot_id(_gem: MapGem) -> String:
	var _slot := _find_accept_slot(_gem)
	return _slot.slot_id if _slot != null else ""


func get_socketed_gems(_slot_type: String = "") -> Array[MapGem]:
	var _gems: Array[MapGem] = []
	for _slot_id in gem_slots.keys():
		var _slot := get_gem_slot(str(_slot_id))
		if _slot == null or _slot.gem == null:
			continue
		if not _slot_type.is_empty() and _slot.slot_type != _slot_type:
			continue
		_gems.append(_slot.gem)
	return _gems


func get_modifier_effects() -> Dictionary:
	return {
		"building_level": building_level,
		"modifier_gems": get_socketed_gems(BuildingGemSlot.SLOT_TYPE_MODIFIER).size(),
	}


func get_detail_data() -> Dictionary:
	var _slot_data := {}
	for _slot_id in gem_slots.keys():
		var _slot := get_gem_slot(str(_slot_id))
		if _slot != null:
			_slot_data[_slot.slot_id] = _slot.get_save_data()

	return {
		"building_id": building_id,
		"building_type": building_type,
		"building_level": building_level,
		"origin_cell": origin_cell,
		"size_in_cells": size_in_cells,
		"component_types": component_types.duplicate(),
		"slots": _slot_data,
		"runtime": runtime_data.duplicate(true),
	}


func set_status_label_text(_text: String, _color: Color = Color.WHITE) -> void:
	_ensure_status_label()
	if _status_label == null:
		return

	_status_label.text = _text
	_status_label.visible = show_status_label and not _text.is_empty()
	_status_label.modulate = _color


func process_socketed_gem_drag(_delta: float) -> void:
	if not _is_pending_socketed_gem_drag:
		return

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_cancel_socketed_gem_drag()
		return
	if _pending_socketed_gem_start_position.distance_to(get_global_mouse_position()) < GEM_DRAG_START_DISTANCE:
		return

	var _slot_id := _pending_socketed_gem_slot_id
	_cancel_socketed_gem_drag()
	_begin_socketed_gem_drag(_slot_id)


func handle_socketed_gem_drag_input(_event: InputEvent) -> bool:
	var _mouse_event := _event as InputEventMouseButton
	if _mouse_event == null:
		return false
	if _mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return false

	if _mouse_event.pressed:
		var _slot_id: String = _find_removable_gem_slot_under_mouse()
		if _slot_id.is_empty():
			return false

		_is_pending_socketed_gem_drag = true
		_pending_socketed_gem_slot_id = _slot_id
		_pending_socketed_gem_start_position = get_global_mouse_position()
		return true

	if _is_pending_socketed_gem_drag:
		_cancel_socketed_gem_drag()
		return true

	return false


func try_collect_slot_to_inventory(_slot_id: String, _inventory: GemInventoryPanel = null) -> bool:
	var _target_inventory: GemInventoryPanel = _inventory if _inventory != null else _find_inventory()
	if _target_inventory == null or not _target_inventory.has_empty_slot():
		return false

	var _gem := detach_gem_from_slot(_slot_id)
	if _gem == null:
		return false

	if _target_inventory.add_gem(_gem):
		return true

	place_gem_in_empty_slot(_gem, _slot_id)
	return false


func set_attach_highlight(_enabled: bool) -> void:
	modulate = Color(1.35, 1.25, 0.65, 1.0) if _enabled else Color.WHITE


func _ensure_default_gem_slots() -> void:
	if has_gem_slot(SLOT_MODIFIER):
		return

	var _slot := BuildingGemSlot.new()
	_slot.setup(SLOT_MODIFIER, BuildingGemSlot.SLOT_TYPE_MODIFIER)
	add_gem_slot(_slot)


func _on_gem_slot_changed(_slot: BuildingGemSlot) -> void:
	pass


func _find_accept_slot(_gem: MapGem, _slot_id: String = "") -> BuildingGemSlot:
	if _gem == null:
		return null
	if not _slot_id.is_empty():
		var _target_slot := get_gem_slot(_slot_id)
		return _target_slot if _target_slot != null and _target_slot.can_accept_gem(_gem) else null

	for _current_slot_id in gem_slots.keys():
		var _slot := get_gem_slot(str(_current_slot_id))
		if _slot != null and _slot.can_accept_gem(_gem):
			return _slot
	return null


func _mount_gem_to_slot(_gem: MapGem, _slot: BuildingGemSlot) -> void:
	if _gem == null or _slot == null:
		return

	if _gem.get_parent() != null:
		_gem.get_parent().remove_child(_gem)

	var _socket: Node = get_node_or_null(_slot.socket_path) if not _slot.socket_path.is_empty() else null
	var _parent: Node = _socket if _socket != null else self
	_parent.add_child(_gem)
	_gem.position = Vector2.ZERO
	_gem.z_index = 1


func _ensure_status_label() -> void:
	if _status_label != null:
		return

	_status_label = get_node_or_null("StatusLabel") as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "StatusLabel"
		add_child(_status_label)

	_status_label.position = status_label_offset
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_status_label.add_theme_constant_override("outline_size", 4)
	_status_label.custom_minimum_size = Vector2(128.0, 22.0)
	_status_label.size = Vector2(128.0, 22.0)
	_status_label.position.x = status_label_offset.x - _status_label.size.x * 0.5
	_status_label.visible = false


func _find_removable_gem_slot_under_mouse() -> String:
	var _mouse_position := get_global_mouse_position()
	var _nearest_slot_id := ""
	var _nearest_distance := GEM_SLOT_CLICK_RADIUS

	for _slot_id in gem_slots.keys():
		var _slot := get_gem_slot(str(_slot_id))
		if _slot == null or _slot.gem == null or not _slot.can_remove:
			continue

		var _distance := _slot.gem.global_position.distance_to(_mouse_position)
		if _distance <= _nearest_distance:
			_nearest_slot_id = _slot.slot_id
			_nearest_distance = _distance

	return _nearest_slot_id


func _begin_socketed_gem_drag(_slot_id: String) -> void:
	var _gem := detach_gem_from_slot(_slot_id)
	if _gem == null:
		return

	var _inventory := _find_inventory()
	var _drag_layer: Node = _inventory.get_drag_layer() if _inventory != null else get_tree().current_scene
	_drag_layer.add_child(_gem)
	_gem.global_position = get_global_mouse_position()
	_gem.begin_drag_from_building(self, _slot_id)


func _cancel_socketed_gem_drag() -> void:
	_is_pending_socketed_gem_drag = false
	_pending_socketed_gem_slot_id = ""


func _find_inventory() -> GemInventoryPanel:
	for _node in get_tree().get_nodes_in_group(GemInventoryPanel.GROUP_NAME):
		var _inventory := _node as GemInventoryPanel
		if _inventory != null:
			return _inventory
	return null
