extends Node
## Prozeduraler Blasmusik-Soundtrack (Humbta-Humbta) ohne externe Assets.
## Mit steigendem Pegel (Promille) spielt die Kapelle immer schräger:
## Verstimmung, Tempo-Schwanken und daneben gegriffene Töne.

const SAMPLE_RATE := 22050.0
const BPM := 116.0

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _pegel := 0.0                 # 0.0 = nüchtern, 3.0 = Vollrausch
var _phase_tuba := 0.0
var _phase_horn := 0.0
var _beat_timer := 0.0
var _beat := 0
var _tuba_freq := 87.31           # F2
var _horn_freq := 349.23          # F4
var _env_tuba := 0.0
var _env_horn := 0.0
var _detune := 1.0

# Einfache Polka-Bassline (F-Dur): F B C F ...
const TUBA_NOTES := [87.31, 116.54, 130.81, 87.31]
const HORN_CHORD := [349.23, 440.0, 523.25, 440.0]

var enabled := true


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.15
	_player.stream = gen
	_player.volume_db = -10.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func set_pegel(promille: float) -> void:
	_pegel = clampf(promille, 0.0, 3.0)


func _process(_delta: float) -> void:
	if not enabled or _playback == null:
		return
	_fill_buffer()


func _fill_buffer() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	# Tempo schwankt im Rausch: Kapelle eilt und schleppt.
	var wobble := 1.0 + sin(Time.get_ticks_msec() / 900.0) * 0.08 * _pegel
	var beat_len := (60.0 / BPM) / wobble
	for i in frames:
		_beat_timer += 1.0 / SAMPLE_RATE
		if _beat_timer >= beat_len / 2.0:   # Achtel: Hum-bta
			_beat_timer = 0.0
			_beat = (_beat + 1) % 8
			_trigger_beat()
		var s := _synth_frame()
		_playback.push_frame(Vector2(s, s))


func _trigger_beat() -> void:
	if _beat % 2 == 0:
		# Tuba auf den schweren Zeiten
		_tuba_freq = TUBA_NOTES[(_beat / 2) % TUBA_NOTES.size()]
		_env_tuba = 1.0
	else:
		# Hörner auf den Nachschlag
		_horn_freq = HORN_CHORD[randi() % HORN_CHORD.size()]
		_env_horn = 0.8
	# Verstimmung: je mehr Promille, desto weiter daneben.
	_detune = 1.0 + randf_range(-0.06, 0.06) * _pegel
	# Im Vollrausch greift wer komplett daneben.
	if _pegel > 1.5 and randf() < 0.06 * _pegel:
		_detune *= randf_range(0.7, 1.4)


func _synth_frame() -> float:
	var dt := 1.0 / SAMPLE_RATE
	_phase_tuba = fmod(_phase_tuba + _tuba_freq * _detune * dt, 1.0)
	_phase_horn = fmod(_phase_horn + _horn_freq * _detune * dt, 1.0)
	_env_tuba = maxf(0.0, _env_tuba - dt * 5.0)
	_env_horn = maxf(0.0, _env_horn - dt * 7.0)
	# Tuba: weiche Rechteckwelle, Horn: Sägezahn-artig
	var tuba := (1.0 if _phase_tuba < 0.5 else -1.0) * 0.28 * _env_tuba
	var horn := (_phase_horn * 2.0 - 1.0) * 0.14 * _env_horn
	return tuba + horn


func play_shot() -> void:
	_burst(0.10, 0.9)


func play_plopp() -> void:
	_burst(0.03, 0.4)


func _burst(dur: float, amp: float) -> void:
	## Kurzer Rausch-Impuls (Schuss / Plopp) direkt in den Puffer.
	if _playback == null:
		return
	var n := mini(int(dur * SAMPLE_RATE), _playback.get_frames_available())
	for i in n:
		var env := 1.0 - float(i) / n
		var s := randf_range(-1.0, 1.0) * amp * env
		_playback.push_frame(Vector2(s, s))
