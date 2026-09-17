extends CanvasLayer

@onready var popup: Panel = $Popup
@onready var popup_label: Label = $Popup/PopupLabel
@onready var anim: AnimationPlayer = $Popup/AnimationPlayer

@export var popup_duration: float = 2.0

var _busy: bool = false

func _ready() -> void:
	# Il popup deve stare sopra tutto e sopravvivere al cambio scena (è un autoload).
	layer = 100
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)
	popup.pivot_offset = popup.size / 2.0

## Mostra il popup con un testo custom, aspetta, lo nasconde e poi (opzionale)
## cambia scena. Se next_scene è "" non cambia scena, mostra solo il popup.
## Ad ogni chiamata (= fine livello) salva automaticamente lo stato del gioco.
## Esempio: PopupManager.show_and_change_scene("Livello 2 sbloccato", "res://scenes/MainMenu.tscn")
func show_and_change_scene(text: String, next_scene: String = "") -> void:
	print("1) show_and_change_scene chiamata con testo: ", text)
	
	if _busy:
		print("2) BLOCCATO: _busy è già true, esco senza fare nulla")
		return
	_busy = true
	
	print("3) Sto per chiamare Global.save_game()")
	Global.save_game()
	print("4) Global.save_game() chiamata completata")
	
	popup_label.text = text
	anim.play("popup_in")
	await anim.animation_finished
	await get_tree().create_timer(popup_duration).timeout
	anim.play("popup_out")
	await anim.animation_finished
	_busy = false
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
## Comodo se vuoi solo mostrare il popup senza cambiare scena.
func show_popup(text: String) -> void:
	await show_and_change_scene(text, "")
