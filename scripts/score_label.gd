extends Label

@onready var score_label: Label = $"."




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	score_label.text =  str(Global.vita)
