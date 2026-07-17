@tool
extends Node2D
class_name RouteMarkerController

const ROUTE_MARKER_SCRIPT_PATH := "res://systems/battle/route_marker.gd"
const MARKER_TYPE_START := 0
const MARKER_TYPE_END := 2

@export var cell_size := 64
@export var snap_in_editor := true


# 继承方法：进入场景树后校正路线标记点。
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(snap_in_editor)
		snap_all_markers_to_grid_from_position()
		return

	visible = false
	snap_all_markers_to_grid()


# 继承方法：编辑器中持续校正路线标记点。
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not snap_in_editor:
		return

	snap_all_markers_to_grid_from_position()


# 本类方法：将全部路线点吸附到 origin_cell 对应格子中心。
func snap_all_markers_to_grid() -> void:
	for _marker in get_route_markers():
		_marker.position = cell_to_local_position(_get_marker_origin_cell(_marker))
		refresh_marker_view(_marker)


# 本类方法：根据当前位置反推格子，并吸附全部路线点。
func snap_all_markers_to_grid_from_position() -> void:
	for _marker in get_route_markers():
		var _origin_cell := local_position_to_nearest_cell(_marker.position)
		_marker.set("origin_cell", _origin_cell)
		_marker.position = cell_to_local_position(_origin_cell)
		refresh_marker_view(_marker)


# 本类方法：根据格子坐标获取本地坐标。
func cell_to_local_position(_cell: Vector2i) -> Vector2:
	return Vector2(
		_cell.x * cell_size + cell_size * 0.5,
		_cell.y * cell_size + cell_size * 0.5
	)


# 本类方法：根据本地坐标获取最近格子中心对应的格子坐标。
func local_position_to_nearest_cell(_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(_position.x / cell_size),
		floori(_position.y / cell_size)
	)


# 本类方法：获取全部路线点。
func get_route_markers() -> Array[Node2D]:
	var _markers: Array[Node2D] = []
	_collect_route_markers(self, _markers)
	return _markers


# 本类方法：刷新指定路线点的颜色和文本显示。
func refresh_marker_view(_marker: Node2D) -> void:
	if _marker == null:
		return
	var _marker_type := _get_marker_type(_marker)

	var _background := _marker.get_node_or_null("Background") as ColorRect
	if _background != null:
		_background.color = _get_marker_color(_marker_type)

	var _label := _marker.get_node_or_null("Label") as Label
	if _label != null:
		_label.text = _get_marker_text(_marker_type)


# 本类方法：递归收集路线点。
func _collect_route_markers(_root: Node, _markers: Array[Node2D]) -> void:
	for _child in _root.get_children():
		var _node_2d := _child as Node2D
		if _node_2d != null and _is_route_marker_node(_node_2d):
			_markers.append(_node_2d)
			continue
		_collect_route_markers(_child, _markers)


# 本类方法：读取路线点格子坐标。
func _get_marker_origin_cell(_marker: Node2D) -> Vector2i:
	var _value = _marker.get("origin_cell")
	if _value is Vector2i:
		return _value
	return local_position_to_nearest_cell(_marker.position)


# 本类方法：读取路线点类型。
func _get_marker_type(_marker: Node2D) -> int:
	var _value = _marker.get("marker_type")
	if _value is int:
		return _value
	return 1


# 本类方法：判断节点是否挂载路线点脚本。
func _is_route_marker_node(_node: Node2D) -> bool:
	var _script := _node.get_script() as Script
	if _script == null:
		return false
	return _script.resource_path == ROUTE_MARKER_SCRIPT_PATH


# 本类方法：根据类型获取显示颜色。
func _get_marker_color(_marker_type: int) -> Color:
	match _marker_type:
		MARKER_TYPE_START:
			return Color(0.05, 0.72, 0.28, 0.92)
		MARKER_TYPE_END:
			return Color(0.9, 0.16, 0.16, 0.92)
		_:
			return Color(0.95, 0.62, 0.02, 0.92)


# 本类方法：根据类型获取显示文本。
func _get_marker_text(_marker_type: int) -> String:
	match _marker_type:
		MARKER_TYPE_START:
			return "S"
		MARKER_TYPE_END:
			return "E"
		_:
			return "W"
