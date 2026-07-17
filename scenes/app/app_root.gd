extends Control

# 系统层节点，用于挂载运行期常驻系统节点。
@onready var _systems: Node = $Systems
# 页面层节点，用于承载主菜单、关卡选择等整页 UI。
@onready var _page_layer: Control = $PageLayer
# 关卡根节点，用于承载战斗中的关卡内容。
@onready var _level_root: Node2D = $LevelRoot
# 实体根节点，用于承载角色、敌人和可交互实体。
@onready var _entity_root: Node2D = $EntityRoot
# 特效根节点，用于承载表现特效。
@onready var _effect_root: Node2D = $EffectRoot
# HUD 层节点，用于承载常驻界面。
@onready var _hud_layer: CanvasLayer = $HudLayer
# 暂停层节点，用于承载暂停菜单和阻断式界面。
@onready var _pause_layer: CanvasLayer = $PauseLayer
# 暂停根节点，用于显示暂停菜单。
@onready var _pause_root: Control = $PauseLayer/PauseRoot
# 转场层节点，用于承载切换动画和遮罩。
@onready var _transition_layer: CanvasLayer = $TransitionLayer
# 调试层节点，用于承载调试面板和开发期信息。
@onready var _debug_layer: CanvasLayer = $DebugLayer

var _is_pause_menu_open := false


# 继承方法：主场景准备完成后绑定 App 并启动初始化流程。
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	App.bind_app_root(self)
	_pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_root.visible = false
	App.initialize()


# 继承方法：处理战斗页中的暂停快捷键。
func _unhandled_input(event: InputEvent) -> void:
	var _current_page_id := SceneFlow.get_current_page_id()
	if _current_page_id != "battle":
		return

	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()


# 本类方法：返回系统层节点。
func get_systems() -> Node:
	return _systems


# 本类方法：返回页面层节点。
func get_page_layer() -> Control:
	return _page_layer


# 本类方法：返回关卡根节点。
func get_level_root() -> Node2D:
	return _level_root


# 本类方法：返回实体根节点。
func get_entity_root() -> Node2D:
	return _entity_root


# 本类方法：返回特效根节点。
func get_effect_root() -> Node2D:
	return _effect_root


# 本类方法：返回 HUD 层节点。
func get_hud_layer() -> CanvasLayer:
	return _hud_layer


# 本类方法：返回暂停层节点。
func get_pause_layer() -> CanvasLayer:
	return _pause_layer


# 本类方法：返回转场层节点。
func get_transition_layer() -> CanvasLayer:
	return _transition_layer


# 本类方法：返回调试层节点。
func get_debug_layer() -> CanvasLayer:
	return _debug_layer


# 信号处理：点击继续游戏按钮后关闭暂停菜单。
func _on_resume_button_pressed() -> void:
	_set_pause_menu_open(false)


# 信号处理：点击返回主菜单按钮后关闭暂停并切回主菜单。
func _on_main_menu_button_pressed() -> void:
	_set_pause_menu_open(false)
	SceneFlow.go_to_page("main_menu")


# 本类方法：切换暂停菜单显隐与游戏暂停状态。
func _toggle_pause_menu() -> void:
	_set_pause_menu_open(not _is_pause_menu_open)


# 本类方法：设置暂停菜单开关。
func _set_pause_menu_open(is_open: bool) -> void:
	_is_pause_menu_open = is_open
	get_tree().paused = is_open
	_pause_root.visible = is_open
