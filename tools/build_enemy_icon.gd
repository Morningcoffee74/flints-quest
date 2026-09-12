extends SceneTree

## Tekent assets/sprites/ui/enemy_icon.png (16×16): een simpel schedel-icoon
## voor de vijanden-eis in de HUD (wordt daar rood = verslagen / grijs = nog te
## doen ingekleurd via modulate, dus het icoon zelf is wit).
## Draaien: Godot --headless --path . --script tools/build_enemy_icon.gd ; daarna --import

const OUT := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/ui/enemy_icon.png"

func _init() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var w := Color.WHITE
	var dark := Color(0.0, 0.0, 0.0, 0.0)
	# Schedel: ronde kop (rijen 1..10), kaak (11..14), oogkassen en neus uit.
	var rows := [
		"....######......",
		"...########.....",
		"..##########....",
		".############...",
		".############...",
		".##..####..##...",
		".##..####..##...",
		".############...",
		"..####..####....",
		"..##########....",
		"...########.....",
		"...#.#.#.##.....",
		"...########.....",
		"....#.#.#.#.....",
		"................",
		"................",
	]
	for y in 16:
		for x in 16:
			img.set_pixel(x, y, w if rows[y][x] == "#" else dark)
	var err := img.save_png(OUT)
	print("KLAAR: enemy_icon.png" if err == OK else "FOUT %d" % err)
	quit(0 if err == OK else 1)
