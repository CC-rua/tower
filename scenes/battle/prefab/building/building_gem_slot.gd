extends RefCounted
class_name BuildingGemSlot

const SLOT_TYPE_MODIFIER := "modifier"
const SLOT_TYPE_TOWER_CORE := "tower_core"
const SLOT_TYPE_CRAFT_INPUT := "craft_input"
const SLOT_TYPE_CRAFT_OUTPUT := "craft_output"
const SLOT_TYPE_PRODUCER_OUTPUT := "producer_output"

var slot_id := ""
var slot_type := SLOT_TYPE_MODIFIER
var gem: MapGem = null
var can_insert := true
var can_remove := true
var accepted_traits: Array[String] = []
var socket_path := NodePath("")


func setup(_slot_id: String, _slot_type: String = SLOT_TYPE_MODIFIER, _socket_path: NodePath = NodePath("")) -> void:
	slot_id = _slot_id
	slot_type = _slot_type
	socket_path = _socket_path


func is_empty() -> bool:
	return gem == null


func can_accept_gem(_gem: MapGem) -> bool:
	if _gem == null or not can_insert or gem != null:
		return false
	if accepted_traits.is_empty():
		return true

	for _trait_id in accepted_traits:
		if _gem.get_trait_ratio(_trait_id) > 0.0:
			return true
	return false


func set_gem(_gem: MapGem) -> bool:
	if not can_accept_gem(_gem):
		return false

	gem = _gem
	return true


func take_gem() -> MapGem:
	if not can_remove:
		return null

	var _old_gem := gem
	gem = null
	return _old_gem


func get_save_data() -> Dictionary:
	return {
		"slot_id": slot_id,
		"slot_type": slot_type,
		"can_insert": can_insert,
		"can_remove": can_remove,
		"accepted_traits": accepted_traits.duplicate(),
		"has_gem": gem != null,
	}
