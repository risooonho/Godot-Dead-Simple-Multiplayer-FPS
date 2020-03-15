extends KinematicBody

var speed = 6.5
var movement = Vector3()
var jump_force = 5
var mouse_sensitivity = 1

var health = 100

puppet var slave_transform
puppet var slave_camera_angle
puppet var slave_light

func _ready():
	yield(get_tree().create_timer(0.01), "timeout")
	var is_master = is_network_master()
	
	$Camera/RayCast.enabled = is_master
	$Camera.current = is_master
	$HUD.visible = is_master
	$Camera/HeadOrientation.visible = !is_master

func _physics_process(delta):
	if is_network_master():
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
		
		other_abilities()
		
		rset_unreliable("slave_transform", transform)
		rset_unreliable("slave_camera_angle", $Camera.rotation_degrees.x)
		rset("slave_light", $Camera/FlashLight.visible)
		if health <= 0:
			health = 100
			global_transform = Network.spawn_node.global_transform
	else:
		transform = slave_transform
		$Camera.rotation_degrees.x = slave_camera_angle
		$Camera/FlashLight.visible = slave_light
# Mouse movements to look arround ==============================================

func _input(event):
	
	if is_network_master():
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation_degrees.y -= event.relative.x * mouse_sensitivity / 10
				$Camera.rotation_degrees.x -= event.relative.y * mouse_sensitivity / 10
				$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)

func other_abilities():
	if Input.is_action_just_pressed("shoot"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		if $Camera/RayCast.is_colliding():
			var target = $Camera/RayCast.get_collider()
			
			if target.has_method("damage"):
				target.rpc_unreliable("damage", 25)
		
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("flashlight"):
		$Camera/FlashLight.visible = !$Camera/FlashLight.visible

remotesync func damage(amount):
	health -= amount
	$HUD/Health.text = str(health)
