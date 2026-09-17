extends CharacterBody2D

const SPEED: float = 160.0
const JUMP_VELOCITY: float = -250.0
const MAX_JUMPS: int = 2

const FIRE_COOLDOWN_FRAMES: int = 60

var jump_count: int = 0
var tempo: int = 0
var facing_dir: int = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn: Marker2D = $Spawn
@onready var RaccogliMonete: CollisionShape2D = $raccoglimonete/CollisionShape2D


func _ready() -> void:
	print("[PLAYER LOADED] Skin selezionata?: ", Global.skin.get("selected", false))
	print("[PLAYER LOADED] Tipo skin: '", Global.skin.get("type", ""), "'")


func _physics_process(delta: float) -> void:
	if not Global.magnete:
		if RaccogliMonete and RaccogliMonete.shape:
			RaccogliMonete.shape.radius = 7
	else:
		if RaccogliMonete and RaccogliMonete.shape:
			RaccogliMonete.shape.radius = 45

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0

	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	Global.tempo2 += 1
	tempo += 1

	var axis := Input.get_axis("move_left", "move_right")
	Global.direction = axis

	if axis != 0:
		var new_facing := int(signf(axis))
		if new_facing != facing_dir:
			facing_dir = new_facing
			animated_sprite.flip_h = (facing_dir < 0)

	var base_anim := ""
	if is_on_floor():
		if axis == 0.0:
			base_anim = "idle"
		else:
			base_anim = "run"
	else:
		base_anim = "jump"

	var suffix := get_active_skin_suffix()
	play_anim(base_anim, suffix)

	if axis != 0.0:
		velocity.x = axis * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	if Input.is_action_just_pressed("Gomitolo") and Global.gomitolo and Global.tempo2 > (FIRE_COOLDOWN_FRAMES - 20):
		spara_gomitolo()
		Global.tempo2 = 0

	if Input.is_action_just_pressed("Box") and Global.box and tempo > FIRE_COOLDOWN_FRAMES:
		Spawn_box()
		tempo = 0

func get_active_skin_suffix() -> String:
	var is_selected: bool = Global.skin.get("selected", false)
	
	# 1. Se hai selezionato una skin nel negozio, usi sempre quella
	if is_selected:
		var type_str: String = str(Global.skin.get("type", "")).strip_edges().to_lower()
		if type_str != "" and type_str != "default":
			return type_str
		return ""
	
	# 2. Se hai scelto "Deseleziona", il personaggio assume la skin del power-up attivo
	if Global.magnete:
		return "magnete"
	elif Global.box:
		return "box"
	elif Global.gomitolo:
		return "gomitolo"
		
	# 3. Se non hai né skin selezionate né power-up attivi, usi la default
	return ""
func play_anim(base_anim: String, suffix: String) -> void:
	var anim_name := base_anim
	if suffix != "":
		anim_name = "%s_%s" % [base_anim, suffix]

	var frames := animated_sprite.sprite_frames
	
	if frames != null and not frames.has_animation(anim_name):
		anim_name = base_anim

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play(anim_name)


func spara_gomitolo() -> void:
	var vatia: PackedScene = load("res://scenes/proietile_gomitolo.tscn")
	if vatia == null:
		return
	var drop_instance: Node2D = vatia.instantiate()

	var parent := get_parent()
	parent.add_child(drop_instance)

	if is_instance_valid(spawn):
		drop_instance.global_position = spawn.global_position
	else:
		drop_instance.global_position = global_position

	Global.direction = facing_dir


func Spawn_box() -> void:
	var vatia: PackedScene = load("res://scenes/box2.tscn")
	if vatia == null:
		return
	var drop_instance: Node2D = vatia.instantiate()

	var parent := get_parent()
	parent.add_child(drop_instance)

	drop_instance.global_position = global_position + Vector2(0, 20)
