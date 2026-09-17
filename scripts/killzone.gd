extends Area2D

@onready var morte: AudioStreamPlayer2D = $morte
var checpoint_manager
@onready var player: CharacterBody2D = $"../Player"

@onready var death_effect: ColorRect = $CanvasLayer/ColorRect


func _on_body_entered(body: Node2D) -> void:
	morte.play()

	# Avvia l'effetto
	death_effect.fade_in()

	# Aspetta che l'effetto finisca
	await get_tree().create_timer(
		death_effect.duration_in +
		death_effect.await_time +
		death_effect.duration_out
	).timeout

	print("you died!")

	Global.vita = 3
	Global.money = 0
	Global.gomitolo = false
	Global.magnete=false
	Global.box = false
	Global.MoneteCorrenti = 0

	get_tree().reload_current_scene()
