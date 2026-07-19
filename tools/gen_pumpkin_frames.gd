extends SceneTree

## Snijdt assets/sprites/enemies/common/Endboss/Pumpkin.png (raster 14x6 cellen
## van 112x112) in een SpriteFrames-resource voor de W1-eindbaas.
## Draaien: Godot --headless --path . --script tools/gen_pumpkin_frames.gd

const SRC := "res://assets/sprites/enemies/common/Endboss/Pumpkin.png"
const OUT := "res://assets/sprites/enemies/common/Endboss/pumpkin_frames.tres"
const CW := 112
const CH := 112

# animatie -> rij, begin-kolom, aantal frames, fps, loopt
const ANIMS := {
	"walk":   {"row": 0, "from": 0, "count": 4, "fps": 8.0,  "loop": true},
	"attack": {"row": 2, "from": 0, "count": 6, "fps": 10.0, "loop": false},
	"hurt":   {"row": 4, "from": 0, "count": 5, "fps": 12.0, "loop": false},
	"death":  {"row": 5, "from": 0, "count": 7, "fps": 9.0,  "loop": false},
}

func _initialize() -> void:
	var tex := load(SRC) as Texture2D
	if tex == null:
		push_error("kon Pumpkin.png niet laden (import?)")
		quit()
		return
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for anim_name: String in ANIMS:
		var a: Dictionary = ANIMS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, a["fps"])
		frames.set_animation_loop(anim_name, a["loop"])
		for i in range(a["count"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((a["from"] + i) * CW, a["row"] * CH, CW, CH)
			frames.add_frame(anim_name, at)
	var err := ResourceSaver.save(frames, OUT)
	print("save ", OUT, " -> err=", err, " anims=", frames.get_animation_names())
	quit()
