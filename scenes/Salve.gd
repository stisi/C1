extends Control
## MODUS 1 – "Die Ehrensalve": Rhythmus-/Timing-Minigame.
## Der Hauptmann zählt ein ("Oans... zwoa... drei... FEUER!").
## Genau auf den vierten Schlag tippen – je genauer, desto synchroner
## kracht die Salve. Das Toleranzfenster schrumpft pro Level.

const BEAT_SEC := 0.8
const SALVEN_PRO_LEVEL := 3

var _schuetzinnen: Array[Figur] = []
var _bubble: SpeechBubble
var _info: Label
var _score_label: Label
var _puls: ColorRect

var _beat := 0
var _target_time_ms := 0
var _armed := false           # wartet auf den Feuer-Tap
var _salve_nr := 0
var _beat_timer: Timer


func _ready() -> void:
	_build_ui()
	_start_salve()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.75, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var wiese := ColorRect.new()
	wiese.color = Color(0.4, 0.65, 0.3)
	wiese.position = Vector2(0, 760)
	wiese.size = Vector2(720, 520)
	add_child(wiese)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 30)
	_score_label.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	_score_label.position = Vector2(20, 20)
	add_child(_score_label)
	_update_score()
	GameState.score_changed.connect(func(_s): _update_score())

	# Die Reihe der Schützinnen
	for i in 5:
		var f := Figur.new()
		f.typ = Figur.Typ.SCHUETZIN
		f.position = Vector2(110 + i * 125, 900)
		f.scale = Vector2(1.3, 1.3)
		add_child(f)
		_schuetzinnen.append(f)

	# Pulsierender Taktgeber
	_puls = ColorRect.new()
	_puls.color = Color(0.8, 0.2, 0.2)
	_puls.size = Vector2(140, 140)
	_puls.position = Vector2(290, 480)
	_puls.pivot_offset = _puls.size / 2.0
	add_child(_puls)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 44)
	_info.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_info.position = Vector2(0, 320)
	_info.size = Vector2(720, 60)
	add_child(_info)

	_bubble = SpeechBubble.new()
	_bubble.position = Vector2(130, 120)
	add_child(_bubble)

	_beat_timer = Timer.new()
	_beat_timer.wait_time = BEAT_SEC
	_beat_timer.timeout.connect(_on_beat)
	add_child(_beat_timer)


func _update_score() -> void:
	_score_label.text = "Level %d  •  %d Punkte" % [GameState.level, GameState.score]


func _start_salve() -> void:
	_salve_nr += 1
	_beat = 0
	_armed = false
	_info.text = "Obacht..."
	await get_tree().create_timer(1.0).timeout
	_beat_timer.start()


func _on_beat() -> void:
	_beat += 1
	AudioDirigent.play_plopp()
	var tw := create_tween()
	tw.tween_property(_puls, "scale", Vector2(1.4, 1.4), 0.08)
	tw.tween_property(_puls, "scale", Vector2.ONE, 0.2)
	match _beat:
		1: _info.text = "Oans..."
		2: _info.text = "Zwoa..."
		3: _info.text = "Drei..."
		4:
			_info.text = "FEUER!"
			_target_time_ms = Time.get_ticks_msec()
			_armed = true
			_beat_timer.stop()
			# Verschlafen? Nach 1.2s gilt die Salve als verpatzt.
			get_tree().create_timer(1.2).timeout.connect(func():
				if _armed:
					_armed = false
					_resolve(999.0))


func _gui_input(event: InputEvent) -> void:
	_handle_tap(event)


func _input(event: InputEvent) -> void:
	_handle_tap(event)


func _handle_tap(event: InputEvent) -> void:
	if not _armed:
		return
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_armed = false
		var error_ms := absf(Time.get_ticks_msec() - _target_time_ms)
		_resolve(error_ms)


func _resolve(error_ms: float) -> void:
	var toleranz := GameState.salve_tolerance_ms()
	var perfekt := error_ms <= toleranz
	_feuere_salve(error_ms, toleranz)
	if perfekt:
		var punkte := int(100 + (toleranz - error_ms))
		GameState.add_score(punkte)
		_info.text = "+%d" % punkte
		_bubble.say(Dialekt.pick(Dialekt.SALVE_PERFEKT))
		for f in _schuetzinnen:
			f.jubelt = true
	else:
		GameState.add_score(-30)
		_info.text = "Daneben! (%d ms)" % int(error_ms)
		_bubble.say(Dialekt.pick(Dialekt.SALVE_DANEBEN))
	await get_tree().create_timer(2.6).timeout
	for f in _schuetzinnen:
		f.jubelt = false
	if _salve_nr < SALVEN_PRO_LEVEL:
		_start_salve()
	else:
		# Nach der Salve wird ex't: ab ins Bier-Minigame.
		get_tree().change_scene_to_file("res://scenes/BierExen.tscn")


func _feuere_salve(error_ms: float, toleranz: float) -> void:
	## Je größer der Fehler, desto stotternder ballert die Reihe.
	var streuung := clampf(error_ms / maxf(toleranz, 1.0), 0.0, 4.0) * 0.18
	for f in _schuetzinnen:
		var verzug := randf() * streuung
		get_tree().create_timer(verzug).timeout.connect(_einzelschuss.bind(f))


func _einzelschuss(f: Figur) -> void:
	AudioDirigent.play_shot()
	f.gewehr_winkel = -0.7
	var blitz := ColorRect.new()
	blitz.color = Color(1.0, 0.9, 0.4)
	blitz.size = Vector2(26, 26)
	blitz.position = f.position + Vector2(40, -190)
	add_child(blitz)
	get_tree().create_timer(0.12).timeout.connect(blitz.queue_free)
	get_tree().create_timer(0.3).timeout.connect(func(): f.gewehr_winkel = -0.5)
