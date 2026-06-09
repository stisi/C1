extends Control
## Ehrentafel: Highscores "Ehrenschützin" und "Marketender des Jahres".

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.35, 0.25, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 34)
	add_child(vbox)

	var titel := Label.new()
	titel.text = "EHRENTAFEL"
	titel.add_theme_font_size_override("font_size", 56)
	titel.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titel)

	vbox.add_child(_eintrag("Ehrenschützin",
		GameState.highscores["ehrenschuetzin"]))
	vbox.add_child(_eintrag("Marketender des Jahres",
		GameState.highscores["marketender"]))

	var b := Button.new()
	b.text = "Zurück"
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(360, 90)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(b)


func _eintrag(name_: String, punkte: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 34)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text = "%s\n%d Punkte" % [name_, punkte] if punkte > 0 \
		else "%s\n– no koaner –" % name_
	return l
