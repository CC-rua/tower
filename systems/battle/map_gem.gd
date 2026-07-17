extends Node2D
class_name MapGem

@export var gem_id := ""

# 宝石效果数据，后续可替换为配置行或 Resource。
var effect_data: Variant = null


# 本类方法：初始化宝石数据。
func setup(_gem_id: String = "", _effect_data: Variant = null) -> void:
	gem_id = _gem_id
	effect_data = _effect_data
