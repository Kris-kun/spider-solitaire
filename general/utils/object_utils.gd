class_name ObjectUtils


static func coalesce(val1, val2, val3 = null):
	return val1 if val1 != null else val2 if val2 != null else val3
