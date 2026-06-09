extends Control
## MODUS 2 – "Der Marketender": Mander im Dirndl schenken Schnaps aus.
## Halten = einschenken. Stamperl exakt bis zur Marke füllen, nicht
## überlaufen lassen. REGEL: Nach jedem Ausschank trinkt der Marketender
## selbst eins mit – der Pegel steigt und macht alles schwerer:
##  - Bildschirm wackelt und verschwimmt
##  - die Hand zittert, die Flasche schwankt
##  - Touch-Eingaben kommen leicht versetzt an (Eingabe-Lag)
## Promille-Anzeige: Spielhahnfeder, die immer schiefer hängt.

const ZIEL_MIN := 0.82            # Stamperl gilt ab hier als voll
const ZIEL_MAX := 1.0             # darüber läuft's über

var _stamperl_fuellung := 0.0
var _stamperl_nr := 0
var _giesst := false
var _fertig := false
var _wertung_laeuft := false
var _input_verzoegerung: Array = []   # [endzeit_ms, pressed] – versetzte Eingaben

var _welt: Node2D                 # alles, was im Rausch wackelt
var _flasche: Node2D
var _glas: Node2D
var _feder_anzeige: Figur
var _bubble: SpeechBubble
var _info: Label
var _score_label: Label
var _blur: ColorRect
var _wobble_t := 0.0


func _ready() -> void:
	_welt = Node2D.new()
	add_child(_welt)

	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.7, 0.45)
	bg.position = Vector2(-100, -100)
	bg.size = Vector2(920, 1480)
	_welt.add_child(bg)
	_zeltdeko()

	# Durstige Schützin wartet am Tisch
	var schuetzin := Figur.new()
	schuetzin.typ = Figur.Typ.SCHUETZIN
	schuetzin.position = Vector2(140, 700)
	schuetzin.scale = Vector2(1.4, 1.4)
	_welt.add_child(schuetzin)

	# Der Marketender selbst (Promille-Feder als Anzeige)
	_feder_anzeige = Figur.new()
	_feder_anzeige.typ = Figur.Typ.MARKETENDER
	_feder_anzeige.position = Vector2(580, 700)
	_feder_anzeige.scale = Vector2(1.4, 1.4)
	_welt.add_child(_feder_anzeige)

	_glas = Node2D.new()
	_glas.position = Vector2(360, 880)
	_glas.draw.connect(_draw_glas)
	_welt.add_child(_glas)

	_flasche = Node2D.new()
	_flasche.position = Vector2(360, 700)
	_flasche.draw.connect(_draw_flasche)
	_welt.add_child(_flasche)

	# Unschärfe-Schleier (verschwimmender Blick)
	_blur = ColorRect.new()
	_blur.color = Color(0.9, 0.85, 0.7, 0.0)
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blur)

	_info = Label.new()
	_info.text = "Halten = einschenken. Bis zur Marke – net drüber!"
	_info.add_theme_font_size_override("font_size", 30)
	_info.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.position = Vector2(0, 90)
	_info.size = Vector2(720, 60)
	add_child(_info)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	_score_label.position = Vector2(20, 20)
	add_child(_score_label)
	_update_hud()
	GameState.score_changed.connect(func(_s): _update_hud())
	GameState.promille_changed.connect(func(_p): _update_hud())

	_bubble = SpeechBubble.new()
	_bubble.position = Vector2(110, 380)
	add_child(_bubble)
	_bubble.say(Dialekt.pick(Dialekt.DURSTIGE_SCHUETZINNEN), 2.5)


func _zeltdeko() -> void:
	# Weiß-blaue Zeltbahnen
	for i in 8:
		var bahn := ColorRect.new()
		bahn.color = Color(0.95, 0.95, 0.95) if i % 2 == 0 else Color(0.55, 0.65, 0.85)
		bahn.position = Vector2(-100 + i * 115, -100)
		bahn.size = Vector2(115, 320)
		_welt.add_child(bahn)
	var tisch := ColorRect.new()
	tisch.color = Color(0.55, 0.38, 0.2)
	tisch.position = Vector2(-100, 920)
	tisch.size = Vector2(920, 660)
	_welt.add_child(tisch)


func _update_hud() -> void:
	_score_label.text = "Level %d  •  %d Punkte  •  %.1f ‰" \
		% [GameState.level, GameState.score, GameState.promille]


func _process(delta: float) -> void:
	if _fertig:
		return
	_wobble_t += delta
	var p := GameState.promille

	# Verspätete Eingaben anwenden (Eingabe-Lag im Rausch)
	var now := Time.get_ticks_msec()
	while not _input_verzoegerung.is_empty() and _input_verzoegerung[0][0] <= now:
		_giesst = _input_verzoegerung.pop_front()[1]

	# Bildschirmwackeln + Verschwimmen
	_welt.position = Vector2(
		sin(_wobble_t * 1.7) * 14.0 * p,
		cos(_wobble_t * 1.3) * 10.0 * p)
	_welt.rotation = sin(_wobble_t * 0.9) * 0.02 * p
	_blur.color.a = clampf(p * 0.13, 0.0, 0.45)

	# Flasche schwankt, Hand zittert
	var zitter := sin(_wobble_t * 23.0) * 4.0 * p + randf_range(-1.5, 1.5) * p
	_flasche.position.x = 360 + sin(_wobble_t * 2.1) * 30.0 * p + zitter
	_flasche.rotation = (0.9 if _giesst else 0.0) + sin(_wobble_t * 3.3) * 0.15 * p

	# Einschenken: trifft der Strahl das Glas überhaupt noch?
	if _giesst:
		var daneben := absf(_flasche.position.x - _glas.position.x) > 50.0
		if not daneben:
			_stamperl_fuellung += delta * 0.45
		if _stamperl_fuellung > ZIEL_MAX:
			_stamperl_abschliessen(false, "Übergelaufen!")
	_flasche.queue_redraw()
	_glas.queue_redraw()

	# Promille-Feder hängt immer schiefer (bis ~80° im Vollrausch)
	_feder_anzeige.feder_winkel = p / 3.0 * 1.4
	if p >= 3.0:
		_umfallen()


