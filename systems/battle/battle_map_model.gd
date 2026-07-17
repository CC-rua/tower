extends RefCounted
class_name BattleMapModel

const MapCellDataScript = preload("res://systems/battle/map_cell_data.gd")
const BattleRoutePointScript = preload("res://systems/battle/battle_route_point.gd")
const BattleRouteDataScript = preload("res://systems/battle/battle_route_data.gd")

const MARKER_TYPE_START := "start"
const MARKER_TYPE_END := "end"
const MARKER_TYPE_WAYPOINT := "waypoint"

# 缓存地图格子数据，键为 Vector2i，值为 MapCellData。
var cells := {}
# 缓存起点数据，键为 marker_id，值为 Vector2i。
var starts := {}
# 缓存终点数据，键为 marker_id，值为 Vector2i。
var ends := {}
# 缓存路线数据，键为 route_id，值为 BattleRouteData。
var routes := {}

# 缓存路线关键点，键为 route_id，值为 Array[BattleRoutePoint]。
var _route_points := {}
# 基于 Road 图层构建的寻路网格。
var _astar: AStarGrid2D = null


# 本类方法：清空所有运行时地图数据。
func clear() -> void:
	cells.clear()
	starts.clear()
	ends.clear()
	routes.clear()
	_route_points.clear()
	_astar = null


# 本类方法：从各个 TileMapLayer 装载地图逻辑数据。
func load_from_layers(
	_ground_layer: TileMapLayer,
	_road_layer: TileMapLayer,
	_blocker_layer: TileMapLayer = null,
	_marker_layer: TileMapLayer = null
) -> void:
	clear()
	load_ground_layer(_ground_layer)
	load_road_layer(_road_layer)
	load_blocker_layer(_blocker_layer)
	read_marker_layer(_marker_layer)
	build_astar_from_road(_road_layer)
	build_routes_from_marker_points()


# 本类方法：获取或创建指定格子的地图数据。
func get_or_create_cell(_cell: Vector2i) -> MapCellData:
	if not cells.has(_cell):
		var _data: MapCellData = MapCellDataScript.new()
		_data.setup(_cell)
		cells[_cell] = _data
	return cells[_cell]


# 本类方法：获取指定格子的地图数据。
func get_cell(_cell: Vector2i) -> MapCellData:
	return cells.get(_cell)


# 本类方法：判断指定格子是否允许放置塔位。
func can_place_tower(_cell: Vector2i) -> bool:
	var _data := get_cell(_cell)
	return _data != null and _data.can_place_tower()


# 本类方法：判断指定格子是否存在可安装宝石的塔位。
func can_attach_gem(_cell: Vector2i) -> bool:
	var _data := get_cell(_cell)
	return _data != null and _data.can_attach_gem()


# 本类方法：登记可移除障碍物节点。
func register_obstacle(_obstacle: MapObstacle) -> bool:
	if _obstacle == null:
		return false

	var _occupied_cells := _obstacle.get_occupied_cells()
	for _cell in _occupied_cells:
		var _data := get_or_create_cell(_cell)
		if _data.has_road or _data.has_blocker:
			push_warning("BattleMapModel: obstacle cannot be placed on road or blocker: %s." % _cell)
			return false
		if _data.obstacle_node != null and _data.obstacle_node != _obstacle:
			push_warning("BattleMapModel: obstacle cell is already occupied: %s." % _cell)
			return false
		if _data.tower_node != null:
			push_warning("BattleMapModel: obstacle overlaps map object: %s." % _cell)
			return false

	for _cell in _occupied_cells:
		get_or_create_cell(_cell).obstacle_node = _obstacle

	return true


# 本类方法：取消登记可移除障碍物节点。
func unregister_obstacle(_obstacle: MapObstacle) -> void:
	if _obstacle == null:
		return

	for _cell in _obstacle.get_occupied_cells():
		var _data := get_cell(_cell)
		if _data != null and _data.obstacle_node == _obstacle:
			_data.obstacle_node = null


