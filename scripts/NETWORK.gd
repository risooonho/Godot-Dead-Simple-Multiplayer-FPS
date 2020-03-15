extends Node

const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 4242
const MAX_PLAYERS = 32

var map_scene = "res://scenes/Map.tscn"
var player_scene = "res://scenes/Player2D.tscn"
var lobby_scene = "res://scenes/Lobby.tscn"

var spawn_node = null

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	load_game()

func join_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().set_network_peer(peer)
	
	load_game()

func load_game():
	get_tree().change_scene(map_scene)

	# Wait for the map to load, then search for the SpawnPoint node
	yield(get_tree().create_timer(0.01), "timeout")
	spawn_node = get_tree().get_root().find_node("SpawnPoint", true, false)

	# If this is not the host, spawn the player locally
	if not get_tree().is_network_server():
		spawn_player( get_tree().get_network_unique_id() )

func spawn_player(id):
	var player_instance = load(player_scene).instance()
	player_instance.name = str(id) # The node name is now the id
	spawn_node.add_child(player_instance)
	player_instance.set_network_master(id)

func _on_network_peer_connected(id):
	if id != 1: # Do not spawn from the signal of the host connected (id = 1)
		spawn_player(id)

func _on_network_peer_disconnected(id):
	get_tree().get_root().find_node(str(id), true, false).queue_free()

func _on_server_disconnected():
	get_tree().set_network_peer(null) # Sends a network_peer_disconnected signal
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene(lobby_scene)
