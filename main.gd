extends Node

var steam_peer : SteamMultiplayerPeer
var use_steam := false

var enet_peer := ENetMultiplayerPeer.new()
var PORT := 9999
var IP_ADDRESS := '127.0.0.1'

@onready var main_menu: VBoxContainer = %MainMenu
@onready var lobby_list: VBoxContainer = %LobbyList
@onready var button_join: Button = %ButtonJoin
@onready var button_host: Button = %ButtonHost
@onready var player_spawner: MultiplayerSpawner = %PlayerSpawner

const PLAYER = preload("uid://bmh4v78n5n038")

func _ready() -> void:
	button_host.pressed.connect(host)
	button_join.pressed.connect(join)
	if use_steam:
		_ready_steam()
	
func host():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(1)
	main_menu.hide()
	if use_steam == false:
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
	else:
		host_steam()
		
		
func join():
	multiplayer.connected_to_server.connect(func(): main_menu.hide())
	if use_steam == false:
		enet_peer.create_client(IP_ADDRESS, PORT)
		multiplayer.multiplayer_peer = enet_peer
	else:
		get_friends_in_lobbies()


func add_player(peer_id: int):
	var new_player = PLAYER.instantiate()
	new_player.name = str(peer_id)
	
	var rand_x = randf_range(-5.0, 5.0)
	var rand_z = randf_range(-5.0, 5.0)

	new_player.position = Vector3(rand_x, 1.0, rand_z)
	player_spawner.add_child(new_player, true)

func remove_player(peer_id: int):
	for spawn_child in player_spawner.get_children():
		if spawn_child.name == str(peer_id):
			spawn_child.queue_free()

func _ready_steam():
	var is_steam_init = Steam.steamInit(480, true) # 480 SPACEWAR
	if is_steam_init == false:
		push_warning("Steam not init, did you forget to sign in?")
	else:
		prints("Steam is init:", is_steam_init)
		Steam.initRelayNetworkAccess()
		steam_peer = SteamMultiplayerPeer.new()
		steam_peer.server_relay = true
		button_join.text = 'Refresh'

func get_friends_in_lobbies():
	lobby_list.get_children().all(func(node: Node): node.queue_free())
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)
		
		if game_info and game_info.id == Steam.getAppID() and game_info.lobby != 0:
			var new_button = Button.new()
			new_button.text = Steam.getFriendPersonaName(steam_id)
			new_button.add_theme_font_size_override('font-size', 24)
			new_button.pressed.connect(join_steam.bind(game_info.lobby))
			lobby_list.add_child(new_button)
		
func join_steam(lobby_id: int):
	Steam.joinLobby(lobby_id)
	Steam.lobby_joined.connect(on_steam_joined)
		
func host_steam():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC)
	Steam.lobby_created.connect(on_steam_created)
	
func on_steam_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int):
	steam_peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = steam_peer

func on_steam_created(result: int, _lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		steam_peer.create_host()
		multiplayer.multiplayer_peer = steam_peer
