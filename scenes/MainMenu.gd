extends Control
## Hauptmenü: Modus 1 (Ehrensalve), Modus 2 (Marketender), Versus, Highscores.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.75, 0.9)   # Tiroler Himmel
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_berge()
	_figuren()

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(60, 60)
	vbox.size = Vector2(600, 0)
	vbox.add_theme_constant_override("separation", 22)
	add_child(vbox)

	var titel := Label.new()
	titel.text = "Schützenmadln"
	titel.add_theme_font_size_override("font_size", 64)
	titel.add_theme_color_override("font_color", Color(0.2, 0.12, 0.05))
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titel)

	var untertitel := Label.new()
	untertitel.text = "– Salve & Schnaps –"
	untertitel.add_theme_font_size_override("font_size", 34)
	untertitel.add_theme_color_override("font_color", Color(0.45, 0.25, 0.1))
	untertitel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(untertitel)

	vbox.add_child(_spacer(30))
	vbox.add_child(_menu_btn("Die Ehrensalve\n(Schützinnen)", _start_salve))
	vbox.add_child(_menu_btn("Der Marketender\n(Mander im Dirndl)", _start_marketender))
	vbox.add_child(_menu_btn("Frau gegen Marketender\n(2 Spieler, abwechselnd)", _start_versus))
	vbox.add_child(_menu_btn("Ehrentafel (Highscores)", _show_scores))


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _menu_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 28)
	b.custom_minimum_size = Vector2(0, 100)
	b.pressed.connect(cb)
	return b


func _berge() -> void:
	var berge := Polygon2D.new()
	berge.polygon = PackedVector2Array([
		Vector2(0, 700), Vector2(180, 430), Vector2(330, 640),
		Vector2(480, 380), Vector2(720, 680), Vector2(720, 1280), Vector2(0, 1280)
	])
	berge.color = Color(0.5, 0.55, 0.5)
	add_child(berge)
	var wiese := Polygon2D.new()
	wiese.polygon = PackedVector2Array([
		Vector2(0, 860), Vector2(720, 820), Vector2(720, 1280), Vector2(0, 1280)
	])
	wiese.color = Color(0.4, 0.65, 0.3)
	add_child(wiese)


func _figuren() -> void:
	var schuetzin := Figur.new()
	schuetzin.typ = Figur.Typ.SCHUETZIN
	schuetzin.position = Vector2(180, 1030)
	schuetzin.scale = Vector2(1.4, 1.4)
	schuetzin.jubelt = true
	add_child(schuetzin)
	var marketender := Figur.new()
	marketender.typ = Figur.Typ.MARKETENDER
	marketender.position = Vector2(545, 1030)
	marketender.scale = Vector2(1.4, 1.4)
	add_child(marketender)
	var bubble := SpeechBubble.new()
	bubble.position = Vector2(150, 870)
	add_child(bubble)
	await get_tree().create_timer(0.8).timeout
	bubble.say(Dialekt.pick(Dialekt.VERSUS_ANSAGE), 3.0)


func _start_salve() -> void:
	GameState.versus_active = false
	GameState.reset_run(GameState.Mode.SALVE)
	get_tree().change_scene_to_file("res://scenes/Salve.tscn")


func _start_marketender() -> void:
	GameState.versus_active = false
	GameState.reset_run(GameState.Mode.MARKETENDER)
	get_tree().change_scene_to_file("res://scenes/Marketender.tscn")


func _start_versus() -> void:
	GameState.versus_start()
	GameState.reset_run(GameState.Mode.SALVE)
	get_tree().change_scene_to_file("res://scenes/Salve.tscn")


func _show_scores() -> void:
	get_tree().change_scene_to_file("res://scenes/Ehrentafel.tscn")
