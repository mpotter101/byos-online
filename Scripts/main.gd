extends Node3D

# Responsible for:
#	Coordinating between Top Level Objects
#	Managing top-level game state

# TODO: Move ui management onto the Menus node?
# 	need to do some thinking on object structure here to see if it will actually reduce events/fubctions in this area

@export var profile: Profile
@export var networker: Networker
@export var chat: Chat
@export var main_menu: Main_Menu
@export var options_menu: Control
@export var blocker_pop_up: Control
@export var join_lobby_menu: Join_Lobby_Menu
@export var gui: Gui
@export var world: World
@export var local_player: Player

enum GAME_STAGE {
	MAIN_MENU = 0,
	PLAYING = 1,
}

var game_stage: GAME_STAGE = GAME_STAGE.MAIN_MENU

func _ready() -> void:
	blocker_pop_up.hide()
	join_lobby_menu.hide()
	# connect to events from child objects
	chat.chat_message_queued.connect(_handle_chat_message_queued)
	chat.user_started_typing.connect(_on_user_started_typing)
	chat.user_finished_typing.connect(_on_user_finished_typing)
	
	main_menu.play_offline_pressed.connect(_start_singleplayer)
	main_menu.host_lobby_pressed.connect(_start_host_lobby)
	main_menu.join_lobby_pressed.connect(_start_join_lobby)
	
	networker.upnp_setup_startup.connect(_on_hosting_started)
	networker.upnp_setup_completed.connect(_on_hosting_ready)
	networker.player_connected.connect(_give_character_to_player)
	networker.player_disconnected.connect(world.remove_player)
	
	join_lobby_menu.join_lobby.connect(_on_join_lobby_pressed)
	join_lobby_menu.cancel_join_lobby.connect(_cancel_join_lobby)
	
	gui.emote_button_pressed.connect(_on_emote_button_pressed)
	
func _process(_delta: float) -> void:
	_handle_actions()
	
func _on_emote_button_pressed(emote_name: String):
	local_player._play_emote(emote_name)
	
func _handle_actions():
	if Input.is_action_just_pressed("ui_cancel") and game_stage == GAME_STAGE.PLAYING:
		options_menu.visible = not options_menu.visible
		gui.visible = not gui.visible

func _handle_chat_message_queued(message):
	chat._Add_Message.rpc(profile.username, message)

func _on_user_started_typing():
	local_player._pause_input()

func _on_user_finished_typing():
	local_player._resume_input()

func _enter_playing_game_stage():
	main_menu.hide()
	options_menu.hide()
	join_lobby_menu.hide()
	blocker_pop_up.hide()
	gui.show()
	gui._load_profile(profile)
	game_stage = GAME_STAGE.PLAYING
	
	# tie our player to their instanced character
	
func _start_host_lobby():
	networker._host_game()

func _start_join_lobby():
	main_menu.hide()
	options_menu.hide()
	join_lobby_menu.show()
	
func _cancel_join_lobby():
	main_menu.show()
	options_menu.show()

func _on_hosting_started():
	blocker_pop_up.show()
	
# functions that start playing the game
	
func _start_singleplayer():
	_give_character_to_player()
	_enter_playing_game_stage()
	
# TODO - Add error handling here to return to menu if something fails.
#		and show an error pop-up saying something like: "Failed to Connect to Host: <reason>"
func _on_hosting_ready(_err):
	blocker_pop_up.hide()
	main_menu.hide()
	options_menu.hide()
	_give_character_to_player()
	_enter_playing_game_stage()
		
func _on_join_lobby_pressed(ipAddress: String, portAddress: String):
	networker._join_game(ipAddress, portAddress)
	_give_character_to_player()
	_enter_playing_game_stage()
	
func _give_character_to_player(peerId: int = -2):
	var unique_id = peerId
	
	if unique_id < Helper._INVALID_PEER_ID: 
		unique_id = multiplayer.get_unique_id()

	var character = world.add_player(unique_id, profile._get_selected_character_json_filepath())
	
	if local_player.peer_id == null:
		local_player.peer_id = unique_id
		local_player.name = str(unique_id)
		local_player.set_multiplayer_authority(unique_id)
		local_player._assign_character(character)
