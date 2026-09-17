extends Area2D

@onready var polpetta: Area2D = $"."
@onready var nemico: Node2D = $"."

var random = 0

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	randomize()
	random= randi() % 3
	
	if body.is_in_group("protagonista"):
		release_drop()
		queue_free() 
		

func release_drop():
	if polpetta:
		if random == 0:
			var vatia = load("res://scenes/polpetta.tscn")
			var drop_instance = vatia.instantiate()
			drop_instance.position = position  # lo fa spawnare dove si trova l’oggetto
			get_parent().add_child(drop_instance)
		else:
			var vatia = load("res://scenes/coin.tscn")
			var drop_instance = vatia.instantiate()
			drop_instance.position = position  # lo fa spawnare dove si trova l’oggetto
			get_parent().add_child(drop_instance)
		
#
