extends MapBuilding
class_name GemCrafterBuilding

const SLOT_INPUT_A := "input_a"
const SLOT_INPUT_B := "input_b"
const SLOT_OUTPUT := "output"
const STATE_IDLE := "idle"
const STATE_CRAFTING := "crafting"
const STATE_READY := "ready"
const CRAFT_TIME_BY_LEVEL := {
	1: 5.0,
	2: 10.0,
	3: 20.0,
	4: 35.0,
	5: 60.0,
}

var craft_state := STATE_IDLE
var craft_timer := 0.0
var craft_duration := 0.0


func can_start_craft() -> bool:
	var _gem_a := _get_slot_gem(SLOT_INPUT_A)
	var _gem_b := _get_slot_gem(SLOT_INPUT_B)
	return _gem_a != null and _gem_b != null and _gem_a.gem_level == _gem_b.gem_level and _gem_a.gem_level < MapGem.MAX_LEVEL and not _has_output_gem()


func _ready() -> void:
	super._ready()
	building_type = MapBuilding.TYPE_GEM_CRAFTER
	set_process(true)


func _process(_delta: float) -> void:
	process_socketed_gem_drag(_delta)
	if craft_state == STATE_CRAFTING:
		craft_timer = max(craft_timer - _delta * _get_craft_speed_multiplier(), 0.0)
		if craft_timer <= 0.0:
			_finish_craft()
	else:
		_try_start_craft()

	_update_runtime_data()
	_refresh_status_label()


func _input(_event: InputEvent) -> void:
	if handle_socketed_gem_drag_input(_event):
		get_viewport().set_input_as_handled()
		return

	var _mouse_event := _event as InputEventMouseButton
	if _mouse_event == null or not _mouse_event.pressed:
		return
	if _mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if global_position.distance_to(get_global_mouse_position()) > 32.0:
		return

	var _collected := try_collect_slot_to_inventory(SLOT_OUTPUT)
	if not _collected and craft_state != STATE_CRAFTING:
		_collected = try_collect_slot_to_inventory(SLOT_INPUT_B)
	if not _collected and craft_state != STATE_CRAFTING:
		_collected = try_collect_slot_to_inventory(SLOT_INPUT_A)
	if not _collected and craft_state != STATE_CRAFTING:
		_collected = try_collect_slot_to_inventory(MapBuilding.SLOT_MODIFIER)

	if _collected:
		craft_state = STATE_IDLE
		get_viewport().set_input_as_handled()


func attach_gem_to_slot(_gem: MapGem, _slot_id: String = "") -> bool:
	if craft_state == STATE_CRAFTING:
		return false
	return super.attach_gem_to_slot(_gem, _slot_id)


func detach_gem_from_slot(_slot_id: String) -> MapGem:
	if craft_state == STATE_CRAFTING and (_slot_id == SLOT_INPUT_A or _slot_id == SLOT_INPUT_B):
		return null
	return super.detach_gem_from_slot(_slot_id)


func _ensure_default_gem_slots() -> void:
	_add_craft_slot(SLOT_INPUT_A, BuildingGemSlot.SLOT_TYPE_CRAFT_INPUT, NodePath("InputSocketA"), true, true)
	_add_craft_slot(SLOT_INPUT_B, BuildingGemSlot.SLOT_TYPE_CRAFT_INPUT, NodePath("InputSocketB"), true, true)
	_add_craft_slot(SLOT_OUTPUT, BuildingGemSlot.SLOT_TYPE_CRAFT_OUTPUT, NodePath("OutputSocket"), false, true)
	super._ensure_default_gem_slots()


func _find_accept_slot(_gem: MapGem, _slot_id: String = "") -> BuildingGemSlot:
	if not _slot_id.is_empty():
		return super._find_accept_slot(_gem, _slot_id)

	var _slot_a := get_gem_slot(SLOT_INPUT_A)
	if _slot_a != null and _slot_a.can_accept_gem(_gem):
		return _slot_a

	var _slot_b := get_gem_slot(SLOT_INPUT_B)
	if _slot_b != null and _slot_b.can_accept_gem(_gem):
		return _slot_b

	return super._find_accept_slot(_gem, _slot_id)


func _add_craft_slot(_slot_id: String, _slot_type: String, _socket_path: NodePath, _can_insert: bool, _can_remove: bool) -> void:
	if has_gem_slot(_slot_id):
		return

	var _slot := BuildingGemSlot.new()
	_slot.setup(_slot_id, _slot_type, _socket_path)
	_slot.can_insert = _can_insert
	_slot.can_remove = _can_remove
	add_gem_slot(_slot)


