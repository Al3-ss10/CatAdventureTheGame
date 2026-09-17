extends Area2D

## Script per Area2D che gestisce il rilevamento del player 
## e la visualizzazione del messaggio UI associato.

@onready var panel: PanelContainer = $"../Panel"
@onready var label: RichTextLabel = $"../Panel/Margin/RichTextLabel"


@export var message_text: String = ""
@export var typewriter_speed: float = 0.02   # Secondi tra un carattere e l'altro
@export var fade_duration: float = 0.25      # Durata dissolvenza in/out

## Dizionario di testi di prova basato sul NOME del nodo.
const TEST_MESSAGES := {
	"MessageBox": "Questo è un messaggio di prova per MessageBox.",
	"test": "Questo è un messaggio di prova generico.",
	"test1": "Sei entrato nella zona numero uno!",
	"test2": "Attenzione: qui c'è qualcosa di interessante.",
	"test3": "Complimenti, hai trovato il terzo segreto!",
	"test4": "Questo è l'ultimo messaggio di prova disponibile.",
}

var _is_player_inside: bool = false
var _has_shown_for_this_stay: bool = false
var _tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Inizializza l'interfaccia come nascosta
	panel.modulate.a = 0.0
	panel.visible = false
	label.bbcode_enabled = true
	label.visible_ratio = 1.0


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("protagonista"):
		return
		
	if _is_player_inside or _has_shown_for_this_stay:
		return

	_is_player_inside = true
	_has_shown_for_this_stay = true

	var text_to_show: String = message_text
	
	if text_to_show == "":
		# .to_lower() converte il nome del nodo in minuscolo per evitare errori di battitura (es. "Test1" -> "test1")
		var node_name_lowercase: String = name.to_lower()
		
		# Debug: Stampa nella console cosa sta cercando
		print("Sto cercando il messaggio per il nodo: '", node_name_lowercase, "'")
		
		text_to_show = TEST_MESSAGES.get(node_name_lowercase, "")
		
		# Se non lo trova neanche così, mostra un messaggio di errore chiaro a schermo
		if text_to_show == "":
			text_to_show = "ERRORE: Nessun messaggio trovato per il nodo chiamato '" + name + "'"

	_show_message(text_to_show)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("protagonista"):
		return

	_is_player_inside = false
	# Permette di rivedere il messaggio solo se esce e rientra nell'area
	_has_shown_for_this_stay = false
	
	_hide_message()


func _show_message(text: String) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	label.text = text
	label.visible_ratio = 0.0
	panel.visible = true
	
	var char_count: int = label.get_total_character_count()
	var type_time: float = char_count * typewriter_speed

	_tween = create_tween().set_parallel(false)
	
	# 1. Fade-in del pannello
	_tween.tween_property(panel, "modulate:a", 1.0, fade_duration)
	
	# 2. Effetto macchina da scrivere sul testo
	if char_count > 0:
		_tween.tween_property(label, "visible_ratio", 1.0, type_time)
	else:
		label.visible_ratio = 1.0


func _hide_message() -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	
	# Dissolvenza in uscita (Fade-out)
	_tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	
	# Nasconde il pannello al termine della dissolvenza
	_tween.tween_callback(func(): panel.visible = false)
