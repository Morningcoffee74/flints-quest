extends SceneTree

## Genereert scenes/levels/world2/W2L1..L11.tscn uit ontwerpdata (Wereld 2: Water).
##
## Wereld 2 is een ZWEMWERELD: de waterlijn ligt op rij 20 (y=640) en daaronder
## is één grote zee tot de zeebodem op rij 36. Daar tussenin liggen EILANDEN
## (rotsplateaus die net boven water uitsteken, top = rij 19) waar je loopt, en
## open ZEE-stukken waar je zwemt tussen rotsformaties door. De achtergrond
## klopt altijd: lucht boven de waterlijn, onderwater eronder (ParallaxBGWater).
##
## Elk level heeft een eigen LOOK (tileset "coral"/"reef"/"sand" + decor-set)
## en een eigen "ding": vliegende vissen, stroming, tunnel, geheime nis,
## springveer, jagers… — niet alles in elk level, wél oplopend in moeite.
## Levelspec: n, pct (munten-eis %), both, tileset, decor, hint, staart, boss,
## secties. Vijanden-eis = 40% (L1) → 80% (L11) van alle vijanden (_kill_pct).
##
## Secties (lengtes in tegels van 32px, ×LENGTH_SCALE):
##   ["is", lengte, opties]  — eiland (lopen); opties: crabs, coins, block,
##       power ("purple"/"blue"/"orange"), checkpoint, spikes (n zee-egels),
##       tunnel (true: tunnel van 4 tegels onder het eiland met mijnen/munten),
##       pocket (true: geheime nis onder het eiland, alleen vanaf de linker zee
##       bereikbaar, met schat), spring (true: springveer naar hoog platform),
##       leapers (n vliegende vissen in de zee naast dit eiland)
##   ["st", [rijen], opties] — platform-trap boven een eiland (rij 16 → 13 → 10)
##   ["sea", lengte, opties] — open zee (zwemmen); opties:
##       pattern: "pillars" / "gates" / "slalom" / "blocks" / "none"
##       piranhas (n), hunters (n jagende grote vissen), mines (n), coins (n),
##       current (-1 tegenstroom / 1 meestroom), leapers (n vliegende vissen)
##
## Validatie: BFS met een speler-doos (1×3) door elke zee, objecten op eilanden,
## mijnen/munten/vissen niet in rots, enz. Bij een fout wordt niets weggeschreven.
## Draaien: Godot --headless --path . --script tools/gen_levels_world2.gd

const OUT_DIR := "/Users/wb-antal/claude-projecten/Flint-Game/scenes/levels/world2/"
const SURF := 20
const ISLAND_Y := 19
const BED := 36
const ROCK_BOTTOM := 40
const WATER_TOP_PX := 628
const LEVEL_HEIGHT := 1200
const TUNNEL_TOP := 27
const TUNNEL_H := 4
const POCKET_TOP := 31
const POCKET_H := 4

const MAX_UP := 3
const MAX_GAP_FLAT := 5
const MAX_GAP_DOWN := 6
const LENGTH_SCALE := 0.8
const N_LEVELS := 11

## Decor uit props_source.png: naam → [regio, schaal]
const PROPS: Dictionary = {
	"seaweed":    [[614, 317, 52, 67], 2],
	"coral_y":    [[434, 332, 46, 51], 2],
	"coral_p":    [[514, 327, 48, 56], 2],
	"totem":      [[432, 41, 92, 231], 1],
	"totem_moss": [[596, 41, 120, 231], 1],
	"log":        [[49, 95, 85, 98], 1],
	"arch":       [[752, 70, 245, 186], 1],
}

const TILESETS: Dictionary = {
	"coral": "res://scenes/levels/world2_tileset.tres",
	"reef":  "res://scenes/levels/world2_tileset_reef.tres",
	"sand":  "res://scenes/levels/world2_tileset_sand.tres",
}

var L: Dictionary = {}
var _cx := 0
var _fail := false
var _rng := RandomNumberGenerator.new()
var _decor_names: Array = []

func _init() -> void:
	for spec: Dictionary in _levels():
		_build(spec)
	if _fail:
		push_error("GEFAALD: validatiefouten, zie hierboven")
	else:
		print("KLAAR: %d W2-levels gegenereerd" % _levels().size())
	quit(1 if _fail else 0)

func _kill_pct(n: int) -> float:
	return 0.4 + 0.4 * (n - 1) / float(N_LEVELS - 1)

# ---------------------------------------------------------------- secties ---

func _reset(spec: Dictionary) -> void:
	L = {
		"n": spec["n"], "pct": spec["pct"], "both": spec["both"],
		"hint": spec.get("hint", ""), "tileset": spec.get("tileset", "coral"),
		"boss": spec.get("boss", false),
		"islands": [], "seas": [], "solids": [], "cuts": [], "plats": [], "spring_plats": [],
		"crabs": [], "spikes_g": [], "coin_rows": [], "coins_free": [],
		"piranhas": [], "leapers": [], "mines": [], "decor": [], "currents": [], "springs": [],
		"blocks": [], "power": [], "checkpoints": [],
		"cabin": 0, "boss_x": 0, "boss_arena": [0, 0],
	}
	_cx = 0
	_rng.seed = 2000 + int(spec["n"])
	_decor_names = spec.get("decor", ["seaweed", "coral_y", "coral_p"])

func _scaled(raw: int, min_len: int) -> int:
	return maxi(min_len, roundi(raw * LENGTH_SCALE))

