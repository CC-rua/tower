extends RefCounted
class_name MapCellData

# 格子坐标，统一使用 TileMapLayer 的 cell 坐标。
var cell := Vector2i.ZERO
# 标记该格子是否属于地图地面范围。
var has_ground := false
# 标记该格子是否属于怪物道路。
var has_road := false
# 标记该格子是否存在不可操作地形阻挡。
var has_blocker := false

# 当前格子上的可移除障碍物节点引用。
var obstacle_node: Node2D = null
# 当前格子上的塔位节点引用。无宝石时表现为塔基，有宝石时表现为防御塔。
var tower_node: Node2D = null
# 当前格子上的通用建筑节点引用。防御塔、经济、仓储、产出、合成都属于建筑。
var building_node: Node2D = null


# 本类方法：初始化格子数据。
func setup(_cell: Vector2i) -> void:
	cell = _cell


# 本类方法：判断该格子是否会阻止放置塔位。
func blocks_tower() -> bool:
	return has_road or has_blocker or obstacle_node != null or building_node != null or tower_node != null


# 本类方法：判断该格子是否允许放置塔位。
func can_place_tower() -> bool:
	return has_ground and not blocks_tower()


# 本类方法：判断该格子是否允许放置通用建筑。
func can_place_building() -> bool:
	return has_ground and not blocks_tower()


# 本类方法：判断该格子是否存在可安装宝石的塔位。
func can_attach_gem() -> bool:
	return building_node != null and not has_road and not has_blocker and obstacle_node == null
