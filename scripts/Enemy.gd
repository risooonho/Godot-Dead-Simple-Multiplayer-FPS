extends KinematicBody

var player = null
var distance = 999
var get_distance = 999
var vector = Vector3()

var agro = null

puppet var puppet_transform = null


func _ready():
	set_network_master(1)

func _process(delta):
	if is_network_master():
		for i in get_tree().get_nodes_in_group("Player").size():
			player = get_tree().get_nodes_in_group("Player")[i]
			vector = player.global_transform.origin - global_transform.origin
			get_distance = vector.length()
			if get_distance < distance:
				agro = player
	
		if agro:
			look_at(agro.global_transform.origin, Vector3.UP)
		move_and_slide(vector/2)
		rset_unreliable("puppet_transform", transform)
	else:
		transform = puppet_transform
		
func set_player(p):
	player = p
