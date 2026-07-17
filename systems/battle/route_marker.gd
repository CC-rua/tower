extends Node2D
class_name RouteMarker

enum MarkerType {
	START,
	WAYPOINT,
	END,
}

const TYPE_START := "start"
const TYPE_WAYPOINT := "waypoint"
const TYPE_END := "end"

@export_enum("Start", "Waypoint", "End") var marker_type: int = MarkerType.WAYPOINT
@export var origin_cell := Vector2i.ZERO


# 本类方法：获取路线点类型字符串。
func get_marker_type_name() -> String:
	match marker_type:
		MarkerType.START:
			return TYPE_START
		MarkerType.END:
			return TYPE_END
		_:
			return TYPE_WAYPOINT
