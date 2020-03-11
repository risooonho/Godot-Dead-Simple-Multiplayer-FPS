extends Spatial

#	for b in 6:
#		var bot = bot_scene.instance()
#		world.get_node("bots").add_child(bot)
#		bot.global_transform.origin = game.spawn_points[randi() % game.spawn_points.size()].global_transform.origin
#		bot.name = str(world.get_node("bots").get_children().size())
#		bots.push_back(bot.name)

# Called when the node enters the scene tree for the first time.
#func _ready():
#	print($SpawnPoints.get_children().size())
#	print(   randi()% 4    )
#	print($SpawnPoints.get_child(0))


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	print( randi()% $SpawnPoints.get_children().size() + 1  )
#	print(   randi()% ($SpawnPoints.get_children().size() -1)    )
#	print( rand_range(0,$SpawnPoints.get_children().size() -1)   )
