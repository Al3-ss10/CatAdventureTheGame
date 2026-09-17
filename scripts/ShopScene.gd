extends Control

const ITEM_CARD_SCENE := preload("res://scenes/ItemCard.tscn")

@export var grid_container: GridContainer
@export var money_label: Label
@export var back_button: Button
@export var status_label: Label
@export var notification_panel: Control # Il contenitore della notifica in basso

@export_group("Pannello Dettagli")
@export var right_panel: Control # Il pannello laterale destro intero
@export var detail_rarity_label: Label
@export var detail_name_label: Label
@export var detail_type_label: Label
@export var detail_price_label: Label
@export var buy_button: Button

var selected_item_data: Dictionary = {}
var notification_timer: SceneTreeTimer = null


func _ready() -> void:
	_resolve_node_references()

	if back_button:
		if not back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.connect(_on_back_button_pressed)
	if buy_button:
		if not buy_button.pressed.is_connected(_on_buy_button_pressed):
			buy_button.pressed.connect(_on_buy_button_pressed)

	# Nasconde i pannelli dinamici all'avvio
	if right_panel:
		right_panel.visible = false
	if notification_panel:
		notification_panel.visible = false

	await get_tree().process_frame
	await get_tree().process_frame
	
	refresh_shop()


func _resolve_node_references() -> void:
	if grid_container == null:
		if has_node("UI/Body/Left/ScrollContainer/ItemGrid"):
			grid_container = $UI/Body/Left/ScrollContainer/ItemGrid

	if money_label == null:
		if has_node("UI/TopBar/TopBarHBox/GoldLabel"):
			money_label = $UI/TopBar/TopBarHBox/GoldLabel

	if status_label == null:
		if has_node("UI/NotificationAnim/NotifLabel"):
			status_label = $UI/NotificationAnim/NotifLabel

	if notification_panel == null:
		if has_node("UI/NotificationAnim"):
			notification_panel = $UI/NotificationAnim

	if right_panel == null:
		if has_node("UI/Body/Right"):
			right_panel = $UI/Body/Right

	if detail_name_label == null and has_node("UI/Body/Right/DetailPanel/ItemName"):
		detail_name_label = $UI/Body/Right/DetailPanel/ItemName
	if detail_rarity_label == null and has_node("UI/Body/Right/DetailPanel/RarityLabel"):
		detail_rarity_label = $UI/Body/Right/DetailPanel/RarityLabel
	if detail_type_label == null and has_node("UI/Body/Right/DetailPanel/TypeLabel"):
		detail_type_label = $UI/Body/Right/DetailPanel/TypeLabel
	if detail_price_label == null and has_node("UI/Body/Right/DetailPanel/ItemPrice"):
		detail_price_label = $UI/Body/Right/DetailPanel/ItemPrice
	if buy_button == null and has_node("UI/Body/Right/DetailPanel/BuyButton"):
		buy_button = $UI/Body/Right/DetailPanel/BuyButton


func refresh_shop() -> void:
	_update_money_display()
	_populate_grid()


func _update_money_display() -> void:
	if money_label:
		money_label.text = str(Global.money)


func _populate_grid() -> void:
	if grid_container == null:
		return

	for child in grid_container.get_children():
		child.queue_free()

	if Global.ItemDB.is_empty():
		return

	for item_id in Global.ItemDB.keys():
		var item_data: Dictionary = Global.ItemDB[item_id]
		var card_instance = ITEM_CARD_SCENE.instantiate()
		if card_instance == null:
			continue
			
		grid_container.add_child(card_instance)

		if card_instance.has_method("setup"):
			card_instance.setup(item_data)

		if card_instance.has_signal("clicked"):
			if not card_instance.is_connected("clicked", _on_item_card_clicked):
				card_instance.clicked.connect(_on_item_card_clicked)


func _on_item_card_clicked(item_data: Dictionary) -> void:
	selected_item_data = item_data
	
	if right_panel:
		right_panel.visible = true
		
	_update_detail_panel()


func _update_detail_panel() -> void:
	if selected_item_data.is_empty():
		if right_panel: right_panel.visible = false
		return

	var item_id: String = selected_item_data.get("id", "")
	var item_type: String = selected_item_data.get("type", "")
	var price: int = selected_item_data.get("price", 0)

	if detail_name_label:
		detail_name_label.text = selected_item_data.get("name", "")
	if detail_rarity_label:
		detail_rarity_label.text = str(selected_item_data.get("rarity", "COMMON")).to_upper()
	if detail_type_label:
		detail_type_label.text = "[" + item_type.capitalize() + "]"
	if detail_price_label:
		detail_price_label.text = "🪙 " + str(price)

	if buy_button:
		buy_button.disabled = false
		if item_type == "skin":
			var sbloccata: bool = Global.skin_sbloccate.get(item_id, false)
			var equipaggiata: bool = Global.skin.get("selected", false) and Global.skin.get("type", "") == item_id

			if equipaggiata:
				buy_button.text = "EQUIPAGGIATO"
				buy_button.disabled = true
			elif sbloccata:
				buy_button.text = "EQUIPAGGIA"
			else:
				buy_button.text = "ACQUISTA"
		else:
			buy_button.text = "ACQUISTA"


func _on_buy_button_pressed() -> void:
	if selected_item_data.is_empty():
		return

	var item_id: String = selected_item_data.get("id", "")
	var item_type: String = selected_item_data.get("type", "")
	var price: int = selected_item_data.get("price", 0)

	if item_type == "skin":
		var sbloccata: bool = Global.skin_sbloccate.get(item_id, false)

		if sbloccata:
			Global.select_skin(item_id)
			_show_status("Skin equipaggiata!")
		else:
			if Global.money >= price:
				Global.money -= price
				Global.sblocca_skin(item_id)
				Global.select_skin(item_id)
				_show_status("Acquistato con successo!")
			else:
				_show_status("Monete insufficienti!")
	else:
		if Global.money >= price:
			Global.money -= price
			if Global.ListaPowerUp.has(item_id):
				Global.ListaPowerUp[item_id] += 1
			Global.save_game()
			_show_status("Acquistato con successo!")
		else:
			_show_status("Monete insufficienti!")

	refresh_shop()


func _show_status(msg: String) -> void:
	if status_label:
		status_label.text = msg
	
	if notification_panel:
		notification_panel.visible = true
		
	if notification_timer and notification_timer.timeout.is_connected(_hide_notification):
		notification_timer.timeout.disconnect(_hide_notification)
		
	notification_timer = get_tree().create_timer(2.5)
	notification_timer.timeout.connect(_hide_notification)


func _hide_notification() -> void:
	if notification_panel:
		notification_panel.visible = false


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
