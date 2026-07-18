extends MapBuilding
class_name GemProducerBuilding

const SLOT_OUTPUT := "output"

@export var produced_trait_id := MapGem.TRAIT_ATTACK
@export_range(1, 6, 1) var produced_gem_level := 1
@export var produce_interval := 20.0

var produce_timer := 0.0


func setup_producer(_cell: Vector2i, _trait_id: String, _gem_level: int = 1, _building_id: String = "gem_producer") -> void:
	setup_building(_cell, MapBuilding.TYPE_GEM_PRODUCER, _building_id)
	produced_trait_id = _trait_id
	produced_gem_level = clampi(_gem_level, MapGem.MIN_LEVEL, MapGem.MAX_LEVEL)


func _ready() -> void:
	super._ready()
	building_type = MapBuilding.TYPE_GEM_PRODUCER
	set_process(true)


func _process(_delta: float) -> void:
	process_socketed_gem_drag(_delta)
	if _has_output_gem():
		runtime_data["produce_timer"] = produce_timer
		_refresh_status_label()
		return

	produce_timer = max(produce_timer - _delta * _get_produce_speed_multiplier(), 0.0)
	runtime_data["produce_timer"] = produce_timer
	if produce_timer > 0.0:
		_refresh_status_label()
		return

	_create_output_gem()
	produce_timer = max(produce_interval, 0.1)
	runtime_data["produce_timer"] = produce_timer
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

	if try_collect_slot_to_inventory(SLOT_OUTPUT) or try_collect_slot_to_inventory(MapBuilding.SLOT_MODIFIER):
		get_viewport().set_input_as_handled()


func _ensure_default_gem_slots() -> void:
	super._ensure_default_gem_slots()
	if has_gem_slot(SLOT_OUTPUT):
		return

	var _slot := BuildingGemSlot.new()
	_slot.setup(SLOT_OUTPUT, BuildingGemSlot.SLOT_TYPE_PRODUCER_OUTPUT, NodePath("OutputSocket"))
	_slot.can_insert = false
	_slot.can_remove = true
	add_gem_slot(_slot)


func _create_output_gem() -> void:
	var _slot := get_gem_slot(SLOT_OUTPUT)
	if _slot == null or _slot.gem != null:
		return

	var _gem := MapGem.new()
	var _safe_trait_id: String = produced_trait_id if MapGem.TRAIT_IDS.has(produced_trait_id) else MapGem.TRAIT_ATTACK
	_gem.setup_pure_trait(
		"%s_%s_lv%d" % [building_id if not building_id.is_empty() else "producer", _safe_trait_id, produced_gem_level],
		_safe_trait_id,
		produced_gem_level
	)
	place_gem_in_empty_slot(_gem, SLOT_OUTPUT)


func _has_output_gem() -> bool:
	var _slot := get_gem_slot(SLOT_OUTPUT)
	return _slot != null and _slot.gem != null


func _refresh_status_label() -> void:
	if _has_output_gem():
		set_status_label_text("可领取", Color(0.7, 1.0, 0.72, 1.0))
		return

	set_status_label_text("生产 %.1fs" % produce_timer, Color(0.9, 0.95, 1.0, 1.0))


func _on_gem_slot_changed(_slot: BuildingGemSlot) -> void:
	_refresh_status_label()


func _get_produce_speed_multiplier() -> float:
	var _multiplier := 1.0
	for _gem in get_socketed_gems(BuildingGemSlot.SLOT_TYPE_MODIFIER):
		_multiplier += _gem.get_trait_ratio(MapGem.TRAIT_ATTACK_SPEED) * max(_gem.gem_level, 1) * 0.08
	return max(_multiplier, 0.1)


func get_detail_data() -> Dictionary:
	var _data := super.get_detail_data()
	_data["produced_trait_id"] = produced_trait_id
	_data["produced_gem_level"] = produced_gem_level
	_data["produce_interval"] = produce_interval
	_data["produce_timer"] = produce_timer
	return _data
