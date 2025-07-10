extends MarginContainer
class_name Join_Lobby_Menu

@export var ipTextEdit: TextEdit
@export var portTextEdit: TextEdit
@export var join_lobby_button: Button
@export var cancel_button: Button

signal join_lobby(ip: String, port: String)
signal cancel_join_lobby()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	join_lobby_button.pressed.connect(_on_join_lobby_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
func _on_join_lobby_button_pressed():
	var ipAddress = str(ipTextEdit.text)
	var portAddress = str(portTextEdit.text)
	join_lobby.emit(ipAddress, portAddress)

func _on_cancel_button_pressed():
	hide()
	cancel_join_lobby.emit()
