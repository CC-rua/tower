extends RefCounted
class_name ConfigRow

# 行主键，通常对应 Excel 中的 id 字段。
var id := 0


# 本类方法：使用原始字典填充当前配置行对象。
func from_dict(_raw_data: Dictionary) -> void:
	if _raw_data.has("id"):
		id = int(_raw_data["id"])


# 本类方法：将原始数组转换为整数数组。
func to_int_array(_raw_value: Variant) -> Array[int]:
	var _result: Array[int] = []
	if not (_raw_value is Array):
		return _result

	for _item in _raw_value:
		_result.append(int(_item))
	return _result


# 本类方法：将原始数组转换为字符串数组。
func to_string_array(_raw_value: Variant) -> Array[String]:
	var _result: Array[String] = []
	if not (_raw_value is Array):
		return _result

	for _item in _raw_value:
		_result.append(str(_item))
	return _result


# 本类方法：将原始数组转换为布尔数组。
func to_bool_array(_raw_value: Variant) -> Array[bool]:
	var _result: Array[bool] = []
	if not (_raw_value is Array):
		return _result

	for _item in _raw_value:
		_result.append(bool(_item))
	return _result


# 本类方法：将原始值转换为字典。
func to_dictionary(_raw_value: Variant) -> Dictionary:
	if _raw_value is Dictionary:
		return _raw_value.duplicate(true)
	return {}


# 本类方法：将原始值转换为 Callable。
func to_callable(_raw_value: Variant) -> Callable:
	if _raw_value is Callable:
		return _raw_value
	return Callable()
