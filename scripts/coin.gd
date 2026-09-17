extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if sprite == null:
		push_error("Sprite2D non trovato! Controlla il nome del nodo nella Scena.")
		return

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/color_band.gdshader")
	# Colore oro (#ffd700) con opacità al 70%
	var base_color := Color("#ffd700")
	base_color.a = 0.7
	
	mat.set_shader_parameter("band_color",     base_color)
	mat.set_shader_parameter("scroll_speed",   2.0) # Leggermente più veloce per dare brillantezza
	mat.set_shader_parameter("band_width",     0.12)
	mat.set_shader_parameter("band_angle",     0.6)
	mat.set_shader_parameter("glow_intensity", 1.8) # Intensità dorata aumentata
	sprite.material = mat

func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if Global.vita <= 0:
		Global.money = 0
		Global.MoneteCorrenti = 0
	else:
		if area.name == "raccoglimonete":
			Global.money += 1
			Global.MoneteCorrenti += 1
			
			if animation_player and animation_player.has_animation("pick-up"):
				animation_player.play("pick-up")

			# Dissolvenza dello sprite senza ingrandimento
			var tween := create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
			tween.tween_callback(queue_free)
