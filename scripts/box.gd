extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if sprite == null:
		push_error("Sprite2D non trovato! Controlla il nome del nodo nella Scena.")
		return

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/color_band.gdshader")
	var base_color := Color("#4da6ff")
	base_color.a = 0.7
	
	mat.set_shader_parameter("band_color", base_color)
	mat.set_shader_parameter("scroll_speed", 1.8)
	mat.set_shader_parameter("band_width", 0.10)
	mat.set_shader_parameter("band_angle", 0.6)
	mat.set_shader_parameter("glow_intensity", 1.4)
	sprite.material = mat


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('protagonista'):
		if Global.box:
			Global.ListaPowerUp['scatola'] += 1
		if Global.gomitolo:
			Global.gomitolo = false
		if Global.magnete:
			Global.magnete = false
		Global.box = true

		# Sblocca solo la skin nel negozio senza selezionarla forzatamente
		Global.skin_sbloccate['box'] = true

		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
