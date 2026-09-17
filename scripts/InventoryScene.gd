extends Control

const RARITY_COLORS := {
	"common":    Color("#9d9d9d"),
	"uncommon":  Color("#00a300"),
	"rare":      Color("#4da6ff"),
	"epic":      Color("#b04dff"),
	"legendary": Color("#ffaa00"),
}

const RARITY_NAMES := {
	"common": "Comune",
	"uncommon": "Non Comune",
	"rare": "Raro",
	"epic": "Epico",
	"legendary": "Leggendario"
}

const FILTER_NAMES := {
	"all": "Tutti",
	"weapon": "Armi",
	"armor": "Armature",
	"consumable": "Consumabili",
	"accessory": "Accessori"
}

# ─── Node References ─────────────────────────────────────────────────────────
@onready var item_grid        : GridContainer  = $UI/Body/Left/ScrollContainer/ItemGrid
@onready var detail_panel     : VBoxContainer  = $UI/Body/Right/DetailPanel
@onready var filter_bar       : HBoxContainer  = $UI/FilterBar

@onready var use_button       : Button         = $UI/Body/Right/DetailPanel/Buttons/UseButton
@onready var drop_button      : Button         = $UI/Body/Right/DetailPanel/Buttons/DropButton
@onready var equip_button     : Button         = $UI/Body/Right/DetailPanel/Buttons/EquipButton

var item_card_scene := preload("res://scenes/InventoryCard.tscn")
var active_filter: String = "all"
var selected_item: Dictionary = {}

# ─── Ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1. Ricarica sempre lo stato salvato prima di popolare la UI
	if get_node_or_null("/root/Global"):
		Global.load_game()

	detail_panel.visible = false
	_build_filter_buttons()
	_populate_grid("all")
	
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	
	if $UI/TopBar/TopBarHBox.has_node("BackButton"):
		$UI/TopBar/TopBarHBox/BackButton.pressed.connect(_on_back_pressed)

# ─── Back ────────────────────────────────────────────────────────────────────
func _on_back_pressed() -> void:
	# Salva prima di uscire dall'inventario
	if get_node_or_null("/root/Global"):
		Global.save_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── Style Helpers ───────────────────────────────────────────────────────────
func _get_button_normal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.1, 0.8)
	style.set_corner_radius_all(4)
	return style

