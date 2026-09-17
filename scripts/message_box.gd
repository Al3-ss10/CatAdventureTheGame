extends Node2D

## MessageBox: gestisce la visualizzazione dei messaggi UI.
## Se il player si trova dentro più aree contemporaneamente,
## i messaggi vengono mostrati a rotazione uno dopo l'altro.

signal message_started(text: String)
signal message_finished(text: String)

@onready var trigger_area: Area2D = $trigger
@onready var panel: PanelContainer = $UILayer/Panel
@onready var label: RichTextLabel = $UILayer/Panel/Margin/RichTextLabel



@export_group("Configurazione Testo")
@export var message_text: String = ""         ## Testo personalizzato da Inspector

@export_group("Impostazioni Animazione")
@export var typewriter_speed: float = 0.02   # Secondi tra un carattere e l'altro
@export var fade_duration: float = 0.25      # Durata dissolvenza in/out
@export var cycle_display_time: float = 2.5  # Tempo di permanenza a schermo per messaggio durante la rotazione

## Dizionario di testi di prova basati sul NOME del nodo.
const TEST_MESSAGES := {
	"moneta": "Raccogli monete per poter acquistare oggetti nello shop",
	"polpetta": "Le polpette rigenerano la vita",
	"blocco": "Interagisci con il blocco e otterrai una moneta o una polpetta",
	"salto": "Salta due volte per raggiungere le piattaforme più lontane",
	"nemico": "Colpisci il nemico dall'alto per eliminarlo",
	"coppa": "Raccogli tutte le monete del livello ed elimina il nemico per finire il livello",
	"magnete": "il magnete è un power-up che permette di raccogliere monete più lontane",
	"scatola": "la scatola è un power-up che permette di posizionare una piattaforma a mezz'aria. premi V per attivare il potere",
	"gomitolo": "il gomitolo è un power-up che ti permette di lanciare un proiettile rimbalzante che può eliminare i nemici. premi C per attivare il potere",
}

# --- STATI STATICI (CONDIVISI TRA TUTTE LE ISTANZE) ---
static var _active_triggers: Array = []
static var _current_index: int = 0
static var _is_rotating: bool = false

var _default_text: String = ""
var _is_player_inside: bool = false
var _persistent_tween: Tween


func _ready() -> void:
	panel.modulate.a = 0.0
	panel.visible = false
	label.bbcode_enabled = true
	label.visible_ratio = 1.0

	# Collegamento automatico dell'Area2D figlia
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)

	if message_text != "":
		_default_text = message_text
	else:
		_default_text = TEST_MESSAGES.get(name.to_lower(), "")
	

# ==============================================================================
# RILEVAMENTO PLAYER
# ==============================================================================
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("protagonista"):
		return
	

	if not _is_player_inside:
		_is_player_inside = true
		if not _active_triggers.has(self):
			_active_triggers.append(self)

		if not _is_rotating:
			_start_rotation_loop()

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("protagonista"):
		return

	_is_player_inside = false
	_active_triggers.erase(self)
	_hide_message()

	# Se il player è uscito da tutte le aree, arresta la rotazione
	if _active_triggers.is_empty():
		_is_rotating = false


# ==============================================================================
# GESTIONE ROTAZIONE TRA AREE SOVRAPPOSTE
# ==============================================================================

static func _start_rotation_loop() -> void:
	if _is_rotating:
		return
	_is_rotating = true
	_current_index = 0

	while _is_rotating and not _active_triggers.is_empty():
		if _current_index >= _active_triggers.size():
			_current_index = 0

		var current_node = _active_triggers[_current_index]
		if is_instance_valid(current_node) and current_node._is_player_inside:
			await current_node._show_message_cycle()

		_current_index += 1

	_is_rotating = false


func _show_message_cycle() -> void:
	var target_text: String = _default_text
	
	if target_text == "":
		return

	message_started.emit(target_text)

	label.text = target_text
	label.visible_ratio = 0.0
	panel.visible = true
	

	# Fade-in
	if _persistent_tween and _persistent_tween.is_running():
		_persistent_tween.kill()

	_persistent_tween = create_tween()
	_persistent_tween.tween_property(panel, "modulate:a", 1.0, fade_duration)
	await _persistent_tween.finished

	if not _is_player_inside:
		return

	# Typewriter
	var char_count: int = label.get_total_character_count()
	if char_count > 0:
		_persistent_tween = create_tween()
		_persistent_tween.tween_property(
			label, "visible_ratio", 1.0, char_count * typewriter_speed
		)
		await _persistent_tween.finished

	if not _is_player_inside:
		return

	# Gestione attesa a schermo:
	# Se c'è solo UN'AREA attiva, il messaggio resta fisso senza scomparire
	if _active_triggers.size() == 1:
		while _is_player_inside and _active_triggers.size() == 1:
			await get_tree().create_timer(0.2).timeout
	else:
		# Se ci sono PIÙ AREE, aspetta il tempo di ciclo prima di sfumare e passare al prossimo
		await get_tree().create_timer(cycle_display_time).timeout

	if not _is_player_inside:
		return

	# Fade-out per il cambio messaggio
	_persistent_tween = create_tween()
	_persistent_tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	await _persistent_tween.finished
	panel.visible = false
	message_finished.emit(target_text)


func _hide_message() -> void:
	if _persistent_tween and _persistent_tween.is_running():
		_persistent_tween.kill()

	_persistent_tween = create_tween()
	_persistent_tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	_persistent_tween.tween_callback(func(): panel.visible = false)
