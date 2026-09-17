extends Node2D

@onready var coppa: Area2D = $fine




func _ready() -> void:
	Global.MoneteCorrenti = 0
	var vatia = load("res://scenes/scarafaggio.tscn")
	var drop_instance = vatia.instantiate()
	drop_instance.position = Vector2(420.0, -2)
	get_parent().add_child(drop_instance)
	drop_instance.morto.connect(_on_nemico_morto)
	


func _on_nemico_morto() -> void:
	coppa.morto=true
