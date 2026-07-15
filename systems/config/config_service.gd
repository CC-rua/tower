extends RefCounted
class_name ConfigService

const SETTINGS_PATH := "res://data/config_gdscript/settings.gd"
const LEGACY_SETTINGS_PATH := "res://data/ref/settings.gd"

const ConfigTableScript = preload("res://systems/config/config_table.gd")
const ConfigRowScript = preload("res://systems/config/config_row.gd")
const DemoRefScript = preload("res://systems/config/refs/demo_ref.gd")

# 缓存插件生成的 settings 实例，作为原始配置入口。
var _settings_instance: Node = null
# 缓存原始表对象，键为表名。
var _raw_tables := {}
# 缓存解析后的配置表，键为表名。
var _config_tables := {}
# 配置行解析器映射，键为表名，值为对应 Ref 脚本。
var _row_script_map := {
	"demo": DemoRefScript,
}


# 本类方法：初始化配置服务并加载全部配置。
func initialize() -> void:
	reload_configs()


# 本类方法：重新加载 settings 和全部解析后的配置表。
func reload_configs() -> void:
	_settings_instance = null
	_raw_tables.clear()
	_config_tables.clear()
	_load_settings_instance()
	_build_tables()


# 本类方法：获取解析后的配置表。
func get_config(_config_name: String) -> Variant:
	return _config_tables.get(_config_name)


# 本类方法：获取解析后的配置表，语义上等同于 get_config。
func get_table(_table_name: String) -> Variant:
	return _config_tables.get(_table_name)


# 本类方法：判断指定配置表是否已完成解析。
func has_config(_config_name: String) -> bool:
	return _config_tables.has(_config_name)


# 本类方法：返回全部解析后的配置表副本。
func get_all_configs() -> Dictionary:
	return _config_tables.duplicate()


# 本类方法：获取原始 settings 实例。
func get_settings_instance() -> Node:
	return _settings_instance


# 本类方法：获取指定表的原始插件对象。
func get_raw_table(_table_name: String) -> Variant:
	return _raw_tables.get(_table_name)


# 本类方法：按主键获取指定表中的一行配置对象。
func get_row(_table_name: String, _row_id: int) -> ConfigRow:
	var _table: ConfigTable = _config_tables.get(_table_name)
	if _table == null:
		return null
	return _table.get_row(_row_id)


# 本类方法：获取指定表中的全部配置行。
func get_rows(_table_name: String) -> Array[ConfigRow]:
	var _table: ConfigTable = _config_tables.get(_table_name)
	if _table == null:
		return []
	return _table.get_rows()


# 本类方法：加载插件导出的 settings 实例。
func _load_settings_instance() -> void:
	var _script_path := _resolve_settings_path()
	if _script_path.is_empty():
		push_warning("ConfigService: settings.gd not found.")
		return

	var _settings_script := load(_script_path)
	if _settings_script == null:
		push_error("ConfigService: failed to load settings script: %s" % _script_path)
		return

	_settings_instance = _settings_script.new()


# 本类方法：从 settings 实例中提取表并构建解析后的配置表。
func _build_tables() -> void:
	if _settings_instance == null:
		return

	for _property in _settings_instance.get_property_list():
		if not (_property is Dictionary):
			continue

		var _usage := int(_property.get("usage", 0))
		if (_usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		var _property_name := str(_property.get("name", ""))
		if _should_skip_property(_property_name):
			continue

		var _raw_table = _settings_instance.get(_property_name)
		if _raw_table == null:
			continue
		if not (_raw_table is Object):
			continue
		if not _raw_table.has_method("get"):
			continue

		var _raw_data = _raw_table.get("data")
		if not (_raw_data is Dictionary):
			continue

		_raw_tables[_property_name] = _raw_table
		_config_tables[_property_name] = _build_single_table(_property_name, _raw_data)


# 本类方法：根据原始 data 字典构建一张解析后的配置表。
func _build_single_table(_table_name: String, _raw_data_map: Dictionary) -> ConfigTable:
	var _table: ConfigTable = ConfigTableScript.new()
	_table.setup(_table_name)

	var _row_ids := _raw_data_map.keys()
	_row_ids.sort()

	for _row_id in _row_ids:
		var _raw_row = _raw_data_map[_row_id]
		if not (_raw_row is Dictionary):
			continue

		var _row := _create_row_object(_table_name, _raw_row)
		_table.add_row(_row)

	return _table


# 本类方法：根据表名创建对应的配置行对象。
func _create_row_object(_table_name: String, _raw_row: Dictionary) -> ConfigRow:
	var _row_script = _row_script_map.get(_table_name, ConfigRowScript)
	var _row: ConfigRow = _row_script.new()
	_row.from_dict(_raw_row)
	return _row


# 本类方法：解析 settings.gd 的实际路径，优先使用新目录。
func _resolve_settings_path() -> String:
	if ResourceLoader.exists(SETTINGS_PATH):
		return SETTINGS_PATH
	if ResourceLoader.exists(LEGACY_SETTINGS_PATH):
		return LEGACY_SETTINGS_PATH
	return ""


# 本类方法：过滤掉 settings 实例上的内置属性。
func _should_skip_property(_property_name: String) -> bool:
	return _property_name in ["script", "RefCounted", "Node", "_import_path", "_editor_description"]
