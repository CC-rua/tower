extends Control

const DEFENSE_TOWER_BUILDING_ID := "defense_tower"
const DEFENSE_TOWER_PREVIEW_TEXTURE := preload("res://resource/image/tower_base_64x64_opaque_center.png")

@onready var _battle_map_controller: BattleMapController = $"../../LevelRoot/CurrentLevel/BattleMapController"
@onready var _ground_layer: TileMapLayer = $"../../LevelRoot/CurrentLevel/TileMap/Ground"
@onready var _building_bar_panel: BuildingBarPanel = $BuildingBarPanel
@onready var _gem_inventory_panel: Control = $GemInventoryPanel
@onready var _building_bar_toggle_button: Button = $BuildingBarToggleButton
@onready var _placement_preview: Sprite2D = $PlacementPreview

var _is_placing_building := false
var _pending_building_id := ""
var _hovered_cell := Vector2i(-9999, -9999)


func _ready() -> void:
	_building_bar_panel.building_selected.connect(_on_building_bar_panel_building_selected)
	_placement_preview.visible = false
	_set_default_hud_mode()
	_refresh_building_bar_toggle_button()


func _process(_delta: float) -> void:
	if _is_placing_building:
		_update_placement_preview()


func _input(event: InputEvent) -> void:
	if not _is_placing_building:
		return

	var _mouse_event := event as InputEventMouseButton
	if _mouse_event == null or not _mouse_event.pressed:
		return

	if _mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_finish_building_placement(true)
		get_viewport().set_input_as_handled()
		return

	if _mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _try_place_pending_building():
		get_viewport().set_input_as_handled()


func _on_building_bar_toggle_button_pressed() -> void:
	if _is_placing_building:
		_finish_building_placement(true)
		return

	_set_building_selection_mode(not _building_bar_panel.visible)
	_refresh_building_bar_toggle_button()


func _on_building_bar_panel_building_selected(building_id: String) -> void:
	if building_id == DEFENSE_TOWER_BUILDING_ID:
		_start_building_placement(building_id)


func _refresh_building_bar_toggle_button() -> void:
	var _is_open := _building_bar_panel.visible
	_building_bar_toggle_button.button_pressed = _is_open
	_building_bar_toggle_button.tooltip_text = "关闭建筑栏" if _is_open else "打开建筑栏"


func _start_building_placement(building_id: String) -> void:
	_pending_building_id = building_id
	_is_placing_building = true
	_set_hud_state(false, false, false)
	_placement_preview.texture = _get_building_preview_texture(building_id)
	_placement_preview.modulate = Color(1.0, 1.0, 1.0, 0.72)
	_placement_preview.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_update_placement_preview()


func _finish_building_placement(show_building_bar: bool) -> void:
	_is_placing_building = false
	_pending_building_id = ""
	_hovered_cell = Vector2i(-9999, -9999)
	_placement_preview.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_building_selection_mode(show_building_bar)
	_refresh_building_bar_toggle_button()


func _update_placement_preview() -> void:
	var _cell := _get_hovered_ground_cell()
	var _is_valid_cell := _can_place_pending_building_at(_cell)
	if _cell == _hovered_cell and _placement_preview.visible and _is_valid_cell:
		return

	_hovered_cell = _cell
	if _is_valid_cell:
		_placement_preview.global_position = _ground_layer.to_global(_ground_layer.map_to_local(_cell))
	else:
		_placement_preview.global_position = get_global_mouse_position()

	_placement_preview.modulate = Color(0.72, 1.0, 0.76, 0.8) if _is_valid_cell else Color(1.0, 0.56, 0.56, 0.7)


func _try_place_pending_building() -> bool:
	var _cell := _get_hovered_ground_cell()
	if not _can_place_pending_building_at(_cell):
		return false

	if _pending_building_id == DEFENSE_TOWER_BUILDING_ID:
		var _tower := _battle_map_controller.place_tower(_cell)
		if _tower == null:
			return false

		_tower.tower_id = DEFENSE_TOWER_BUILDING_ID
		_finish_building_placement(true)
		return true

	return false


func _get_hovered_ground_cell() -> Vector2i:
	var _mouse_local := _ground_layer.to_local(get_global_mouse_position())
	return _ground_layer.local_to_map(_mouse_local)


func _can_place_pending_building_at(cell: Vector2i) -> bool:
	if _battle_map_controller == null or _ground_layer == null:
		return false
	if not _ground_layer.get_used_rect().has_point(cell):
		return false

	if _pending_building_id == DEFENSE_TOWER_BUILDING_ID:
		return _battle_map_controller.can_place_tower(cell)

	return false


func _get_building_preview_texture(building_id: String) -> Texture2D:
	if building_id == DEFENSE_TOWER_BUILDING_ID:
		return DEFENSE_TOWER_PREVIEW_TEXTURE
	return null


func _set_building_selection_mode(is_enabled: bool) -> void:
	if is_enabled:
		_set_hud_state(true, false, true)
	else:
		_set_default_hud_mode()


func _set_default_hud_mode() -> void:
	_set_hud_state(false, true, true)


func _set_hud_state(building_bar_visible: bool, gem_inventory_visible: bool, toggle_button_visible: bool) -> void:
	_building_bar_panel.visible = building_bar_visible
	_gem_inventory_panel.visible = gem_inventory_visible
	_building_bar_toggle_button.visible = toggle_button_visible
