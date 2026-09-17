# =============================================================================
# 
# Script written by Roadside Games (Modified for manual trigger & bug fixes)
# 
# This script is completely free to use, modify, and distribute.
# No attribution required, though it's always appreciated!
# 
# =============================================================================
extends ColorRect

# ===================================================
# VARIABLES
# ===================================================
@export_category("Zoom Settings")
@export var zoom_start: float = 2.0
@export var zoom_end: float = 0.001 
@export var zoom_tween_type: Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var zoom_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT

@export_category("Center Settings")
@export var center_start: Vector2 = Vector2(0.5, 0.3)
@export var center_end: Vector2 = Vector2(0.5, 0.5)
@export var center_tween_type: Tween.TransitionType = Tween.TransitionType.TRANS_BOUNCE
@export var center_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT

@export_category("Strength Settings")
@export var strength_start: float = 1.0 
@export var strength_end: float = 0.0
@export var strength_tween_type: Tween.TransitionType = Tween.TransitionType.TRANS_EXPO
@export var strength_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT

@export_category("Duration Settings")
@export var duration_in: float = 0.75     # MODIFICATO: Più veloce a chiudersi (era 1.6)
@export var duration_out: float = 0.75    # MODIFICATO: Più veloce a riaprirsi (era 1.6)
@export var await_time: float = 0.2      # MODIFICATO: Ridotto il tempo di attesa a schermo nero (era 1.0)

var _tween: Tween

# ===================================================
# INITIALIZATION
# ===================================================
func _ready() -> void:
	size = get_viewport_rect().size
	z_index = 1000 
	mouse_filter = MOUSE_FILTER_IGNORE 
	
	visible = false
	_set_shader_values(strength_start, zoom_start, center_start)

# ===================================================
# TWEENING IN AND OUT
# ===================================================
func fade_in() -> void:
	visible = true 
	_set_shader_values(strength_start, zoom_start, center_start)
	
	if _tween:
		_tween.kill()
		
	_tween = create_tween()
	_tween.parallel().tween_method(_shader_value_progress, strength_start, strength_end, duration_in).set_trans(strength_tween_type).set_ease(strength_ease_type)
	_tween.parallel().tween_method(_shader_value_zoom, zoom_start, zoom_end, duration_in).set_trans(zoom_tween_type).set_ease(zoom_ease_type)
	_tween.parallel().tween_method(_shader_value_center, center_start, center_end, duration_in).set_trans(center_tween_type).set_ease(center_ease_type)
	_tween.tween_callback(fade_out)
	_tween.play()

func fade_out() -> void:
	await get_tree().create_timer(await_time).timeout
	
	_set_shader_values(strength_end, zoom_end, center_end)
	
	if _tween:
		_tween.kill()
		
	_tween = create_tween()
	_tween.parallel().tween_method(_shader_value_progress, strength_end, strength_start, duration_out).set_trans(strength_tween_type).set_ease(strength_ease_type)
	_tween.parallel().tween_method(_shader_value_zoom, zoom_end, zoom_start, duration_out).set_trans(zoom_tween_type).set_ease(zoom_ease_type)
	_tween.parallel().tween_method(_shader_value_center, center_end, center_start, duration_out).set_trans(center_tween_type).set_ease(center_ease_type)
	
	_tween.tween_callback(func(): visible = false)
	_tween.play()

# ===================================================
# SHADER CALLBACK METHODS
# ===================================================
func _shader_value_progress(value: float) -> void:
	if material:
		material.set_shader_parameter("strength", value)

func _shader_value_zoom(value: float) -> void:
	if material:
		material.set_shader_parameter("zoom", value)

func _shader_value_center(value: Vector2) -> void:
	if material:
		material.set_shader_parameter("center", value)

func _set_shader_values(strength_value: float, zoom_value: float, center_value: Vector2) -> void:
	if material:
		material.set_shader_parameter("strength", strength_value)
		material.set_shader_parameter("zoom", zoom_value)
		material.set_shader_parameter("center", center_value)
