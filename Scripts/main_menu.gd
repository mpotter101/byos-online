extends VBoxContainer
class_name Main_Menu

@export var play_offline_button: Button
@export var host_lobby_button: Button
@export var join_lobby_button: Button

signal play_offline_pressed
signal host_lobby_pressed
signal join_lobby_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_offline_button.pressed.connect(_play_offline_pressed)
	host_lobby_button.pressed.connect(_host_lobby_pressed)
	join_lobby_button.pressed.connect(_join_lobby_pressed)

func _play_offline_pressed():
	play_offline_pressed.emit()
	
func _host_lobby_pressed():
	host_lobby_pressed.emit()
	
func _join_lobby_pressed():
	join_lobby_pressed.emit()
