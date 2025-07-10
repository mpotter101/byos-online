extends Node
class_name Helper

@warning_ignore("unused_private_class_variable") # Variable is used by other classes
static var _INVALID_PEER_ID = 0

static func _Get_Random_Int_From_Range(min_val: int, max_val: int) -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(min_val, max_val)
	
static func _Get_Random_Float_From_Range(min_val: float, max_val: float) -> float:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randf_range(min_val, max_val)

static func _Load_Json(jsonPath: String) -> Variant:
	if FileAccess.file_exists(jsonPath):
		var file = FileAccess.open(jsonPath, FileAccess.READ)
		var text = file.get_as_text()
		return JSON.parse_string(text)
		
	return {}
