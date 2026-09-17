extends PanelContainer

signal card_selected

const RARITY_COLORS := {
	"common":    Color("#9d9d9d"),
	'uncommon': Color("00a300ff"),
	"rare":      Color("#4da6ff"),
	"epic":      Color("#b04dff"),
	"legendary": Color("#ffaa00"),
}

var _item: Dictionary = {}

func setup(item: Dictionary) -> void:
	_item = item

	var name_label  : Label       = get_node("VBox/NameLabel")
	var qty_label   : Label       = get_node("VBox/QtyLabel")
	var r_bar       : ColorRect   = get_node("RarityBar")
	var equip_badge : Label       = get_node("EquipBadge")
	var icon        : TextureRect = get_node("VBox/IconRect")

	name_label.text = item.get("name", "")
	qty_label.text  = "x" + str(item.get("quantity", 1))

	var rarity_col: Color = RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	r_bar.color = rarity_col

	equip_badge.visible = item.get("equipped", false)

	if ResourceLoader.exists(item.get("icon", "")):
		icon.texture = load(item["icon"])

	var style := StyleBoxFlat.new()
	style.bg_color                   = Color("#1e1830")
	style.border_width_left          = 3
	style.border_color               = rarity_col
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left        = 8
	style.content_margin_right       = 8
	style.content_margin_top         = 8
	style.content_margin_bottom      = 8
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card_selected.emit()

func _on_mouse_entered() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)

func _on_mouse_exited() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
