extends Node3D
class_name World

@export var playerPrefab: PackedScene

func add_player(peer_id, jsonFilePath: String) -> Character:
	var player: Character = playerPrefab.instantiate() as Character
	player.peer_id = peer_id
	player.json_file_path = jsonFilePath
	player.name = str(peer_id)
	add_child(player, true)
	return player
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
