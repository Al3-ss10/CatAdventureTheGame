extends Area2D

@onready var danno: AudioStreamPlayer2D = $"../danno"
@onready var morte: AudioStreamPlayer2D = $"../morte"

# Trascina qui il tuo ColorRect dall'ispettore

@onready var transizione_shader: ColorRect = $CanvasLayer/ColorRect

func _on_body_entered(body: Node2D) -> void:
	if not Global.flag:
		Global.vita -= 1
		danno.play()

	if Global.vita <= 0:
		# Disattiva l'area per sicurezza
		monitoring = false 
		
		# ===================================================
		# CONGELA IL GIOCO
		# ===================================================
		get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		
		# 1. FA PARTIRE L'EFFETTO SHADER
		var tempo_shader: float = 0.5 # Imposta qui la stessa durata del "duration_in" dello shader
		if transizione_shader:
			transizione_shader.process_mode = Node.PROCESS_MODE_ALWAYS
			transizione_shader.fade_in()
			# Se lo shader ha una variabile pubblica per la durata, la leggiamo direttamente:
			if "duration_in" in transizione_shader:
				tempo_shader = transizione_shader.duration_in
				tempo_shader+= transizione_shader.duration_out
				tempo_shader += transizione_shader.await_time

		# 2. FA PARTIRE L'AUDIO
		morte.process_mode = Node.PROCESS_MODE_ALWAYS
		morte.play()
		
		# ===================================================
		# ATTESA SINCRONIZZATA
		# ===================================================
		# Creiamo un timer che gira anche a gioco congelato (PROCESS_MODE_ALWAYS)
		var timer_attesa = get_tree().create_timer(tempo_shader, true, false, true)
		
		# Aspettiamo che il timer dello shader FINISCA
		await timer_attesa.timeout
		
		# Se vuoi essere sicuro al 100% che anche l'audio sia terminato prima di restartare,
		# puoi lasciare questa riga (se l'audio è più lungo, aspetterà l'audio, altrimenti passa subito oltre)
		if morte.playing:
			await morte.finished
		
		# ===================================================
		# RIAVVIO
		# ===================================================
		if get_tree():
			get_tree().reload_current_scene()
			Global.vita = 3
			Global.money = 0
			Global.gomitolo = false
			Global.box = false
			Global.magnete = false

			Global.MoneteCorrenti = 0
