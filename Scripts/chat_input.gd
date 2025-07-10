extends MarginContainer
class_name Chat_Input

@export var input_line_edit: LineEdit
@export var send_message_button: Button
@export var focus_on_ui_accept_pressed: bool = true

signal user_is_typing(current_message: String)
signal user_started_typing
signal user_finished_typing
signal send_message(message: String)

var typing: bool = false

func _ready() -> void:
	connect("hidden", _release_focus)
	input_line_edit.focus_entered.connect(func(): typing = true; user_started_typing.emit())
	input_line_edit.focus_exited.connect(func(): typing = false; user_finished_typing.emit())

func _process(_delta: float) -> void:
	if not visible: return
	
	if Input.is_action_just_pressed("ui_accept"):
		if focus_on_ui_accept_pressed and not typing:
			_focus()
		elif typing and not _text_is_empty():
			_handle_send_message()
		elif typing and _text_is_empty():
			_release_focus()
	
func _handle_send_message():
	send_message.emit(_get_trimmed_text())
	
func _clear():
	input_line_edit.clear()
	
	if typing:
		# emit_event = false
		_release_focus()
		_focus()

func _get_trimmed_text() -> String:
	return str(input_line_edit.text).strip_edges()
	
func _text_is_empty() -> bool:
	return _get_trimmed_text().length() <= 0
	
func _focus():
	input_line_edit.grab_focus()
	
func _release_focus():
	input_line_edit.release_focus()
	send_message_button.release_focus()
