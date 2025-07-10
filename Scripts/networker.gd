extends Control
class_name Networker

@export var serverAddressLabel: Label

var validPortRange = Vector2(8008, 8108)
var publicIp = ""
var port = -1
var thread = null
var upnp = null
var peer = ENetMultiplayerPeer.new()

# Emitted when UPnP port mapping setup is completed (regardless of success or failure).
signal upnp_setup_startup
signal upnp_setup_completed(error)

signal player_connected
signal player_disconnected

func _ready():
	# Prompts user for access to network on game boot
	peer.create_server(validPortRange.x)
	peer.close()

func _start_threaded_upnp():
	# Universal Plug-n-play blocks the main thread. Creating new thread to run discovery operation.
	# https://docs.godotengine.org/en/stable/classes/class_upnp.html
	thread = Thread.new()
	thread.start(_upnp_setup.bind(validPortRange))

func _upnp_setup(portRange):
	# UPNP queries take some time.
	upnp = UPNP.new()
	var err = upnp.discover()
	
	if not err == UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
		print("Discovery failed. ", err)
		call_deferred("_on_thread_done", err)
		return 

	var gateway = upnp.get_gateway()
	var gatewayIsValid = gateway.is_valid_gateway()

	if gateway and gatewayIsValid:
		var SUCCESS = 0 # https://docs.godotengine.org/en/stable/classes/class_upnp.html#enum-upnp-upnpresult
		var successUDP
		var successTCP
		for possiblePort in range(portRange.x, portRange.y):
			var prt = int(possiblePort)
			successUDP = upnp.add_port_mapping(prt, prt, ProjectSettings.get_setting("application/config/name"), "UDP")
			successTCP = upnp.add_port_mapping(prt, prt, ProjectSettings.get_setting("application/config/name"), "TCP")
			
			if successTCP == SUCCESS and successUDP == SUCCESS:
				port = prt
				break
			else:
				# If either mapping fails, clean up that port just in case
				upnp.delete_port_mapping(prt, "UDP")
				upnp.delete_port_mapping(prt, "TCP")
			
		if port > -1:
			publicIp = gateway.query_external_address()
		
	if port < 0:
		err = {code = 1, message = "Failed to find open port"}
		
	call_deferred("_on_upnp_setup_thread_done", err)

func _on_upnp_setup_thread_done(err):
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.connect("peer_connected", func (p_id): player_connected.emit(p_id))
	multiplayer.connect("peer_disconnected", func (p_id): player_disconnected.emit(p_id))
	
	serverAddressLabel.text = str(publicIp, ":", port)
	
	upnp_setup_completed.emit(err)

func _host_game():
	upnp_setup_startup.emit()
	_start_threaded_upnp()

func _join_game(ip: String, prt: String):
	peer.create_client(ip, str(prt).to_int())
	multiplayer.multiplayer_peer = peer
	serverAddressLabel.text = str(ip, ":", prt)

func _exit_tree():
	# Wait for thread finish here to handle game exit while the thread is running.
	# this method combines our side-thread into the main one. Meaning it will conclude its
	# operation here.
	# https://docs.godotengine.org/en/stable/classes/class_thread.html
	if thread and thread.is_alive():
		thread.wait_to_finish()
	
	# stop port forwarding
	if upnp:
		upnp.delete_port_mapping(port, "UDP")
		upnp.delete_port_mapping(port, "TCP")
	
	if peer:
		peer.close()
