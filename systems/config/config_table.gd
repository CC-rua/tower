extends RefCounted
class_name ConfigTable

# 表名称，用于调试和错误提示。
var table_name := ""
# 当前表的配置行列表，保留原始顺序。
var row_list: Array[ConfigRow] = []
# 以主键索引配置行，便于按 id 快速查询。
var row_map := {}


# 本类方法：初始化配置表容器。
func setup(_table_name: String) -> void:
	table_name = _table_name


# 本类方法：向表中添加一行配置数据。
func add_row(_row: ConfigRow) -> void:
	row_list.append(_row)
	row_map[_row.id] = _row


# 本类方法：根据主键获取配置行。
func get_row(_row_id: int) -> ConfigRow:
	return row_map.get(_row_id)


# 本类方法：返回全部配置行。
func get_rows() -> Array[ConfigRow]:
	return row_list
