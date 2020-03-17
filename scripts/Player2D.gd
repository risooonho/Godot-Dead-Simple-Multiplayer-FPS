extends Sprite

puppet var puppet_position = Vector2()

func _physics_process(delta):
	if is_network_master():
		if Input.is_action_pressed("left"):
			position.x -= 10
		
		if Input.is_action_pressed("right"):
			position.x += 10
		
		# The data to send each frame:
		rset_unreliable("puppet_position", position)
	else:
		position = puppet_position
