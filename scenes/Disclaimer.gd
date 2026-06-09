extends Control
## Pflicht-Disclaimer (16+): Alkohol-Humor, Aufruf zur Verantwortung.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)

	var alter := Label.new()
	alter.text = "16+"
	alter.add_theme_font_size_override("font_size", 90)
	alter.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	alter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(alter)

	var text := Label.new()
	text.text = "Dieses Spiel enthält satirischen Alkohol-Humor.\n\nTrink verantwortungsvoll –\nim echten Leben schießt man nüchtern.\n\nKein echter Schnaps wurde beim\nEntwickeln dieses Spiels verschwendet."
	text.add_theme_font_size_override("font_size", 30)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(620, 0)
	text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(text)

	var btn := Button.new()
	btn.text = "Verstanden – eini ins Zelt!"
	btn.add_theme_font_size_override("font_size", 32)
	btn.custom_minimum_size = Vector2(420, 90)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(btn)
