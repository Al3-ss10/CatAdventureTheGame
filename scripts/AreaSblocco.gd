extends Area2D

var morto : bool = false
var padre: Node

func _ready() -> void:
	padre = get_parent()

func _on_body_entered(body: Node2D) -> void:
	if padre.name == "game":
		if body.is_in_group("protagonista") and morto == true and Global.MoneteCorrenti >= 6:
			_sblocca_livello(1, "res://scenes/Main.tscn")

	elif padre and padre.name == "game2":
		if body.is_in_group("protagonista") and Global.MoneteCorrenti >= 4:
			_sblocca_livello(2, "res://scenes/MainMenu.tscn")

	elif padre and padre.name == "game3":
		if body.is_in_group("protagonista") and Global.MoneteCorrenti == 3:
			_sblocca_livello(3, "res://scenes/MainMenu.tscn")

	elif padre and padre.name == "game4":
		if body.is_in_group("protagonista") and Global.MoneteCorrenti >= 3 and morto == true:
			_sblocca_livello(3, "res://scenes/MainMenu.tscn")


## Centralizza la logica: mostra il popup SOLO la prima volta (se era locked),
## poi cambia scena in ogni caso.
func _sblocca_livello(level_index: int, next_scene: String) -> void:
	var era_bloccato: bool = Global.levels[level_index]['locked']

	Global.MoneteCorrenti = 0
	Global.levels[level_index]['locked'] = false

	if era_bloccato:
		var testo := "Livello %d sbloccato" % (level_index + 1)
		PopupManager.show_and_change_scene(testo, next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)