func _input(event: InputEvent) -> void:
	if _fertig:
		return
	var ist_touch := event is InputEventScreenTouch or event is InputEventMouseButton
	if not ist_touch:
		return
	# Touch kommt je nach Pegel bis zu ~0,5s versetzt an.
	var lag_ms := int(GameState.promille * 160.0)
	_input_verzoegerung.append([Time.get_ticks_msec() + lag_ms, event.pressed])


func _stamperl_abschliessen(geschafft: bool, text: String) -> void:
	if _wertung_laeuft:
		return
	_wertung_laeuft = true
	_giesst = false
	_input_verzoegerung.clear()
	_stamperl_nr += 1
	if geschafft:
		var punkte := int(120 * _stamperl_fuellung)
		GameState.add_score(punkte)
		_info.text = "%s +%d" % [text, punkte]
		_bubble.say(Dialekt.pick(Dialekt.SCHNAPS_PERFEKT))
	else:
		GameState.add_score(-40)
		_info.text = text
		_bubble.say(Dialekt.pick(Dialekt.SCHNAPS_DANEBEN))

	# DIE REGEL: selber eins mittrinken. Prost. Hicks.
	GameState.add_promille(0.35)
	if GameState.promille > 1.5 and randf() < 0.5:
		await get_tree().create_timer(1.2).timeout
		_bubble.say(Dialekt.pick(Dialekt.BETRUNKEN_KOMMENTARE))

	_stamperl_fuellung = 0.0
	await get_tree().create_timer(2.2).timeout
	_wertung_laeuft = false
	if _fertig:
		return
	if _stamperl_nr >= GameState.marketender_targets():
		_level_geschafft()
	else:
		_bubble.say(Dialekt.pick(Dialekt.DURSTIGE_SCHUETZINNEN), 2.0)


func _level_geschafft() -> void:
	_fertig = true
	GameState.level += 1
	if GameState.level > 6:
		get_tree().change_scene_to_file("res://scenes/Ergebnis.tscn")
	else:
		# Kurze Verschnaufpause senkt den Pegel minimal – mehr Gnade gibt's net.
		GameState.add_promille(-0.2)
		get_tree().change_scene_to_file("res://scenes/Marketender.tscn")


func _umfallen() -> void:
	## Vollrausch: Der Marketender fällt um, der Lauf ist vorbei.
	_fertig = true
	_feder_anzeige.umgefallen = true
	_info.text = "Umgefallen! Aus is'!"
	_bubble.say("Zefix... liegen... bleibt er...", 2.5)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/Ergebnis.tscn")


func _physics_process(_delta: float) -> void:
	# Wertung erst, wenn der Finger (samt Rausch-Verzögerung) oben ist.
	if _fertig or _giesst or _wertung_laeuft:
		return
	# Glas voll genug und nicht mehr am Gießen -> werten (einmalig)
	if _stamperl_fuellung >= ZIEL_MIN and _stamperl_fuellung <= ZIEL_MAX:
		_stamperl_abschliessen(true, "Passt!")
	elif _stamperl_fuellung > 0.05 and _stamperl_fuellung < ZIEL_MIN \
			and _input_verzoegerung.is_empty():
		# Zu wenig eingeschenkt und losgelassen: zählt als halbe Sache
		_stamperl_abschliessen(false, "Z'wenig! Des is a Pfütze, koa Stamperl!")


func _draw_flasche() -> void:
	_flasche.draw_rect(Rect2(-22, -60, 44, 90), Color(0.25, 0.45, 0.25))
	_flasche.draw_rect(Rect2(-8, -95, 16, 35), Color(0.25, 0.45, 0.25))
	_flasche.draw_rect(Rect2(-10, -102, 20, 8), Color(0.6, 0.45, 0.2))
	_flasche.draw_rect(Rect2(-16, -45, 32, 40), Color(0.9, 0.85, 0.7))
	if _giesst:
		# Schnapsstrahl
		_flasche.draw_rect(Rect2(-3, 30, 6, 130), Color(0.95, 0.92, 0.75, 0.85))


func _draw_glas() -> void:
	# Stamperl mit Füllmarke
	_glas.draw_rect(Rect2(-30, -10, 60, 70), Color(0.8, 0.85, 0.9, 0.5))
	var h := 64.0 * clampf(_stamperl_fuellung, 0.0, 1.1)
	_glas.draw_rect(Rect2(-26, 56 - h, 52, h), Color(0.95, 0.9, 0.7))
	# Ziel-Marke
	_glas.draw_line(Vector2(-34, 56 - 64 * ZIEL_MIN), Vector2(34, 56 - 64 * ZIEL_MIN),
		Color(0.8, 0.2, 0.2), 3.0)
	if _stamperl_fuellung > ZIEL_MAX:
		_glas.draw_circle(Vector2(0, 70), 18, Color(0.95, 0.9, 0.7, 0.8))
