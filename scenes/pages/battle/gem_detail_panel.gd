extends PanelContainer
class_name GemDetailPanel

var _is_enabled := true

@onready var _gem_id_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/GemIdRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_damage_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackDamageRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_range_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackRangeRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_interval_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/AttackIntervalRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _damage_type_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/DamageTypeRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _target_policy_value_label: Label = $MarginContainer/VBoxContainer/ContentVBox/TargetPolicyRow/MarginContainer/HBoxContainer/ValueLabel
@onready var _attack_color_preview: ColorRect = $MarginContainer/VBoxContainer/ContentVBox/AttackColorRow/MarginContainer/HBoxContainer/ColorPreview


func _ready() -> void:
	visible = false
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
	_gem_id_value_label.text = _gem.gem_id if not _gem.gem_id.is_empty() else "-"
	_attack_damage_value_label.text = "%.1f" % _gem.attack_damage
	_attack_range_value_label.text = "%.1f" % _gem.attack_range
	_attack_interval_value_label.text = "%.2f s" % _gem.attack_interval
	_damage_type_value_label.text = _gem.damage_type
	_target_policy_value_label.text = _gem.target_policy
	_attack_color_preview.color = _gem.attack_color
