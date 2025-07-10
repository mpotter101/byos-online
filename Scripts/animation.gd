extends Node
class_name DeltaSpriteAnimationManager

class DeltaSpriteFrameCoords:

	var x: int = 0
	var y: int = 0
	var durationMs: int = 33

	func _init(frameX, frameY, frameDurationMs) -> void:
		x = frameX;
		y = frameY;
		durationMs = frameDurationMs;

# ---------------------------------

class DeltaSpriteAnimation extends Node:

	var frames: Array[DeltaSpriteFrameCoords] = []
	var currentFrame: DeltaSpriteFrameCoords
	var currentDurationMs: float = 0
	var hasFrames: bool = false
	var frameCount: int = 0

	signal animation_completed

	func _init(jsonName: String, jsonFrames: Array) -> void:
		name = jsonName
		
		for frame in jsonFrames:
			frames.append(
				 DeltaSpriteFrameCoords.new(frame.x, frame.y, frame.durationMs)
			);
			
		frameCount = frames.size()
		
		if frameCount > 0:
			currentFrame = frames[0]
			hasFrames = true
			
	func _Update(delta: float):
		currentDurationMs += delta * 1000
		
		if !hasFrames:
			return
			
		if currentDurationMs >= currentFrame.durationMs:
			_IncrementCurrentFrame()
					
	func _IncrementCurrentFrame():
		var index = frames.find(currentFrame)
		index += 1
		currentDurationMs = 0
		
		if index >= frameCount:
			animation_completed.emit(name)
			index = 0
			
		currentFrame = frames[index]

# ---------------------------------
# Expects to be working with a Sprite3D node
# ---------------------------------
	
var animations: Array[DeltaSpriteAnimation]
var currentAnimation: DeltaSpriteAnimation
var isPlaying: bool = true
var json: Variant
var peer_id: int = Helper._INVALID_PEER_ID
var sprite: Sprite3D
var sprite_animator: Sprite_Animator
var is_local: bool = true

signal animation_completed
	
func _can_perform() -> bool:
	return (is_multiplayer_authority() or is_local) and currentAnimation
	
func _init(fileJson: Variant, sprite3d: Sprite3D, spriteAnimator: Sprite_Animator, unique_id: int = Helper._INVALID_PEER_ID):
	peer_id = unique_id
	sprite = sprite3d
	sprite_animator = spriteAnimator
	
	if not (fileJson as Dictionary).size() == 0:
		_LoadAnimationsFromJson(fileJson)

func _LoadAnimationsFromJson(fileJson: Variant):
	json = fileJson

	for anim in json.animations:
		var animation = DeltaSpriteAnimation.new(anim.name, anim.frames)
		animation.animation_completed.connect(_On_Animation_Completed)
		animations.append(animation)

	if animations.size() > 0:
		currentAnimation = animations[0]
		
	_AssignSpriteDataFromJson()
		
func _AssignSpriteDataFromJson():
	var texture = load(json.spritesheet)
	sprite.hframes = json.horizontal_frames
	sprite.vframes = json.vertical_frames
	sprite.frame = 0
	sprite.texture = texture
	sprite.pixel_size = json.pixelSizeInMeters
	sprite.position.y = json.sprite_y_offset

func _UnloadAnimations():
	for anim in animations:
		anim.animation_completed.disconnect(_On_Animation_Completed)

	animations.clear()

func _GetAnimationNames() -> Array[String]:
	var names: Array[String]

	for anim in animations:
		names.append(anim.name)
	
	return names

func _PlayAnimationByNameFromStart(animName: String):
	for anim in animations:
		if (anim.name == animName):
			anim.currentFrame = anim.frames [0]
			_PlayAnimation(anim)
			break;
	
func _PlayAnimationByName(animName: String):
	for anim in animations:
		if (anim.name == animName):
			_PlayAnimation(anim)
			break;
	
func _PlayAnimation(anim: DeltaSpriteAnimation):
	currentAnimation = anim;
	isPlaying = true;
	
func _Play():
	isPlaying = true
	
func _Pause():
	isPlaying = false
	
func _UpdateAnimation(delta: float, sprite3d: Sprite3D):
	if not _can_perform(): return
	
	if isPlaying:
		currentAnimation._Update(delta)
		
		sprite3d.frame_coords.x = currentAnimation.currentFrame.x
		sprite3d.frame_coords.y = currentAnimation.currentFrame.y
		
func _On_Animation_Completed(animationName: String):
	animation_completed.emit(animationName)
