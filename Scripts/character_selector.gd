extends OptionButton
class_name Character_Selector

@export var characters_folder = "res://Characters"
@export var characterPreview: TextureRect

var json_file_paths: Array = []
var json_file_contents: Array = []
var character_textures: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_characters_from_folder()
	selected = 0
	item_selected.connect(_on_item_selected)
	
func _on_item_selected(index: int):
	var characterTexture: Texture = character_textures[index] as Texture
	characterPreview.texture = characterTexture

func _collect_json_files(dir: DirAccess):
	json_file_paths = []
	json_file_contents = []
	character_textures = []
	
	var files = dir.get_files()
	for filename in files:
		if filename.contains(".json"):
			var filePath = str(characters_folder, "/", filename)
			var json = Helper._Load_Json(filePath)
			var texture = load(json.spritesheet)
			
			json_file_paths.append(filePath)
			json_file_contents.append(json)
			character_textures.append(texture)
	
func _create_option_buttons(json_options: Array):
	clear()
	for option in json_options:
		add_item(option.name)

func _load_characters_from_folder():
	var dir: DirAccess = DirAccess.open(characters_folder)
	if not dir: return
		
	_collect_json_files(dir)
	_create_option_buttons(json_file_contents)
	
