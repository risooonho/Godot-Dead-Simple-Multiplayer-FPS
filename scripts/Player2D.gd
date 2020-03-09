extends Sprite

func _ready():
	var is_me = name == str( get_tree().get_network_unique_id() )
	set_physics_process(is_me) # Keyboard inputs settings allowed

	rset_config("transform", MultiplayerAPI.RPC_MODE_REMOTE)

func _physics_process(delta):
	if Input.is_action_pressed("left"):
		position.x -= 10
	
	if Input.is_action_pressed("right"):
		position.x += 10
	
	rset_unreliable("transform", transform)
	
