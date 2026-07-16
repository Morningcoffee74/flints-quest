extends Node

## Dev-tool: laadt een level, teleporteert de speler langs vaste punten en
## slaat viewport-screenshots op. Start met:
##   godot --path . res://tools/ShotRunner.tscn
## Instellen via omgevingsvariabelen:
##   SHOT_SCENE=res://scenes/levels/world1/W1L1.tscn
##   SHOT_XS=600,2080,3400,6300     (x-posities in px)
##   SHOT_OUT=/tmp                  (uitvoermap)

func _ready() -> void:
	_run()

func _run() -> void:
	var scene_path := OS.get_environment("SHOT_SCENE")
	if scene_path.is_empty():
		scene_path = "res://scenes/levels/world1/W1L1.tscn"
	var out_dir := OS.get_environment("SHOT_OUT")
	if out_dir.is_empty():
		out_dir = "/tmp"
	var xs: Array = []
	for part: String in OS.get_environment("SHOT_XS").split(",", false):
		xs.append(part.to_float())
	if xs.is_empty():
		xs = [600.0]

	var level: Node = (load(scene_path) as PackedScene).instantiate()
	add_child(level)
	await get_tree().create_timer(1.2).timeout

	var player: Node2D = level.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var idx := 1
	for x: float in xs:
		player.global_position = Vector2(x, 560.0)
		player.velocity = Vector2.ZERO
		camera.reset_smoothing()
		if idx == xs.size():
			# Laatste shot: power-ups actief zodat de HUD-balkjes te zien zijn.
			player.activate_speed()
			player.activate_strong_punch()
		await get_tree().create_timer(1.0).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/shot%d.png" % [out_dir, idx])
		print("shot %d @ x=%d" % [idx, int(x)])
		idx += 1
	get_tree().quit()
