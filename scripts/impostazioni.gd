extends Control

# Per comodità definiamo il percorso di salvataggio per le impostazioni/comandi
const SETTINGS_SAVE_PATH := "user://settings.json"

# Percorso della scena del menu principale (assicurati che corrisponda esattamente)
const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"

# Nomi delle azioni registrate nell'InputMap di Godot
const ACTIONS := {
	"salta": "jump",
	"sinistra": "move_left",
	"destra": "move_right",
	"box": "Box",
	"gomitolo": "Gomitolo"
}

# Riferimento per sapere quale tasto stiamo rimappando
var _action_to_rebind: String = ""
var _is_rebinding: bool = false

# Nodi UI
@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var btn_back: Button = $MarginContainer/VBoxContainer/TopHeaderHBox/BtnBack


func _ready() -> void:
	load_keybindings()
	_update_ui_buttons()
	
	if btn_back:
		btn_back.pressed.connect(_on_btn_back_pressed)


func _input(event: InputEvent) -> void:
	if not _is_rebinding:
		return

	if event is InputEventMouseButton:
		return

	if event is InputEventKey or event is InputEventJoypadButton:
		_rebind_action(_action_to_rebind, event)
		_is_rebinding = false
		_action_to_rebind = ""
		_update_info_text("Tasto configurato con successo!")
		_update_ui_buttons()


# ==============================================================================
# SEZIONE 1: RIMAPPATURA E SALVATAGGIO COMANDI
# ==============================================================================

func start_rebinding(action_key: String) -> void:
	if not ACTIONS.has(action_key):
		return
	
	_action_to_rebind = ACTIONS[action_key]
	_is_rebinding = true
	_update_info_text("Premi un nuovo tasto per l'azione: " + action_key.capitalize())


func _rebind_action(action_name: String, new_event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)
	save_keybindings()


func save_keybindings() -> void:
	var bindings := {}
	
	for action_alias in ACTIONS.keys():
		var action_name: String = ACTIONS[action_alias]
		var events := InputMap.action_get_events(action_name)
		if events.size() > 0:
			var event = events[0]
			if event is InputEventKey:
				bindings[action_alias] = {
					"type": "key",
					"keycode": event.physical_keycode
				}
			elif event is InputEventJoypadButton:
				bindings[action_alias] = {
					"type": "joybutton",
					"button_index": event.button_index
				}

	var file := FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(bindings, "\t"))
		file.close()
	else:
		push_error("Impossibile salvare le impostazioni dei comandi.")


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


# ==============================================================================
# SEZIONE 2: RESET DATI E NAVIGAZIONE
# ==============================================================================

func _on_btn_back_pressed() -> void:
	# 1. Eseguiamo le operazioni sui dati in modo protetto
	if get_node_or_null("/root/Global"):
		if FileAccess.file_exists("user://savegame.save"):
			Global.load_game()
		Global.load_keybindings()

	# 2. Scheduliamo il cambio scena in modo sicuro per evitare blocchi nel thread principale
	call_deferred("_deferred_change_scene")

func _deferred_change_scene() -> void:
	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("Impossibile cambiare scena. Codice errore: " + str(error))
func _on_reset_game_data_pressed() -> void:
	Global.reset_save_and_file()
	Global.save_game()


func _on_reset_controls_pressed() -> void:
	InputMap.load_from_project_settings()
	if FileAccess.file_exists(SETTINGS_SAVE_PATH):
		DirAccess.remove_absolute(SETTINGS_SAVE_PATH)
	_update_ui_buttons()
	_update_info_text("Comandi riportati ai valori predefiniti.")


# ==============================================================================
# SEZIONE 3: HELPERS UI
# ==============================================================================

func _on_bind_salta_pressed() -> void: start_rebinding("salta")
func _on_bind_sinistra_pressed() -> void: start_rebinding("sinistra")
func _on_bind_destra_pressed() -> void: start_rebinding("destra")
func _on_bind_box_pressed() -> void: start_rebinding("box")
func _on_bind_gomitolo_pressed() -> void: start_rebinding("gomitolo")


func _update_ui_buttons() -> void:
	_set_button_text("MarginContainer/VBoxContainer/ContentVBox/SezioneComandi/BtnSalta", "salta")
	_set_button_text("MarginContainer/VBoxContainer/ContentVBox/SezioneComandi/BtnSinistra", "sinistra")
	_set_button_text("MarginContainer/VBoxContainer/ContentVBox/SezioneComandi/BtnDestra", "destra")
	_set_button_text("MarginContainer/VBoxContainer/ContentVBox/SezioneComandi/BtnBox", "box")
	_set_button_text("MarginContainer/VBoxContainer/ContentVBox/SezioneComandi/BtnGomitolo", "gomitolo")


func _set_button_text(button_path: String, action_alias: String) -> void:
	var btn := get_node_or_null(button_path) as Button
	if btn == null:
		return
	
	var action_name: String = ACTIONS[action_alias]
	var events := InputMap.action_get_events(action_name)
	
	if events.size() > 0:
		var key_text := events[0].as_text().replace(" (Fisico)", "").replace(" (Physical)", "")
		btn.text = action_alias.capitalize() + ": " + key_text
	else:
		btn.text = action_alias.capitalize() + ": [Nessuno]"


func _update_info_text(msg: String) -> void:
	if info_label:
		info_label.text = msg
