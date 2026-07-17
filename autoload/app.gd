extends Node

const APP_ROOT_SCENE_PATH := "res://scenes/app/app.tscn"
const START_PAGE_ID := "main_menu"
const DEFAULT_BATTLE_LEVEL_SCENE_PATH := "res://scenes/battle/levels/level_001.tscn"

# 标记应用是否已经完成初始化，避免重复初始化。
var _is_initialized := false
# 缓存主场景根节点，供全局系统访问页面挂载层。
var _app_root: Node = null
# 当前选中的战斗关卡场景路径。
var _selected_battle_level_scene_path := DEFAULT_BATTLE_LEVEL_SCENE_PATH


# 继承方法：节点进入场景树后设置常驻处理模式。
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# 本类方法：绑定应用主场景根节点。
func bind_app_root(_app_root_node: Node) -> void:
	_app_root = _app_root_node


# 本类方法：获取当前绑定的应用主场景根节点。
func get_app_root() -> Node:
	return _app_root


# 本类方法：按既定顺序初始化全局系统并进入启动页。
func initialize() -> void:
	if _is_initialized:
		return

	ConfigManager.initialize()
	SaveManager.initialize()
	SceneFlow.initialize(_app_root)
	SceneFlow.go_to_page(START_PAGE_ID)
	_is_initialized = true


# 本类方法：返回应用是否已完成初始化。
func is_initialized() -> bool:
	return _is_initialized


# 本类方法：设置当前待进入的战斗关卡场景路径。
func set_selected_battle_level_scene_path(scene_path: String) -> void:
	var _normalized_path := scene_path.strip_edges()
	if _normalized_path.is_empty():
		_selected_battle_level_scene_path = DEFAULT_BATTLE_LEVEL_SCENE_PATH
		return

	_selected_battle_level_scene_path = _normalized_path


# 本类方法：获取当前待进入的战斗关卡场景路径。
func get_selected_battle_level_scene_path() -> String:
	return _selected_battle_level_scene_path


# 本类方法：重置当前待进入的战斗关卡场景路径。
func reset_selected_battle_level_scene_path() -> void:
	_selected_battle_level_scene_path = DEFAULT_BATTLE_LEVEL_SCENE_PATH
