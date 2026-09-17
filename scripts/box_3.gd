extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var i=0

func _physics_process(delta: float) -> void:
	i+=1
	if i == 100:
		queue_free()

	move_and_slide()
