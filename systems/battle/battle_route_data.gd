extends RefCounted
class_name BattleRouteData

# 路线标识，建议由波次配置直接引用。
var route_id := ""
# 路线经过的格子序列，怪物最终按这个数组移动。
var cells: Array[Vector2i] = []


# 本类方法：初始化路线数据。
func setup(_route_id: String, _cells: Array[Vector2i]) -> void:
	route_id = _route_id
	cells = _cells.duplicate()


# 本类方法：将格子路线转换为世界坐标路线。
func to_world_points(_tile_layer: TileMapLayer) -> Array[Vector2]:
	var _points: Array[Vector2] = []
	if _tile_layer == null:
		return _points

	for _cell in cells:
		_points.append(_tile_layer.to_global(_tile_layer.map_to_local(_cell)))

	return _points
