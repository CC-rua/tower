extends Node
class_name BattleEconomyController

signal currency_changed(currency_id: String, amount: int, capacity: int)
signal currencies_changed

const CURRENCY_MAGIC := "magic"
const CURRENCY_STONE := "stone"
const CURRENCY_GOLD := "gold"

@export var initial_magic := 120
@export var initial_stone := 80
@export var initial_gold := 260
@export var magic_capacity := 140
@export var stone_capacity := 100
@export var gold_capacity := 300
@export var magic_recovery_per_second := 1.0
@export var magic_recovery_enabled := false

var _magic_amount := 0
var _stone_amount := 0
var _gold_amount := 0
var _magic_recovery_progress := 0.0


func _ready() -> void:
	_magic_amount = clampi(initial_magic, 0, max(magic_capacity, 1))
	_stone_amount = clampi(initial_stone, 0, max(stone_capacity, 1))
	_gold_amount = clampi(initial_gold, 0, max(gold_capacity, 1))
	_refresh_process_enabled()
	_emit_all_currency_changed()


func _process(delta: float) -> void:
	if magic_recovery_per_second <= 0.0 or _magic_amount >= magic_capacity:
		return

	_magic_recovery_progress += magic_recovery_per_second * delta
	var _recover_amount := int(_magic_recovery_progress)
	if _recover_amount <= 0:
		return

	_magic_recovery_progress -= float(_recover_amount)
	add_magic(_recover_amount)


func get_currency_amount(currency_id: String) -> int:
	match currency_id:
		CURRENCY_MAGIC:
			return _magic_amount
		CURRENCY_STONE:
			return _stone_amount
		CURRENCY_GOLD:
			return _gold_amount
		_:
			push_warning("BattleEconomyController: unknown currency id: %s." % currency_id)
			return 0


func get_currency_capacity(currency_id: String) -> int:
	match currency_id:
		CURRENCY_MAGIC:
			return magic_capacity
		CURRENCY_STONE:
			return stone_capacity
		CURRENCY_GOLD:
			return gold_capacity
		_:
			push_warning("BattleEconomyController: unknown currency id: %s." % currency_id)
			return 1


func get_currency_snapshot() -> Dictionary:
	return {
		CURRENCY_MAGIC: {"amount": _magic_amount, "capacity": magic_capacity},
		CURRENCY_STONE: {"amount": _stone_amount, "capacity": stone_capacity},
		CURRENCY_GOLD: {"amount": _gold_amount, "capacity": gold_capacity}
	}


func add_magic(amount: int) -> void:
	_set_currency_amount(CURRENCY_MAGIC, _magic_amount + max(amount, 0))


func add_stone(amount: int) -> void:
	_set_currency_amount(CURRENCY_STONE, _stone_amount + max(amount, 0))


func add_gold(amount: int) -> void:
	_set_currency_amount(CURRENCY_GOLD, _gold_amount + max(amount, 0))


func deduct_magic(amount: int) -> int:
	var _safe_amount: int = max(amount, 0)
	_set_currency_amount(CURRENCY_MAGIC, _magic_amount - _safe_amount)
	return _magic_amount


func set_currency_amount(currency_id: String, amount: int) -> void:
	_set_currency_amount(currency_id, amount)


func set_magic_recovery_enabled(is_enabled: bool) -> void:
	magic_recovery_enabled = is_enabled
	_refresh_process_enabled()


func spend_currency(currency_id: String, amount: int) -> bool:
	var _safe_amount: int = max(amount, 0)
	if get_currency_amount(currency_id) < _safe_amount:
		return false

	_set_currency_amount(currency_id, get_currency_amount(currency_id) - _safe_amount)
	return true


func set_currency_capacity(currency_id: String, capacity: int) -> void:
	var _safe_capacity: int = max(capacity, 1)
	var _old_capacity := get_currency_capacity(currency_id)
	match currency_id:
		CURRENCY_MAGIC:
			magic_capacity = _safe_capacity
		CURRENCY_STONE:
			stone_capacity = _safe_capacity
		CURRENCY_GOLD:
			gold_capacity = _safe_capacity
		_:
			push_warning("BattleEconomyController: unknown currency id: %s." % currency_id)
			return

	_set_currency_amount(currency_id, min(get_currency_amount(currency_id), _safe_capacity))
	if _old_capacity != _safe_capacity:
		currency_changed.emit(currency_id, get_currency_amount(currency_id), _safe_capacity)
		currencies_changed.emit()


func _set_currency_amount(currency_id: String, amount: int) -> void:
	var _capacity := get_currency_capacity(currency_id)
	var _new_amount: int = clampi(amount, 0, _capacity)
	var _old_amount := get_currency_amount(currency_id)
	if _new_amount == _old_amount:
		return

	match currency_id:
		CURRENCY_MAGIC:
			_magic_amount = _new_amount
		CURRENCY_STONE:
			_stone_amount = _new_amount
		CURRENCY_GOLD:
			_gold_amount = _new_amount
		_:
			return

	currency_changed.emit(currency_id, _new_amount, _capacity)
	currencies_changed.emit()


func _emit_all_currency_changed() -> void:
	currency_changed.emit(CURRENCY_MAGIC, _magic_amount, magic_capacity)
	currency_changed.emit(CURRENCY_STONE, _stone_amount, stone_capacity)
	currency_changed.emit(CURRENCY_GOLD, _gold_amount, gold_capacity)
	currencies_changed.emit()


func _refresh_process_enabled() -> void:
	set_process(magic_recovery_enabled and magic_recovery_per_second > 0.0)
