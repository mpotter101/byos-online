extends Node3D
class_name Sprite_Animator

# -1 for a peer_id means we are an offline object.
@export var peer_id: int = Helper._INVALID_PEER_ID
@export var json_file_path: String
@export var current_animation_name: String = ""
@export var my_sprite: Sprite3D
@export var is_local: bool = true

var my_Json: Variant

var spriteAnimManager: DeltaSpriteAnimationManager
var camera: Camera3D

var isFlickering: bool = false
var flickerDurationMs: int
var flickerDurationCurrentMs: int
var flickerDurationTotalMs: int
var flickerHoldMs: int = 50

var Facings = [
	"_facing_toward",
	"_facing_away",
	"_right",
	"_left"
]

signal animation_completed
signal flicker_completed

func _can_perform() -> bool:
	return is_multiplayer_authority() or is_local

func _enter_tree() -> void:
	set_multiplayer_authority(peer_id)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	
	if json_file_path:
		_Load_Sprite_From_File_Path(json_file_path)
	
# Called every frame. 'delta' is the elapsed time since the previous frame in seconds.
func _process(delta: float) -> void:
	_handle_visual_state(delta)
	
	# Waits until the end of all processes to make sure our sprite doesn't "fidget" as something moves.
	call_deferred("_Aim_Sprite_At_Camera")
	
func _Get_Random_Emote_Name() -> String:
	return my_Json.emotes [Helper._Get_Random_Int_From_Range(0, my_Json.emotes.size() - 1)].animation
	
func _handle_visual_state(delta):
	if not spriteAnimManager: _Load_Sprite_From_File_Path(json_file_path)
	if not _can_perform(): return
	
	spriteAnimManager._UpdateAnimation(delta, my_sprite)
	
	if isFlickering:
		_handle_flicker(delta)
	
# Causes sprite to rapidly flash on and off over given duration
func _flicker(durationMs: int):
	flickerDurationCurrentMs = 0
	flickerDurationTotalMs = 0
	flickerDurationMs = durationMs
	isFlickering = true
	
func _handle_flicker(delta: float):
	var ms = roundi(delta * 1000)
	
	flickerDurationCurrentMs += ms
	flickerDurationTotalMs += ms
	
	if flickerDurationCurrentMs >= flickerHoldMs:
		visible = !visible
		flickerDurationCurrentMs = 0
	
	if flickerDurationTotalMs >= flickerDurationMs:
		visible = true
		isFlickering = false
		flicker_completed.emit()
	
func _Load_Sprite_From_File_Path(json_Path: String):
	json_file_path = json_Path
	_Load_Sprite()
	
func _get_current_animation_name():
	return spriteAnimManager.currentAnimation.name
	
func _Load_Sprite():
	my_Json = Helper._Load_Json(json_file_path)
	spriteAnimManager = DeltaSpriteAnimationManager.new(my_Json, my_sprite, self, peer_id)
	spriteAnimManager.set_multiplayer_authority(peer_id)
	spriteAnimManager.peer_id = peer_id
	spriteAnimManager.animation_completed.connect(_On_Animation_Completed)
	spriteAnimManager._Play()
	
	spriteAnimManager.set_multiplayer_authority(peer_id)
	
	add_child(spriteAnimManager)
	
func _Aim_Sprite_At_Camera():
	if not camera: return
	# Keeps the "feet" of the sprite planted
	var lookAt = Vector3(
		camera.global_position.x,
		global_position.y,
		camera.global_position.z)
		
	my_sprite.look_at(lookAt, Vector3.UP)
	my_sprite.rotation.x = 0
	my_sprite.rotation.z = 0

# Event Handlers

func _Play_Animation_By_Name(animName: String):
	spriteAnimManager._PlayAnimationByName(animName)

func _Play_Animation_By_Name_From_Start(animName: String):
	spriteAnimManager._PlayAnimationByNameFromStart(animName)

func _On_Animation_Completed(animationName: String):
	animation_completed.emit(animationName)