func _is(len_raw: int, o: Dictionary = {}) -> void:
	var len_t := _scaled(len_raw, 8)
	var x0 := _cx
	var x1 := x0 + len_t
	L["islands"].append([x0, x1])
	for i: int in o.get("crabs", 0):
		var cx: int = x0 + (i + 1) * len_t / (o.get("crabs", 0) + 1)
		var limit: int = mini(cx - x0 - 3, x1 - 3 - cx) * 32
		L["crabs"].append([cx, maxi(32, limit)])
	var coins: int = o.get("coins", 0)
	if coins > 0:
		# Boven zee-egels hangen de munten hoger (springen om te pakken).
		L["coin_rows"].append([x0 + 2, ISLAND_Y - 3 if o.get("spikes", 0) > 0 else ISLAND_Y - 1, coins])
	if o.get("block", false):
		L["blocks"].append([x0 + len_t / 3, ISLAND_Y * 32 - 16])
	if o.has("power"):
		L["power"].append([o["power"], x0 + 2 * len_t / 3, ISLAND_Y - 3])
	if o.get("checkpoint", false):
		L["checkpoints"].append(x0 + len_t / 2)
	for i: int in o.get("spikes", 0):
		var sx: int = x0 + 4 + i * 7
		if sx + 3 <= x1 - 4:
			L["spikes_g"].append([sx, 3, "small_metal"])
	if o.get("tunnel", false):
		L["cuts"].append([x0, TUNNEL_TOP, len_t, TUNNEL_H])
		var mx := x0 + 3
		var k := 0
		while mx < x1 - 3:
			L["mines"].append([mx, TUNNEL_TOP if k % 2 == 0 else TUNNEL_TOP + TUNNEL_H - 1])
			mx += 6
			k += 1
		var cx := x0 + 1
		while cx < x1 - 1:
			L["coins_free"].append([cx, TUNNEL_TOP + 1 + ((cx / 2) % 2)])
			cx += 3
	if o.get("pocket", false):
		# Geheime nis: open aan de linkerkant (zee), doodlopend, met schat.
		var pw: int = mini(6, len_t - 3)
		L["cuts"].append([x0, POCKET_TOP, pw, POCKET_H])
		L["coins_free"].append([x0 + 2, POCKET_TOP + 1])
		L["coins_free"].append([x0 + 3, POCKET_TOP + 2])
		L["power"].append([o.get("pocket_power", "purple"), x0 + pw - 2, POCKET_TOP + 1, "free"])
	if o.get("spring", false):
		var sx: int = x0 + len_t / 3
		L["springs"].append(sx)
		L["spring_plats"].append([sx + 2, 12, 5])
		L["coin_rows"].append([sx + 2, 10, 3])
		if o.has("spring_power"):
			L["power"].append([o["spring_power"], sx + 4, 9])
	for i: int in o.get("leapers", 0):
		# Vliegende vis in de zee vlak naast het eiland (om en om links/rechts).
		var lx: int = (x0 - 3) if i % 2 == 0 else (x1 + 2)
		L["leapers"].append([lx, SURF + 1])
	var n_decor: int = 1 if len_t < 16 else 2
	for i: int in n_decor:
		var dx: int = x0 + 1 + _rng.randi_range(0, maxi(0, len_t - 5))
		L["decor"].append([dx, _decor_names[_rng.randi_range(0, _decor_names.size() - 1)]])
	_cx = x1

func _st(rows: Array, o: Dictionary = {}) -> void:
	var plen := 4
	var x := _cx + 2
	for i: int in rows.size():
		var row: int = rows[i]
		L["plats"].append([x, row, plen])
		if o.get("coins", true):
			L["coin_rows"].append([x, row - 2, 2])
		if i == rows.size() - 1 and o.has("power"):
			L["power"].append([o["power"], x + plen / 2, row - 3])
		x += plen + 3
	var new_cx := x - 3 + 2
	var last: Array = L["islands"][L["islands"].size() - 1]
	if last[1] == _cx:
		last[1] = new_cx
	else:
		L["islands"].append([_cx, new_cx])
	_cx = new_cx

func _sea(len_raw: int, o: Dictionary = {}) -> void:
	var len_t := _scaled(len_raw, 14)
	var x0 := _cx
	var x1 := x0 + len_t
	L["seas"].append([x0, x1])
	var pattern: String = o.get("pattern", "none")
	var margin := 4
	var ox0 := x0 + margin
	var ox1 := x1 - margin
	var lanes: Array = []
	match pattern:
		"pillars":
			var x := ox0
			var k := 0
			while x + 2 <= ox1:
				var top: int = 27 if k % 2 == 0 else 30
				L["solids"].append([x, top, 2, ROCK_BOTTOM - top])
				L["coins_free"].append([x, top - 2])
				lanes.append([x + 4, 24])
				x += 8
				k += 1
		"gates":
			var x := ox0
			var k := 0
			while x + 2 <= ox1:
				if k % 2 == 0:
					# Duik-poort: rots vanaf rij 17 (boven water) tot rij 29 → onderdoor.
					L["solids"].append([x, ISLAND_Y - 2, 2, 30 - (ISLAND_Y - 2)])
					L["coins_free"].append([x, 32])
					L["coins_free"].append([x + 1, 33])
				else:
					# Stijg-poort: rots vanaf de bodem tot rij 25 → erover.
					L["solids"].append([x, 25, 2, ROCK_BOTTOM - 25])
					L["coins_free"].append([x, 22])
					L["coins_free"].append([x + 1, 21])
				lanes.append([x + 4, 28])
				x += 8
				k += 1
		"slalom":
			var x := ox0
			var k := 0
			while x + 3 <= ox1:
				if k % 2 == 0:
					L["solids"].append([x, 28, 2, ROCK_BOTTOM - 28])
					L["coins_free"].append([x, 25])
					lanes.append([x + 3, 32])
				else:
					L["solids"].append([x, ISLAND_Y - 2, 3, 24 - (ISLAND_Y - 2)])
					L["coins_free"].append([x + 1, 27])
					lanes.append([x + 4, 30])
				x += 6
				k += 1
		"blocks":
			var x := ox0
			var k := 0
			while x + 3 <= ox1:
				if k % 2 == 0:
					var row: int = [28, 31, 25][(k / 2) % 3]
					L["solids"].append([x, row, 3, 3])
					L["coins_free"].append([x + 1, row - 2])
					lanes.append([x + 5, row - 4])
				else:
					L["solids"].append([x, ISLAND_Y - 2, 3, 22 - (ISLAND_Y - 2)])
					L["coins_free"].append([x + 1, 24])
					lanes.append([x + 5, 27])
				x += 7
				k += 1
		_:
			lanes.append([x0 + len_t / 2, 26])

	var n_p: int = o.get("piranhas", 0)
	for i: int in n_p:
		var px: int = x0 + (i + 1) * len_t / (n_p + 1)
		var row: int = 24 if i % 2 == 0 else 31
		L["piranhas"].append([px, _free_row(px, row), 96.0, false])
	var n_h: int = o.get("hunters", 0)
	for i: int in n_h:
		var px: int = x0 + (i + 1) * len_t / (n_h + 1)
		L["piranhas"].append([px, _free_row(px, 27), 80.0, true])
	var n_m: int = o.get("mines", 0)
	if n_m > 0 and not lanes.is_empty():
		for i: int in n_m:
			var lane: Array = lanes[(i * lanes.size()) / n_m]
			L["mines"].append([lane[0], lane[1] + (2 if i % 2 == 0 else -2)])
	var n_c: int = o.get("coins", 0)
	for i: int in n_c:
		var cx: int = x0 + 2 + i * maxi(2, (len_t - 4) / maxi(1, n_c))
		var row: int = 23 + int(round(4.0 * (1.0 + sin(i * 0.9))))
		L["coins_free"].append([cx, _free_row(cx, row)])
	var cur: int = o.get("current", 0)
	if cur != 0:
		L["currents"].append([x0, x1, cur])
	for i: int in o.get("leapers", 0):
		var lx: int = x0 + 3 if i % 2 == 0 else x1 - 3
		L["leapers"].append([lx, SURF + 1])
	_cx = x1

