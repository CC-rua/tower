extends Control

const DEFENSE_TOWER_BUILDING_ID := "defense_tower"
const DEFENSE_TOWER_PREVIEW_TEXTURE := preload("res://resource/image/tower_base_64x64_opaque_center.png")

@onready var _battle_map_controller: BattleMapController = $"../../LevelRoot/CurrentLevel/BattleMapController"
@onready var _enemy_controller: EnemyController = $"../../LevelRoot/CurrentLevel/EnemyController"
@onready var _economy_controller: BattleEconomyController = $"../../LevelRoot/CurrentLevel/BattleEconomyController"
@onready var _ground_layer: TileMapLayer = $"../../LevelRoot/CurrentLevel/TileMap/Ground"
@onready var _battle_control_bar: Control = $BattleControlBar
@onready var _currency_panel: Control = $CurrencyPanel
@onready var _magic_progress_bar: ProgressBar = $CurrencyPanel/MarginContainer/HBoxContainer/MagicRow/MarginContainer/HBoxContainer/ValueBar
@onready var _stone_progress_bar: ProgressBar = $CurrencyPanel/MarginContainer/HBoxContainer/StoneRow/MarginContainer/HBoxContainer/ValueBar
@onready var _gold_progress_bar: ProgressBar = $CurrencyPanel/MarginContainer/HBoxContainer/GoldRow/MarginContainer/HBoxContainer/ValueBar
@onready var _start_battle_button: Button = $BattleControlBar/MarginContainer/HBoxContainer/StartBattleButton
@onready var _start_next_wave_button: Button = $BattleControlBar/MarginContainer/HBoxContainer/NextWaveButton
@onready var _double_speed_button: Button = $BattleControlBar/MarginContainer/HBoxContainer/DoubleSpeedButton
@onready var _building_bar_panel: BuildingBarPanel = $BuildingBarPanel
@onready var _gem_inventory_panel: Control = $GemInventoryPanel
@onready var _gem_detail_panel: GemDetailPanel = $GemDetailPanel
@onready var _building_bar_toggle_button: Button = $BuildingBarToggleButton
@onready var _placement_preview: Sprite2D = $PlacementPreview

var _is_placing_building := false
var _pending_building_id := ""
var _hovered_cell := Vector2i(-9999, -9999)

func _ready() -> void:
	_building_bar_panel.building_selected.connect(_on_building_bar_panel_building_selected)
	_start_battle_button.pressed.connect(_on_start_battle_button_pressed)
	_start_next_wave_button.pressed.connect(_on_start_next_wave_button_pressed)
	_double_speed_button.toggled.connect(_on_double_speed_button_toggled)
	_placement_preview.visible = false
	Engine.time_scale = 1.0
	if _economy_controller != null:
		_economy_controller.currency_changed.connect(_on_economy_currency_changed)
	_refresh_currency_display()
	_set_default_hud_mode()
	_refresh_building_bar_toggle_button()
	_refresh_battle_control_buttons()


func _process(_delta: float) -> void:
	if _is_placing_building:
		_update_placement_preview()
	_refresh_battle_control_buttons()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


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


func _on_start_battle_button_pressed() -> void:
	if _enemy_controller == null:
		return

	_enemy_controller.start_battle()
	_refresh_battle_control_buttons()


func _on_start_next_wave_button_pressed() -> void:
	if _enemy_controller == null:
		return

	_enemy_controller.trigger_next_wave_now()
	_refresh_battle_control_buttons()


func _on_double_speed_button_toggled(is_toggled_on: bool) -> void:
	Engine.time_scale = 2.0 if is_toggled_on else 1.0
	_refresh_battle_control_buttons()


