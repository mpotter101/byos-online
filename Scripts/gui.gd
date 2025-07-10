extends Control
class_name Gui

@export var emote_button_container: Emote_Button_Container

signal emote_button_pressed(emote_name: String)

func _load_profile(profile: Profile):
	var json = Helper._Load_Json(profile._get_selected_character_json_filepath())
	emote_button_container._prepare_emote_buttons(json)
	emote_button_container.emote_button_pressed.connect(
		func(emote_name): emote_button_pressed.emit(emote_name)
	)