func _free_row(x: int, preferred: int) -> int:
	for d in range(0, BED):
		for row: int in [preferred - d, preferred + d]:
			if row < SURF + 1 or row > BED - 3:
				continue
			if not _solid_at(x, row) and not _solid_at(x, row + 1):
				return row
	return preferred

func _solid_at(x: int, row: int) -> bool:
	for r: Array in L["solids"]:
		if x >= r[0] and x < r[0] + r[2] and row >= r[1] and row < r[1] + r[3]:
			return true
	return false

func _finish(tail_raw: int) -> void:
	var tail := _scaled(tail_raw, 12)
	L["cabin"] = _cx + tail - 6
	L["islands"].append([_cx, _cx + tail])
	if L["boss"]:
		L["boss_x"] = _cx + tail / 2
		L["boss_arena"] = [(_cx + 3) * 32, (_cx + tail - 4) * 32]
		L["decor"].append([_cx + 2, "totem"])
		L["decor"].append([_cx + tail - 4, "totem_moss"])
	_cx += tail
	L["w"] = _cx

# ------------------------------------------------------------- validatie ---

func _rects() -> Array:
	var cells: Dictionary = {}
	for isl: Array in L["islands"]:
		for x in range(isl[0], isl[1]):
			for y in range(ISLAND_Y, ROCK_BOTTOM):
				cells[Vector2i(x, y)] = true
	for sea: Array in L["seas"]:
		for x in range(sea[0], sea[1]):
			for y in range(BED, ROCK_BOTTOM):
				cells[Vector2i(x, y)] = true
	for s: Array in L["solids"]:
		for x in range(s[0], s[0] + s[2]):
			for y in range(s[1], s[1] + s[3]):
				cells[Vector2i(x, y)] = true
	for c: Array in L["cuts"]:
		for x in range(c[0], c[0] + c[2]):
			for y in range(c[1], c[1] + c[3]):
				cells.erase(Vector2i(x, y))
	var out: Array = []
	var keys := cells.keys()
	keys.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	var run_start: Vector2i = Vector2i(-99999, -99999)
	var run_len := 0
	for k: Vector2i in keys:
		if run_len > 0 and k.y == run_start.y and k.x == run_start.x + run_len:
			run_len += 1
		else:
			if run_len > 0:
				out.append([run_start.x, run_start.y, run_len, 1])
			run_start = k
			run_len = 1
	if run_len > 0:
		out.append([run_start.x, run_start.y, run_len, 1])
	for p: Array in L["plats"]:
		out.append([p[0], p[1], p[2], 1])
	for p: Array in L["spring_plats"]:
		out.append([p[0], p[1], p[2], 1])
	return out

func _solid_grid() -> Dictionary:
	var g: Dictionary = {}
	for r: Array in _rects():
		for x in range(r[0], r[0] + r[2]):
			for y in range(r[1], r[1] + r[3]):
				g[Vector2i(x, y)] = true
	return g

