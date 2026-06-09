class_name Figur
extends Node2D
## Prozedural gezeichnete Comic-Figuren (keine externen Assets nötig).
## SCHUETZIN: Frau in Tiroler Schützentracht (Hut mit Spielhahnfeder,
##            Lodenjanker, Bandelier, Gewehr).
## MARKETENDER: Mann im Dirndl (Schürze, Schnapsfassl, Dreitagebart).

enum Typ { SCHUETZIN, MARKETENDER }

const LODEN := Color(0.45, 0.33, 0.2)
const DIRNDL := Color(0.78, 0.2, 0.25)
const SCHUERZE := Color(0.55, 0.75, 0.55)
const HAUT := Color(0.98, 0.85, 0.72)
const HUT := Color(0.25, 0.5, 0.25)

@export var typ: Typ = Typ.SCHUETZIN
var feder_winkel := 0.0      # Spielhahnfeder; hängt im Rausch schief
var gewehr_winkel := -0.5    # Anschlagswinkel des Gewehrs
var jubelt := false
var umgefallen := false
var _wobble_t := randf() * TAU


func _process(delta: float) -> void:
	_wobble_t += delta * 2.0
	if umgefallen:
		rotation = lerp_angle(rotation, PI / 2.0 * 0.9, delta * 4.0)
	elif jubelt:
		position.y += sin(_wobble_t * 6.0) * 1.5
	queue_redraw()


func _draw() -> void:
	if typ == Typ.SCHUETZIN:
		_draw_schuetzin()
	else:
		_draw_marketender()


func _kopf(haarfarbe: Color, mit_bart: bool) -> void:
	draw_circle(Vector2(0, -70), 22, HAUT)
	# Augen + Grinsen (Comic)
	draw_circle(Vector2(-7, -74), 3, Color.BLACK)
	draw_circle(Vector2(7, -74), 3, Color.BLACK)
	draw_arc(Vector2(0, -66), 9, 0.3, PI - 0.3, 12, Color.BLACK, 2.5)
	if mit_bart:
		# Dreitagebart – der Mann im Dirndl bleibt erkennbar a Mannsbild.
		for p in [Vector2(-10, -58), Vector2(0, -55), Vector2(10, -58), Vector2(-5, -60), Vector2(5, -60)]:
			draw_circle(p, 1.4, Color(0.2, 0.15, 0.1))
	else:
		# Zöpfe
		draw_circle(Vector2(-22, -62), 7, haarfarbe)
		draw_circle(Vector2(22, -62), 7, haarfarbe)


func _draw_schuetzin() -> void:
	# Lodenjanker (Körper)
	draw_rect(Rect2(-24, -50, 48, 60), LODEN)
	# Bandelier (Schärpe quer über die Brust)
	draw_line(Vector2(-22, -48), Vector2(22, 0), Color(0.85, 0.75, 0.3), 8.0)
	# Rock
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, 10), Vector2(24, 10), Vector2(34, 50), Vector2(-34, 50)
	]), Color(0.3, 0.22, 0.15))
	_kopf(Color(0.4, 0.25, 0.1), false)
	# Tiroler Hut
	draw_rect(Rect2(-26, -92, 52, 8), HUT)
	draw_rect(Rect2(-16, -108, 32, 18), HUT)
	_feder(Vector2(8, -106))
	# Gewehr (rotierbar für die Salve)
	draw_set_transform(Vector2(20, -30), gewehr_winkel, Vector2.ONE)
	draw_rect(Rect2(-4, -70, 8, 80), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(-3, -78, 6, 12), Color(0.2, 0.2, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if jubelt:
		# Arme hoch!
		draw_line(Vector2(-20, -40), Vector2(-38, -70), HAUT, 7.0)
		draw_line(Vector2(20, -40), Vector2(38, -70), HAUT, 7.0)


func _draw_marketender() -> void:
	# Dirndl-Oberteil – etwas zu eng, sitzt halt net wie angegossen.
	draw_rect(Rect2(-26, -50, 52, 35), DIRNDL)
	# Breite Mannsbild-Schultern schauen raus
	draw_line(Vector2(-30, -48), Vector2(30, -48), HAUT, 6.0)
	# Dirndl-Rock
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26, -15), Vector2(26, -15), Vector2(40, 50), Vector2(-40, 50)
	]), DIRNDL)
	# Schürze
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -12), Vector2(16, -12), Vector2(24, 46), Vector2(-24, 46)
	]), SCHUERZE)
	# Schnapsfassl umgehängt
	draw_line(Vector2(-18, -45), Vector2(14, -5), Color(0.4, 0.3, 0.15), 5.0)
	draw_rect(Rect2(2, -12, 26, 18), Color(0.6, 0.42, 0.2))
	draw_rect(Rect2(2, -7, 26, 3), Color(0.3, 0.3, 0.3))
	_kopf(Color(0.25, 0.18, 0.1), true)
	# Haarmasche als Krönung
	draw_circle(Vector2(-14, -88), 6, Color(0.9, 0.6, 0.7))
	draw_circle(Vector2(-2, -88), 6, Color(0.9, 0.6, 0.7))
	if umgefallen:
		# X-Augen überm Comic-Gesicht
		draw_line(Vector2(-10, -78), Vector2(-4, -70), Color.BLACK, 2.5)
		draw_line(Vector2(-4, -78), Vector2(-10, -70), Color.BLACK, 2.5)


func _feder(at: Vector2) -> void:
	## Spielhahnfeder – Winkel dient im Modus 2 als Promille-Anzeige.
	draw_set_transform(at, feder_winkel, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(6, -16), Vector2(10, -30), Vector2(2, -18)
	]), Color(0.1, 0.1, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, -10), Vector2(12, -26), Vector2(8, -12)
	]), Color(0.5, 0.3, 0.1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
