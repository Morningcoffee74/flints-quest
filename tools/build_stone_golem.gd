extends SceneTree

## Kleurt de blauwe "Frost Guardian" (assets/sprites/enemies/common/Endboss/
## Frost_Guardian_FREE_v1.0/, sheet 16×5 cellen van 192×128) om tot een
## grijsbruine STENEN GOLEM voor de W3-eindbaas:
## blauwe/cyaan pixels → bruingrijs steen; rode accenten blijven (mos/roest).
## Uitvoer: assets/sprites/enemies/world3/StoneGolem.png (zelfde raster).
## Rijen: 0 idle (6) · 1 walk (10) · 2 attack (14) · 3 hurt (7) · 4 death (16).
## Draaien: Godot --headless --path . --script tools/build_stone_golem.gd ; daarna --import.

const SRC := "res://assets/sprites/enemies/common/Endboss/Frost_Guardian_FREE_v1.0/frost_guardian_free_192x128_SpriteSheet.png"
const OUT := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/enemies/world3/StoneGolem.png"

func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if src == null:
		push_error("bron ontbreekt")
		quit(1)
		return
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				img.set_pixel(x, y, c)
				continue
			var h := c.h
			if h > 0.42 and h < 0.75:
				# Blauw → steen: warme, ontverzadigde bruingrijze tint.
				c = Color.from_hsv(0.085, clampf(c.s * 0.35, 0.0, 0.4), clampf(c.v * 0.82, 0.0, 1.0), c.a)
			elif h >= 0.75 or h < 0.05:
				# Paars/rood (schaduwen, ogen) → donkerder roestbruin.
				c = Color.from_hsv(0.05, clampf(c.s * 0.8, 0.0, 1.0), clampf(c.v * 0.85, 0.0, 1.0), c.a)
			img.set_pixel(x, y, c)
	var err := img.save_png(OUT)
	print("KLAAR: StoneGolem.png" if err == OK else "FOUT %d" % err)
	quit(0 if err == OK else 1)
