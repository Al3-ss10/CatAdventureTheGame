extends Node

# --- Dichiarazione variabili ---
var vita: int
var vitaPrev: int
var money: int
var MoneteCorrenti: int
var popup_message: String
var direction: int
var tempo2: int
var flag: bool
var gomitolo: bool
var box: bool
var magnete: bool
var ListaPowerUp: Dictionary
var skin: Dictionary
var skin_sbloccate: Dictionary
var ItemDB: Dictionary
var levels: Array

const SKIN_LIST := ["gomitolo", "box", "magnete", "siberiano", "smoking", "marroncino"]
const SAVE_PATH := "user://savegame.json"
const SETTINGS_SAVE_PATH := "user://settings.json"

const ACTIONS := {
	"salta": "jump",
	"sinistra": "move_left",
	"destra": "move_right",
	"powerup": "use_powerup"
}


func _ready() -> void:
	_apply_defaults()
	load_game()
	load_keybindings()


func _apply_defaults() -> void:
	vita = 3
	vitaPrev = 3
	money = 1000
	MoneteCorrenti = 0
	popup_message = ""
	direction = 1
	tempo2 = 0
	flag = false
	gomitolo = false
	box = false
	magnete = false

	ListaPowerUp = {
		'polpetta': 0,
		'scatola': 0,
		'gomitolo': 0,
		'magnete': 0,
	}

	skin = {
		"selected": false,
		"type": ""
	}

	skin_sbloccate = {
		"gomitolo": false,
		"box": false,
		"magnete": false,
		"siberiano": false,
		"smoking": false,
		"marroncino": false,
	}

	ItemDB = {
		"polpetta": {
			"id": "polpetta",
			"name": "Polpetta",
			"desc": "Ripristina 1 punto vita.",
			"icon": "res://assets/sprites/polpetta icona.png",
			"rarity": "common",
			"type": "consumable",
			"stat": "+1 HP",
			"price": 1,
			"equipped": false,
		},
		"gomitolo": {
			"id": "gomitolo",
			"name": "Gomitolo",
			"desc": "Gomitolo di lana lanciabile che sconfigge i nemici.",
			"icon": "res://assets/sprites/gomitolo.png",
			"rarity": "uncommon",
			"type": "weapon",
			"stat": "+DMG",
			"price": 2,
			"equipped": false,
		},
		"scatola": {
			"id": "scatola",
			"name": "Scatola",
			"desc": "Scatola di cartone fluttuante.",
			"icon": "res://assets/sprites/box.png",
			"rarity": "rare",
			"type": "armor",
			"stat": "+DEF",
			"price": 5,
			"equipped": false,
		},
		"magnete": {
			"id": "magnete",
			"name": "Magnete",
			"desc": "Attira le monete vicine.",
			"icon": "res://assets/sprites/Magnete.png",
			"rarity": "rare",
			"type": "accessory",
			"stat": "+DEF",
			"price": 5,
			"equipped": false,
		},
		"siberiano": {
			"id": "siberiano",
			"name": "Skin Siberiano",
			"desc": "Un soffice gatto siberiano.",
			"icon": "res://assets/sprites/anteprima siberiano.png",
			"rarity": "legendary",
			"type": "skin",
			"stat": "Cosmetico",
			"price": 100,
			"equipped": false,
		},
		"smoking": {
			"id": "smoking",
			"name": "Skin del gatto smoking",
			"desc": "un gatto domestico",
			"icon": "res://assets/sprites/anteprima smoking.png",
			"rarity": "rare",
			"type": "skin",
			"stat": "Cosmetico",
			"price": 50,
			"equipped": false,
		},
		"marroncino": {
			"id": "marroncino",
			"name": "Skin Marroncino",
			"desc": "Un gatto dal morbido pelo marrone.",
			"icon": "res://assets/sprites/anteprima marroncino.png",
			"rarity": "uncommon",
			"type": "skin",
			"stat": "Cosmetico",
			"price": 25,
			"equipped": false,
		},
	}

	levels = [
		{ "id": 1,  "name": "Livello 1",  "scene": "res://scenes/game.tscn",  "locked": false },
		{ "id": 2,  "name": "Livello 2",  "scene": "res://scenes/game2.tscn",  "locked": true },
		{ "id": 3,  "name": "Livello 3",  "scene": "res://scenes/game3.tscn",  "locked": true },
		{ "id": 4,  "name": "Livello 4",  "scene": "res://scenes/game4.tscn",  "locked": true },
	]


