extends MarginContainer
class_name Chat_Message

@export var message_name: Label
@export var message_area: Label

func _Set_Message(messageName: String, message: String):
	message_name.text = messageName
	message_area.text = message
