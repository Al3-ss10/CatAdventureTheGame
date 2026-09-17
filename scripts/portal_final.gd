extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("protagonista") and Global.money >= 15:
		body.set_position($DestinationPortal.global_position)
