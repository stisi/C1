extends Node
## Globaler Spielzustand: Level, Punkte, Promille, 2-Spieler-Wechselmodus.

const SAVE_PATH := "user://schuetzenmadln_save.cfg"

enum Mode { SALVE, MARKETENDER }

# --- Laufender Spielstand ---
var current_mode: Mode = Mode.SALVE
var level: int = 1
var score: int = 0
var promille: float = 0.0          # Betrunkenheit des Marketenders (0.0 .. 3.0)

# --- 2-Spieler-Wechselmodus (Frau vs. Marketender) ---
var versus_active: bool = false
var versus_round: int = 1          # 3 Runden pro Spieler
var versus_scores := {Mode.SALVE: 0, Mode.MARKETENDER: 0}

# --- Highscores ---
var highscores := {
	"ehrenschuetzin": 0,           # Modus 1
	"marketender": 0,              # Modus 2
}

signal score_changed(new_score: int)
signal promille_changed(new_promille: float)


func _ready() -> void:
	load_scores()


func add_score(points: int) -> void:
	score = maxi(0, score + points)
	score_changed.emit(score)


func add_promille(amount: float) -> void:
	promille = clampf(promille + amount, 0.0, 3.0)
	promille_changed.emit(promille)
	AudioDirigent.set_pegel(promille)


func reset_run(mode: Mode) -> void:
	current_mode = mode
	level = 1
	score = 0
	promille = 0.0
	AudioDirigent.set_pegel(0.0)


func finish_run() -> void:
	## Lauf beenden, Highscore eintragen, ggf. Versus-Wertung fortschreiben.
	var key := "ehrenschuetzin" if current_mode == Mode.SALVE else "marketender"
	if score > highscores[key]:
		highscores[key] = score
		save_scores()
	if versus_active:
		versus_scores[current_mode] += score


func versus_start() -> void:
	versus_active = true
	versus_round = 1
	versus_scores = {Mode.SALVE: 0, Mode.MARKETENDER: 0}


func versus_next_mode() -> Mode:
	## Wechselt nach jedem Lauf zwischen Schützin und Marketender.
	return Mode.MARKETENDER if current_mode == Mode.SALVE else Mode.SALVE


func save_scores() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("highscores", "ehrenschuetzin", highscores["ehrenschuetzin"])
	cfg.set_value("highscores", "marketender", highscores["marketender"])
	cfg.save(SAVE_PATH)


func load_scores() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highscores["ehrenschuetzin"] = cfg.get_value("highscores", "ehrenschuetzin", 0)
		highscores["marketender"] = cfg.get_value("highscores", "marketender", 0)


# --- Schwierigkeitskurven ---

func salve_tolerance_ms() -> float:
	## Toleranzfenster der Salve wird pro Level kleiner (350ms -> min 80ms).
	return maxf(80.0, 350.0 - (level - 1) * 45.0)


func marketender_targets() -> int:
	## Anzahl Stamperl pro Level.
	return 3 + level
