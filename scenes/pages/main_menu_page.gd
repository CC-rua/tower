extends Control


# 信号处理：点击开始游戏按钮后进入关卡选择页面。
func _on_start_button_pressed() -> void:
	SceneFlow.go_to_page("level_select")