func _validate() -> PackedStringArray:
	var errs := PackedStringArray()
	var grid := _solid_grid()

	for sea: Array in L["seas"]:
		var x0: int = sea[0]
		var x1: int = sea[1]
		var seen: Dictionary = {}
		var queue: Array = []
		for y in range(SURF, SURF + 4):
			if _fits(grid, x0, y):
				queue.append(Vector2i(x0, y))
				seen[Vector2i(x0, y)] = true
		if queue.is_empty():
			errs.append("zee x=%d: instap bij het oppervlak zit dicht" % x0)
			continue
		var reached := false
		while not queue.is_empty():
			var c: Vector2i = queue.pop_front()
			if c.x == x1 - 1 and c.y <= SURF + 3:
				reached = true
				break
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = c + d
				if q.x < x0 or q.x >= x1 or q.y < SURF or q.y + 2 >= BED:
					continue
				if seen.has(q) or not _fits(grid, q.x, q.y):
					continue
				seen[q] = true
				queue.append(q)
		if not reached:
			errs.append("zee x=%d..%d: geen doorzwembare route naar de overkant" % [x0, x1])

	for c: Array in L["cuts"]:
		# Tunnel (beide monden) of nis (linkermond) moet op open zee uitkomen.
		var mouths: Array = [c[0] - 1] if c[3] == POCKET_H and c[1] == POCKET_TOP else [c[0] - 1, c[0] + c[2]]
		for side_x: int in mouths:
			for y in range(c[1], c[1] + c[3]):
				if grid.has(Vector2i(side_x, y)):
					errs.append("tunnel/nis bij x=%d: mond bij x=%d zit dicht" % [c[0], side_x])
					break

	var supports: Array = []
	for isl: Array in L["islands"]:
		supports.append({"x": isl[0], "end": isl[1], "row": ISLAND_Y, "ok": true})
	for p: Array in L["plats"]:
		supports.append({"x": p[0], "end": p[0] + p[2], "row": p[1], "ok": false})
	for p: Array in L["spring_plats"]:
		supports.append({"x": p[0], "end": p[0] + p[2], "row": p[1], "ok": true})
	var changed := true
	while changed:
		changed = false
		for s: Dictionary in supports:
			if s["ok"]:
				continue
			for src: Dictionary in supports:
				if not src["ok"] or src == s:
					continue
				var dh: int = src["row"] - s["row"]
				if dh > MAX_UP:
					continue
				var g: int = maxi(s["x"] - src["end"], src["x"] - s["end"])
				var limit := MAX_GAP_DOWN
				if dh == 3:
					limit = 3
				elif dh > 0:
					limit = 4
				elif dh == 0:
					limit = MAX_GAP_FLAT
				if g <= limit:
					s["ok"] = true
					changed = true
					break
	for s: Dictionary in supports:
		if not s["ok"]:
			errs.append("platform x=%d rij %d onbereikbaar" % [s["x"], s["row"]])

	for x: int in L["checkpoints"]:
		if not _on_island(x):
			errs.append("checkpoint op x=%d staat niet op een eiland" % x)
	for c: Array in L["crabs"]:
		if not _on_island(c[0]):
			errs.append("krab op x=%d staat niet op een eiland" % c[0])
	for b: Array in L["blocks"]:
		if not _on_island(b[0]):
			errs.append("block op x=%d staat niet op een eiland" % b[0])
	for sx: int in L["springs"]:
		if not _on_island(sx):
			errs.append("springveer op x=%d staat niet op een eiland" % sx)
	if not _on_island(L["cabin"]):
		errs.append("cabin op x=%d staat niet op een eiland" % L["cabin"])
	for sp: Array in L["spikes_g"]:
		if not (_on_island(sp[0]) and _on_island(sp[0] + sp[1] - 1)):
			errs.append("zee-egels op x=%d hangen boven water" % sp[0])
	for d: Array in L["decor"]:
		if not _on_island(d[0]):
			errs.append("decor op x=%d staat niet op een eiland" % d[0])
	for lp: Array in L["leapers"]:
		if _on_island(lp[0]) or lp[0] < 0:
			errs.append("vliegende vis op x=%d zit niet in zee" % lp[0])

	for p: Array in L["power"]:
		if p.size() > 3:
			continue  # vrij geplaatst (nis)
		var px: int = p[1]
		var prow: int = p[2]
		var ok := false
		for s: Dictionary in supports:
			if s["x"] - 1 <= px and px < s["end"] + 1 and s["row"] > prow and s["row"] - prow <= 5:
				ok = true
		if not ok:
			errs.append("power-up op x=%d rij %d is niet te pakken" % [px, prow])

	for m: Array in L["mines"]:
		if grid.has(Vector2i(m[0], m[1])):
			errs.append("mijn op x=%d rij %d zit in rots" % [m[0], m[1]])
	for c: Array in L["coins_free"]:
		if grid.has(Vector2i(c[0], c[1])):
			errs.append("munt op x=%d rij %d zit in rots" % [c[0], c[1]])
	for pr: Array in L["piranhas"]:
		if grid.has(Vector2i(pr[0], pr[1])) or grid.has(Vector2i(pr[0], pr[1] + 1)):
			errs.append("vis op x=%d rij %d zit in rots" % [pr[0], pr[1]])

	var total: int = L["crabs"].size() + L["piranhas"].size() + L["leapers"].size()
	if total == 0:
		errs.append("level heeft geen vijanden")
	if L["checkpoints"].size() < 1:
		errs.append("level heeft geen checkpoint")

	for row: Array in L["coin_rows"]:
		var cx0: int = row[0]
		var crow: int = row[1]
		var cx1: int = cx0 + maxi(0, row[2] - 1) * 2
		if crow >= ISLAND_Y - 2 and crow < ISLAND_Y:
			for sp: Array in L["spikes_g"]:
				if cx0 <= sp[0] + sp[1] - 1 and sp[0] <= cx1:
					errs.append("munt(en) x=%d..%d overlappen zee-egels x=%d" % [cx0, cx1, sp[0]])
	return errs

func _fits(grid: Dictionary, x: int, y: int) -> bool:
	for dy in 3:
		if grid.has(Vector2i(x, y + dy)):
			return false
	return true

func _on_island(x: int) -> bool:
	for isl: Array in L["islands"]:
		if x >= isl[0] and x < isl[1]:
			return true
	return false

# ------------------------------------------------------------ scene-write ---

func _build(spec: Dictionary) -> void:
	_reset(spec)
	for sec: Array in spec["secties"]:
		match sec[0]:
			"is":  _is(sec[1], sec[2] if sec.size() > 2 else {})
			"st":  _st(sec[1], sec[2] if sec.size() > 2 else {})
			"sea": _sea(sec[1], sec[2] if sec.size() > 2 else {})
	_finish(spec.get("staart", 20))

	var errs := _validate()
	if not errs.is_empty():
		_fail = true
		for e: String in errs:
			printerr("W2L%d: %s" % [L["n"], e])
		return
	_write_level()

func _esc(s: String) -> String:
	return s.replace("\\", "\\\\").replace('"', '\\"')

