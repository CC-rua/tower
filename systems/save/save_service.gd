extends RefCounted
class_name SaveService

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

# 当前内存中的完整存档数据。
var _save_data := {}


# 本类方法：初始化存档服务并加载存档。
func initialize() -> void:
	load_save()


# 本类方法：返回完整存档数据副本。
func get_all() -> Dictionary:
	return _save_data.duplicate(true)


# 本类方法：读取指定分区的存档数据。
func get_section(_section_name: String, _default_value = {}) -> Variant:
	return _save_data.get(_section_name, _default_value)


# 本类方法：设置指定分区的存档数据。
func set_section(_section_name: String, _value: Variant) -> void:
	_save_data[_section_name] = _value


# 本类方法：将当前存档数据写入磁盘。
func save() -> bool:
	var _file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if _file == null:
		push_error("Failed to open save file for writing: %s" % SAVE_PATH)
		return false

	_file.store_string(JSON.stringify(_save_data, "\t"))
	return true


# 本类方法：从磁盘读取存档，必要时回退到默认存档。
func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data = build_default_save_data()
		save()
		return

	var _file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if _file == null:
		push_error("Failed to open save file for reading: %s" % SAVE_PATH)
		_save_data = build_default_save_data()
		return

	var _content := _file.get_as_text()
	var _json := JSON.new()
	var _error := _json.parse(_content)
	if _error != OK:
		push_error("Failed to parse save file, fallback to default data.")
		_save_data = build_default_save_data()
		return

	if _json.data is Dictionary:
		_save_data = merge_with_default_save_data(_json.data)
	else:
		_save_data = build_default_save_data()


# 本类方法：重置存档内容并立即保存。
func reset_save() -> void:
	_save_data = build_default_save_data()
	save()


# 本类方法：构建默认存档数据结构。
func build_default_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"settings": {
			"master_volume": 1.0,
			"music_volume": 1.0,
			"sfx_volume": 1.0,
			"language": "zh_CN",
		},
		"player_progress": {
			"last_selected_stage": "",
		},
		"unlocked_content": {},
		"stage_stars": {},
		"meta_progression": {},
	}


# 本类方法：将旧存档数据合并到默认结构中，补齐缺失字段。
func merge_with_default_save_data(_data: Dictionary) -> Dictionary:
	var _merged := build_default_save_data()
	for _key in _data.keys():
		_merged[_key] = _data[_key]
	return _merged
