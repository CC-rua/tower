extends Control

# 系统层节点，用于挂载运行期常驻系统节点。
@onready var _systems: Node = $Systems
# 世界层节点，用于组织关卡、实体和特效根节点。
@onready var _world: Node2D = $World
# 页面层节点，用于承载主菜单、关卡选择等整页 UI。
@onready var _page_layer: Control = $PageLayer
# 关卡根节点，用于承载战斗中的关卡内容。
@onready var _level_root: Node2D = $World/LevelRoot
# 实体根节点，用于承载角色、敌人和可交互实体。
@onready var _entity_root: Node2D = $World/EntityRoot
# 特效根节点，用于承载表现特效。
@onready var _effect_root: Node2D = $World/EffectRoot
# HUD 层节点，用于承载常驻界面。
@onready var _hud_layer: CanvasLayer = $HudLayer
# 暂停层节点，用于承载暂停菜单和阻断式界面。
@onready var _pause_layer: CanvasLayer = $PauseLayer
# 转场层节点，用于承载切换动画和遮罩。
@onready var _transition_layer: CanvasLayer = $TransitionLayer
# 调试层节点，用于承载调试面板和开发期信息。
@onready var _debug_layer: CanvasLayer = $DebugLayer


# 继承方法：主场景准备完成后绑定 App 并启动初始化流程。
func _ready() -> void:
	App.bind_app_root(self)
	App.initialize()


# 本类方法：返回系统层节点。
func get_systems() -> Node:
	return _systems


# 本类方法：返回世界层节点。
func get_world() -> Node2D:
	return _world


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