# 本类方法：登记塔位节点。
func register_tower(_tower: MapTower) -> bool:
	if _tower == null:
		return false

	for _cell in _tower.get_occupied_cells():
		var _data := get_or_create_cell(_cell)
		if not _data.can_place_tower():
			push_warning("BattleMapModel: tower cannot be placed at cell: %s." % _cell)
			return false

	for _cell in _tower.get_occupied_cells():
		get_or_create_cell(_cell).tower_node = _tower

	return true


# 本类方法：取消登记塔位节点。
func unregister_tower(_tower: MapTower) -> void:
	if _tower == null:
		return

	for _cell in _tower.get_occupied_cells():
		var _data := get_cell(_cell)
		if _data != null and _data.tower_node == _tower:
			_data.tower_node = null


# 本类方法：给指定格子的塔位安装宝石。
func attach_gem(_cell: Vector2i, _gem_data: Variant) -> bool:
	var _data := get_cell(_cell)
	if _data == null or not _data.can_attach_gem():
		return false

	var _tower := _data.tower_node as MapTower
	if _tower == null:
		return false
	if _tower.has_gem():
		return false

	_tower.attach_gem(_gem_data)
	return true


# 本类方法：移除指定格子塔位上的宝石。
func detach_gem(_cell: Vector2i) -> Variant:
	var _data := get_cell(_cell)
	if _data == null:
		return null
	var _tower := _data.tower_node as MapTower
	if _tower == null:
		return null

	return _tower.detach_gem()


# 本类方法：获取指定路线的格子序列。
func get_route_cells(_route_id: String) -> Array[Vector2i]:
	var _route: BattleRouteData = routes.get(_route_id)
	if _route == null:
		return []
	return _route.cells.duplicate()


# 本类方法：获取指定路线的世界坐标点序列。
func get_route_world_points(_route_id: String, _tile_layer: TileMapLayer) -> Array[Vector2]:
	var _route: BattleRouteData = routes.get(_route_id)
	if _route == null:
		return []
	return _route.to_world_points(_tile_layer)


# 本类方法：读取地面图层并建立地图范围。
func load_ground_layer(_layer: TileMapLayer) -> void:
	if _layer == null:
		return

	for _cell in _layer.get_used_cells():
		get_or_create_cell(_cell).has_ground = true


# 本类方法：读取道路图层并标记怪物可走格子。
func load_road_layer(_layer: TileMapLayer) -> void:
	if _layer == null:
		return

	for _cell in _layer.get_used_cells():
		var _data := get_or_create_cell(_cell)
		_data.has_ground = true
		_data.has_road = true


# 本类方法：读取不可操作阻挡图层并标记阻挡塔基的格子。
func load_blocker_layer(_layer: TileMapLayer) -> void:
	if _layer == null:
		return

	for _cell in _layer.get_used_cells():
		var _data := get_or_create_cell(_cell)
		_data.has_ground = true
		_data.has_blocker = true


# 本类方法：读取路径标记图层，识别起点、终点和路线关键点。
func read_marker_layer(_layer: TileMapLayer) -> void:
	if _layer == null:
		return

	for _cell in _layer.get_used_cells():
		var _marker_type := _read_cell_custom_string(_layer, _cell, "marker_type", "")
		var _marker_id := _read_cell_custom_string(_layer, _cell, "marker_id", "")
		var _route_id := _read_cell_custom_string(_layer, _cell, "route_id", "")
		var _order := _read_cell_custom_int(_layer, _cell, "order", 0)

		if _marker_type == MARKER_TYPE_START and not _marker_id.is_empty():
			starts[_marker_id] = _cell
		elif _marker_type == MARKER_TYPE_END and not _marker_id.is_empty():
			ends[_marker_id] = _cell

		if not _route_id.is_empty():
			_add_route_point(_route_id, _order, _cell, _marker_type)


