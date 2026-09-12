extends SceneTree

## Koppelt een zwem-spritesheet aan de "swim"-animatie in player_frames.tres.
##
## Nodig zodra een nieuwe SwimFlint.png andere afmetingen heeft dan de huidige
## 4 frames van 128x128 (512x128) — bijvoorbeeld een SpriteCook-sheet met 6 of 8
## frames. Past de sheet exact in het bestaande raster, dan hoef je dit script
## niet te draaien; de bestaande .tres klopt dan al.
##
## Draaien (na Godot --headless --path . --import zodat de PNG geïmporteerd is):
##   Godot --headless --path . --script tools/gen_swim_frames.gd
##
## Frame-breedte wordt afgeleid uit de hoogte van de sheet (vierkante frames).
## Wijk je daarvan af, zet dan FRAME_W/FRAME_H hieronder met de hand.

const SHEET := "res://assets/sprites/player/SwimFlint.png"
const FRAMES_RES := "res://scenes/player/player_frames.tres"
const ANIM := "swim"
const FPS := 8.0

# 0 = automatisch afleiden uit de sheet (vierkante frames op één rij).
const FRAME_W := 0
const FRAME_H := 0

func _initialize() -> void:
	var tex := load(SHEET) as Texture2D
	if tex == null:
		push_error("Kon %s niet laden. Draai eerst: Godot --headless --path . --import" % SHEET)
		quit(1)
		return

	var frames := load(FRAMES_RES) as SpriteFrames
	if frames == null:
		push_error("Kon %s niet laden." % FRAMES_RES)
		quit(1)
		return

	var sheet_w := tex.get_width()
	var sheet_h := tex.get_height()
	var fh: int = FRAME_H if FRAME_H > 0 else sheet_h
	var fw: int = FRAME_W if FRAME_W > 0 else fh
	if fw <= 0 or sheet_w % fw != 0:
		push_error("Sheet %dx%d is niet deelbaar door framebreedte %d — zet FRAME_W met de hand." % [sheet_w, sheet_h, fw])
		quit(1)
		return
	var count := sheet_w / fw

	if frames.has_animation(ANIM):
		frames.clear(ANIM)
	else:
		frames.add_animation(ANIM)
	frames.set_animation_speed(ANIM, FPS)
	frames.set_animation_loop(ANIM, true)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(ANIM, at)

	var err := ResourceSaver.save(frames, FRAMES_RES)
	print("sheet %dx%d -> %d frames van %dx%d; save err=%d" % [sheet_w, sheet_h, count, fw, fh, err])
	quit(0 if err == OK else 1)
