extends Node

const SaveServiceScript = preload("res://systems/save/save_service.gd")

# 存档服务实例，负责单存档文件的读写与兼容处理。
var _service := SaveServiceScript.new()


# 本类方法：初始化存档服务并加载当前存档。
func initialize() -> void:
	_service.initialize()


# 本类方法：获取完整存档数据副本。
func get_all() -> Dictionary:
	return _service.get_all()


# 本类方法：读取指定分区存档数据。
func get_section(_section_name: String, _default_value = {}) -> Variant:
	return _service.get_section(_section_name, _default_value)


# 本类方法：设置指定分区存档数据。
func set_section(_section_name: String, _value: Variant) -> void:
	_service.set_section(_section_name, _value)


# 本类方法：将当前存档写入磁盘。
func save() -> bool:
	return _service.save()


# 本类方法：从磁盘重新加载存档。
func load_save() -> void:
	_service.load_save()


# 本类方法：重置存档为默认内容并保存。
func reset_save() -> void:
	_service.reset_save()
