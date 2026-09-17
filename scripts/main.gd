extends Node2D

@onready var popup: Panel = $CanvasLayer/Popup
@onready var popup_label: Label = $CanvasLayer/Popup/PopupLabel
@onready var anim: AnimationPlayer = $CanvasLayer/Popup/AnimationPlayer
@onready var timer: Timer = $Timer

## Scena del menu principale a cui tornare dopo il popup.
@export_file("*.tscn") var next_scene: String = "res://scenes/MainMenu.tscn"

## Quanto resta visibile il popup prima di sparire e cambiare scena.
@export var popup_duration: float = 3.0


func _ready() -> void:
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)
	popup.pivot_offset = popup.size / 2.0

	if Global.popup_message != "":
		popup_label.text = Global.popup_message
		Global.popup_message = ""  # consumato, evita che riappaia se si ritorna qui
		_play_sequence()
	else:
		# Nessun messaggio: vai dritto al menu senza mostrare nulla.
		get_tree().change_scene_to_file(next_scene)


func _play_sequence() -> void:
	anim.play("popup_in")
	await anim.animation_finished

	timer.wait_time = popup_duration
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


func _on_timer_timeout() -> void:
	anim.play("popup_out")
	await anim.animation_finished
	get_tree().change_scene_to_file(next_scene)
