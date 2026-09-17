extends Control

# Percorsi anteprime skin
const SKIN_PREVIEWS := {
	"default":    "res://assets/sprites/anteprima base.png",
	"gomitolo":   "res://assets/sprites/anteprima gomitolo.png",
	"box":        "res://assets/sprites/antemprima scatola.png",
	"magnete":    "res://assets/sprites/anteprima magnete.png",
	"siberiano": "res://assets/sprites/anteprima siberiano.png",
	"smoking": "res://assets/sprites/anteprima smoking.png",
	"marroncino": "res://assets/sprites/anteprima marroncino.png"
}

const CATENE_TEXTURE := "res://assets/sprites/catene.png"

@onready var grid: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopHeaderHBox/BackButton
@onready var deselect_button: Button = $MarginContainer/VBoxContainer/BottomContainer/DeselectButton

var slot_buttons: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	deselect_button.pressed.connect(_on_deselect_pressed)
	refresh_menu()


func refresh_menu() -> void:
	for child in grid.get_children():
		child.queue_free()
	slot_buttons.clear()

	_build_slots()
	_refresh_selection_visuals()


func _build_slots() -> void:
	# Slot "default"
	_create_slot("default", true)

	# Slot per tutte le skin
	for skin_name in Global.SKIN_LIST:
		var sbloccata: bool = Global.skin_sbloccate.get(skin_name, false)
		_create_slot(skin_name, sbloccata)


func _create_slot(skin_name: String, sbloccata: bool) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(120, 150)
	slot.clip_contents = true 
	
	# Stile identico al MessageBox (sfondo scuro #322b28 e bordo arancione #f77f00, angoli netti)
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color8(50, 43, 40)
	style_box.corner_radius_top_left = 0
	style_box.corner_radius_top_right = 0
	style_box.corner_radius_bottom_right = 0
	style_box.corner_radius_bottom_left = 0
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color8(247, 127, 0)
	slot.add_theme_stylebox_override("panel", style_box)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(vbox)

	# Anteprima
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(100, 90)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(SKIN_PREVIEWS.get(skin_name, "")):
		preview.texture = load(SKIN_PREVIEWS[skin_name])
	vbox.add_child(preview)

	# Nome skin
	var label := Label.new()
	label.text = skin_name.capitalize()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	# Catene overlay se bloccata
	if not sbloccata:
		var chains := TextureRect.new()
		chains.name = "ChainsOverlay"
		chains.set_anchors_preset(Control.PRESET_FULL_RECT)
		chains.stretch_mode = TextureRect.STRETCH_SCALE
		if ResourceLoader.exists(CATENE_TEXTURE):
			chains.texture = load(CATENE_TEXTURE)
		chains.modulate = Color(1, 1, 1, 0.9)
		slot.add_child(chains)

	# Bottone di selezione
	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_skin_clicked.bind(skin_name))
	slot.add_child(button)

	slot_buttons[skin_name] = slot
	grid.add_child(slot)


func _on_skin_clicked(skin_name: String) -> void:
	if skin_name == "default":
		_deselect_skin()
		return

	var sbloccata: bool = Global.skin_sbloccate.get(skin_name, false)

	if sbloccata:
		Global.select_skin(skin_name)
		print("[SHOP] Skin equipaggiata: ", skin_name)
	else:
		print("[SHOP] Skin bloccata!")

	_refresh_selection_visuals()


func _on_deselect_pressed() -> void:
	_deselect_skin()


func _deselect_skin() -> void:
	Global.select_skin("default")
	_refresh_selection_visuals()


func _refresh_selection_visuals() -> void:
	var current: String = Global.skin.get('type', '') if Global.skin.get('selected', false) else "default"

	for skin_name in slot_buttons.keys():
		var slot: PanelContainer = slot_buttons[skin_name]
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel")
		if style:
			if skin_name == current:
				style.border_color = Color8(255, 230, 100) # Bordo dorato se equipaggiato
			else:
				style.border_color = Color8(247, 127, 0) # Bordo arancione standard del message box


func _on_back_pressed() -> void:
	var target_scene := "res://scenes/MainMenu.tscn"
	
	if not ResourceLoader.exists(target_scene):
		print("ERRORE: La scena non esiste nel percorso: ", target_scene)
		return
		
	var error := get_tree().change_scene_to_file(target_scene)
	if error != OK:
		print("ERRORE: Impossibile cambiare scena, codice: ", error)
