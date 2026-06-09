extends Control
## Ergebnis nach einem Lauf. Im Versus-Modus: Geräte-Übergabe an den
## nächsten Spieler bzw. Endabrechnung Frau vs. Marketender.

func _ready() -> void:
	GameState.finish_run()
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.18, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 26)
	add_child(vbox)

	var ist_salve := GameState.current_mode == GameState.Mode.SALVE
	var titel := Label.new()
	titel.add_theme_font_size_override("font_size", 44)
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titel.text = "Salve geschlagen!" if ist_salve else "Ausschank beendet!"
	vbox.add_child(titel)

	var punkte := Label.new()
	punkte.add_theme_font_size_override("font_size", 60)
	punkte.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	punkte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	punkte.text = "%d Punkte" % GameState.score
	vbox.add_child(punkte)

	var key := "ehrenschuetzin" if ist_salve else "marketender"
	if GameState.score >= GameState.highscores[key] and GameState.score > 0:
		var rekord := Label.new()
		rekord.add_theme_font_size_override("font_size", 32)
		rekord.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		rekord.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rekord.text = "Neuer Rekord: %s!" \
			% ("Ehrenschützin" if ist_salve else "Marketender des Jahres")
		vbox.add_child(rekord)

	if GameState.versus_active:
		_versus_teil(vbox)
	else:
		vbox.add_child(_btn("Nochmal!", func():
			GameState.reset_run(GameState.current_mode)
			var ziel := "res://scenes/Salve.tscn" if ist_salve \
				else "res://scenes/Marketender.tscn"
			get_tree().change_scene_to_file(ziel)))
		vbox.add_child(_btn("Zum Hauptmenü", func():
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")))


func _versus_teil(vbox: VBoxContainer) -> void:
	var s_frau: int = GameState.versus_scores[GameState.Mode.SALVE]
	var s_mann: int = GameState.versus_scores[GameState.Mode.MARKETENDER]
	var beide_gespielt := GameState.current_mode == GameState.Mode.MARKETENDER

	if not beide_gespielt:
		var hinweis := Label.new()
		hinweis.add_theme_font_size_override("font_size", 30)
		hinweis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hinweis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hinweis.custom_minimum_size = Vector2(600, 0)
		hinweis.text = "Handy weitergeben!\nJetzt kommt der Marketender dran – Dirndl richten, Bua!"
		vbox.add_child(hinweis)
		vbox.add_child(_btn("Bin bereit – Ausschank!", func():
			GameState.reset_run(GameState.Mode.MARKETENDER)
			get_tree().change_scene_to_file("res://scenes/Marketender.tscn")))
	else:
		var stand := Label.new()
		stand.add_theme_font_size_override("font_size", 34)
		stand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stand.text = "Schützin %d : %d Marketender" % [s_frau, s_mann]
		vbox.add_child(stand)
		var sieger := Label.new()
		sieger.add_theme_font_size_override("font_size", 40)
		sieger.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
		sieger.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if s_frau > s_mann:
			sieger.text = "D'Madln gwinnen – wia immer!"
		elif s_mann > s_frau:
			sieger.text = "Da Marketender gwinnt – trotz Pegel!"
		else:
			sieger.text = "Unentschieden – no a Runde!"
		vbox.add_child(sieger)
		GameState.versus_active = false
		vbox.add_child(_btn("Zum Hauptmenü", func():
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")))


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(440, 90)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b
