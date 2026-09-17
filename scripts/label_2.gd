extends Label

@onready var label: Label = $"../Label_plains"




func _process(delta: float) -> void:
	if Global.money == 1:
		label.text = "hai raccolto " + str(Global.money) + " moneta. necessiti di quindici
	 monete per oltrepassare il portale"
	else:
		label.text = "hai raccolto " + str(Global.money) + " monete. necessiti di quindici
	 	monete per oltrepassare il portale"
