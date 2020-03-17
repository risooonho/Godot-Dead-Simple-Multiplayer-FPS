extends KinematicBody

var mute = false

var speed = 6.5
var movement = Vector3()
var jump_force = 5
var mouse_sensitivity = 1

var health = 100
var ammo = 10
var score = 0

puppet var puppet_transform = transform
puppet var puppet_camera_angle : float

var impact_scene = "res://scenes/Impact.tscn"
var bullet_scene = "res://scenes/Bullet.tscn"

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	yield(get_tree().create_timer(0.01), "timeout")
	var is_master = is_network_master()
	
	$Camera/RayCast.enabled = is_master
	$Camera.current = is_master
	$HUD.visible = is_master
	$Camera/HeadOrientation.visible = !is_master

	$HUD/Ammo.text = str(ammo)

func _physics_process(delta):
	if is_network_master():
		$HUD/Ammo.text = str(ammo)
		
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
		
		rset_unreliable("puppet_transform", transform)
		rset_unreliable("puppet_camera_angle", $Camera.rotation_degrees.x)
#		rpc_unreliable("flashlight", $Camera/FlashLight.visible)
		
		if health <= 0:
			rpc("restore_health")
			$HUD/Health.text = str(health)
			global_transform = Network.spawn_node.global_transform
			movement.y = 0
	else:
		transform = puppet_transform
		$Camera.rotation_degrees.x = puppet_camera_angle
		pass
# Mouse movements to look arround ==============================================

func _input(event):
	
	if is_network_master():
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation_degrees.y -= event.relative.x * mouse_sensitivity / 10
				$Camera.rotation_degrees.x -= event.relative.y * mouse_sensitivity / 10
				$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)

func other_abilities():
	
	if Input.is_action_just_pressed("mute"):
		mute = !mute
		AudioServer.set_bus_mute(0, mute)
	
	if ammo > 0:
		if Input.is_action_just_pressed("shoot"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			ammo -= 1
			$HUD/Ammo.text = str(ammo)
			rpc("play_sound")
			
			rpc("bullet", $Camera/BulletPosition.global_transform, $Camera/BulletPosition.global_transform.basis.z)
			rpc("bullet_light")
			if $Camera/RayCast.is_colliding():
				var target = $Camera/RayCast.get_collider()
				rpc("impact", $Camera/RayCast.get_collision_point())
				
				if target.has_method("damage"):
					target.rpc_unreliable("damage", 25)
					if target.health < 25:
						score += 1
						$HUD/Score.text = "Score: " + str(score)
						rpc("update_score", score)
		
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("flashlight"):
		$Camera/FlashLight.visible = !$Camera/FlashLight.visible
		rpc("flashlight", $Camera/FlashLight.visible)

func _on_network_peer_connected(id):
	rpc("flashlight", $Camera/FlashLight.visible)

remotesync func flashlight(status):
	$Camera/FlashLight.visible = status

remotesync func restore_health():
	health = 100

remotesync func impact(impact_position):
	var impact_instance = load(impact_scene).instance()
	get_tree().get_root().get_node("Map").add_child(impact_instance)
	impact_instance.global_transform.origin = impact_position
	yield(get_tree().create_timer(1), "timeout")
	impact_instance.queue_free()

remotesync func damage(amount):
	health -= amount
	$HUD/Health.text = str(health)

remotesync func play_sound():
	$Camera/ShootSound.play()

remotesync func bullet(emitter, direction):
	var bullet_instance = load(bullet_scene).instance()
	
	get_tree().get_root().get_node("Map").add_child(bullet_instance)
	bullet_instance.global_transform = emitter
	bullet_instance.linear_velocity = direction * - 500
	yield(get_tree().create_timer(2), "timeout")
	bullet_instance.queue_free()

remotesync func bullet_light():
	$Camera/BulletLight.visible = true
	yield(get_tree().create_timer(0.05), "timeout")
	$Camera/BulletLight.visible = false

remotesync func update_score(ennemy_new_score):
	score = ennemy_new_score
