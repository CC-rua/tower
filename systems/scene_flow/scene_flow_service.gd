extends RefCounted
class_name SceneFlowService

const PAGE_SCENE_PATHS := {
	"boot": "res://scenes/pages/boot/boot_page.tscn",
	"main_menu": "res://scenes/pages/main_menu/main_menu_page.tscn",
	"level_select": "res://scenes/pages/level_select/level_select_page.tscn",
	"battle": "res://scenes/pages/battle/battle_page.tscn",
	"result": "res://scenes/pages/result/result_page.tscn",
}
const PAGE_TRANSITION_OPTIONS := {
	"speed": 2.0,
	"pattern": "circle",
	"wait_time": 0.0,
	"color": Color.BLACK,
}

var _page_layer: Node = null
# 当前已挂载的页面实例。
var _current_page: Node = null
# 当前页面标识，用于外部查询当前流程状态。
var _current_page_id := ""
# 标记页面切换是否正在进行，避免重复切换。
var _is_switching := false


# 本类方法：绑定页面挂载层节点。
func setup(_page_layer_node: Node) -> void:
	_page_layer = _page_layer_node


# 本类方法：获取当前页面标识。
func get_current_page_id() -> String:
	return _current_page_id


# 本类方法：执行页面级子场景切换。
func go_to_page(_page_id: String) -> bool:
	if _is_switching:
		push_warning("SceneFlowService is switching pages, request ignored: %s" % _page_id)
		return false
	if not PAGE_SCENE_PATHS.has(_page_id):
		push_error("Unknown page id: %s" % _page_id)
		return false
	if _page_layer == null:
		push_error("SceneFlowService page layer is not initialized.")
		return false

	_is_switching = true

	await _play_page_transition_out()

	var _switch_result := _replace_page(_page_id)
	if not _switch_result:
		_is_switching = false
		await _play_page_transition_in()
		return false

	await _play_page_transition_in()
	_is_switching = false
	return true


# 本类方法：执行整场景切换前的页面替换逻辑。
func _replace_page(_page_id: String) -> bool:
	var _page_scene := load(PAGE_SCENE_PATHS[_page_id]) as PackedScene
	if _page_scene == null:
		push_error("Failed to load page scene: %s" % PAGE_SCENE_PATHS[_page_id])
		return false

	if is_instance_valid(_current_page):
		_current_page.queue_free()
		_current_page = null

	_current_page = _page_scene.instantiate()
	_page_layer.add_child(_current_page)
	_current_page_id = _page_id
	return true


# 本类方法：播放页面切换淡出动画。
func _play_page_transition_out() -> void:
	if SceneManager == null:
		return
	await SceneManager.fade_out(PAGE_TRANSITION_OPTIONS)


# 本类方法：播放页面切换淡入动画。
func _play_page_transition_in() -> void:
	if SceneManager == null:
		return
	await SceneManager.fade_in(PAGE_TRANSITION_OPTIONS)


# 本类方法：通过 SceneManager 执行整场景切换。
func change_scene(_scene_path: String, _options: Dictionary = {}) -> void:
	if SceneManager == null:
		push_error("SceneManager autoload is unavailable.")
		return
	await SceneManager.change_scene(_scene_path, _options)