func set_magic_amount(amount: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_amount(BattleEconomyController.CURRENCY_MAGIC, amount)


func set_stone_amount(amount: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_amount(BattleEconomyController.CURRENCY_STONE, amount)


func set_gold_amount(amount: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_amount(BattleEconomyController.CURRENCY_GOLD, amount)


func set_magic_capacity(capacity: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_capacity(BattleEconomyController.CURRENCY_MAGIC, capacity)


func set_stone_capacity(capacity: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_capacity(BattleEconomyController.CURRENCY_STONE, capacity)


func set_gold_capacity(capacity: int) -> void:
	if _economy_controller != null:
		_economy_controller.set_currency_capacity(BattleEconomyController.CURRENCY_GOLD, capacity)


func _refresh_currency_display() -> void:
	if _economy_controller == null:
		_refresh_currency_bar(_magic_progress_bar, 0, 1)
		_refresh_currency_bar(_stone_progress_bar, 0, 1)
		_refresh_currency_bar(_gold_progress_bar, 0, 1)
		return

	_refresh_currency_bar(
		_magic_progress_bar,
		_economy_controller.get_currency_amount(BattleEconomyController.CURRENCY_MAGIC),
		_economy_controller.get_currency_capacity(BattleEconomyController.CURRENCY_MAGIC)
	)
	_refresh_currency_bar(
		_stone_progress_bar,
		_economy_controller.get_currency_amount(BattleEconomyController.CURRENCY_STONE),
		_economy_controller.get_currency_capacity(BattleEconomyController.CURRENCY_STONE)
	)
	_refresh_currency_bar(
		_gold_progress_bar,
		_economy_controller.get_currency_amount(BattleEconomyController.CURRENCY_GOLD),
		_economy_controller.get_currency_capacity(BattleEconomyController.CURRENCY_GOLD)
	)


func _refresh_currency_bar(progress_bar: ProgressBar, amount: int, capacity: int) -> void:
	if progress_bar == null:
		return

	progress_bar.max_value = max(capacity, 1)
	progress_bar.value = clamp(amount, 0, capacity)
	progress_bar.tooltip_text = "%d/%d" % [amount, capacity]


func _on_economy_currency_changed(currency_id: String, amount: int, capacity: int) -> void:
	match currency_id:
		BattleEconomyController.CURRENCY_MAGIC:
			_refresh_currency_bar(_magic_progress_bar, amount, capacity)
		BattleEconomyController.CURRENCY_STONE:
			_refresh_currency_bar(_stone_progress_bar, amount, capacity)
		BattleEconomyController.CURRENCY_GOLD:
			_refresh_currency_bar(_gold_progress_bar, amount, capacity)


func _refresh_building_bar_toggle_button() -> void:
	var _is_open := _building_bar_panel.visible
	_building_bar_toggle_button.button_pressed = _is_open
	_building_bar_toggle_button.tooltip_text = "关闭建筑栏" if _is_open else "打开建筑栏"


func _refresh_battle_control_buttons() -> void:
	if _enemy_controller == null:
		_start_battle_button.disabled = true
		_start_next_wave_button.disabled = true
		_double_speed_button.disabled = true
		_start_next_wave_button.text = "下一波"
		_start_next_wave_button.tooltip_text = "开始下一波"
		return

	var _has_started := _enemy_controller.has_battle_started()
	var _is_finished := _enemy_controller.is_battle_finished()
	_start_battle_button.disabled = _has_started or _is_finished
	_start_battle_button.text = "战斗进行中" if _has_started and not _is_finished else "开始战斗"
	var _can_trigger_next_wave := _enemy_controller.can_trigger_next_wave_now()
	_start_next_wave_button.disabled = not _can_trigger_next_wave
	_start_next_wave_button.tooltip_text = "开始下一波"
	if not _has_started:
		_start_next_wave_button.text = "等待开始"
	elif _is_finished:
		_start_next_wave_button.text = "战斗结束"
	elif _can_trigger_next_wave:
		var _cooldown_remaining := _enemy_controller.get_next_wave_cooldown_remaining()
		_start_next_wave_button.text = "下一波 %.1f s" % _cooldown_remaining if _cooldown_remaining > 0.0 else "下一波就绪"
	else:
		_start_next_wave_button.text = "本波进行中"
	_double_speed_button.disabled = false
	_double_speed_button.button_pressed = is_equal_approx(Engine.time_scale, 2.0)
	_double_speed_button.text = "恢复一倍速" if _double_speed_button.button_pressed else "二倍速"


func _start_building_placement(building_id: String) -> void:
	_pending_building_id = building_id
	_is_placing_building = true
	_set_hud_state(false, false, false, false)
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
		_set_hud_state(false, true, false, true)
	else:
		_set_default_hud_mode()


func _set_default_hud_mode() -> void:
	_set_hud_state(true, false, true, true)


func _set_hud_state(battle_control_visible: bool, building_bar_visible: bool, gem_inventory_visible: bool, toggle_button_visible: bool) -> void:
	_battle_control_bar.visible = battle_control_visible
	_currency_panel.visible = battle_control_visible
	_building_bar_panel.visible = building_bar_visible
	_gem_inventory_panel.visible = gem_inventory_visible
	_gem_detail_panel.set_enabled(gem_inventory_visible)
	_building_bar_toggle_button.visible = toggle_button_visible
