extends Control

@onready var _title_label: Label = $MarginContainer/Content/TitleLabel
@onready var _description_label: Label = $MarginContainer/Content/DescriptionLabel


func _ready() -> void:
	var _result_data: Dictionary = App.get_latest_battle_result()
	_title_label.text = str(_result_data.get("title", "结算"))
	_description_label.text = str(_result_data.get("description", ""))


func _on_back_to_level_select_button_pressed() -> void:
	SceneFlow.go_to_page("level_select")
