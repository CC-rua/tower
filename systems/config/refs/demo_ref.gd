extends ConfigRow
class_name DemoRef

const TABLE_NAME := "demo"

# 整数字段示例，用于演示数值类型约束。
var int_value := 0
# 浮点字段示例，用于演示浮点类型约束。
var float_value := 0.0
# 字符串字段示例。
var string_value := ""
# 布尔字段示例。
var bool_value := false
# 整数数组字段示例。
var array_value: Array[int] = []
# 字符串数组字段示例。
var array_str_value: Array[String] = []
# 布尔数组字段示例。
var array_bool_value: Array[bool] = []
# 字典字段示例。
var dict_value := {}
# 可调用字段示例。
var function_value: Callable = Callable()
# 带参数的可调用字段示例。
var function_params_value: Callable = Callable()
# 可翻译字符串字段示例。
var tr_string_value := ""
# 可翻译字符串数组字段示例。
var tr_array_str_value: Array[String] = []
# 可翻译字典字段示例。
var tr_dict_value := {}


# 本类方法：使用原始字典填充 Demo 配置行对象。
func from_dict(_raw_data: Dictionary) -> void:
	super.from_dict(_raw_data)
	int_value = int(_raw_data.get("int", 0))
	float_value = float(_raw_data.get("float ", _raw_data.get("float", 0.0)))
	string_value = str(_raw_data.get("string", ""))
	bool_value = bool(_raw_data.get("bool", false))
	array_value = to_int_array(_raw_data.get("array", []))
	array_str_value = to_string_array(_raw_data.get("array_str", []))
	array_bool_value = to_bool_array(_raw_data.get("array_bool", []))
	dict_value = to_dictionary(_raw_data.get("dict", {}))
	function_value = to_callable(_raw_data.get("function", Callable()))
	function_params_value = to_callable(_raw_data.get("function_params", Callable()))
	tr_string_value = str(_raw_data.get("tr_string", ""))
	tr_array_str_value = to_string_array(_raw_data.get("tr_array_str", []))
	tr_dict_value = to_dictionary(_raw_data.get("tr_dict", {}))


# 本类方法：从 ConfigManager 缓存中按 id 获取一行 Demo 配置。
static func get_by_id(_row_id: int) -> DemoRef:
	return ConfigManager.get_row(TABLE_NAME, _row_id) as DemoRef


# 本类方法：从 ConfigManager 缓存中获取全部 Demo 配置。
static func get_all() -> Array[DemoRef]:
	var _rows = ConfigManager.get_rows(TABLE_NAME)
	var _result: Array[DemoRef] = []
	for _row in _rows:
		if _row is DemoRef:
			_result.append(_row)
	return _result
