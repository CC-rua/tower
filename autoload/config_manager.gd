extends Node

const ConfigServiceScript = preload("res://systems/config/config_service.gd")

# 配置服务实例，负责加载和查询导出的配置脚本。
var _service := ConfigServiceScript.new()
# 标记配置系统是否已经初始化完成。
var _is_initialized := false


# 本类方法：初始化配置系统并加载全部配置。
func initialize() -> void:
	if _is_initialized:
		return

	_service.initialize()
	_is_initialized = true


# 本类方法：手动重新加载全部配置。
func reload_configs() -> void:
	_service.reload_configs()


# 本类方法：获取指定名称的配置对象。
func get_config(_config_name: String) -> Variant:
	return _service.get_config(_config_name)


# 本类方法：获取指定名称的配置表。
func get_table(_table_name: String) -> Variant:
	return _service.get_table(_table_name)


# 本类方法：获取原始 settings 实例。
func get_settings_instance() -> Node:
	return _service.get_settings_instance()


# 本类方法：获取指定名称的原始插件表对象。
func get_raw_table(_table_name: String) -> Variant:
	return _service.get_raw_table(_table_name)


# 本类方法：按主键获取指定表中的一行强类型配置对象。
func get_row(_table_name: String, _row_id: int) -> Variant:
	return _service.get_row(_table_name, _row_id)


# 本类方法：获取指定表中的全部强类型配置对象。
func get_rows(_table_name: String) -> Array[ConfigRow]:
	return _service.get_rows(_table_name)


# 本类方法：判断指定配置是否存在。
func has_config(_config_name: String) -> bool:
	return _service.has_config(_config_name)


# 本类方法：获取全部已加载配置。
func get_all_configs() -> Dictionary:
	return _service.get_all_configs()
