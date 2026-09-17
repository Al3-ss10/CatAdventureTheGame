extends Control

# Path dell'immagine delle catene
const CHAIN_TEXTURE := "res://assets/sprites/catene.png"

# ─── Node References ──────────────────────────────────────────────────────────
@onready var level_list : VBoxContainer = $UI/ScrollMargin/ScrollContainer/LevelList
@onready var scroll     : ScrollContainer = $UI/ScrollMargin/ScrollContainer

# ─── Ready ────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1. Ricarica sempre lo stato salvato dei livelli prima di generare l'interfaccia
	if get_node_or_null("/root/Global"):
		Global.load_game()

	$UI/MarginContainer/TopBarHBox/BackButton.pressed.connect(_on_back_pressed)
	_build_list()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── Build ────────────────────────────────────────────────────────────────────
func _build_list() -> void:
	# Pulisce i figli esistenti per permettere l'aggiornamento della lista a runtime
	for child in level_list.get_children():
		child.queue_free()

	# ACCESSO ALLA VARIABILE GLOBALE (Global.levels)
	for level in Global.levels:
		var row := _make_row(level)
		level_list.add_child(row)

func _make_row(level: Dictionary) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)

	# Stile personalizzato per i pannelli dei livelli
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.18, 0.12, 0.1, 0.8)
	stylebox.border_color = Color(1, 0.51, 0.16, 0.6)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", stylebox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	var num_label := Label.new()
	num_label.text = str(level["id"]).lpad(2, "0")
	num_label.add_theme_font_size_override("font_size", 24)
	num_label.add_theme_color_override("font_color", Color(1, 0.51, 0.16, 1))
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_label.custom_minimum_size = Vector2(40, 0)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sep := VSeparator.new()

	var name_label := Label.new()
	name_label.text = level["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.7, 1))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var status_label := Label.new()
	status_label.text = "BLOCCATO" if level["locked"] else "GIOCA"
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.3, 1) if level["locked"] else Color(0.4, 0.9, 0.4, 1))
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	hbox.add_child(num_label)
	hbox.add_child(sep)
	hbox.add_child(name_label)
	hbox.add_child(status_label)
	panel.add_child(hbox)

	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.custom_minimum_size = Vector2(0, 70)

	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if level["locked"]:
		panel.modulate = Color(0.5, 0.5, 0.5, 0.8)

		var chain := TextureRect.new()
		if ResourceLoader.exists(CHAIN_TEXTURE):
			var tex := load(CHAIN_TEXTURE) as Texture2D
			if tex:
				chain.texture = tex
		chain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chain.stretch_mode = TextureRect.STRETCH_SCALE
		chain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		stack.add_child(panel)
		stack.add_child(chain)
	else:
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_level_pressed.bind(level["scene"]))

		stack.add_child(panel)
		stack.add_child(btn)

	margin.add_child(stack)
	return margin

# ─── Navigazione ──────────────────────────────────────────────────────────────
func _on_level_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
