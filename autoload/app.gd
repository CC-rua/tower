extends Node

const APP_ROOT_SCENE_PATH := "res://scenes/app/app.tscn"
const START_PAGE_ID := "main_menu"

# 标记应用是否已经完成初始化，避免重复初始化。
var _is_initialized := false
# 缓存主场景根节点，供全局系统访问页面挂载层。
var _app_root: Node = null


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
