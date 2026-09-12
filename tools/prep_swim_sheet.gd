extends SceneTree

## Maakt van een ruwe SpriteCook-zwemsheet een sheet die 1-op-1 in
## player_frames.tres past: 4 frames van 128x128 (512x128).
##
## Twee correcties op de ruwe output:
##  1. De cyaanwitte waterspatten die SpriteCook erbij tekent worden weggehaald
##     (de zwemsprite wordt over echt water heen getekend, dus die spatten
##     flikkeren). Gaten die daardoor midden in de figuur vallen worden met de
##     omringende kleur dichtgemaakt; spatten buiten de figuur verdwijnen.
##  2. De figuur dreef per frame ~30px omhoog. Elk frame wordt op zijn eigen
##     bounding box gecentreerd in de cel, zodat de animatie stil ligt.
##
## Draaien:
##   Godot --headless --path . --script tools/prep_swim_sheet.gd -- <bron.png> <doel.png>

const CELL := 128

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Gebruik: --script tools/prep_swim_sheet.gd -- <bron.png> <doel.png>")
		quit(1)
		return
	var src := Image.load_from_file(args[0])
	if src == null:
		push_error("Kon bron niet laden: %s" % args[0])
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)

	var fh := src.get_height()
	var n := src.get_width() / fh
	if n <= 0 or src.get_width() % fh != 0:
		push_error("Sheet %dx%d is geen rij vierkante frames." % [src.get_width(), src.get_height()])
		quit(1)
		return

	var out := Image.create_empty(CELL * n, CELL, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	for i in n:
		var f := Image.create_empty(fh, fh, false, Image.FORMAT_RGBA8)
		f.blit_rect(src, Rect2i(i * fh, 0, fh, fh), Vector2i.ZERO)
		var removed := _strip_splash(f)
		_fill_interior(f, removed)
		var specks := _keep_largest_blob(f)
		var box := _bbox(f)
		if box.size.x <= 0:
			continue
		if box.size.x > CELL or box.size.y > CELL:
			push_error("Frame %d is %dx%d en past niet in %d." % [i, box.size.x, box.size.y, CELL])
			quit(1)
			return
		var dst := Vector2i(
			i * CELL + (CELL - box.size.x) / 2,
			(CELL - box.size.y) / 2)
		out.blit_rect(f, box, dst)
		print("frame %d: %d spatpixels + %d losse spikkels weg, bbox %dx%d gecentreerd" % [i, removed.size(), specks, box.size.x, box.size.y])

	var err := out.save_png(args[1])
	print("geschreven: %s (%dx%d), err=%d" % [args[1], out.get_width(), out.get_height(), err])
	quit(0 if err == OK else 1)


## Cyaanwit waterschuim: duidelijk lichter naar blauw/groen dan naar rood.
## De blauwgrijze sjerp (102,112,151) en de huid blijven zo staan.
func _is_splash(c: Color) -> bool:
	return c.a > 0.1 and c.b > 0.78 and c.g - c.r > 0.12 and c.b >= c.g


func _strip_splash(img: Image) -> Array:
	var removed: Array = []
	for y in img.get_height():
		for x in img.get_width():
			if _is_splash(img.get_pixel(x, y)):
				removed.append(Vector2i(x, y))
	for p in removed:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	return removed


## Vult weggehaalde pixels die binnen de figuur lagen met het gemiddelde van hun
## ondoorzichtige buren. Pixels aan de buitenkant hebben te weinig buren en
## blijven transparant.
func _fill_interior(img: Image, removed: Array) -> void:
	var todo := removed.duplicate()
	for _pass in 4:
		var next: Array = []
		for p in todo:
			var sum := Color(0, 0, 0, 0)
			var count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var x: int = p.x + dx
					var y: int = p.y + dy
					if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
						continue
					var c := img.get_pixel(x, y)
					if c.a > 0.5:
						sum += c
						count += 1
			if count >= 5:
				img.set_pixel(p.x, p.y, Color(sum.r / count, sum.g / count, sum.b / count, 1.0))
			else:
				next.append(p)
		if next.size() == todo.size():
			break
		todo = next


func _bbox(img: Image) -> Rect2i:
	var minx := img.get_width()
	var maxx := -1
	var miny := img.get_height()
	var maxy := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.1:
				minx = mini(minx, x)
				maxx = maxi(maxx, x)
				miny = mini(miny, y)
				maxy = maxi(maxy, y)
	if maxx < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


## Houdt alleen de grootste samenhangende vlek over. Wat SpriteCook naast de
## figuur aan schuim tekende en niet als spat herkend werd (grijswitte spikkels)
## verdwijnt zo alsnog.
func _keep_largest_blob(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var sizes: Array[int] = []
	for start_y in h:
		for start_x in w:
			if img.get_pixel(start_x, start_y).a <= 0.1 or label[start_y * w + start_x] != -1:
				continue
			var id := sizes.size()
			var count := 0
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			label[start_y * w + start_x] = id
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var x: int = p.x + dx
						var y: int = p.y + dy
						if x < 0 or y < 0 or x >= w or y >= h:
							continue
						if label[y * w + x] != -1 or img.get_pixel(x, y).a <= 0.1:
							continue
						label[y * w + x] = id
						stack.push_back(Vector2i(x, y))
			sizes.append(count)

	if sizes.is_empty():
		return 0
	var best := 0
	for i in sizes.size():
		if sizes[i] > sizes[best]:
			best = i
	var wiped := 0
	for y in h:
		for x in w:
			var id := label[y * w + x]
			if id != -1 and id != best:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				wiped += 1
	return wiped
