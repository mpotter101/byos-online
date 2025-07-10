extends PanelContainer
class_name Emote_Button

@export var spritesheet: Texture
@export var my_button: Button
@export var my_sprite2d: Sprite2D
@export var my_label: Label

signal emote_button_pressed(emoteName: String)

func _ready() -> void:
	my_button.pressed.connect(func(): emote_button_pressed.emit(my_label.text))

func _setup(emote_name: String, frame_coords: Vector2, hFrames: int, vFrames: int, sprite: Texture2D):
	my_sprite2d.texture = sprite
	my_sprite2d.hframes = hFrames
	my_sprite2d.vframes = vFrames
	my_sprite2d.frame_coords = frame_coords
	my_label.text = emote_name
	name = emote_name
