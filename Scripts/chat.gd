extends Control
class_name Chat

@export var chat_history_scroll_container: ScrollContainer
@export var chat_history: Control
@export var chat_message_prefab: PackedScene
@export var default_name: String = "Nameless"
@export var chat_input: Chat_Input

var peer_id: int = Helper._INVALID_PEER_ID

var scrollbar: VScrollBar
var max_scroll_length

signal user_started_typing
signal user_finished_typing
signal chat_message_queued

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scrollbar = chat_history_scroll_container.get_v_scroll_bar()
	max_scroll_length = scrollbar.max_value
	
	chat_input.connect("send_message", _handle_message_send)
	scrollbar.changed.connect(handle_scrollbar_changed)
	
	chat_input.user_started_typing.connect(_on_user_started_typing)
	chat_input.user_finished_typing.connect(_on_user_finished_typing)
	
# Auto scrolls to bottom
func handle_scrollbar_changed(): 
	if max_scroll_length != scrollbar.max_value: 
		max_scroll_length = scrollbar.max_value 
		chat_history_scroll_container.scroll_vertical = max_scroll_length
	
func _handle_message_send(message: String):
	chat_input._clear()
	chat_input._focus()
	chat_message_queued.emit(message)
	
func _on_user_started_typing():
	user_started_typing.emit()
	
func _on_user_finished_typing():
	user_finished_typing.emit()

@rpc("any_peer", "call_local")
func _Add_Message(username: String, message: String):
	if not username:
		username = default_name
		
	var chatMessage: Chat_Message = chat_message_prefab.instantiate() as Chat_Message
	chatMessage._Set_Message(username, message)
	chat_history.add_child(chatMessage)
