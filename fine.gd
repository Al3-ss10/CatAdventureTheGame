extends Area2D

var morto : bool = false
var padre: Node
var _gia_attivato : bool = false

func _ready() -> void:
	padre = get_parent()

func _on_body_entered(body: Node2D) -> void:
	if _gia_attivato or not body.is_in_group("protagonista"):
		return

	if padre.name == "game":
		if morto == true and Global.MoneteCorrenti >= 6:
			_sblocca_livello(1)
	elif padre and padre.name == "game2":
		if Global.MoneteCorrenti >= 4:
			_sblocca_livello(2)
	elif padre and padre.name == "game3":
		if Global.MoneteCorrenti == 3:
			_sblocca_livello(3)
	elif padre and padre.name == "game4":
		if Global.MoneteCorrenti >= 3 and morto == true:
			_sblocca_livello(3)

func _sblocca_livello(level_index: int) -> void:
	_gia_attivato = true

	var era_bloccato: bool = Global.levels[level_index]['locked']
	Global.MoneteCorrenti = 0
	Global.levels[level_index]['locked'] = false

	var testo_messaggio : String = ""
	if era_bloccato:
		testo_messaggio = "Livello %d sbloccato!" % (level_index + 1)
	else:
		testo_messaggio = "Livello completato!"

	Global.save_game()
	_mostra_popup_custom(testo_messaggio)

func _mostra_popup_custom(msg: String) -> void:
	# CanvasLayer per mostrare il popup sopra a tutto
	var canvas := CanvasLayer.new()
	canvas.layer = 100

	# 1. SFONDO SCURO / OVERLAY
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.08, 0.06, 0.85)
	canvas.add_child(bg)

	# 2. PANNELLO CENTRALE
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 160)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.18, 0.12, 0.1, 0.95)
	card_style.border_color = Color(1, 0.51, 0.16, 1)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", card_style)

	# 3. CONTENUTO DEL POPUP
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_label := Label.new()
	title_label.text = "COMPLIMENTI!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2, 1))
	title_label.add_theme_color_override("font_outline_color", Color(1, 0.15, 0, 1))
	title_label.add_theme_color_override("font_shadow_color", Color(0.8, 0, 0, 0.6))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.add_theme_font_size_override("font_size", 22)

	var msg_label := Label.new()
	msg_label.text = msg
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_color_override("font_color", Color(1, 0.85, 0.7, 1))
	msg_label.add_theme_font_size_override("font_size", 18)

	vbox.add_child(title_label)
	vbox.add_child(msg_label)
	margin.add_child(vbox)
	panel.add_child(margin)
	canvas.add_child(panel)

	# Aggiunge il popup alla scena corrente
	get_tree().root.add_child(canvas)

	# 4. TIMER DI 3 SECONDI
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	canvas.add_child(timer)

	# Quando scade il timer: elimina il popup e poi cambia scena
	timer.timeout.connect(func():
		canvas.queue_free() # Rimuove ed elimina il popup da schermo
		_cambia_scena()
	)
	
	timer.start()

func _cambia_scena() -> void:
	if ResourceLoader.exists("res://scenes/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif ResourceLoader.exists("res://MainMenu.tscn"):
		get_tree().change_scene_to_file("res://MainMenu.tscn")