func _try_start_craft() -> void:
	if craft_state == STATE_READY:
		return
	if _has_output_gem():
		craft_state = STATE_READY
		return

	var _gem_a := _get_slot_gem(SLOT_INPUT_A)
	var _gem_b := _get_slot_gem(SLOT_INPUT_B)
	if not can_start_craft():
		craft_state = STATE_IDLE
		craft_timer = 0.0
		craft_duration = 0.0
		return

	craft_duration = float(CRAFT_TIME_BY_LEVEL.get(_gem_a.gem_level, 10.0))
	craft_timer = craft_duration
	craft_state = STATE_CRAFTING


func _finish_craft() -> void:
	var _gem_a := _get_slot_gem(SLOT_INPUT_A)
	var _gem_b := _get_slot_gem(SLOT_INPUT_B)
	if _gem_a == null or _gem_b == null:
		craft_state = STATE_IDLE
		return

	var _materials: Array[MapGem] = [_gem_a, _gem_b]
	var _result := MapGem.create_fused_gem(
		"%s_fused_lv%d" % [building_id if not building_id.is_empty() else "crafter", _gem_a.gem_level + 1],
		_materials
	)

	_consume_input_gem(SLOT_INPUT_A)
	_consume_input_gem(SLOT_INPUT_B)
	place_gem_in_empty_slot(_result, SLOT_OUTPUT)
	craft_state = STATE_READY
	craft_timer = 0.0


func _consume_input_gem(_slot_id: String) -> void:
	var _slot := get_gem_slot(_slot_id)
	if _slot == null or _slot.gem == null:
		return

	var _gem := _slot.gem
	_slot.gem = null
	if _gem.get_parent() != null:
		_gem.get_parent().remove_child(_gem)
	_gem.queue_free()


func _get_slot_gem(_slot_id: String) -> MapGem:
	var _slot := get_gem_slot(_slot_id)
	return _slot.gem if _slot != null else null


func _has_output_gem() -> bool:
	return _get_slot_gem(SLOT_OUTPUT) != null


func _refresh_status_label() -> void:
	if _has_output_gem() or craft_state == STATE_READY:
		set_status_label_text("可领取", Color(0.7, 1.0, 0.72, 1.0))
		return

	if craft_state == STATE_CRAFTING:
		set_status_label_text("合成 %.1fs" % craft_timer, Color(0.9, 0.95, 1.0, 1.0))
		return

	var _gem_a := _get_slot_gem(SLOT_INPUT_A)
	var _gem_b := _get_slot_gem(SLOT_INPUT_B)
	if _gem_a == null and _gem_b == null:
		set_status_label_text("等待宝石", Color(0.82, 0.86, 0.92, 1.0))
	elif _gem_a == null or _gem_b == null:
		set_status_label_text("缺少材料", Color(1.0, 0.9, 0.62, 1.0))
	elif _gem_a.gem_level != _gem_b.gem_level:
		set_status_label_text("等级不符", Color(1.0, 0.62, 0.58, 1.0))
	elif _gem_a.gem_level >= MapGem.MAX_LEVEL:
		set_status_label_text("已满级", Color(1.0, 0.62, 0.58, 1.0))
	else:
		set_status_label_text("", Color.WHITE)


func _on_gem_slot_changed(_slot: BuildingGemSlot) -> void:
	if _slot != null and _slot.slot_id == SLOT_OUTPUT and _slot.gem == null and craft_state == STATE_READY:
		craft_state = STATE_IDLE
	_refresh_status_label()


func _get_craft_speed_multiplier() -> float:
	var _multiplier := 1.0
	for _gem in get_socketed_gems(BuildingGemSlot.SLOT_TYPE_MODIFIER):
		_multiplier += _gem.get_trait_ratio(MapGem.TRAIT_ATTACK_SPEED) * max(_gem.gem_level, 1) * 0.08
	return max(_multiplier, 0.1)


func _update_runtime_data() -> void:
	runtime_data["craft_state"] = craft_state
	runtime_data["craft_timer"] = craft_timer
	runtime_data["craft_duration"] = craft_duration


func get_detail_data() -> Dictionary:
	var _data := super.get_detail_data()
	_data["craft_state"] = craft_state
	_data["craft_timer"] = craft_timer
	_data["craft_duration"] = craft_duration
	return _data
