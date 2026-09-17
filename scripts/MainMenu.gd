extends Control

# Percorsi delle scene
const SCENE_LEVEL_SELECT = "res://scenes/LevelSelect.tscn"
const SCENE_INVENTORY    = "res://scenes/InventoryScene.tscn"
const SCENE_SHOP         = "res://scenes/ShopScene.tscn"
const SCENE_SKIN         = "res://scenes/SkinSelector.tscn"
const SCENE_SETTINGS     = "res://scenes/impostazioni.tscn"

# --- REGOLAZIONE OFFSET ---
# Modifica questo valore per spostare il gatto verticalmente quando si flippa!
# (Valori positivi spingono in basso, valori negativi spingono in alto)
@export var offset_y_flip: float = 35.0

# Posizioni base
const POS_Y_NORMALE: float = 32.0
const POS_X_NORMALE_LEFT: float = -12.0
const POS_X_FLIPPATA_LEFT: float = -10.0

const POS_X_NORMALE_EXIT: float = 197.0
const POS_X_FLIPPATA_EXIT: float = 195.0

# Riferimenti ai pulsanti e ai rispettivi gatti figli
@onready var buttons_and_cats: Dictionary = {
	$CenterContainer/MainVBox/ButtonsVBox/PlayButton: $CenterContainer/MainVBox/ButtonsVBox/PlayButton/CatPlay,
	$CenterContainer/MainVBox/ButtonsVBox/InventoryButton: $CenterContainer/MainVBox/ButtonsVBox/InventoryButton/CatInventory,
	$CenterContainer/MainVBox/ButtonsVBox/ShopButton: $CenterContainer/MainVBox/ButtonsVBox/ShopButton/CatShop,
	$CenterContainer/MainVBox/ButtonsVBox/SkinButton: $CenterContainer/MainVBox/ButtonsVBox/SkinButton/CatSkin,
	$CenterContainer/MainVBox/ButtonsVBox/BottomRow/SettingsButton: $CenterContainer/MainVBox/ButtonsVBox/BottomRow/SettingsButton/CatSettings,
	$CenterContainer/MainVBox/ButtonsVBox/BottomRow/ExitButton: $CenterContainer/MainVBox/ButtonsVBox/BottomRow/ExitButton/CatExit
}

func _ready() -> void:
	# 1. Ricarica i dati salvati e i comandi ogni volta che entri nel MainMenu
	if get_node_or_null("/root/Global"):
		Global.load_game()
		Global.load_keybindings()

	# 2. Connessioni segnali click (tuo codice originale)
	$CenterContainer/MainVBox/ButtonsVBox/PlayButton.pressed.connect(_on_gioca)
	$CenterContainer/MainVBox/ButtonsVBox/InventoryButton.pressed.connect(_on_inventario)
	$CenterContainer/MainVBox/ButtonsVBox/ShopButton.pressed.connect(_on_shop)
	$CenterContainer/MainVBox/ButtonsVBox/SkinButton.pressed.connect(_on_skin)
	$CenterContainer/MainVBox/ButtonsVBox/BottomRow/SettingsButton.pressed.connect(_on_impostazioni)
	$CenterContainer/MainVBox/ButtonsVBox/BottomRow/ExitButton.pressed.connect(_on_esci)

	# 3. Connessioni segnali del mouse (tuo codice originale)
	for button in buttons_and_cats.keys():
		var cat_sprite: AnimatedSprite2D = buttons_and_cats[button]
		cat_sprite.hide()
		
		button.mouse_entered.connect(_on_button_mouse_entered.bind(cat_sprite))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(cat_sprite))

	# 4. Timer per lo specchio verticale (tuo codice originale)
	var flip_timer = Timer.new()
	flip_timer.wait_time = 2.0
	flip_timer.autostart = true
	flip_timer.timeout.connect(_on_flip_timer_timeout)
	add_child(flip_timer)
func _on_flip_timer_timeout() -> void:
	for cat_sprite in buttons_and_cats.values():
		cat_sprite.flip_v = !cat_sprite.flip_v
		
		var is_exit_button = (cat_sprite == $CenterContainer/MainVBox/ButtonsVBox/BottomRow/ExitButton/CatExit)
		
		if cat_sprite.flip_v:
			# Applica la posizione normale Y sommata alla variabile di offset
			var pos_y_flippata: float = POS_Y_NORMALE + offset_y_flip
			
			if is_exit_button:
				cat_sprite.position = Vector2(POS_X_FLIPPATA_EXIT, pos_y_flippata)
			else:
				cat_sprite.position = Vector2(POS_X_FLIPPATA_LEFT, pos_y_flippata)
		else:
			# Posizione normale
			if is_exit_button:
				cat_sprite.position = Vector2(POS_X_NORMALE_EXIT, POS_Y_NORMALE)
			else:
				cat_sprite.position = Vector2(POS_X_NORMALE_LEFT, POS_Y_NORMALE)

func _on_button_mouse_entered(cat_sprite: AnimatedSprite2D) -> void:
	cat_sprite.show()
	cat_sprite.play()

func _on_button_mouse_exited(cat_sprite: AnimatedSprite2D) -> void:
	cat_sprite.hide()
	cat_sprite.stop()

# --- CAMBIO SCENE ---

func _on_gioca() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_SELECT)

func _on_inventario() -> void:
	get_tree().change_scene_to_file(SCENE_INVENTORY)

func _on_shop() -> void:
	get_tree().change_scene_to_file(SCENE_SHOP)

func _on_skin() -> void:
	get_tree().change_scene_to_file(SCENE_SKIN)

func _on_impostazioni() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)

func _on_esci() -> void:
	get_tree().quit()
