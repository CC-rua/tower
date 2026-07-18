@tool
extends Node2D
class_name MapObjectsController

@export var cell_size := 64
@export var obstacle_root_path := NodePath("Obstacles")
@export var tower_root_path := NodePath("Towers")
@export var snap_in_editor := true

var _obstacle_root: Node = null
var _tower_root: Node = null


# 继承方法：进入场景树后统一校正可操作地图对象位置。
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(snap_in_editor)
		snap_all_objects_to_grid_from_position()
		return

	snap_all_objects_to_grid()


# 继承方法：编辑器中持续校正可操作对象的位置。
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not snap_in_editor:
		return

	snap_all_objects_to_grid_from_position()


# 本类方法：将全部可操作对象吸附到 64x64 格子中心。
func snap_all_objects_to_grid() -> void:
	_cache_roots()
	_snap_children(_obstacle_root)
	_snap_children(_tower_root)


# 本类方法：根据对象当前位置反推格子，并吸附全部可操作对象。
func snap_all_objects_to_grid_from_position() -> void:
	_cache_roots()
	_snap_children_from_position(_obstacle_root)
	_snap_children_from_position(_tower_root)


# 本类方法：根据单格坐标获取对象层本地坐标。
func cell_to_local_position(_cell: Vector2i) -> Vector2:
	return Vector2(
		_cell.x * cell_size + cell_size * 0.5,
		_cell.y * cell_size + cell_size * 0.5
	)


# 本类方法：根据左上格和占格尺寸获取对象层本地坐标，使对象位于占用矩形中心。
func cell_rect_to_local_position(_origin_cell: Vector2i, _size_in_cells: Vector2i = Vector2i.ONE) -> Vector2:
	var _safe_size := Vector2i(max(_size_in_cells.x, 1), max(_size_in_cells.y, 1))
	return Vector2(
		(_origin_cell.x + _safe_size.x * 0.5) * cell_size,
		(_origin_cell.y + _safe_size.y * 0.5) * cell_size
	)


# 本类方法：根据本地坐标获取最近的格子坐标。
func local_position_to_cell(_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(_position.x / cell_size),
		floori(_position.y / cell_size)
	)


# 本类方法：根据本地坐标获取最近格子中心对应的格子坐标。
func local_position_to_nearest_cell(_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(_position.x / cell_size),
		floori(_position.y / cell_size)
	)


# 本类方法：根据对象中心位置和占格尺寸反推出左上 origin_cell。
func local_position_to_origin_cell(_position: Vector2, _size_in_cells: Vector2i = Vector2i.ONE) -> Vector2i:
	var _safe_size := Vector2i(max(_size_in_cells.x, 1), max(_size_in_cells.y, 1))
	return Vector2i(
		floori(_position.x / cell_size - _safe_size.x * 0.5),
		floori(_position.y / cell_size - _safe_size.y * 0.5)
	)


# 本类方法：将指定对象吸附到它的 origin_cell 对应格子中心。
func snap_object_to_grid(_object: Node2D) -> void:
	if _object == null:
		return

	if _object is MapObstacle:
		var _obstacle: MapObstacle = _object as MapObstacle
		_object.position = cell_rect_to_local_position(_obstacle.origin_cell, _obstacle.size_in_cells)
	elif _object is MapBuilding:
		var _building: MapBuilding = _object as MapBuilding
		_object.position = cell_rect_to_local_position(_building.origin_cell, _building.size_in_cells)


# 本类方法：根据对象当前位置更新 origin_cell，并吸附到格子中心。
func snap_object_to_grid_from_position(_object: Node2D) -> void:
	if _object == null:
		return

	if _object is MapObstacle:
		var _obstacle: MapObstacle = _object as MapObstacle
		var _cell: Vector2i = local_position_to_origin_cell(_object.position, _obstacle.size_in_cells)
		_obstacle.origin_cell = _cell
		_object.position = cell_rect_to_local_position(_cell, _obstacle.size_in_cells)
	elif _object is MapBuilding:
		var _building: MapBuilding = _object as MapBuilding
		var _cell: Vector2i = local_position_to_origin_cell(_object.position, _building.size_in_cells)
		_building.origin_cell = _cell
		_object.position = cell_rect_to_local_position(_cell, _building.size_in_cells)


# 本类方法：缓存对象根节点。
func _cache_roots() -> void:
	_obstacle_root = get_node_or_null(obstacle_root_path)
	_tower_root = get_node_or_null(tower_root_path)


# 本类方法：吸附指定根节点下的全部 Node2D 子节点。
func _snap_children(_root: Node) -> void:
	if _root == null:
		return

	for _child in _root.get_children():
		var _object := _child as Node2D
		if _object != null:
			snap_object_to_grid(_object)


# 本类方法：根据当前位置吸附指定根节点下的全部 Node2D 子节点。
func _snap_children_from_position(_root: Node) -> void:
	if _root == null:
		return

	for _child in _root.get_children():
		var _object := _child as Node2D
		if _object != null:
			snap_object_to_grid_from_position(_object)
