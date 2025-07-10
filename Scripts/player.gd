extends Node3D
class_name Player

@export var mouseSensitivity: float = 0.1
@export var camZoomSpeed: float = 10
@export var moveSpeed: float = 10.0 #TODO Move this to character stats

@export var camPivotY: Node3D
@export var camPivotX: Node3D
@export var camSpringArm: SpringArm3D

# Used to find our character to control
var peer_id = null # intentionally null and not Helper._INVALID_PEER_ID
var my_character: Character = null

# Camera-zoom variables
var camDistancesMeters = [1.5, 3, 6, 9, 12, 15]
var camDistancesMetersSize: int = 4
var currentDistanceIndex = 1
var isCamCloseEnoughToTargetDistance = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_handle_camera_zoom(delta)
	
	if my_character:
		_handle_character_move(delta)
		_handle_character_state()
	
func _assign_character(character: Character):
	my_character = character
	
func _input(event):
	if event is InputEventMouseMotion:
		_handle_camera_input(event)

func _handle_camera_input(event):
		if Input.is_action_pressed("secondary_click"):
			var delta = get_process_delta_time()
			camPivotY.rotate_y(-event.relative.x * mouseSensitivity * delta)
			camPivotX.rotate_x(-event.relative.y * mouseSensitivity * delta)
			camPivotX.rotation.x = clamp(camPivotX.rotation.x, deg_to_rad(-35), deg_to_rad(35))

func _handle_camera_zoom(delta: float):
	if Input.is_action_just_pressed("zoom_out"):
		currentDistanceIndex += 1
		isCamCloseEnoughToTargetDistance = false
		if currentDistanceIndex >= camDistancesMetersSize - 1:
			currentDistanceIndex = camDistancesMetersSize - 1
			
	if Input.is_action_just_pressed("zoom_in"):
		currentDistanceIndex -= 1
		isCamCloseEnoughToTargetDistance = false
		if currentDistanceIndex < 0:
			currentDistanceIndex = 0
			
	if !isCamCloseEnoughToTargetDistance:
		camSpringArm.spring_length = lerpf(camSpringArm.spring_length, camDistancesMeters[currentDistanceIndex], delta * camZoomSpeed)
		if abs(camDistancesMeters [currentDistanceIndex]- camSpringArm.spring_length) < 0.1:
			isCamCloseEnoughToTargetDistance = true

func _handle_character_move(delta: float):
	if not my_character is Node3D: return
	
	var inputDir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (camPivotY.transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
	
	my_character._networked_move(direction, delta)
	global_position = my_character.global_position

func _any_movement_held():
	return (Input.is_action_pressed("move_backward") or
	Input.is_action_pressed("move_forward") or
	Input.is_action_pressed("move_left") or
	Input.is_action_pressed("move_right"))

func _handle_character_state():
	if _any_movement_held():
		my_character._Move()
	elif not _any_movement_held():
		my_character._Idle()
	
