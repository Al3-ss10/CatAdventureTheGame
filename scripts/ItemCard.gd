extends PanelContainer

signal clicked(item_data: Dictionary)

@export var icon_rect: TextureRect
@export var name_label: Label
@export var price_label: Label
@export var card_button: Button

var item_data: Dictionary = {}

const RARITY_COLORS := {
	"common": Color(0.5, 0.5, 0.5, 1.0),     # Grigio
	"uncommon": Color(0.1, 0.7, 0.2, 1.0),   # Verde
	"rare": Color(0.1, 0.5, 0.9, 1.0),       # Blu
	"legendary": Color(0.9, 0.6, 0.0, 1.0)   # Arancione/Oro
}


func _ready() -> void:
	if not icon_rect:
		icon_rect = _find_child_by_type(self, "TextureRect") as TextureRect
	if not name_label:
		name_label = _find_child_by_name(self, "NameLabel") as Label
	if not price_label:
		price_label = _find_child_by_name(self, "PriceLabel") as Label
	if not card_button:
		card_button = _find_child_by_type(self, "Button") as Button

	if card_button:
		if not card_button.pressed.is_connected(_on_button_pressed):
			card_button.pressed.connect(_on_button_pressed)
	else:
		self.gui_input.connect(_on_gui_input)


func setup(data: Dictionary) -> void:
	item_data = data
	var item_id: String = data.get("id", "")
	var item_type: String = data.get("type", "")

	self_modulate = Color(1, 1, 1, 1)

	if name_label:
		name_label.text = data.get("name", "Item")

	var icon_path: String = data.get("icon", "")
	if icon_rect and icon_path != "" and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
		icon_rect.modulate = Color(1, 1, 1, 1)

	var rarity: String = data.get("rarity", "common")
	if RARITY_COLORS.has(rarity):
		var rarity_color = RARITY_COLORS[rarity]
		
		# Stile principale della card con angoli smussati
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = rarity_color
		card_style.corner_radius_top_left = 10
		card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_left = 10
		card_style.corner_radius_bottom_right = 10
		add_theme_stylebox_override("panel", card_style)

		# Cornice attorno all'icona
		if icon_rect and icon_rect.get_parent() is PanelContainer:
			var icon_panel = icon_rect.get_parent() as PanelContainer
			var icon_style = StyleBoxFlat.new()
			icon_style.bg_color = Color(rarity_color.r * 0.6, rarity_color.g * 0.6, rarity_color.b * 0.6, 1.0)
			icon_style.corner_radius_top_left = 6
			icon_style.corner_radius_top_right = 6
			icon_style.corner_radius_bottom_left = 6
			icon_style.corner_radius_bottom_right = 6
			icon_style.border_width_left = 2
			icon_style.border_width_top = 2
			icon_style.border_width_right = 2
			icon_style.border_width_bottom = 2
			icon_style.border_color = Color(0, 0, 0, 0.4)
			icon_panel.add_theme_stylebox_override("panel", icon_style)

	_update_price_display(item_id, item_type)


func _update_price_display(item_id: String, item_type: String) -> void:
	if not price_label:
		return

	var price: int = item_data.get("price", 0)

	if item_type == "skin":
		var sbloccata: bool = Global.skin_sbloccate.get(item_id, false)
		var equipaggiata: bool = Global.skin.get("selected", false) and Global.skin.get("type", "") == item_id

		if equipaggiata:
			price_label.text = "EQUIPAGGIATO"
		elif sbloccata:
			price_label.text = "POSSEDUTO"
		else:
			price_label.text = str(price) + " 🪙"
	else:
		price_label.text = str(price) + " 🪙"


func _on_button_pressed() -> void:
	clicked.emit(item_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(item_data)


func _find_child_by_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.is_class(type_name):
			return child
		var sub = _find_child_by_type(child, type_name)
		if sub:
			return sub
	return null


func _find_child_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_child_by_name(child, node_name)
		if found:
			return found
	return null
