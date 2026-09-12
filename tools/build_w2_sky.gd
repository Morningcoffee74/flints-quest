extends SceneTree

## Tekent assets/sprites/backgrounds/world2/sky.png (256×224, pixel-stijl): de
## lucht boven de waterlijn van Wereld 2 — verloop, zon, wolken en een paar
## eilandjes aan de horizon. De onderste rij sluit qua kleur aan op de bovenkant
## van back.png (de onderwater-verte), zodat de horizon precies op de waterlijn
## ligt. In ParallaxBGWater.tscn staat hij op schaal 4 (1024×896) van y=-256..640.
## Draaien: Godot --headless --script tools/build_w2_sky.gd ; daarna --import.

const OUT := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/backgrounds/world2/sky.png"
const W := 256
const H := 224

func _init() -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var top := Color("4f9fe6")
	var mid := Color("8fd0f5")
	var low := Color("d4ecf9")
	for y in H:
		var t := float(y) / float(H - 1)
		var c := top.lerp(mid, clampf(t / 0.55, 0.0, 1.0)) if t < 0.55 else mid.lerp(low, (t - 0.55) / 0.45)
		for x in W:
			img.set_pixel(x, y, c)

	# Zon rechtsboven met zachte gloed.
	_disc(img, 206, 34, 16, Color("fff6c8"))
	_disc(img, 206, 34, 11, Color("fffbe0"))

	# Wolken: clusters van ellipsen, onderkant iets donkerder.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var cloud_specs := [[28, 40, 1.0], [96, 26, 0.8], [150, 56, 1.1], [232, 78, 0.9], [60, 92, 0.7], [180, 112, 0.6], [12, 130, 0.5], [120, 140, 0.55]]
	for spec: Array in cloud_specs:
		_cloud(img, rng, int(spec[0]), int(spec[1]), float(spec[2]))

	# Verre eilandjes aan de horizon (donkerder blauw, laag en breed).
	var isle := Color("5b8fd0")
	for spec: Array in [[20, 18, 4], [70, 10, 3], [140, 26, 5], [205, 14, 3], [240, 20, 4]]:
		var cx := int(spec[0]); var half := int(spec[1]); var h := int(spec[2])
		for dx in range(-half, half + 1):
			var hh := int(round(h * (1.0 - pow(float(dx) / float(half), 2))))
			for dy in hh:
				var px := posmod(cx + dx, W)
				img.set_pixel(px, H - 1 - dy, isle)

	# Onderste 2 rijen: nevel richting de waterlijn (aansluitend op back.png-blauw).
	var horizon := Color("6fb0ea")
	for y in range(H - 2, H):
		for x in W:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(horizon, 0.5))

	var err := img.save_png(OUT)
	print("KLAAR: sky.png" if err == OK else "FOUT: %d" % err)
	quit(0 if err == OK else 1)

func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(posmod(x, W), clampi(y, 0, H - 1), c)

func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var fx := float(x - cx) / float(rx)
			var fy := float(y - cy) / float(ry)
			if fx * fx + fy * fy <= 1.0:
				img.set_pixel(posmod(x, W), clampi(y, 0, H - 1), c)

func _cloud(img: Image, rng: RandomNumberGenerator, cx: int, cy: int, s: float) -> void:
	var shade := Color("d9ebf8")
	var white := Color("f8fcff")
	var puffs := []
	for i in 4:
		puffs.append([cx + int((i - 1.5) * 9 * s), cy + rng.randi_range(-2, 2), int((7 + rng.randi_range(0, 4)) * s), int((4 + rng.randi_range(0, 2)) * s)])
	for p: Array in puffs:
		_ellipse(img, p[0], p[1] + 2, p[2], p[3], shade)
	for p: Array in puffs:
		_ellipse(img, p[0], p[1], p[2], p[3], white)
