extends Node2D

# --- Segnali ---
signal morto_signal

var SPEED = 20
var direction = 1
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_up: RayCast2D = $RayCastUp
@onready var nemico: RigidBody2D = $"."
@onready var uccisione: AudioStreamPlayer2D = $uccisione
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var nascita_eseguita = false
var pavimento = 0
var morte = 0

# --- Variabili per il salto/planata ---
@export var velocita_salto: float = -300.0      # velocità verticale iniziale della salita (negativo = su)
@export var gravita_salita: float = 600.0       # decelerazione durante la salita
@export var durata_planata: float = 1.0         # secondi impiegati per planare dal picco fino al punto target

enum FaseSalto { NESSUNA, SALITA, PLANATA }
var fase_salto: FaseSalto = FaseSalto.NESSUNA
var velocita_verticale: float = 0.0
var giocatore: Node2D = null
var tween_planata: Tween = null
var layer_originale: int = 0
var mask_originale: int = 0
var immune_da_alto: bool = false
@export var durata_immunita_post_planata: float = 0.5  # secondi di immunità dal RayCastUp dopo l'atterraggio
@export var cooldown_salto: float = 3.0  # secondi minimi tra un salto e il successivo
var in_cooldown_salto: bool = false

func nascita():
	if nascita_eseguita == false:
		SPEED = 0
		animated_sprite_2d.play("nascita")
		await animated_sprite_2d.animation_finished
		SPEED = 20
		animated_sprite_2d.play("default")
		nascita_eseguita = true
	else:
		pass

func Morte():
	morto_signal.emit() # Emette il segnale quando il nemico muore
	animated_sprite_2d.play("morte")
	SPEED = 0
	uccisione.play()
	await animated_sprite_2d.animation_finished
	queue_free()
	Global.flag = true

# Funzione pubblica che un altro nemico può chiamare per forzarci a invertire
func inverti_direzione_forzata():
	direction *= -1
	animated_sprite_2d.flip_h = direction == -1

# --- Collegata al segnale body_entered dell'Area2D "salto" ---
func _on_salto_body_entered(body: Node2D) -> void:
	if fase_salto != FaseSalto.NESSUNA or in_cooldown_salto:
		return
	if body.is_in_group("protagonista"):
		giocatore = body
		_inizia_salto()

func _inizia_salto() -> void:
	fase_salto = FaseSalto.SALITA
	velocita_verticale = velocita_salto
	if nemico != null:
		nemico.freeze = true
		nemico.gravity_scale = 0.0
		nemico.linear_velocity = Vector2.ZERO
		nemico.angular_velocity = 0.0
		layer_originale = nemico.collision_layer
		mask_originale = nemico.collision_mask
		nemico.collision_layer = 0  # disabilita temporaneamente le collisioni fisiche
		nemico.collision_mask = 0
	animated_sprite_2d.play("salto")
	_avvia_cooldown_salto()

func _avvia_cooldown_salto() -> void:
	in_cooldown_salto = true
	await get_tree().create_timer(cooldown_salto).timeout
	in_cooldown_salto = false

func _gestisci_salita(delta: float) -> void:
	# Sale dritto, decelerando per gravità, senza movimento orizzontale
	velocita_verticale += gravita_salita * delta
	global_position.y += velocita_verticale * delta

	# Quando la velocità verticale torna a 0/positiva, ha raggiunto il picco
	if velocita_verticale >= 0:
		_inizia_planata()

func _inizia_planata() -> void:
	fase_salto = FaseSalto.PLANATA
	animated_sprite_2d.play("planata")

	# Cattura la posizione del giocatore UNA SOLA VOLTA, qui al picco
	var punto_target: Vector2 = global_position
	if giocatore != null:
		punto_target = giocatore.global_position

	# Orienta lo sprite verso la direzione in cui si muoverà
	var direzione_verso_target = sign(punto_target.x - global_position.x)
	if direzione_verso_target != 0:
		direction = direzione_verso_target
		animated_sprite_2d.flip_h = direction == -1

	# Interpola la posizione dal punto attuale (il picco) fino al punto target, in modo fluido
	if tween_planata != null and tween_planata.is_valid():
		tween_planata.kill()
	tween_planata = create_tween()
	tween_planata.set_trans(Tween.TRANS_SINE)
	tween_planata.set_ease(Tween.EASE_IN)
	tween_planata.tween_method(_aggiorna_posizione_planata, global_position, punto_target, durata_planata)
	tween_planata.finished.connect(_fine_planata)

func _aggiorna_posizione_planata(pos: Vector2) -> void:
	global_position = pos

func _fine_planata() -> void:
	fase_salto = FaseSalto.NESSUNA
	velocita_verticale = 0.0
	giocatore = null
	if nemico != null:
		nemico.freeze = false
		nemico.gravity_scale = 1.0
		nemico.collision_layer = layer_originale
		nemico.collision_mask = mask_originale
	animated_sprite_2d.play("default")

	# Periodo di immunità dal RayCastUp, per evitare morti accidentali
	# se il nemico atterra proprio sotto/vicino al player
	immune_da_alto = true
	await get_tree().create_timer(durata_immunita_post_planata).timeout
	immune_da_alto = false

func _physics_process(delta: float) -> void:
	nascita()

	ray_cast_up.force_raycast_update()
	ray_cast_down.force_raycast_update()
	ray_cast_right.force_raycast_update()
	ray_cast_left.force_raycast_update()

	# Durante la salita gestiamo il movimento manuale frame-by-frame.
	# Durante la planata, è il Tween che muove il nodo: non serve fare nulla qui.
	if fase_salto == FaseSalto.SALITA:
		_gestisci_salita(delta)
		return
	if fase_salto == FaseSalto.PLANATA:
		return

	if ray_cast_up.is_colliding() and not immune_da_alto:
		Morte()
		return

	var ostacolo_laterale = false

	if direction == 1 and ray_cast_right.is_colliding():
		ostacolo_laterale = true
	if direction == -1 and ray_cast_left.is_colliding():
		ostacolo_laterale = true

	# Se colpiamo un nemico, invertiamo noi E forziamo lui a invertire
	if direction == 1 and ray_cast_right.is_colliding():
		var corpo = ray_cast_right.get_collider()
		if corpo != null and corpo.is_in_group("enemy"):
			ostacolo_laterale = true
			if corpo.has_method("inverti_direzione_forzata"):
				corpo.inverti_direzione_forzata()
	if direction == -1 and ray_cast_left.is_colliding():
		var corpo = ray_cast_left.get_collider()
		if corpo != null and corpo.is_in_group("enemy"):
			ostacolo_laterale = true
			if corpo.has_method("inverti_direzione_forzata"):
				corpo.inverti_direzione_forzata()

	var niente_pavimento = not ray_cast_down.is_colliding()

	if ostacolo_laterale or niente_pavimento:
		direction *= -1
		animated_sprite_2d.flip_h = direction == -1

	position.x += direction * SPEED * delta
