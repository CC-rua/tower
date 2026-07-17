extends Node
class_name BattleMapController

const BattleMapModelScript = preload("res://systems/battle/battle_map_model.gd")
const MapTowerScript = preload("res://systems/battle/map_tower.gd")
const DEFAULT_TOWER_SCENE := preload("res://scenes/battle/objects/map_tower.tscn")

@export var ground_layer_path := NodePath("../TileMap/Ground")
@export var road_layer_path := NodePath("../TileMap/Road")
@export var blocker_layer_path := NodePath("../TileMap/Blocker")
@export var marker_layer_path := NodePath("../TileMap/Marker")
@export var obstacle_root_path := NodePath("../MapObjects/Obstacles")
@export var tower_root_path := NodePath("../MapObjects/Towers")
@export var tower_scene: PackedScene = DEFAULT_TOWER_SCENE

# 地图逻辑装载完成后发出，怪物生成器、建塔系统可等待该信号。
signal map_loaded(_map_model: BattleMapModel)

# 当前战斗地图运行时数据。
var map_model: BattleMapModel = null

var _ground_layer: TileMapLayer = null
var _road_layer: TileMapLayer = null
var _blocker_layer: TileMapLayer = null
var _marker_layer: TileMapLayer = null
var _obstacle_root: Node = null
var _tower_root: Node = null


# 继承方法：节点进入场景树后自动装载 TileMap 逻辑数据。
func _ready() -> void:
	setup_map()


# 本类方法：重新读取 TileMapLayer 并生成运行时地图数据。
func setup_map() -> void:
	_cache_layers()

	if _ground_layer == null:
		push_error("BattleMapController: Ground layer is missing.")
		return
	if _road_layer == null:
		push_error("BattleMapController: Road layer is missing.")
		return

	map_model = BattleMapModelScript.new()
	map_model.load_from_layers(
		_ground_layer,
		_road_layer,
		_blocker_layer,
		_marker_layer
	)
	_register_map_objects()
	map_loaded.emit(map_model)


# 本类方法：获取当前地图模型。
func get_map_model() -> BattleMapModel:
	return map_model


# 本类方法：获取 Road 图层，供路线格子转世界坐标使用。
func get_road_layer() -> TileMapLayer:
	return _road_layer


# 本类方法：获取指定路线的世界坐标点。
func get_route_world_points(_route_id: String) -> Array[Vector2]:
	if map_model == null:
		return []
	return map_model.get_route_world_points(_route_id, _road_layer)


# 本类方法：判断指定格子是否允许放置塔位。
func can_place_tower(_cell: Vector2i) -> bool:
	if map_model == null:
		return false
	return map_model.can_place_tower(_cell)


# 本类方法：判断指定格子是否存在可安装宝石的塔位。
func can_attach_gem(_cell: Vector2i) -> bool:
	if map_model == null:
		return false
	return map_model.can_attach_gem(_cell)


# 本类方法：创建玩家额外放置的塔位节点。无宝石时表现为塔基。
func place_tower(_cell: Vector2i) -> MapTower:
	if map_model == null:
		return null
	if not map_model.can_place_tower(_cell):
		return null

	var _tower := _create_tower_node(_cell)
	if _tower == null:
		return null
	if not map_model.register_tower(_tower):
		_tower.queue_free()
		return null

	return _tower


# 本类方法：给指定格子的塔位安装宝石，使其成为防御塔。
func attach_gem(_cell: Vector2i, _gem_data: MapGem) -> bool:
	if map_model == null:
		return false
	return map_model.attach_gem(_cell, _gem_data)


# 本类方法：移除可操作障碍物节点，并同步释放占格。
func remove_obstacle(_obstacle: MapObstacle) -> void:
	if _obstacle == null:
		return
	if map_model != null:
		map_model.unregister_obstacle(_obstacle)
	_obstacle.queue_free()


# 本类方法：缓存各个地图图层节点。
func _cache_layers() -> void:
	_ground_layer = get_node_or_null(ground_layer_path) as TileMapLayer
	_road_layer = get_node_or_null(road_layer_path) as TileMapLayer
	_blocker_layer = get_node_or_null(blocker_layer_path) as TileMapLayer
	_marker_layer = get_node_or_null(marker_layer_path) as TileMapLayer
	_obstacle_root = get_node_or_null(obstacle_root_path)
	_tower_root = get_node_or_null(tower_root_path)


# 本类方法：扫描场景中的可操作地图对象并登记占格。
func _register_map_objects() -> void:
	if map_model == null:
		return

	if _obstacle_root != null:
		for _child in _obstacle_root.get_children():
			var _obstacle := _child as MapObstacle
			if _obstacle != null:
				map_model.register_obstacle(_obstacle)

	if _tower_root != null:
		for _child in _tower_root.get_children():
			var _tower := _child as MapTower
			if _tower != null:
				map_model.register_tower(_tower)


# 本类方法：实例化塔位节点并放置到塔位根节点下。
func _create_tower_node(_cell: Vector2i) -> MapTower:
	var _tower: MapTower = null

	if tower_scene != null:
		_tower = tower_scene.instantiate() as MapTower
	else:
		_tower = MapTowerScript.new()

	if _tower == null:
		push_error("BattleMapController: tower scene must inherit MapTower.")
		return null

	_tower.setup(_cell, MapTower.SOURCE_PLAYER)

	if _tower_root != null:
		_tower_root.add_child(_tower)
	else:
		add_child(_tower)

	_tower.position = _cell_to_object_position(_cell)
	return _tower


# 本类方法：将逻辑格子坐标转换为 MapObjects 子节点坐标。
func _cell_to_object_position(_cell: Vector2i) -> Vector2:
	var _map_objects_controller := _tower_root.get_parent() as MapObjectsController if _tower_root != null else null
	if _map_objects_controller != null:
		return _map_objects_controller.cell_to_local_position(_cell)

	return Vector2(_cell.x * 64 + 32, _cell.y * 64 + 32)
