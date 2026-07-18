extends Node
class_name BattleMapController

const BattleMapModelScript = preload("res://scenes/battle/levels/script/battle_map_model.gd")
const MapBuildingScript = preload("res://scenes/battle/prefab/building/map_building.gd")
const MapTowerScript = preload("res://scenes/battle/prefab/tower/map_tower.gd")
const DEFAULT_TOWER_SCENE := preload("res://scenes/battle/prefab/tower/map_tower.tscn")
const DEFAULT_GEM_PRODUCER_SCENE := preload("res://scenes/battle/prefab/building/gem_producer_building.tscn")
const DEFAULT_GEM_CRAFTER_SCENE := preload("res://scenes/battle/prefab/building/gem_crafter_building.tscn")

@export var ground_layer_path := NodePath("../TileMap/Ground")
@export var road_layer_path := NodePath("../TileMap/Road")
@export var blocker_layer_path := NodePath("../TileMap/Blocker")
@export var marker_root_path := NodePath("../Marker")
@export var obstacle_root_path := NodePath("../MapObjects/Obstacles")
@export var tower_root_path := NodePath("../MapObjects/Towers")
@export var tower_scene: PackedScene = DEFAULT_TOWER_SCENE
@export var gem_producer_scene: PackedScene = DEFAULT_GEM_PRODUCER_SCENE
@export var gem_crafter_scene: PackedScene = DEFAULT_GEM_CRAFTER_SCENE

# 地图逻辑装载完成后发出，怪物生成器、建塔系统可等待该信号。
signal map_loaded(_map_model: BattleMapModel)

# 当前战斗地图运行时数据。
var map_model: BattleMapModel = null

var _ground_layer: TileMapLayer = null
var _road_layer: TileMapLayer = null
var _blocker_layer: TileMapLayer = null
var _marker_root: Node = null
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
		_blocker_layer
	)
	map_model.load_routes_from_marker_nodes(_marker_root)
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


# 本类方法：获取当前地图中已配置的路线标识。
func get_route_ids() -> Array[String]:
	var _route_ids: Array[String] = []
	if map_model == null:
		return _route_ids

	for _route_id in map_model.routes.keys():
		_route_ids.append(str(_route_id))

	_route_ids.sort()
	return _route_ids


# 本类方法：判断指定格子是否允许放置塔位。
func can_place_tower(_cell: Vector2i) -> bool:
	if map_model == null:
		return false
	return map_model.can_place_tower(_cell)


# 本类方法：判断指定格子是否允许放置通用建筑。
func can_place_building(_cell: Vector2i, _size_in_cells: Vector2i = Vector2i.ONE) -> bool:
	if map_model == null:
		return false
	return map_model.can_place_building(_cell, _size_in_cells)


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


# 本类方法：创建一个通用功能建筑节点。具体经济/仓储/产出/合成建筑后续可传入专用场景。
func place_building(_cell: Vector2i, _building_type: String, _building_id: String = "", _building_scene: PackedScene = null) -> MapBuilding:
	if map_model == null:
		return null
	if not map_model.can_place_building(_cell, _get_building_scene_size(_building_scene)):
		return null

	var _building := _create_building_node(_cell, _building_type, _building_id, _building_scene)
	if _building == null:
		return null
	if not map_model.register_building(_building):
		_building.queue_free()
		return null

	return _building


func place_gem_producer(_cell: Vector2i, _building_id: String = "gem_producer") -> GemProducerBuilding:
	return place_building(_cell, MapBuilding.TYPE_GEM_PRODUCER, _building_id, gem_producer_scene) as GemProducerBuilding


func place_gem_crafter(_cell: Vector2i, _building_id: String = "gem_crafter") -> GemCrafterBuilding:
	return place_building(_cell, MapBuilding.TYPE_GEM_CRAFTER, _building_id, gem_crafter_scene) as GemCrafterBuilding


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
	_marker_root = get_node_or_null(marker_root_path)
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
			var _building := _child as MapBuilding
			if _building != null:
				map_model.register_building(_building)


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

	_tower.position = _cell_to_object_position(_cell, _tower.size_in_cells)
	return _tower


func _create_building_node(_cell: Vector2i, _building_type: String, _building_id: String, _building_scene: PackedScene = null) -> MapBuilding:
	var _building: MapBuilding = null

	if _building_scene != null:
		_building = _building_scene.instantiate() as MapBuilding
	else:
		_building = MapBuildingScript.new()

	if _building == null:
		push_error("BattleMapController: building scene must inherit MapBuilding.")
		return null

	_building.setup_building(_cell, _building_type, _building_id)

	if _tower_root != null:
		_tower_root.add_child(_building)
	else:
		add_child(_building)

	_building.position = _cell_to_object_position(_cell, _building.size_in_cells)
	return _building


func _get_building_scene_size(_building_scene: PackedScene = null) -> Vector2i:
	if _building_scene == null:
		return Vector2i.ONE

	var _building: MapBuilding = _building_scene.instantiate() as MapBuilding
	if _building == null:
		return Vector2i.ONE

	var _size: Vector2i = _building.size_in_cells
	_building.queue_free()
	return Vector2i(max(_size.x, 1), max(_size.y, 1))


# 本类方法：将逻辑格子坐标转换为 MapObjects 子节点坐标。
func _cell_to_object_position(_cell: Vector2i, _size_in_cells: Vector2i = Vector2i.ONE) -> Vector2:
	var _map_objects_controller: MapObjectsController = _tower_root.get_parent() as MapObjectsController if _tower_root != null else null
	if _map_objects_controller != null:
		return _map_objects_controller.cell_rect_to_local_position(_cell, _size_in_cells)

	var _safe_size := Vector2i(max(_size_in_cells.x, 1), max(_size_in_cells.y, 1))
	return Vector2((_cell.x + _safe_size.x * 0.5) * 64, (_cell.y + _safe_size.y * 0.5) * 64)
