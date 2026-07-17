extends RefCounted
class_name BattleRoutePoint

# 所属路线标识。
var route_id := ""
# 点位顺序，运行时按该值从小到大连接。
var order := 0
# 点位所在格子坐标。
var cell := Vector2i.ZERO
# 点位类型：start / waypoint / end。
var marker_type := "waypoint"


# 本类方法：初始化路线点数据。
func setup(_route_id: String, _order: int, _cell: Vector2i, _marker_type: String) -> void:
	route_id = _route_id
	order = _order
	cell = _cell
	marker_type = _marker_type
