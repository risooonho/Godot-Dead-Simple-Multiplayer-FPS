extends KinematicBody

var speed = 6.5
var movement = Vector3()
var jump_force = 5
var mouse_sensitivity = 1

var impact_scene = "res://scenes/Impact.tscn"

var health = 100

# Initialize the node, check if we can control it by comparing his name and my id

func _ready():
	# If the name of this instanced node is the same as the client id we can control it
	var is_me = name == str( get_tree().get_network_unique_id() )
	set_physics_process(is_me) # Keyboard inputs settings allowed
	set_process_input(is_me) # Mouse vision allowed

	# Setup nodes:
	$Camera/RayCast.enabled = is_me
	$Camera.current = is_me
	$HUD.visible = is_me
	$Camera/HeadOrientation.visible = !is_me

	# Data activated to send remotely:
	rset_config("transform", MultiplayerAPI.RPC_MODE_REMOTE)
	$Camera.rset_config("rotation", MultiplayerAPI.RPC_MODE_REMOTE)

# Data sent from this node if the physics_process and process_input are active =

func send_data(): # Data sent each frame to other games to sync the game
	rset_unreliable("transform", transform)
	$Camera.rset_unreliable("rotation", $Camera.rotation)

# Keyboard inputs, gravity and movement ========================================

func _physics_process(delta):
	# Controls from user inputs, set in 2D to normalize the direction
	var direction_2D = Vector2()
	direction_2D.y = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	direction_2D.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction_2D = direction_2D.normalized()
	
	# 2D direction normalized added to Vector3 to apply gravity and jump
	movement.z = direction_2D.y * speed
	movement.x = direction_2D.x * speed
	movement.y -= 9.8 * delta
	
	movement = movement.rotated(Vector3.UP, rotation.y)
	
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			movement.y = jump_force
	
	movement = move_and_slide(movement, Vector3.UP)
	if health <= 0:
		Network.leave_game()
	other_abilities()
	send_data()

# Mouse movements to look arround ==============================================

func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation_degrees.y -= event.relative.x * mouse_sensitivity / 10
			$Camera.rotation_degrees.x -= event.relative.y * mouse_sensitivity / 10
			$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)

# Show the mouse with escape, capture it with right click ======================

func other_abilities():
	if Input.is_action_just_pressed("shoot"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		
		if $Camera/RayCast.is_colliding():
			var target = $Camera/RayCast.get_collider()
			
			if target.has_method("damage"):
				target.rpc_unreliable("damage", 25)
			
			var impact_instance = load(impact_scene).instance()
			get_tree().get_root().add_child(impact_instance)
			impact_instance.global_transform.origin = $Camera/RayCast.get_collision_point()
			yield(get_tree().create_timer(0.5), "timeout")
			impact_instance.queue_free()
		
		
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

remotesync func damage(amount):
	health -= amount
	$HUD/Health.text = str(health)
