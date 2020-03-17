extends Area

var picked = false

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")

func _process(delta):
	if picked:
		queue_free()

func _on_AmmoPack_body_entered(body):
	if body.is_in_group("Player"):
		body.ammo = 10
		picked = true
		rpc("picked", picked)

remotesync func picked(status):
	picked = status

func _on_network_peer_connected(id):
	rpc("picked", picked)
