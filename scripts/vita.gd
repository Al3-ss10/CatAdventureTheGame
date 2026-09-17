extends Node2D


func remove_hearts():
	Global.vita = Global.vita - 1
	print(Global.vita)
func add_hearts():
	if Global.vita == 1 || Global.vita == 2:
		Global.vita += 1
		print(Global.vita)
