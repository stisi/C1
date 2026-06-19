extends Node
## Screenshot-Harness, normal gestartet (Autoloads aktiv).
## SHOT_SCENE / SHOT_OUT als Umgebungsvariablen.

func _ready() -> void:
	var szene := OS.get_environment("SHOT_SCENE")
	var ziel := OS.get_environment("SHOT_OUT")
	var packed: PackedScene = load(szene)
	add_child(packed.instantiate())
	for i in 24:
		await get_tree().process_frame
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ziel)
	print("SHOT OK ", ziel, " ", img.get_size())
	get_tree().quit()