func _write_level() -> void:
	var n: int = L["n"]
	var width_px: int = L["w"] * 32
	var island_px := ISLAND_Y * 32
	var total: int = L["crabs"].size() + L["piranhas"].size() + L["leapers"].size()
	var kills: int = maxi(1, int(ceil(total * _kill_pct(n))))

	var ext := ""
	ext += '[ext_resource type="Script"      path="res://scripts/levels/LevelBase.gd"             id="1"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn"               id="2"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/ui/HUD.tscn"                      id="3"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Crab.tscn"         id="4"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Piranha.tscn"      id="5"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/BigFish.tscn"      id="6"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Coin.tscn"                id="7"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/SpecialBlock.tscn"        id="8"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Cabin.tscn"               id="9"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockPurple.tscn"    id="10"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockBlue.tscn"      id="11"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/ParallaxBGWater.tscn"     id="12"]\n'
	ext += '[ext_resource type="TileSet"     path="%s"       id="13"]\n' % TILESETS[L["tileset"]]
	ext += '[ext_resource type="Script"      path="res://scripts/levels/Terrain.gd"               id="14"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spikes.tscn"              id="15"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Mine.tscn"                id="16"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Checkpoint.tscn"          id="17"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockOrange.tscn"    id="18"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Water.tscn"               id="19"]\n'
	ext += '[ext_resource type="Texture2D"   path="res://assets/sprites/tiles/world2_water/props_source.png" id="20"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/LeapFish.tscn"     id="21"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Current.tscn"             id="22"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spring.tscn"              id="23"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/world2/Octopus.tscn"      id="24"]\n'

	var s := "[gd_scene load_steps=26 format=3]\n\n"
	s += ext + "\n"
	s += '[sub_resource type="RectangleShape2D" id="1"]\n'
	s += "size = Vector2(32.0, 300.0)\n\n"

	s += '[node name="W2L%d" type="Node2D"]\n' % n
	s += 'script = ExtResource("1")\n'
	s += "level_width = %d\n" % width_px
	s += "level_height = %d\n" % LEVEL_HEIGHT
	s += "coins_needed_pct = %d\n" % L["pct"]
	s += "enemies_needed = %d\n" % kills
	s += "require_both = %s\n" % ("true" if L["both"] else "false")
	s += "world_number = 2\n"
	s += "level_number = %d\n" % n
	if not String(L["hint"]).is_empty():
		s += 'intro_hint = "%s"\n' % _esc(L["hint"])
	s += "\n"

	s += '[node name="ParallaxBGWater" parent="." instance=ExtResource("12")]\n\n'
	s += '[node name="HUD" parent="." instance=ExtResource("3")]\n\n'
	s += '[node name="Player" parent="." instance=ExtResource("2")]\n'
	s += "position = Vector2(120.0, %d.0)\n\n" % island_px

	var water_h := BED * 32 - WATER_TOP_PX
	s += '[node name="Sea" parent="." instance=ExtResource("19")]\n'
	s += "position = Vector2(%.1f, %.1f)\n" % [width_px / 2.0, WATER_TOP_PX + water_h / 2.0]
	s += "size = Vector2(%d.0, %d.0)\n\n" % [width_px, water_h]

	var idx := 1
	for c: Array in L["currents"]:
		var cw: int = (int(c[1]) - int(c[0])) * 32
		s += '[node name="Current%d" parent="." instance=ExtResource("22")]\n' % idx
		s += "position = Vector2(%.1f, %.1f)\n" % [int(c[0]) * 32 + cw / 2.0, SURF * 32 + (BED - SURF) * 16.0]
		s += "size = Vector2(%d.0, %d.0)\n" % [cw, (BED - SURF) * 32]
		s += "push = Vector2(%d.0, 0.0)\n\n" % (int(c[2]) * 70)
		idx += 1

	s += '[node name="Decor" type="Node2D" parent="."]\n'
	s += "z_index = -1\n\n"
	idx = 1
	for d: Array in L["decor"]:
		var pr: Array = PROPS[d[1]][0]
		var sc: int = PROPS[d[1]][1]
		s += '[node name="Prop%d" type="Sprite2D" parent="Decor"]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(d[0]) * 32, island_px - int(pr[3]) * sc + 6]
		s += "scale = Vector2(%d.0, %d.0)\n" % [sc, sc]
		s += "centered = false\n"
		s += 'texture = ExtResource("20")\n'
		s += "region_enabled = true\n"
		s += "region_rect = Rect2(%d, %d, %d, %d)\n\n" % [pr[0], pr[1], pr[2], pr[3]]
		idx += 1

	var rects: Array[String] = []
	for r: Array in _rects():
		rects.append("Rect2i(%d, %d, %d, %d)" % [r[0], r[1], r[2], r[3]])
	s += '[node name="Terrain" type="TileMapLayer" parent="."]\n'
	s += "scale = Vector2(2.0, 2.0)\n"
	s += 'tile_set = ExtResource("13")\n'
	s += 'script = ExtResource("14")\n'
	s += "solid_rects = Array[Rect2i]([%s])\n\n" % ", ".join(rects)

	s += '[node name="Enemies" type="Node2D" parent="."]\n\n'
	idx = 1
	for c: Array in L["crabs"]:
		s += '[node name="Crab%d" parent="Enemies" instance=ExtResource("4")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(c[0]) * 32, island_px]
		s += "patrol_limit = %d.0\n\n" % int(c[1])
		idx += 1
	var ip := 1
	var ih := 1
	for pr: Array in L["piranhas"]:
		if pr[3]:
			s += '[node name="BigFish%d" parent="Enemies" instance=ExtResource("6")]\n' % ih
			ih += 1
		else:
			s += '[node name="Piranha%d" parent="Enemies" instance=ExtResource("5")]\n' % ip
			ip += 1
		s += "position = Vector2(%d.0, %d.0)\n" % [int(pr[0]) * 32 + 16, int(pr[1]) * 32 + 16]
		s += "patrol_range = %.1f\n" % pr[2]
		s += "water_top_y = %d.0\n\n" % (SURF * 32)
	idx = 1
	for lp: Array in L["leapers"]:
		s += '[node name="LeapFish%d" parent="Enemies" instance=ExtResource("21")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(lp[0]) * 32 + 16, int(lp[1]) * 32 + 16]
		s += "water_top_y = %d.0\n\n" % (SURF * 32)
		idx += 1
	if L["boss"]:
		s += '[node name="Octopus" parent="Enemies" instance=ExtResource("24")]\n'
		s += "position = Vector2(%d.0, %d.0)\n" % [int(L["boss_x"]) * 32, island_px]
		s += "arena_left = %d.0\n" % L["boss_arena"][0]
		s += "arena_right = %d.0\n\n" % L["boss_arena"][1]

	s += '[node name="Objects" type="Node2D" parent="."]\n\n'
	idx = 1
	for row: Array in L["coin_rows"]:
		for i: int in row[2]:
			s += '[node name="Coin%d" parent="Objects" instance=ExtResource("7")]\n' % idx
			s += "position = Vector2(%d.0, %d.0)\n\n" % [(row[0] + i * 2) * 32 + 16, row[1] * 32 + 8]
			idx += 1
	for c: Array in L["coins_free"]:
		s += '[node name="Coin%d" parent="Objects" instance=ExtResource("7")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(c[0]) * 32 + 16, int(c[1]) * 32 + 16]
		idx += 1
	idx = 1
	for b: Array in L["blocks"]:
		s += '[node name="SpecialBlock%d" parent="Objects" instance=ExtResource("8")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(b[0]) * 32, int(b[1])]
		idx += 1
	idx = 1
	for p: Array in L["power"]:
		var res := '"10"'
		if p[0] == "blue":
			res = '"11"'
		elif p[0] == "orange":
			res = '"18"'
		s += '[node name="Power%d" parent="Objects" instance=ExtResource(%s)]\n' % [idx, res]
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(p[1]) * 32, int(p[2]) * 32 + 16]
		idx += 1
	idx = 1
	for sp: Array in L["spikes_g"]:
		s += '[node name="Spikes%d" parent="Objects" instance=ExtResource("15")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(sp[0]) * 32 + int(sp[1]) * 16, island_px]
		s += "width = %d\n" % (int(sp[1]) * 32)
		s += 'variant = "%s"\n\n' % sp[2]
		idx += 1
	idx = 1
	for m: Array in L["mines"]:
		s += '[node name="Mine%d" parent="Objects" instance=ExtResource("16")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(m[0]) * 32 + 16, int(m[1]) * 32 + 16]
		idx += 1
	idx = 1
	for sx: int in L["springs"]:
		s += '[node name="Spring%d" parent="Objects" instance=ExtResource("23")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [sx * 32 + 16, island_px]
		idx += 1

	idx = 1
	for tx: int in L["checkpoints"]:
		s += '[node name="Checkpoint%d" parent="." instance=ExtResource("17")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [tx * 32, island_px]
		idx += 1

	s += '[node name="Cabin" parent="." instance=ExtResource("9")]\n'
	s += "position = Vector2(%d.0, %d.0)\n\n" % [int(L["cabin"]) * 32, island_px]

	var wall_x: int = (int(L["cabin"]) + 2) * 32
	s += '[node name="CabinWall" type="StaticBody2D" parent="."]\n'
	s += "position = Vector2(%d.0, %d.0)\n" % [wall_x, island_px - 150]
	s += "collision_layer = 1\n"
	s += "collision_mask = 0\n\n"
	s += '[node name="CollisionShape2D" type="CollisionShape2D" parent="CabinWall"]\n'
	s += 'shape = SubResource("1")\n'

	var f := FileAccess.open(OUT_DIR + "W2L%d.tscn" % n, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("geschreven: W2L%d.tscn (%d tegels, %d px, %d/%d vijanden vereist, tiles=%s)" % [n, L["w"], width_px, kills, total, L["tileset"]])

# ----------------------------------------------------------- ontwerpdata ---

func _levels() -> Array:
	return [
		{
			# L1 — zwem-intro: pilaren, poorten, tunnel-eiland, slalom, blokken.
			"n": 1, "pct": 40, "both": false, "staart": 22,
			"tileset": "coral", "decor": ["seaweed", "coral_y", "coral_p"],
			"hint": "Wereld 2: duik de zee in en zwem overal heen! Springknop = slag omhoog, omlaag = duiken. Piranha's kun je boksen; zeemijnen en rotsen ontwijk je.",
			"secties": [
				["is", 22, {"coins": 4}],
				["is", 14, {"crabs": 1, "coins": 3}],
				["sea", 48, {"pattern": "pillars", "piranhas": 2, "coins": 8}],
				["is", 28, {"checkpoint": true, "crabs": 1, "coins": 4, "block": true}],
				["st", [16]],
				["is", 16, {"crabs": 1, "power": "purple", "spikes": 1}],
				["sea", 64, {"pattern": "gates", "piranhas": 2, "mines": 3, "coins": 10}],
				["is", 26, {"checkpoint": true, "coins": 4, "crabs": 1, "tunnel": true}],
				["sea", 54, {"pattern": "slalom", "piranhas": 1, "hunters": 1, "mines": 3, "coins": 8}],
				["is", 24, {"crabs": 1, "coins": 4, "power": "blue"}],
				["sea", 40, {"pattern": "blocks", "piranhas": 1, "hunters": 1, "coins": 6}],
			],
		},
		{
			# L2 — eilandhoppen: veel kleine eilanden, VLIEGENDE VISSEN als verrassing; paars rif.
			"n": 2, "pct": 45, "both": false, "staart": 20,
			"tileset": "reef", "decor": ["seaweed", "coral_p", "log"],
			"hint": "Pas op bij de oevers: sommige vissen springen uit het water!",
			"secties": [
				["is", 20, {"coins": 4}],
				["sea", 30, {"pattern": "pillars", "piranhas": 1, "coins": 5, "leapers": 1}],
				["is", 14, {"crabs": 1, "coins": 3, "leapers": 1}],
				["sea", 34, {"pattern": "none", "piranhas": 2, "coins": 6, "leapers": 2}],
				["is", 24, {"checkpoint": true, "crabs": 1, "block": true, "coins": 4}],
				["st", [16, 13]],
				["sea", 40, {"pattern": "gates", "piranhas": 2, "mines": 2, "coins": 8}],
				["is", 14, {"crabs": 1, "power": "purple", "leapers": 1}],
				["sea", 36, {"pattern": "pillars", "piranhas": 2, "coins": 6, "leapers": 2}],
				["is", 22, {"checkpoint": true, "crabs": 1, "coins": 4, "spikes": 1}],
				["sea", 44, {"pattern": "blocks", "piranhas": 2, "hunters": 1, "coins": 8}],
			],
		},
		{
			# L3 — ruïnes: totems en bogen op de eilanden, SPRINGVEER naar een hoog platform, tunnel.
			"n": 3, "pct": 50, "both": false, "staart": 22,
			"tileset": "coral", "decor": ["totem", "arch", "seaweed"],
			"secties": [
				["is", 22, {"coins": 4, "crabs": 1}],
				["sea", 40, {"pattern": "slalom", "piranhas": 2, "coins": 8}],
				["is", 26, {"checkpoint": true, "crabs": 1, "spring": true, "spring_power": "purple"}],
				["sea", 50, {"pattern": "gates", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 10}],
				["is", 28, {"checkpoint": true, "coins": 4, "crabs": 1, "tunnel": true}],
				["sea", 44, {"pattern": "pillars", "piranhas": 2, "coins": 6, "leapers": 1}],
				["is", 16, {"crabs": 1, "power": "blue", "spikes": 1}],
				["sea", 40, {"pattern": "blocks", "piranhas": 1, "hunters": 1, "mines": 2, "coins": 8}],
			],
		},
		{
			# L4 — STROMING: tegenstroom door de poorten, meestroom terug; zandkleurig rif.
			"n": 4, "pct": 55, "both": true, "staart": 22,
			"tileset": "sand", "decor": ["coral_y", "coral_p", "log"],
			"hint": "Voel je de stroming? Tegen de stroom in kost tijd — zoek de rustige stukken.",
			"secties": [
				["is", 20, {"coins": 4, "crabs": 1}],
				["sea", 44, {"pattern": "pillars", "piranhas": 2, "coins": 6, "current": -1}],
				["is", 22, {"checkpoint": true, "crabs": 1, "block": true, "coins": 4}],
				["sea", 56, {"pattern": "gates", "piranhas": 2, "mines": 3, "coins": 10, "current": -1}],
				["is", 18, {"crabs": 1, "power": "purple", "leapers": 1}],
				["sea", 48, {"pattern": "slalom", "piranhas": 2, "hunters": 1, "coins": 8, "current": 1}],
				["is", 24, {"checkpoint": true, "coins": 4, "crabs": 1, "spikes": 1}],
				["st", [16]],
				["sea", 44, {"pattern": "blocks", "piranhas": 2, "mines": 2, "coins": 8, "current": -1}],
			],
		},
		{
			# L5 — GEHEIME NIS onder een eiland met een power-up; lange slalom; paars rif.
			"n": 5, "pct": 55, "both": true, "staart": 22,
			"tileset": "reef", "decor": ["seaweed", "totem_moss", "coral_p"],
			"hint": "Niet elke rotswand is dicht… zoek de opening onder het eiland.",
			"secties": [
				["is", 20, {"coins": 4, "crabs": 1}],
				["sea", 44, {"pattern": "gates", "piranhas": 2, "mines": 2, "coins": 8}],
				["is", 26, {"checkpoint": true, "crabs": 1, "pocket": true, "pocket_power": "orange", "coins": 4}],
				["sea", 60, {"pattern": "slalom", "piranhas": 2, "hunters": 2, "mines": 3, "coins": 10}],
				["is", 22, {"checkpoint": true, "crabs": 1, "block": true, "leapers": 1}],
				["st", [16, 13]],
				["sea", 40, {"pattern": "pillars", "piranhas": 2, "coins": 6, "leapers": 2}],
				["is", 18, {"crabs": 1, "power": "blue", "spikes": 1}],
				["sea", 48, {"pattern": "blocks", "piranhas": 2, "hunters": 1, "mines": 2, "coins": 8}],
			],
		},
		{
			# L6 — archipel: korte zeeën vol vliegende vissen en jagers, weinig rust; koraal.
			"n": 6, "pct": 60, "both": true, "staart": 22,
			"tileset": "coral", "decor": ["coral_y", "seaweed", "log"],
			"secties": [
				["is", 18, {"coins": 4, "crabs": 1}],
				["sea", 28, {"pattern": "none", "piranhas": 1, "hunters": 1, "coins": 5, "leapers": 2}],
				["is", 12, {"crabs": 1, "coins": 3, "leapers": 1}],
				["sea", 28, {"pattern": "pillars", "piranhas": 2, "coins": 5, "leapers": 2}],
				["is", 22, {"checkpoint": true, "crabs": 1, "block": true, "spikes": 1}],
				["sea", 32, {"pattern": "gates", "piranhas": 1, "hunters": 1, "mines": 2, "coins": 6}],
				["is", 12, {"crabs": 1, "power": "purple", "leapers": 1}],
				["sea", 30, {"pattern": "blocks", "piranhas": 2, "coins": 6, "leapers": 2}],
				["is", 22, {"checkpoint": true, "crabs": 1, "coins": 4}],
				["st", [16, 13, 10], {"power": "blue"}],
				["sea", 36, {"pattern": "slalom", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8}],
			],
		},
		{
			# L7 — tunnelketen: twee tunnel-eilanden, meestroom erdoorheen; zand.
			"n": 7, "pct": 60, "both": true, "staart": 22,
			"tileset": "sand", "decor": ["totem", "coral_y", "seaweed"],
			"secties": [
				["is", 20, {"coins": 4, "crabs": 1}],
				["sea", 40, {"pattern": "pillars", "piranhas": 2, "coins": 6, "current": 1}],
				["is", 30, {"checkpoint": true, "crabs": 1, "tunnel": true, "coins": 4}],
				["sea", 36, {"pattern": "gates", "piranhas": 2, "mines": 2, "coins": 8, "current": 1}],
				["is", 30, {"crabs": 1, "tunnel": true, "power": "purple"}],
				["sea", 48, {"pattern": "blocks", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8, "current": -1}],
				["is", 24, {"checkpoint": true, "crabs": 1, "spring": true, "spring_power": "blue", "leapers": 1}],
				["sea", 44, {"pattern": "slalom", "piranhas": 2, "hunters": 1, "coins": 8}],
			],
		},
		{
			# L8 — jagers en mijnen: zware slalom, korte eilanden met egels; paars rif.
			"n": 8, "pct": 65, "both": true, "staart": 22,
			"tileset": "reef", "decor": ["arch", "seaweed", "coral_p"],
			"secties": [
				["is", 18, {"coins": 4, "crabs": 1}],
				["sea", 50, {"pattern": "slalom", "piranhas": 2, "hunters": 2, "mines": 4, "coins": 8}],
				["is", 20, {"checkpoint": true, "crabs": 1, "spikes": 2, "block": true}],
				["sea", 56, {"pattern": "gates", "piranhas": 2, "hunters": 2, "mines": 4, "coins": 10}],
				["is", 16, {"crabs": 1, "power": "orange", "leapers": 2}],
				["sea", 44, {"pattern": "blocks", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8}],
				["is", 24, {"checkpoint": true, "crabs": 2, "spring": true, "coins": 4}],
				["sea", 48, {"pattern": "pillars", "piranhas": 3, "hunters": 1, "coins": 6, "leapers": 2}],
			],
		},
		{
			# L9 — de grote mix: stroming, tunnel, nis, springveer, jagers — lang; koraal.
			"n": 9, "pct": 70, "both": true, "staart": 22,
			"tileset": "coral", "decor": ["totem_moss", "arch", "log"],
			"secties": [
				["is", 20, {"coins": 4, "crabs": 1}],
				["sea", 44, {"pattern": "gates", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8, "current": -1}],
				["is", 26, {"checkpoint": true, "crabs": 1, "pocket": true, "pocket_power": "purple", "leapers": 1}],
				["sea", 40, {"pattern": "pillars", "piranhas": 2, "coins": 6, "leapers": 2}],
				["is", 30, {"crabs": 1, "tunnel": true, "coins": 4}],
				["sea", 50, {"pattern": "slalom", "piranhas": 2, "hunters": 2, "mines": 3, "coins": 8, "current": 1}],
				["is", 24, {"checkpoint": true, "crabs": 2, "spring": true, "spring_power": "blue", "spikes": 1}],
				["st", [16, 13]],
				["sea", 48, {"pattern": "blocks", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8}],
				["is", 16, {"crabs": 1, "power": "orange", "leapers": 1}],
				["sea", 40, {"pattern": "gates", "piranhas": 3, "hunters": 1, "mines": 3, "coins": 8, "current": -1}],
			],
		},
		{
			# L10 — zwaarste zwemtocht: tegenstroom, vier zeeën, weinig eilanden; zand.
			"n": 10, "pct": 75, "both": true, "staart": 22,
			"tileset": "sand", "decor": ["totem", "totem_moss", "coral_y"],
			"secties": [
				["is", 18, {"coins": 4, "crabs": 1}],
				["sea", 60, {"pattern": "slalom", "piranhas": 3, "hunters": 2, "mines": 4, "coins": 10, "current": -1}],
				["is", 20, {"checkpoint": true, "crabs": 1, "spikes": 1, "block": true, "leapers": 2}],
				["sea", 60, {"pattern": "gates", "piranhas": 3, "hunters": 2, "mines": 4, "coins": 10, "current": -1}],
				["is", 26, {"checkpoint": true, "crabs": 2, "tunnel": true, "power": "purple"}],
				["sea", 56, {"pattern": "blocks", "piranhas": 3, "hunters": 2, "mines": 4, "coins": 10, "current": 1}],
				["is", 20, {"crabs": 1, "spring": true, "spring_power": "orange", "leapers": 2}],
				["sea", 50, {"pattern": "pillars", "piranhas": 3, "hunters": 2, "mines": 3, "coins": 8, "current": -1}],
			],
		},
		{
			# L11 — bosslevel: aanloop met van alles, dan de OCTOPUS-arena op een groot eiland.
			"n": 11, "pct": 0, "both": false, "staart": 60, "boss": true,
			"tileset": "reef", "decor": ["arch", "totem_moss", "seaweed"],
			"hint": "De octopus wacht op het laatste eiland. Boks 'm — en duik het water in als het te heet wordt!",
			"secties": [
				["is", 18, {"coins": 4, "crabs": 1}],
				["sea", 40, {"pattern": "gates", "piranhas": 2, "hunters": 1, "mines": 2, "coins": 8, "current": -1}],
				["is", 22, {"checkpoint": true, "crabs": 1, "spring": true, "spring_power": "purple", "leapers": 1}],
				["sea", 40, {"pattern": "slalom", "piranhas": 2, "hunters": 1, "mines": 3, "coins": 8}],
				["is", 20, {"checkpoint": true, "crabs": 1, "power": "orange", "coins": 4}],
				["sea", 30, {"pattern": "pillars", "piranhas": 2, "coins": 6, "leapers": 2}],
			],
		},
	]
