extends Sprite

func _ready():
	# Check if the name is the same as the id to allow local control:
	var is_me = name == str( get_tree().get_network_unique_id() )
	set_physics_process(is_me) # Keyboard inputs settings allowed or not
	
	# Data sent remotely:
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTE)

func _physics_process(delta):
	if Input.is_action_pressed("left"):
		position.x -= 10
	
	if Input.is_action_pressed("right"):
		position.x += 10
	
	# The data to send each frame:
	rset_unreliable("position", position)
