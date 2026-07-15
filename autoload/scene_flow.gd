extends Node

const SceneFlowServiceScript = preload("res://systems/scene_flow/scene_flow_service.gd")

# 场景流程服务实例，负责页面级切换和整场景切换封装。
var _service := SceneFlowServiceScript.new()


# 本类方法：使用应用主场景初始化场景流程服务。
func initialize(_app_root: Node) -> void:
	if _app_root == null:
		push_error("SceneFlow.initialize: app_root is null.")
		return

	_service.setup(_app_root.get_page_layer())


# 本类方法：获取当前页面标识。
func get_current_page_id() -> String:
	return _service.get_current_page_id()


# 本类方法：切换到指定页面子场景。
func go_to_page(_page_id: String) -> void:
	_service.go_to_page(_page_id)


# 本类方法：通过 SceneManager 执行整场景切换。
func change_scene(_scene_path: String, _options: Dictionary = {}) -> void:
	await _service.change_scene(_scene_path, _options)
