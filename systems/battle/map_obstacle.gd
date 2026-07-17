extends Node2D
class_name MapObstacle

@export var obstacle_id := ""
@export var origin_cell := Vector2i.ZERO
@export var size_in_cells := Vector2i.ONE
@export var remove_cost := 0
@export var hp := 1


# 本类方法：初始化障碍物占格数据。
func setup(_origin_cell: Vector2i, _size_in_cells: Vector2i = Vector2i.ONE, _obstacle_id: String = "") -> void:
	origin_cell = _origin_cell
	size_in_cells = _size_in_cells
	obstacle_id = _obstacle_id


# 本类方法：获取该障碍物占用的全部逻辑格。
func get_occupied_cells() -> Array[Vector2i]:
	var _cells: Array[Vector2i] = []
	var _safe_size := Vector2i(max(size_in_cells.x, 1), max(size_in_cells.y, 1))

	for _x in range(_safe_size.x):
		for _y in range(_safe_size.y):
			_cells.append(origin_cell + Vector2i(_x, _y))

	return _cells


# 本类方法：判断该障碍物是否可以被移除。
func can_remove() -> bool:
	return true