func sblocca_skin(skin_name: String) -> void:
	var formatted_name := skin_name.strip_edges().to_lower()
	if skin_sbloccate.has(formatted_name):
		skin_sbloccate[formatted_name] = true
		save_game()


func select_skin(skin_name: String) -> void:
	var formatted_name := skin_name.strip_edges().to_lower()
	if formatted_name == "" or formatted_name == "default":
		skin["selected"] = false
		skin["type"] = ""
	else:
		if skin_sbloccate.get(formatted_name, false):
			skin["selected"] = true
			skin["type"] = formatted_name
	save_game()


func save_game() -> void:
	var data := {
		"vita": vita,
		"vitaPrev": vitaPrev,
		"money": money,
		"MoneteCorrenti": MoneteCorrenti,
		"direction": direction,
		"tempo2": tempo2,
		"flag": flag,
		"gomitolo": gomitolo,
		"box": box,
		"magnete": magnete,
		"ListaPowerUp": ListaPowerUp,
		"skin": skin,
		"skin_sbloccate": skin_sbloccate,
		"ItemDB": ItemDB,
		"levels_locked": _extract_locked_states(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed

	vita = data.get("vita", vita)
	vitaPrev = data.get("vitaPrev", vitaPrev)
	money = data.get("money", money)
	MoneteCorrenti = data.get("MoneteCorrenti", MoneteCorrenti)
	direction = data.get("direction", direction)
	tempo2 = data.get("tempo2", tempo2)
	flag = data.get("flag", flag)
	gomitolo = data.get("gomitolo", gomitolo)
	box = data.get("box", box)
	magnete = data.get("magnete", magnete)

	if data.has("ListaPowerUp"):
		ListaPowerUp = data["ListaPowerUp"]

	if data.has("skin"):
		var loaded_skin: Dictionary = data["skin"]
		skin["selected"] = loaded_skin.get("selected", false)
		skin["type"] = str(loaded_skin.get("type", "")).strip_edges().to_lower()

	if data.has("skin_sbloccate"):
		var loaded_sbloccate: Dictionary = data["skin_sbloccate"]
		for k in loaded_sbloccate.keys():
			skin_sbloccate[k] = loaded_sbloccate[k]

	if data.has("ItemDB"):
		_merge_item_db(data["ItemDB"])
	if data.has("levels_locked"):
		_apply_locked_states(data["levels_locked"])


func reset_save_and_file() -> void:
	_apply_defaults()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func load_keybindings() -> void:
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH):
		return

	var file := FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var bindings: Dictionary = parsed

	for action_alias in bindings.keys():
		if not ACTIONS.has(action_alias):
			continue

		var action_name: String = ACTIONS[action_alias]
		var data: Dictionary = bindings[action_alias]
		var new_event: InputEvent = null

		if data.get("type") == "key":
			var key_ev := InputEventKey.new()
			key_ev.physical_keycode = data["keycode"] as Key
			new_event = key_ev
		elif data.get("type") == "joybutton":
			var joy_ev := InputEventJoypadButton.new()
			joy_ev.button_index = data["button_index"] as JoyButton
			new_event = joy_ev

		if new_event != null:
			InputMap.action_erase_events(action_name)
			InputMap.action_add_event(action_name, new_event)


func _extract_locked_states() -> Dictionary:
	var result := {}
	for level in levels:
		result[str(level["id"])] = level["locked"]
	return result


func _apply_locked_states(locked_states: Dictionary) -> void:
	for level in levels:
		var key := str(level["id"])
		if locked_states.has(key):
			level["locked"] = locked_states[key]


func _merge_item_db(saved_items: Dictionary) -> void:
	for id in saved_items.keys():
		if ItemDB.has(id):
			var saved_item: Dictionary = saved_items[id]
			if saved_item.has("equipped"):
				ItemDB[id]["equipped"] = saved_item["equipped"]
			if saved_item.has("price"):
				ItemDB[id]["price"] = saved_item["price"]
	
	for id in saved_items.keys():
		if not ItemDB.has(id):
			ItemDB[id] = saved_items[id]
