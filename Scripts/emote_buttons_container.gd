extends Control
class_name Emote_Button_Container

@export var emote_button_prefab: PackedScene
@export var emote_button_box_container: HFlowContainer

signal emote_button_pressed(emote_name: String)

func _prepare_emote_buttons(json: Variant):
	var hFrames = json.horizontal_frames
	var vFrames = json.vertical_frames
	var spritesheet: Texture2D = load(json.spritesheet) as Texture2D
	
	for child in emote_button_box_container.get_children():
		emote_button_box_container.remove_child(child)
	
	for emote in json.emotes:
		var emtBtn: Emote_Button = emote_button_prefab.instantiate() as Emote_Button
		emtBtn._setup(
			emote.name,
			Vector2(emote.thumbnail.x, emote.thumbnail.y),
			hFrames, vFrames,
			spritesheet)
		emtBtn.emote_button_pressed.connect(_on_emote_button_pressed)
		emote_button_box_container.add_child(emtBtn)

func _on_emote_button_pressed(emote_name: String):
	emote_button_pressed.emit(emote_name)