func _get_button_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.16, 0.12, 0.9)
	style.border_color = Color(1, 0.51, 0.16, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

func _apply_button_theme(btn: Button) -> void:
	var style_normal := _get_button_normal_style()
	var style_hover  := _get_button_hover_style()
	var style_empty  := StyleBoxEmpty.new()

	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.7, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.51, 0.16, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 0.51, 0.16, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 0.51, 0.16, 1))

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("hover_pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_empty)

# ─── Filter Bar ──────────────────────────────────────────────────────────────
func _build_filter_buttons() -> void:
	for child in filter_bar.get_children():
		child.queue_free()

	var filters := ["all", "weapon", "armor", "consumable", "accessory"]
	for f in filters:
		var btn := Button.new()
		btn.text = FILTER_NAMES.get(f, f)
		btn.name = "Filter_" + f
		btn.toggle_mode = true
		btn.button_pressed = (f == active_filter)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		_apply_button_theme(btn)

		btn.pressed.connect(_on_filter_pressed.bind(f, btn))
		filter_bar.add_child(btn)

func _on_filter_pressed(filter: String, pressed_btn: Button) -> void:
	active_filter = filter
	for child in filter_bar.get_children():
		if child is Button:
			child.button_pressed = (child == pressed_btn)
	_populate_grid(filter)

# ─── Item Grid ───────────────────────────────────────────────────────────────
func _populate_grid(filter: String) -> void:
	for child in item_grid.get_children():
		child.queue_free()
		
	for item_id in Global.ListaPowerUp:
		if Global.ListaPowerUp[item_id] <= 0:
			continue
		if not Global.ItemDB.has(item_id):
			continue
			
		var item: Dictionary = Global.ItemDB[item_id].duplicate()
		item["quantity"] = Global.ListaPowerUp[item_id]
		
		if filter != "all" and item["type"] != filter:
			continue
			
		var card: PanelContainer = item_card_scene.instantiate()
		item_grid.add_child(card)
		card.setup(item)
		card.card_selected.connect(_on_card_selected.bind(item))

# ─── Detail Panel ────────────────────────────────────────────────────────────
func _on_card_selected(item: Dictionary) -> void:
	selected_item = item
	detail_panel.visible = true
	
	detail_panel.get_node("ItemName").text = item.get("name", "")
	detail_panel.get_node("ItemDesc").text = item.get("desc", "")
	
	if detail_panel.has_node("ItemStat"):
		detail_panel.get_node("ItemStat").text = item.get("stat", "")
		
	var item_id: String = item.get("id", "")
	var qty: int = Global.ListaPowerUp.get(item_id, 0)
	detail_panel.get_node("QuantityLabel").text = "Quantità: " + str(qty)
	
	var rarity_key: String = item.get("rarity", "common")
	var rarity_color: Color = RARITY_COLORS.get(rarity_key, Color.WHITE)
	var rarity_text: String = RARITY_NAMES.get(rarity_key, "Comune").to_upper()
	
	detail_panel.get_node("RarityLabel").text = rarity_text
	detail_panel.get_node("RarityLabel").add_theme_color_override("font_color", rarity_color)
	
	var type_key: String = item.get("type", "")
	var type_text: String = FILTER_NAMES.get(type_key, "Oggetto")
	detail_panel.get_node("TypeLabel").text = "[" + type_text + "]"
	
	var is_equipped: bool = _is_item_equipped(item_id)
	equip_button.text = "RIMUOVI" if is_equipped else "EQUIPAGGIA"
	use_button.text = "USA"
	drop_button.text = "SCARTA"
	
	use_button.visible = item.get("type", "") == "consumable"
	equip_button.visible = item.get("type", "") != "consumable"

func _is_item_equipped(item_id: String) -> bool:
	match item_id:
		"gomitolo": return Global.gomitolo
		"scatola", "box": return Global.box
		"magnete": return Global.magnete
		_: return false

# ─── Buttons ─────────────────────────────────────────────────────────────────
func _on_use_pressed() -> void:
	if selected_item.is_empty():
		return
		
	if selected_item["id"] == 'polpetta':
		if (Global.vita == 1 or Global.vita == 2) and Global.ListaPowerUp.get('polpetta', 0) > 0:
			Global.vita += 1
			Global.ListaPowerUp['polpetta'] -= 1
			Global.save_game()
			_populate_grid(active_filter)
			
			if Global.ListaPowerUp.get('polpetta', 0) <= 0:
				detail_panel.visible = false
				selected_item = {}
			else:
				_on_card_selected(selected_item)

func _on_drop_pressed() -> void:
	if selected_item.is_empty():
		return
	
	var item_id: String = selected_item.get("id", "")
	if Global.ListaPowerUp.get(item_id, 0) > 0:
		Global.ListaPowerUp[item_id] -= 1
		
		# Se l'oggetto era equipaggiato e scarti l'ultima unità, rimuovi l'effetto
		if _is_item_equipped(item_id) and Global.ListaPowerUp[item_id] == 0:
			_rimuovi_powerup_attivo()
		
		Global.save_game()
		_populate_grid(active_filter)
		
		if Global.ListaPowerUp.get(item_id, 0) <= 0:
			detail_panel.visible = false
			selected_item = {}
		else:
			_on_card_selected(selected_item)

func _on_equip_pressed() -> void:
	if selected_item.is_empty():
		return

	var item_id: String = selected_item.get("id", "")
	var is_currently_equipped: bool = _is_item_equipped(item_id)

	if is_currently_equipped:
		_rimuovi_powerup_attivo()
	else:
		if Global.ListaPowerUp.get(item_id, 0) <= 0:
			return
		_rimuovi_powerup_attivo()
		_equipaggia_nuovo_powerup(item_id)

	Global.save_game()
	_populate_grid(active_filter)
	
	if Global.ListaPowerUp.get(item_id, 0) <= 0:
		detail_panel.visible = false
		selected_item = {}
	else:
		_on_card_selected(selected_item)

# Ripristina l'eventuale power-up attivo
func _rimuovi_powerup_attivo() -> void:
	Global.gomitolo = false
	Global.box = false
	Global.magnete = false
	Global.skin['type'] = ""

# Consuma 1 unità dall'inventario e attiva il nuovo power-up con la sua skin
func _equipaggia_nuovo_powerup(item_id: String) -> void:
	match item_id:
		"gomitolo":
			Global.gomitolo = true
			_aggiorna_skin_globale("gomitolo")

		"scatola", "box":
			Global.box = true
			_aggiorna_skin_globale("box")

		"magnete":
			Global.magnete = true
			_aggiorna_skin_globale("magnete")

func _aggiorna_skin_globale(nome_skin: String) -> void:
	Global.skin['selected'] = false
	Global.skin['type'] = nome_skin
