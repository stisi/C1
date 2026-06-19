extends Control
## Bier-Exen nach der Salve: Handy kippen (Gyroskop/Beschleunigung), um die
## Maß zu leeren – aber gschmeidig! Zu schnell gekippt = Bier schwappt über.
## Desktop-Test: Maus/Finger gedrückt halten und rauf/runter ziehen kippt.

const SCHWAPP_LIMIT := 2.2        # Kippgeschwindigkeit, ab der's überschwappt
const ZEITLIMIT := 12.0

var _fuellstand := 1.0            # 1.0 = volle Maß
var _verschuettet := 0.0
var _tilt := 0.0                  # 0 = aufrecht, 1 = ganz gekippt
var _prev_tilt := 0.0
var _zeit := 0.0
var _fertig := false
var _drag_y := -1.0

var _krug: Node2D
var _bubble: SpeechBubble
var _info: Label
var _balken_fuell: ColorRect
var _balken_schwapp: ColorRect


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = Color(0.91, 0.77, 0.53)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	var zelt := Sprite2D.new()
	zelt.texture = load("res://art/bierzelt.svg")
	zelt.position = Vector2(360, 640)
	add_child(zelt)

	_info = Label.new()
	_info.text = "EXEN! Kipp's Handy – aber net zu gach!"
	_info.add_theme_font_size_override("font_size", 34)
	_info.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.position = Vector2(0, 80)
	_info.size = Vector2(720, 60)
	add_child(_info)

	_balken_fuell = _balken(Vector2(60, 180), Color(0.95, 0.75, 0.2), "Maß")
	_balken_schwapp = _balken(Vector2(60, 250), Color(0.85, 0.25, 0.2), "Schwapp")

	_krug = Node2D.new()
	_krug.position = Vector2(360, 760)
	_krug.draw.connect(_draw_krug)
	add_child(_krug)

	_bubble = SpeechBubble.new()
	_bubble.position = Vector2(130, 1020)
	add_child(_bubble)


func _balken(pos: Vector2, farbe: Color, text: String) -> ColorRect:
	var hinter := ColorRect.new()
	hinter.color = Color(0.2, 0.15, 0.1)
	hinter.position = pos
	hinter.size = Vector2(600, 36)
	add_child(hinter)
	var vorder := ColorRect.new()
	vorder.color = farbe
	vorder.position = pos + Vector2(3, 3)
	vorder.size = Vector2(594, 30)
	add_child(vorder)
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(8, 2)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	add_child(l)
	return vorder


func _process(delta: float) -> void:
	if _fertig:
		return
	_zeit += delta
	_prev_tilt = _tilt
	_tilt = _lies_kippung()

	var kippgeschw := absf(_tilt - _prev_tilt) / maxf(delta, 0.001)

	# Trinken: ab ~30% Kippung fließt's, je steiler desto schneller.
	if _tilt > 0.3:
		_fuellstand = maxf(0.0, _fuellstand - (_tilt - 0.3) * delta * 0.55)

	# Überschwappen bei ruckartigem Kippen
	if kippgeschw > SCHWAPP_LIMIT and _fuellstand > 0.05:
		_verschuettet += kippgeschw * delta * 0.15
		_fuellstand = maxf(0.0, _fuellstand - kippgeschw * delta * 0.08)

	_balken_fuell.size.x = 594 * _fuellstand
	_balken_schwapp.size.x = 594 * clampf(_verschuettet, 0.0, 1.0)
	_krug.rotation = -_tilt * 1.6
	_krug.queue_redraw()

	if _fuellstand <= 0.0 or _zeit > ZEITLIMIT or _verschuettet >= 1.0:
		_auswerten()


func _lies_kippung() -> float:
	## Echtes Gerät: Gravitationsvektor; sonst Drag-Fallback.
	var g := Input.get_gravity()
	if g.length() > 1.0:
		# Hochformat aufrecht: g.y ≈ -9.8. Kippen Richtung Gesicht/Seite
		# verschiebt die Schwerkraft auf z bzw. x.
		var kipp := clampf((Vector2(g.x, g.z).length()) / 9.8, 0.0, 1.0)
		return kipp
	return _drag_y


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or (event is InputEventMouseMotion \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		_drag_y = clampf(1.0 - event.position.y / 1280.0, 0.0, 1.0)
	if (event is InputEventScreenTouch and not event.pressed) \
			or (event is InputEventMouseButton and not event.pressed):
		_drag_y = 0.0


func _auswerten() -> void:
	_fertig = true
	var punkte := 0
	if _fuellstand <= 0.0 and _verschuettet < 0.25:
		punkte = int(150 - _verschuettet * 200 + maxf(0.0, ZEITLIMIT - _zeit) * 10)
		_info.text = "Ex! +%d" % punkte
		_bubble.say(Dialekt.pick(Dialekt.BIER_PERFEKT))
	else:
		punkte = -40
		_info.text = "Verschüttet bzw. net gschafft!"
		_bubble.say(Dialekt.pick(Dialekt.BIER_VERSCHUETTET))
	GameState.add_score(punkte)
	await get_tree().create_timer(2.8).timeout
	GameState.level += 1
	if GameState.level > 6:
		get_tree().change_scene_to_file("res://scenes/Ergebnis.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Salve.tscn")


func _draw_krug() -> void:
	# Maßkrug mit Henkel, Füllstand und Schaumkrone
	_krug.draw_rect(Rect2(-90, -160, 180, 320), Color(0.75, 0.78, 0.82, 0.55))
	var bier_h := 300.0 * _fuellstand
	_krug.draw_rect(Rect2(-80, 150 - bier_h, 160, bier_h), Color(0.95, 0.72, 0.15))
	if _fuellstand > 0.02:
		_krug.draw_rect(Rect2(-80, 150 - bier_h - 14, 160, 14), Color(0.99, 0.97, 0.9))
	_krug.draw_arc(Vector2(105, -20), 60, -PI / 2, PI / 2, 16, Color(0.7, 0.72, 0.78), 18.0)
	# Verschüttete Lacke daneben
	if _verschuettet > 0.05:
		_krug.draw_circle(Vector2(-140, 170), 30 + _verschuettet * 60, Color(0.9, 0.7, 0.2, 0.6))
