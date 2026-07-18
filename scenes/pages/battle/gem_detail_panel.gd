extends PanelContainer
class_name GemDetailPanel

const DETAIL_FONT_SIZE := 11
const TITLE_FONT_SIZE := 14
const SECTION_FONT_SIZE := 12
const TRAIT_RATIO_EPSILON := 0.001
const TRAIT_LABEL_MIN_SIZE := Vector2(112.0, 18.0)

var _is_enabled := true
var _trait_value_labels := {}

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _content_vbox: VBoxContainer = $MarginContainer/VBoxContainer/ContentVBox
@onready var _gem_id_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/GemIdRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_damage_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackDamageRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_range_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackRangeRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_interval_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackIntervalRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _damage_type_key_label: Label = $MarginContainer/VBoxContainer/ContentVBox/DamageTypeRow/MarginContainer/HBoxContainer/KeyLabel
@onready var _damage_type_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/DamageTypeRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _target_policy_key_label: Label = $MarginContainer/VBoxContainer/ContentVBox/TargetPolicyRow/MarginContainer/HBoxContainer/KeyLabel
@onready var _target_policy_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/TargetPolicyRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_color_row: Control = $MarginContainer/VBoxContainer/ContentVBox/AttackColorRow


func _ready() -> void:
	visible = false
	_apply_compact_layout()
	_build_trait_ratio_rows()
	set_process(true)


func _process(_delta: float) -> void:
	if not _is_enabled:
		if visible:
			visible = false
		return

	var _selected_gem := _find_selected_gem()
	if _selected_gem == null:
		if visible:
			visible = false
		return

	_apply_gem_data(_selected_gem)
	if not visible:
		visible = true


func set_enabled(is_enabled: bool) -> void:
	_is_enabled = is_enabled
	if not _is_enabled:
		visible = false


func _find_selected_gem() -> MapGem:
	for _node in get_tree().get_nodes_in_group(MapGem.GROUP_NAME):
		var _gem := _node as MapGem
		if _gem != null and _gem.is_selected():
			return _gem

	for _node in get_tree().get_nodes_in_group(GemInventoryPanel.GROUP_NAME):
		var _inventory := _node as GemInventoryPanel
		if _inventory == null:
			continue

		var _selected_gem := _inventory.get_selected_gem()
		if _selected_gem != null and _selected_gem.is_selected():
			return _selected_gem

	return null


func _apply_gem_data(_gem: MapGem) -> void:
	var _effects: Dictionary = _gem.get_effect_snapshot()
	_gem_id_value_label.text = "%s  Lv.%d" % [_gem.gem_id if not _gem.gem_id.is_empty() else "-", _gem.gem_level]
	_attack_damage_value_label.text = "%.1f" % _gem.attack_damage
	_attack_range_value_label.text = "%.1f" % _gem.attack_range
	_attack_interval_value_label.text = "%.2f s" % _gem.attack_interval
	_damage_type_key_label.text = "暴击"
	_damage_type_value_label.text = "%.1f%% / +%.1f%%" % [
		float(_effects.get("crit_chance", 0.0)) * 100.0,
		float(_effects.get("crit_damage", 0.0)) * 100.0,
	]
	_target_policy_key_label.text = "特效"
	_target_policy_value_label.text = _format_special_effects(_effects)
	_update_trait_ratio_rows(_gem)


func _apply_compact_layout() -> void:
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_apply_compact_layout_to_node(self)
	_attack_color_row.visible = false


func _apply_compact_layout_to_node(_node: Node) -> void:
	var _label := _node as Label
	if _label != null and _label != _title_label:
		_label.add_theme_font_size_override("font_size", DETAIL_FONT_SIZE)
		_label.clip_text = true

	var _container := _node as BoxContainer
	if _container != null:
		_container.add_theme_constant_override("separation", 4)

	var _margin_container := _node as MarginContainer
	if _margin_container != null:
		_margin_container.add_theme_constant_override("margin_left", 8)
		_margin_container.add_theme_constant_override("margin_top", 3)
		_margin_container.add_theme_constant_override("margin_right", 8)
		_margin_container.add_theme_constant_override("margin_bottom", 3)

	for _child in _node.get_children():
		_apply_compact_layout_to_node(_child)


func _build_trait_ratio_rows() -> void:
	var _section_label := Label.new()
	_section_label.text = "成分比例"
	_section_label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(_section_label)

	var _trait_grid := GridContainer.new()
	_trait_grid.columns = 2
	_trait_grid.add_theme_constant_override("h_separation", 8)
	_trait_grid.add_theme_constant_override("v_separation", 2)
	_content_vbox.add_child(_trait_grid)

	for _trait_id in MapGem.TRAIT_IDS:
		var _label := Label.new()
		_label.custom_minimum_size = TRAIT_LABEL_MIN_SIZE
		_label.add_theme_font_size_override("font_size", DETAIL_FONT_SIZE)
		_label.clip_text = true
		_trait_grid.add_child(_label)
		_trait_value_labels[_trait_id] = _label


func _update_trait_ratio_rows(_gem: MapGem) -> void:
	var _ratios: Dictionary = _gem.get_trait_ratios()
	for _trait_id in MapGem.TRAIT_IDS:
		var _label: Label = _trait_value_labels.get(_trait_id) as Label
		if _label == null:
			continue

		var _ratio: float = float(_ratios.get(_trait_id, 0.0))
		var _display_name: String = str(MapGem.TRAIT_DISPLAY_NAMES.get(_trait_id, _trait_id))
		_label.text = "%s %.1f%%" % [_display_name, _ratio * 100.0]
		_label.modulate = Color(1.0, 1.0, 1.0, 1.0) if _ratio > TRAIT_RATIO_EPSILON else Color(0.65, 0.65, 0.65, 0.6)


func _format_special_effects(_effects: Dictionary) -> String:
	var _parts: Array[String] = []
	var _slow_chance: float = float(_effects.get("slow_chance", 0.0))
	var _burn_chance: float = float(_effects.get("burn_chance", 0.0))
	var _armor_break: float = float(_effects.get("armor_break", 0.0))
	var _split_ratio: float = float(_effects.get("split_ratio", 0.0))

	if _slow_chance > TRAIT_RATIO_EPSILON:
		_parts.append("减速%.1f%%" % (_slow_chance * 100.0))
	if _burn_chance > TRAIT_RATIO_EPSILON:
		_parts.append("点燃%.1f%%" % (_burn_chance * 100.0))
	if _armor_break > TRAIT_RATIO_EPSILON:
		_parts.append("破甲%.1f" % _armor_break)
	if _split_ratio > TRAIT_RATIO_EPSILON:
		_parts.append("分裂%.1f%%" % (_split_ratio * 100.0))

	return " / ".join(PackedStringArray(_parts)) if not _parts.is_empty() else "-"
