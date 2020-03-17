extends Area

func _on_Area_body_entered(body):
	if body.is_in_group("Player"):
		$OmniLight.visible = true

func _on_Area_body_exited(body):
	if body.is_in_group("Player"):
		$OmniLight.visible = false
