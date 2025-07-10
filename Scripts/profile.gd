extends Control
class_name Profile

@export var usernameTextEdit: TextEdit
@export var characterSelector: Character_Selector
@export var username: String = ""
@export var json_file_path: String = ""

func _ready() -> void:
	usernameTextEdit.text_changed.connect(_on_text_changed)
	
func _process(_delta: float) -> void:
	if usernameTextEdit.has_focus() and Input.is_action_just_pressed("ui_accept"):
		usernameTextEdit.release_focus()
	
func _on_text_changed():
	if usernameTextEdit.text.contains("\n"):
		usernameTextEdit.text = usernameTextEdit.text.replace("\n", "")
		
	username = usernameTextEdit.text.strip_edges()

func _get_selected_character_json_filepath() -> String:
	return characterSelector.json_file_paths[characterSelector.selected]
