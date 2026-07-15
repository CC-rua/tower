extends Control


# 继承方法：启动页短暂停留后进入主菜单。
func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	SceneFlow.go_to_page("main_menu")
