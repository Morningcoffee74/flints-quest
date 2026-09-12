extends SceneTree

## Snijdt assets/sprites/enemies/world4/Gorilla.png (gemaakt door
## tools/build_w4_enemies.gd) tot een SpriteFrames-resource voor de
## Gorilla-eindbaas van Wereld 4 — zelfde aanpak als tools/gen_pumpkin_frames.gd.
##
## Bronraster: 16 × 3 cellen van 288×160.
##   rij 0 = idle (16 frames) · rij 1 = walk (12) · rij 2 = attack (16)
## Het gratis Minotaurus-pakket bevat GEEN hurt- of death-rij; Boss.gd valt voor
## het sterven terug op een tween (omvallen + uitfaden) als de animatie ontbreekt.
##
## Draaien: Godot --headless --path . --script tools/gen_gorilla_frames.gd

const SRC := "res://assets/sprites/enemies/world4/Gorilla.png"
const OUT := "res://assets/sprites/enemies/world4/gorilla_frames.tres"
const CW := 288
const CH := 160

const ANIMS := {
	"idle":   {"row": 0, "from": 0, "count": 16, "fps": 9.0,  "loop": true},
	"walk":   {"row": 1, "from": 0, "count": 12, "fps": 11.0, "loop": true},
	"attack": {"row": 2, "from": 0, "count": 16, "fps": 15.0, "loop": false},
}

func _init() -> void:
	var tex: Texture2D = load(SRC)
	if tex == null:
		push_error("kon %s niet laden — eerst --import draaien?" % SRC)
		quit(1)
		return
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for name: String in ANIMS:
		var a: Dictionary = ANIMS[name]
		frames.add_animation(name)
		frames.set_animation_speed(name, a["fps"])
		frames.set_animation_loop(name, a["loop"])
		for i in int(a["count"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((int(a["from"]) + i) * CW, int(a["row"]) * CH, CW, CH)
			frames.add_frame(name, at)
	if ResourceSaver.save(frames, OUT) != OK:
		push_error("schrijven mislukt: " + OUT)
		quit(1)
		return
	print("geschreven: ", OUT)
	quit()
