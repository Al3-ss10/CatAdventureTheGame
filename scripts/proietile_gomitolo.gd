
extends Area2D

@onready var test: Marker2D = $test
@onready var spawn_gomitolo: Marker2D = $SpawnGomitolo
@onready var proietile_gomitolo: Area2D = $"."




@onready var rx: RayCast2D = $rx
@onready var up: RayCast2D = $up
@onready var lx: RayCast2D = $lx
@onready var down: RayCast2D = $down


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var dirY=1
var i := 1
var direction := 0
var x := 100
var tempo =0
var count=0
var dirX=1
var VelX=160
var vely=VelX*1.15
var t=1 
func _process(delta: float) -> void:
	if count==0:
		dirX = Global.direction
		count+=1
	else: pass
	if i < 150:
		VelX=0.997*VelX
		vely=0.99*vely
		position.x += VelX * delta * dirX
		if dirY==1:
			position.y += (100+0.5*t*t)*delta
			
		elif dirY==-1:
			position.y += 0.5*t*t*delta-vely*delta
		i += 1
		t+=1

	else:
		queue_free()
		
	if down.is_colliding():
		dirY=-1
		t=1

	if up.is_colliding():

		dirY=1
		t=4

	if rx.is_colliding():
		dirX=-1
		
	if lx.is_colliding():
		dirX=1
		
	if dirX==1:
		animated_sprite_2d.flip_h=false
	elif dirX==-1:
		animated_sprite_2d.flip_h=true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemy'):
		if body.has_method("Morte"):
			body.Morte()
		




	
