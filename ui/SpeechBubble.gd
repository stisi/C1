class_name SpeechBubble
extends Control
## Comic-Sprechblase mit Tiroler Spruch. Erscheint, wackelt kurz, verschwindet.

var _label: Label
var _panel: PanelContainer


func _ready() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 0.92)
	style.border_color = Color(0.15, 0.1, 0.05)
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	_label.add_theme_font_size_override("font_size", 26)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(420, 0)
	_panel.add_child(_label)
	add_child(_panel)
	visible = false


func say(text: String, dauer: float = 2.2) -> void:
	_label.text = text
	visible = true
	scale = Vector2(0.2, 0.2)
	pivot_offset = _panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(dauer)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.12)
	tw.tween_callback(func(): visible = false)
