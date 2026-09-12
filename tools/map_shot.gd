extends Node

## Dev-tool: rendert het wereldkaart-scherm van één wereld en slaat er een
## screenshot van op, zodat de bolletjes uit WorldMap.LEVEL_POSITIONS naast de
## echte open plekken op de achtergrond te leggen zijn. Zonder die controle
## staan de coördinaten er makkelijk naast (zie docs/Claude-worldmap-coords-prompt.md).
##
## Start: MAP_WORLD=4 MAP_OUT=/pad Godot --path . res://tools/MapShot.tscn

func _ready() -> void:
	_run()

func _run() -> void:
	var world := int(OS.get_environment("MAP_WORLD"))
	if world <= 0:
		world = 1
	var out_dir := OS.get_environment("MAP_OUT")
	if out_dir.is_empty():
		out_dir = "/tmp"
	# Alles ontgrendelen, anders zijn de bolletjes grijs en slecht te zien.
	GameManager.current_world = world
	var map: Node = (load("res://scenes/ui/WorldMap.tscn") as PackedScene).instantiate()
	add_child(map)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/worldmap_%d.png" % [out_dir, world]
	img.save_png(path)
	print("geschreven: ", path)
	get_tree().quit()
