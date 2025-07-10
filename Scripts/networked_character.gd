extends CharacterBody3D
class_name Character

class PossibleStates extends Node:
	static var IDLE = 0
	static var MOVING = 1
	static var HURT = 2 # indicates we should play a hurt animation and flicker the sprite until i-frames wear-off
	static var ACTION = 3 # action is used for combat moves. Prevents movement, Plays an animation, then returns to idle
	static var EMOTE = 4 # Used for one-off animations. Can be interuptted by moving or getting hurt

@export var sprite_animator: Sprite_Animator
@export var json_file_path: String
@export var peer_id = null
@export var currentState: int = PossibleStates.IDLE

var json = null
var _prev_json_file: String = ""

var _prevState = PossibleStates.IDLE
var _prevAnimationState = PossibleStates.IDLE

var Facings = [
	"_facing_toward",
	"_facing_away",
	"_right",
	"_left"
]

var canIdle = true
var canMove = true
var canHurt = true
var canAction = true
var canEmote = true

const SPEED = 5.0

var emote_animation_name

var loading_json = false
signal json_loaded

func _can_perform() -> bool:
	return is_multiplayer_authority()

func _enter_tree():
	if not peer_id:
		# peer_id is only given when the local client creates an object.
		# When replicated, this is not set. So use the name as a backup.
		peer_id = str(name).to_int()
	
	set_multiplayer_authority(peer_id, true)
	
func _ready() -> void:
	_prepare_sprite()
	
func _json_ready():
	return _prev_json_file and _prev_json_file == json_file_path and not loading_json
	
func _process(_delta: float) -> void:
	# helps keep sprites in order when instantiated from MultiplayerSpawner
	if _json_ready():
		_play_animation_based_on_state()
	elif _prev_json_file != json_file_path:
		_prepare_sprite()
		
func _prepare_sprite():
	if loading_json: return
	
	loading_json = true
	json = Helper._Load_Json(json_file_path)
	
	if not json_loaded.is_connected(_on_json_loaded):
		json_loaded.connect(_on_json_loaded)
		
	sprite_animator.json_file_path = json_file_path
	sprite_animator.peer_id = peer_id
	_reload_sprite()
		
func _on_json_loaded():
	_prev_json_file = json_file_path
	loading_json = false
		
func _play_animation_based_on_state():
	match currentState:
		PossibleStates.IDLE:
			var animationName = _Get_Animation_For_Action_With_Facing("idle")
			sprite_animator._Play_Animation_By_Name(animationName)
		PossibleStates.MOVING:
			var animationName = _Get_Animation_For_Action_With_Facing("move")
			sprite_animator._Play_Animation_By_Name(animationName)
		_:
			pass
			
	if _prevAnimationState == currentState:
		return
		
	_prevAnimationState = currentState
			
	match currentState:
		PossibleStates.HURT:
			var hurtAnimationName = json.action_map.hurt
			sprite_animator._Play_Animation_By_Name_From_Start(hurtAnimationName)
		PossibleStates.ACTION:
			sprite_animator._Play_Animation_By_Name_From_Start(json.action_map.attack)
		PossibleStates.EMOTE:
			sprite_animator._Play_Animation_By_Name_From_Start(emote_animation_name)
		_:
			pass
	
func _reload_sprite():
	if not sprite_animator.animation_completed.is_connected(_On_Animation_Completed):
		sprite_animator.animation_completed.connect(_On_Animation_Completed)
		
	if not sprite_animator.flicker_completed.is_connected(_On_Flicker_Completed):
		sprite_animator.flicker_completed.connect(_On_Flicker_Completed)
		
	sprite_animator._Load_Sprite()
	json_loaded.emit()
	
func _networked_move(direction: Vector3, delta: float):
	if not _can_perform(): return
	_controlled_move_and_collide(direction, delta)

func _controlled_move_and_collide(direction: Vector3, delta: float):
	var finalDir = direction * SPEED * delta
	
	move_and_collide(finalDir)
	
	if direction != Vector3.ZERO:
		look_at(global_position + -finalDir, Vector3.UP)

func _Get_Facing_Based_On_Camera() -> String:
	var activeCamera = get_viewport().get_camera_3d()
	if not activeCamera: return ""
	
	var camForward = activeCamera.global_transform.basis.z
	var myForward = global_transform.basis.z
	var myLeft = global_transform.basis.x
	
	# dot compares how closely two vectors are facing the same direction
	var leftDot = myLeft.dot(camForward)
	var forwardDot = myForward.dot(camForward)
	
	# magic numbers discovered via manual testing.
	# seems to be a range between -4 and 4 and it ping-pongs in value as we rotate.
	if forwardDot > 0.5: 
		return Facings [0]
	elif forwardDot < -0.5:
		return Facings [1]
	elif leftDot > 0:
		return Facings [2]
	elif leftDot < 0:
		return Facings [3]
	
	return Facings [0]
	
func _Get_Animation_For_Action_With_Facing(action: String):
	if not json_file_path or not json:
		return
	
	var facing = _Get_Facing_Based_On_Camera()
	var actionName = action + facing
	return json.action_map[actionName]
	
func _SetState(state: int):
	if state == currentState:
		return
	
	_prevState = currentState
	currentState = state
	
	match currentState:
		# TODO: 
		#	For Idle + Walking
		# 		Update this to use the action map in the json
		#		and to reference from what angle the camera is viewing this object
		#		don't reference the sprite3d since its gonna get rotated to face the camera
		#	For other states
		#		Figure out how to dynamically create UI for all emotes
		
		PossibleStates.IDLE:
			canIdle = true
			canMove = true
			canAction = true
			canEmote = true
		PossibleStates.MOVING:
			pass
		PossibleStates.HURT:
			pass
		PossibleStates.ACTION:
			canIdle = false
			canMove = false
			canAction = false
			canEmote = false
		PossibleStates.EMOTE:
			pass
		_:
			pass

func _On_Animation_Completed(animationName: String):
	if not _can_perform(): return
	
	match currentState:
		PossibleStates.IDLE:
			pass
		PossibleStates.MOVING:
			pass
		PossibleStates.HURT:
			_SetState(PossibleStates.IDLE)
		PossibleStates.ACTION:
			_SetState(PossibleStates.IDLE)
		PossibleStates.EMOTE:
			for emote in json.emotes:
				if emote.animation == animationName:
					if !emote.looping:
						_SetState(PossibleStates.IDLE)
		_:
			pass

func _Emote(emoteName: String):
	if !canEmote or not _can_perform():
		return
		
	for emote in json.emotes:
		if emoteName == emote.name:
			emote_animation_name = emote.animation
			
	_SetState(PossibleStates.EMOTE)

func _Hurt(_damage: int):
	if !canHurt or not _can_perform():
		return
		
	canHurt = false
	_SetState(PossibleStates.HURT)
	sprite_animator._flicker(2000)
	

func _Move():
	if !canMove or not _can_perform():
		return
		
	_SetState(PossibleStates.MOVING)

func _Idle():
	if !canIdle or not _can_perform():
		return
		
	_SetState(PossibleStates.IDLE)

func _Attack():
	if !canAction or not _can_perform():
		return

	_SetState(PossibleStates.ACTION)

func _On_Flicker_Completed():
	canHurt = true
