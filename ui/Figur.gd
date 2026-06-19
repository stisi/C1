class_name Figur
extends Node2D
## Gezeichnete Comic-Figuren aus SVG-Illustrationen.
## SCHUETZIN: Frau in Tiroler Schützentracht (Hut, Lodenjanker, Bandelier, Gewehr).
## MARKETENDER: Mannsbild im Dirndl (Schürze, Schnapsfassl, Dreitagebart).
## Feder (Promille-Anzeige) und Gewehr (Salve) sind eigene, um ihre Basis
## drehbare Teil-Sprites, damit die Animationen erhalten bleiben.

enum Typ { SCHUETZIN, MARKETENDER }

const TARGET_H := 260.0          # gewünschte Bildhöhe der Figur in Pixeln
const TEX := {
	Typ.SCHUETZIN: "res://art/schuetzin.svg",
	Typ.MARKETENDER: "res://art/marketender.svg",
}
# Anbaupunkte in Textur-Pixeln (Bildmitte = 110,190)
const FEDER_MOUNT := {
	Typ.SCHUETZIN: Vector2(138, 56),
	Typ.MARKETENDER: Vector2(92, 60),
}
const GEWEHR_MOUNT := Vector2(168, 226)

@export var typ: Typ = Typ.SCHUETZIN
var feder_winkel := 0.0          # Spielhahnfeder; hängt im Rausch schief
var gewehr_winkel := -0.5        # Anschlagswinkel des Gewehrs
var jubelt := false
var umgefallen := false

var _body: Sprite2D
var _feder_pivot: Node2D
var _gewehr_pivot: Node2D
var _wobble_t := randf() * TAU


func _ready() -> void:
	_body = Sprite2D.new()
	var tex: Texture2D = load(TEX[typ])
	_body.texture = tex
	_body.centered = true
	var s := TARGET_H / tex.get_height()
	_body.scale = Vector2(s, s)
	add_child(_body)

	# Spielhahnfeder als eigenes, um die Basis drehbares Sprite.
	_feder_pivot = Node2D.new()
	_feder_pivot.position = FEDER_MOUNT[typ] - Vector2(110, 190)
	_body.add_child(_feder_pivot)
	var feder := Sprite2D.new()
	feder.texture = load("res://art/feder.svg")
	feder.centered = false
	feder.offset = Vector2(-30, -158)   # Basis (30,158) sitzt auf dem Pivot
	_feder_pivot.add_child(feder)

	# Gewehr nur für die Schützin.
	if typ == Typ.SCHUETZIN:
		_gewehr_pivot = Node2D.new()
		_gewehr_pivot.position = GEWEHR_MOUNT - Vector2(110, 190)
		_body.add_child(_gewehr_pivot)
		var gewehr := Sprite2D.new()
		gewehr.texture = load("res://art/gewehr.svg")
		gewehr.centered = false
		gewehr.offset = Vector2(-22, -290)   # Kolben sitzt in der Hand
		_gewehr_pivot.add_child(gewehr)


func _process(delta: float) -> void:
	_wobble_t += delta * 2.0
	if umgefallen:
		rotation = lerp_angle(rotation, PI / 2.0 * 0.9, delta * 4.0)
	elif jubelt:
		_body.position.y = sin(_wobble_t * 6.0) * 6.0 - 4.0
		_body.rotation = sin(_wobble_t * 3.0) * 0.04
	else:
		_body.position.y = lerp(_body.position.y, 0.0, delta * 6.0)
		_body.rotation = lerp_angle(_body.rotation, 0.0, delta * 6.0)
	_feder_pivot.rotation = feder_winkel
	if _gewehr_pivot:
		_gewehr_pivot.rotation = gewehr_winkel