# 本类方法：根据 Road 图层构建 AStarGrid2D，非道路格子会被标记为 solid。
func build_astar_from_road(_road_layer: TileMapLayer) -> void:
	if _road_layer == null:
		_astar = null
		return

	var _used_rect := _road_layer.get_used_rect()
	if _used_rect.size == Vector2i.ZERO:
		_astar = null
		return

	var _road_cells := {}
	for _cell in _road_layer.get_used_cells():
		_road_cells[_cell] = true

	_astar = AStarGrid2D.new()
	_astar.region = _used_rect
	if _road_layer.tile_set != null:
		_astar.cell_size = Vector2(_road_layer.tile_set.tile_size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()

	for _x in range(_used_rect.position.x, _used_rect.position.x + _used_rect.size.x):
		for _y in range(_used_rect.position.y, _used_rect.position.y + _used_rect.size.y):
			var _cell := Vector2i(_x, _y)
			if not _road_cells.has(_cell):
				_astar.set_point_solid(_cell, true)


# 本类方法：根据 Marker 中的路线关键点生成最终路线。
func build_routes_from_marker_points() -> void:
	routes.clear()
	if _astar == null:
		return

	for _route_id in _route_points.keys():
		var _points: Array = _route_points[_route_id]
		_points.sort_custom(_sort_route_points)

		var _route_cells := _build_route_cells_from_points(_points)
		if _route_cells.is_empty():
			continue

		var _route: BattleRouteData = BattleRouteDataScript.new()
		_route.setup(_route_id, _route_cells)
		routes[_route_id] = _route


# 本类方法：记录单个路线关键点。
func _add_route_point(_route_id: String, _order: int, _cell: Vector2i, _marker_type: String) -> void:
	if not _route_points.has(_route_id):
		_route_points[_route_id] = []

	var _point: BattleRoutePoint = BattleRoutePointScript.new()
	_point.setup(_route_id, _order, _cell, _marker_type)
	_route_points[_route_id].append(_point)


# 本类方法：按路线关键点顺序拼接 AStar 路径。
func _build_route_cells_from_points(_points: Array) -> Array[Vector2i]:
	var _route_cells: Array[Vector2i] = []
	if _points.size() < 2:
		return _route_cells

	for _index in range(_points.size() - 1):
		var _from_point: BattleRoutePoint = _points[_index]
		var _to_point: BattleRoutePoint = _points[_index + 1]
		var _segment := _astar.get_id_path(_from_point.cell, _to_point.cell)

		if _segment.is_empty():
			push_warning("BattleMapModel: route segment not found from %s to %s." % [_from_point.cell, _to_point.cell])
			return []

		for _segment_index in range(_segment.size()):
			if not _route_cells.is_empty() and _segment_index == 0:
				continue
			_route_cells.append(_segment[_segment_index])

	return _route_cells


# 本类方法：读取指定格子的字符串自定义数据。
func _read_cell_custom_string(_layer: TileMapLayer, _cell: Vector2i, _key: String, _default_value: String) -> String:
	var _tile_data := _layer.get_cell_tile_data(_cell)
	if _tile_data == null:
		return _default_value

	var _value = _tile_data.get_custom_data(_key)
	if _value == null:
		return _default_value
	return str(_value)


# 本类方法：读取指定格子的整数自定义数据。
func _read_cell_custom_int(_layer: TileMapLayer, _cell: Vector2i, _key: String, _default_value: int) -> int:
	var _tile_data := _layer.get_cell_tile_data(_cell)
	if _tile_data == null:
		return _default_value

	var _value = _tile_data.get_custom_data(_key)
	if _value == null:
		return _default_value
	return int(_value)


# 本类方法：路线关键点排序方法。
func _sort_route_points(_a: BattleRoutePoint, _b: BattleRoutePoint) -> bool:
	return _a.order < _b.order
