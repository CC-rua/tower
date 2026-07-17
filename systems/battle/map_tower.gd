extends Node2D
class_name MapTower

const SOURCE_PRESET := "preset"
const SOURCE_PLAYER := "player"

@export var tower_id := ""
@export var origin_cell := Vector2i.ZERO
@export var size_in_cells := Vector2i.ONE
@export var source := SOURCE_PRESET

# 宝石提供攻击、减速等效果；为空时该对象就是一个塔基。
var gem_data: MapGem = null


# 本类方法：初始化地图塔位数据。
func setup(_origin_cell: Vector2i, _source: String = SOURCE_PLAYER, _tower_id: String = "") -> void:
	origin_cell = _origin_cell
	source = _source
	tower_id = _tower_id


# 本类方法：获取该塔位占用的全部逻辑格。
func get_occupied_cells() -> Array[Vector2i]:
	var _cells: Array[Vector2i] = []
	var _safe_size := Vector2i(max(size_in_cells.x, 1), max(size_in_cells.y, 1))

	for _x in range(_safe_size.x):
		for _y in range(_safe_size.y):
			_cells.append(origin_cell + Vector2i(_x, _y))

	return _cells


# 本类方法：判断当前是否已安装宝石。
func has_gem() -> bool:
	return gem_data != null


# 本类方法：安装宝石，使塔基成为具备效果的防御塔。
func attach_gem(_gem_data: MapGem) -> void:
	gem_data = _gem_data


# 本类方法：移除宝石，使防御塔退回塔基状态。
func detach_gem() -> MapGem:
	var _old_gem_data := gem_data
	gem_data = null
	return _old_gem_data
