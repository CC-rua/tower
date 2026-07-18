extends PanelContainer
class_name BuildingBarPanel

signal building_selected(building_id: String)

const BuildingBarItemScene := preload("res://scenes/battle/prefab/building_bar_item/building_bar_item.tscn")
const DEFENSE_TOWER_ICON := preload("res://resource/image/defense_tower_icon_128x128.png")
const GEM_PRODUCER_ICON := preload("res://resource/image/gem_producer_building_128x128.png")
const GEM_CRAFTER_ICON := preload("res://resource/image/gem_synthesizer_building_128x128.png")
const DEFAULT_BUILDINGS := [
	{
		"building_id": "defense_tower",
		"display_name": "防御塔",
		"icon_texture": DEFENSE_TOWER_ICON,
	},
	{
		"building_id": "gem_producer",
		"display_name": "宝石产出建筑",
		"icon_texture": GEM_PRODUCER_ICON,
	},
	{
		"building_id": "gem_crafter",
		"display_name": "宝石合成建筑",
		"icon_texture": GEM_CRAFTER_ICON,
	},
]

@export var buildings: Array[Dictionary] = []

@onready var _scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var _slot_container: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/SlotContainer


func _ready() -> void:
	_scroll_container.clip_contents = true
	if buildings.is_empty():
		buildings = _get_default_buildings()
	_build_slots()


func set_buildings(new_buildings: Array[Dictionary]) -> void:
	buildings = new_buildings.duplicate(true)
	if is_node_ready():
		_build_slots()


func _build_slots() -> void:
	for _child in _slot_container.get_children():
		_child.queue_free()

	var _source_buildings: Array[Dictionary] = buildings if not buildings.is_empty() else _get_default_buildings()

	for _building_data in _source_buildings:
		var _item := BuildingBarItemScene.instantiate() as BuildingBarItem
		if _item == null:
			continue

		_item.building_id = str(_building_data.get("building_id", ""))
		_item.display_name = str(_building_data.get("display_name", ""))
		_item.icon_texture = _building_data.get("icon_texture", null) as Texture2D
		_item.building_requested.connect(_on_item_building_requested)
		_slot_container.add_child(_item)


func _gui_input(event: InputEvent) -> void:
	var _mouse_button := event as InputEventMouseButton
	if _mouse_button != null:
		if _mouse_button.pressed and _mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_container.scroll_horizontal = max(_scroll_container.scroll_horizontal - 96, 0)
			accept_event()
			return

		if _mouse_button.pressed and _mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_container.scroll_horizontal += 96
			accept_event()
			return


func _get_default_buildings() -> Array[Dictionary]:
	var _default_buildings: Array[Dictionary] = []
	for _building_data in DEFAULT_BUILDINGS:
		_default_buildings.append(_building_data.duplicate())
	return _default_buildings


func _on_item_building_requested(building_id: String) -> void:
	building_selected.emit(building_id)
