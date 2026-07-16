extends SceneTree

## Genereert scenes/levels/world1/W1L1..L10.tscn uit ontwerpdata.
## Coördinaten in tegels van 32px. Grond-bovenkant = rij 20 (y=640).
##
## Levels zijn opgebouwd uit secties (zie _levels() onderaan):
##   ["fl", lengte, opties]  — vlakke grond; opties: rats, snakes, coins, block,
##                             power ("purple"/"blue"/"orange"), checkpoint, bats
##   ["st", [rijen], opties] — platform-trap boven de grond (rij 17 → 14 → 11);
##                             opties: power, bat, coins (standaard aan)
##   ["gp", breedte, pilaren]— gat in de grond; pilaren = stapstenen (top rij 18)
##   ["hr", lengte, rij, opties] — hoge route: ladder + lang platform; optie spikes
##   ["sr", periodes, variant]   — stekelloop: om-en-om 4 veilig / 3 stekels
##   ["ba", lengte, n]       — vleermuizensteeg: n duikende vleermuizen
##
## Sprongregels (SPEED 180, JUMP -550, GRAVITY 980):
##   max ~4,8 tegels omhoog; ontwerp: max 3 omhoog per sprong
##   horizontaal gat: ≤5 vlak, ≤4 bij 1-2 omhoog, ≤3 bij 3 omhoog, ≤6 omlaag
## Een validatiepas dwingt deze regels af; bij een fout wordt niets weggeschreven.

const OUT_DIR := "/Users/wb-antal/claude-projecten/Flint-Game/scenes/levels/world1/"
const GROUND_Y := 20
const GROUND_DEPTH := 4

const MAX_UP := 3
const MAX_GAP_FLAT := 5
const MAX_GAP_DOWN := 6

var L: Dictionary = {}
var _cx := 0
var _g_start := 0
var _fail := false

func _init() -> void:
	for spec: Dictionary in _levels():
		_build(spec)
	if _fail:
		push_error("GEFAALD: validatiefouten, zie hierboven")
	else:
		print("KLAAR: 10 levels gegenereerd")
	quit(1 if _fail else 0)

# ---------------------------------------------------------------- secties ---

func _reset(spec: Dictionary) -> void:
	L = {
		"n": spec["n"], "pct": spec["pct"], "kills": spec["kills"], "both": spec["both"],
		"ground": [], "plats": [], "pillars": [], "ladders": [],
		"spikes_g": [], "spikes_p": [], "coin_rows": [],
		"rats": [], "snakes": [], "bats": [],
		"blocks": [], "power": [], "checkpoints": [],
		"cabin": 0, "boss": -1,
	}
	_cx = 0
	_g_start = 0

func _fl(len_t: int, o: Dictionary = {}) -> void:
	var x0 := _cx
	for i: int in o.get("rats", 0):
		L["rats"].append(x0 + (i + 1) * len_t / (o.get("rats", 0) + 1))
	for i: int in o.get("snakes", 0):
		L["snakes"].append(x0 + 2 + (i + 1) * len_t / (o.get("snakes", 0) + 1))
	for i: int in o.get("bats", 0):
		L["bats"].append([x0 + (i + 1) * len_t / (o.get("bats", 0) + 1), 9])
	var coins: int = o.get("coins", 0)
	if coins > 0:
		L["coin_rows"].append([x0 + 2, 19, coins])
	if o.get("block", false):
		L["blocks"].append(x0 + len_t / 3)
	if o.has("power"):
		L["power"].append([o["power"], x0 + 2 * len_t / 3, 17])
	if o.get("checkpoint", false):
		L["checkpoints"].append(x0 + len_t / 2)
	_cx += len_t

func _st(rows: Array, o: Dictionary = {}) -> void:
	var plen := 4
	var x := _cx + 2
	for i: int in rows.size():
		var row: int = rows[i]
		L["plats"].append([x, row, plen])
		if o.get("coins", true):
			L["coin_rows"].append([x, row - 2, 2])
		if i == rows.size() - 1:
			if o.has("power"):
				L["power"].append([o["power"], x + plen / 2, row - 3])
			if o.get("bat", false):
				L["bats"].append([x + plen, row - 4])
		x += plen + 3
	_cx = x - 3 + 2

func _gp(w: int, pillars: int = 0) -> void:
	L["ground"].append([_g_start, _cx])
	for i: int in pillars:
		L["pillars"].append([_cx + (i + 1) * w / (pillars + 1), 18])
	_cx += w
	_g_start = _cx

func _hr(len_t: int, row: int, o: Dictionary = {}) -> void:
	var x0 := _cx
	L["ladders"].append([x0 + 1, row])
	L["plats"].append([x0 + 3, row, len_t - 6])
	L["coin_rows"].append([x0 + 4, row - 2, mini(4, (len_t - 6) / 2)])
	L["bats"].append([x0 + len_t / 2, row - 4])
	if o.has("power"):
		L["power"].append([o["power"], x0 + len_t - 5, row - 3])
	if o.get("spikes", false):
		L["spikes_g"].append([x0 + 6, len_t - 10, o.get("variant", "small_wood")])
	_cx += len_t

func _sr(periods: int, variant: String = "small_wood") -> void:
	for i: int in periods:
		var p := _cx + i * 7
		L["spikes_g"].append([p + 4, 3, variant])
	L["coin_rows"].append([_cx + 1, 18, periods])
	_cx += periods * 7 + 2

func _ba(len_t: int, n: int) -> void:
	var x0 := _cx
	for i: int in n:
		L["bats"].append([x0 + (i + 1) * len_t / (n + 1), 8])
	L["coin_rows"].append([x0 + 2, 19, mini(6, len_t / 4)])
	_cx += len_t

func _finish(tail: int, boss: bool = false) -> void:
	if boss:
		L["boss"] = _cx + tail / 2
	L["cabin"] = _cx + tail - 6
	_cx += tail
	L["ground"].append([_g_start, _cx])
	L["w"] = _cx

# ------------------------------------------------------------- validatie ---

func _validate() -> PackedStringArray:
	var errs := PackedStringArray()
	var grounds: Array = L["ground"]

	# 1. Gaten: elk paar opeenvolgende steunpunten hooguit MAX_GAP_FLAT uit elkaar.
	for i: int in grounds.size() - 1:
		var g_end: int = grounds[i][1]
		var g_next: int = grounds[i + 1][0]
		var xs: Array = [g_end - 1]
		for pi: Array in L["pillars"]:
			if pi[0] >= g_end and pi[0] < g_next:
				xs.append(pi[0])
				if pi[1] < GROUND_Y - MAX_UP or pi[1] > GROUND_Y - 1:
					errs.append("pilaar op x=%d: top rij %d niet in 17..19" % [pi[0], pi[1]])
		xs.append(g_next)
		for j: int in xs.size() - 1:
			var empty: int = xs[j + 1] - xs[j] - 1
			if empty > MAX_GAP_FLAT:
				errs.append("gat bij x=%d: %d tegels leeg (max %d)" % [xs[j], empty, MAX_GAP_FLAT])

	# 2. Platform-bereikbaarheid (BFS vanaf grond, pilaren en ladders).
	var supports: Array = []
	for g: Array in grounds:
		supports.append({"x": g[0], "end": g[1], "row": GROUND_Y, "ok": true})
	for pi: Array in L["pillars"]:
		supports.append({"x": pi[0], "end": pi[0] + 1, "row": pi[1], "ok": true})
	for p: Array in L["plats"]:
		supports.append({"x": p[0], "end": p[0] + p[2], "row": p[1], "ok": false})

	var changed := true
	while changed:
		changed = false
		for s: Dictionary in supports:
			if s["ok"]:
				continue
			for lad: Array in L["ladders"]:
				if lad[1] - MAX_UP <= s["row"] and s["x"] - 2 <= lad[0] and lad[0] < s["end"] + 2:
					s["ok"] = true
			if not s["ok"]:
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
						break
			if s["ok"]:
				changed = true
	for s: Dictionary in supports:
		if not s["ok"]:
			errs.append("platform x=%d rij %d onbereikbaar" % [s["x"], s["row"]])

	# 3. Objecten die op vaste grond moeten staan.
	var named: Dictionary = {
		"checkpoint": L["checkpoints"], "rat": L["rats"], "snake": L["snakes"],
		"block": L["blocks"],
	}
	for what: String in named:
		for x: int in named[what]:
			if not _on_ground(x, grounds):
				errs.append("%s op x=%d staat niet boven grond" % [what, x])
	if not _on_ground(L["cabin"], grounds):
		errs.append("cabin op x=%d staat niet boven grond" % L["cabin"])
	if L["boss"] >= 0 and not _on_ground(L["boss"], grounds):
		errs.append("boss op x=%d staat niet boven grond" % L["boss"])
	for sp: Array in L["spikes_g"]:
		if not (_on_ground(sp[0], grounds) and _on_ground(sp[0] + sp[1] - 1, grounds)):
			errs.append("stekels op x=%d..%d hangen boven een gat" % [sp[0], sp[0] + sp[1] - 1])
	for lad: Array in L["ladders"]:
		if not _on_ground(lad[0], grounds):
			errs.append("ladder op x=%d staat niet boven grond" % lad[0])

	# 4. Power-blokken moeten springend te pakken zijn vanaf een steunpunt eronder.
	for p: Array in L["power"]:
		var px: int = p[1]
		var prow: int = p[2]
		var ok := false
		for s: Dictionary in supports:
			if s["x"] - 1 <= px and px < s["end"] + 1 and s["row"] > prow and s["row"] - prow <= 5:
				ok = true
		if not ok:
			errs.append("power-up op x=%d rij %d is niet te pakken" % [px, prow])

	# 5. Genoeg vijanden voor de kill-eis.
	var total: int = L["rats"].size() + L["snakes"].size() + L["bats"].size()
	if L["kills"] > total - 2 and L["boss"] < 0:
		errs.append("kill-eis %d te hoog voor %d vijanden" % [L["kills"], total])

	if L["checkpoints"].size() < 1:
		errs.append("level heeft geen checkpoint")
	return errs

func _on_ground(x: int, grounds: Array) -> bool:
	for g: Array in grounds:
		if x >= g[0] and x < g[1]:
			return true
	return false

# ------------------------------------------------------------ scene-write ---

func _build(spec: Dictionary) -> void:
	_reset(spec)
	for sec: Array in spec["secties"]:
		match sec[0]:
			"fl": _fl(sec[1], sec[2] if sec.size() > 2 else {})
			"st": _st(sec[1], sec[2] if sec.size() > 2 else {})
			"gp": _gp(sec[1], sec[2] if sec.size() > 2 else 0)
			"hr": _hr(sec[1], sec[2], sec[3] if sec.size() > 3 else {})
			"sr": _sr(sec[1], sec[2] if sec.size() > 2 else "small_wood")
			"ba": _ba(sec[1], sec[2])
	_finish(spec.get("staart", 20), spec.get("boss", false))

	var errs := _validate()
	if not errs.is_empty():
		_fail = true
		for e: String in errs:
			printerr("W1L%d: %s" % [L["n"], e])
		return
	_write_level()

func _write_level() -> void:
	var n: int = L["n"]
	var width_px: int = L["w"] * 32
	var has_boss: bool = L["boss"] >= 0

	var ext := ""
	ext += '[ext_resource type="Script"      path="res://scripts/levels/LevelBase.gd"             id="1"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn"               id="2"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/ui/HUD.tscn"                      id="3"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Rat.tscn"          id="4"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Snake.tscn"        id="5"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Bat.tscn"          id="6"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Coin.tscn"                id="7"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/SpecialBlock.tscn"        id="8"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Cabin.tscn"               id="9"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockPurple.tscn"    id="10"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockBlue.tscn"      id="11"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/ParallaxBG.tscn"          id="12"]\n'
	ext += '[ext_resource type="TileSet"     path="res://scenes/levels/world1_tileset.tres"       id="13"]\n'
	ext += '[ext_resource type="Script"      path="res://scripts/levels/Terrain.gd"               id="14"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spikes.tscn"              id="15"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Ladder.tscn"              id="16"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Checkpoint.tscn"          id="17"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockOrange.tscn"    id="18"]\n'
	var load_steps := 19
	if has_boss:
		ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/world1/ForestBoss.tscn"    id="19"]\n'
		load_steps = 20

	var s := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	s += ext + "\n"

	s += '[node name="W1L%d" type="Node2D"]\n' % n
	s += 'script = ExtResource("1")\n'
	s += "level_width = %d\n" % width_px
	s += "level_height = 720\n"
	s += "coins_needed_pct = %d\n" % L["pct"]
	s += "enemies_needed = %d\n" % L["kills"]
	s += "require_both = %s\n\n" % ("true" if L["both"] else "false")

	s += '[node name="ParallaxBG" parent="." instance=ExtResource("12")]\n\n'
	s += '[node name="HUD" parent="." instance=ExtResource("3")]\n\n'
	s += '[node name="Player" parent="." instance=ExtResource("2")]\n'
	s += "position = Vector2(120.0, 640.0)\n\n"

	# --- Terrain ---
	var rects: Array[String] = []
	for g: Array in L["ground"]:
		rects.append("Rect2i(%d, %d, %d, %d)" % [g[0], GROUND_Y, g[1] - g[0], GROUND_DEPTH])
	for p: Array in L["plats"]:
		rects.append("Rect2i(%d, %d, %d, 1)" % [p[0], p[1], p[2]])
	for pi: Array in L["pillars"]:
		rects.append("Rect2i(%d, %d, 1, %d)" % [pi[0], pi[1], GROUND_Y + GROUND_DEPTH - pi[1]])
	s += '[node name="Terrain" type="TileMapLayer" parent="."]\n'
	s += "scale = Vector2(2.0, 2.0)\n"
	s += 'tile_set = ExtResource("13")\n'
	s += 'script = ExtResource("14")\n'
	s += "solid_rects = Array[Rect2i]([%s])\n\n" % ", ".join(rects)

	# --- Vijanden ---
	s += '[node name="Enemies" type="Node2D" parent="."]\n\n'
	var idx := 1
	for tx: int in L["rats"]:
		s += '[node name="Rat%d" parent="Enemies" instance=ExtResource("4")]\n' % idx
		s += "position = Vector2(%d.0, 640.0)\n\n" % (tx * 32)
		idx += 1
	idx = 1
	for tx: int in L["snakes"]:
		s += '[node name="Snake%d" parent="Enemies" instance=ExtResource("5")]\n' % idx
		s += "position = Vector2(%d.0, 640.0)\n\n" % (tx * 32)
		idx += 1
	idx = 1
	for c: Array in L["bats"]:
		s += '[node name="Bat%d" parent="Enemies" instance=ExtResource("6")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [c[0] * 32, c[1] * 32]
		idx += 1
	if has_boss:
		s += '[node name="ForestBoss" parent="Enemies" instance=ExtResource("19")]\n'
		s += "position = Vector2(%d.0, 640.0)\n\n" % (int(L["boss"]) * 32)

	# --- Objecten ---
	s += '[node name="Objects" type="Node2D" parent="."]\n\n'
	idx = 1
	for row: Array in L["coin_rows"]:
		for i: int in row[2]:
			var cx: int = (row[0] + i * 2) * 32 + 16
			var cy: int = row[1] * 32 + 8
			s += '[node name="Coin%d" parent="Objects" instance=ExtResource("7")]\n' % idx
			s += "position = Vector2(%d.0, %d.0)\n\n" % [cx, cy]
			idx += 1
	idx = 1
	for tx: int in L["blocks"]:
		s += '[node name="SpecialBlock%d" parent="Objects" instance=ExtResource("8")]\n' % idx
		s += "position = Vector2(%d.0, 624.0)\n\n" % (tx * 32)
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
		s += "position = Vector2(%d.0, 640.0)\n" % (int(sp[0]) * 32 + int(sp[1]) * 16)
		s += "width = %d\n" % (int(sp[1]) * 32)
		s += 'variant = "%s"\n\n' % sp[2]
		idx += 1
	for sp: Array in L["spikes_p"]:
		s += '[node name="Spikes%d" parent="Objects" instance=ExtResource("15")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(sp[0]) * 32 + int(sp[2]) * 16, int(sp[1]) * 32]
		s += "width = %d\n" % (int(sp[2]) * 32)
		s += 'variant = "%s"\n\n' % sp[3]
		idx += 1
	idx = 1
	for lad: Array in L["ladders"]:
		var top_px: int = int(lad[1]) * 32
		s += '[node name="Ladder%d" parent="Objects" instance=ExtResource("16")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(lad[0]) * 32 + 16, top_px]
		s += "height = %d\n\n" % (640 - top_px)
		idx += 1

	idx = 1
	for tx: int in L["checkpoints"]:
		s += '[node name="Checkpoint%d" parent="." instance=ExtResource("17")]\n' % idx
		s += "position = Vector2(%d.0, 640.0)\n\n" % (tx * 32)
		idx += 1

	s += '[node name="Cabin" parent="." instance=ExtResource("9")]\n'
	s += "position = Vector2(%d.0, 640.0)\n" % (int(L["cabin"]) * 32)

	var f := FileAccess.open(OUT_DIR + "W1L%d.tscn" % n, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("geschreven: W1L%d.tscn (%d tegels, %d px)" % [n, L["w"], width_px])

# ----------------------------------------------------------- ontwerpdata ---

func _levels() -> Array:
	return [
		{
			# L1 — intro: rustig kennismaken met springen, trapjes en de drie vijanden
			"n": 1, "pct": 40, "kills": 3, "both": false, "staart": 22,
			"secties": [
				["fl", 40, {"coins": 6, "rats": 1, "block": true}],
				["st", [17]],
				["fl", 30, {"snakes": 1, "coins": 4}],
				["gp", 3],
				["fl", 32, {"rats": 1, "power": "purple"}],
				["st", [17, 14], {"bat": true}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["gp", 4],
				["fl", 32, {"rats": 1, "block": true}],
				["sr", 3],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["st", [17], {"power": "blue"}],
				["fl", 26, {"rats": 1, "checkpoint": true}],
				["gp", 4],
				["fl", 34, {"coins": 6, "snakes": 1}],
				["ba", 26, 1],
			],
		},
		{
			# L2 — ladder-intro: eerste hoge route + trapjes
			"n": 2, "pct": 50, "kills": 4, "both": false, "staart": 22,
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["st", [17, 14]],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["gp", 4],
				["fl", 30, {"rats": 1}],
				["hr", 34, 12, {"power": "purple"}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 3],
				["fl", 28, {"rats": 1, "block": true}],
				["gp", 4],
				["fl", 30, {"snakes": 1, "coins": 5}],
				["st", [17, 14], {"power": "blue", "bat": true}],
				["fl", 26, {"rats": 1, "checkpoint": true}],
				["ba", 28, 2],
				["fl", 30, {"snakes": 1, "coins": 5}],
				["gp", 5],
				["fl", 26, {"coins": 4}],
			],
		},
		{
			# L3 — twee pilaar-oversteken + oranje power-up-intro
			"n": 3, "pct": 50, "kills": 5, "both": false, "staart": 22,
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["st", [17]],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["gp", 9, 1],
				["fl", 30, {"rats": 1, "power": "orange"}],
				["st", [17, 14], {"bat": true}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1}],
				["hr", 34, 12, {"power": "blue"}],
				["fl", 28, {"snakes": 1, "coins": 5, "block": true}],
				["gp", 13, 2],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["ba", 28, 2],
				["fl", 30, {"snakes": 1, "coins": 5}],
				["gp", 5],
				["fl", 26, {"coins": 4}],
			],
		},
		{
			# L4 — stekels-intro serieus: beide eisen verplicht
			"n": 4, "pct": 60, "kills": 6, "both": true, "staart": 22,
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["sr", 3],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["st", [17, 14], {"power": "purple"}],
				["fl", 28, {"rats": 1}],
				["gp", 9, 1],
				["fl", 30, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1, "bats": 1}],
				["hr", 36, 12, {"power": "blue", "spikes": true}],
				["fl", 28, {"snakes": 1, "coins": 5, "block": true}],
				["gp", 4],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["gp", 13, 2],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L5 — klimlevel: twee hoge routes en een laddertoren
			"n": 5, "pct": 60, "kills": 7, "both": true, "staart": 22,
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["st", [17, 14, 11], {"power": "purple"}],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["gp", 4],
				["fl", 28, {"rats": 1}],
				["hr", 38, 12, {"spikes": true}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1, "bats": 1}],
				["gp", 9, 1],
				["fl", 28, {"snakes": 1, "block": true}],
				["hr", 38, 11, {"power": "blue", "spikes": true}],
				["fl", 28, {"rats": 1, "checkpoint": true, "coins": 5}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["gp", 5],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L6 — vleermuizensteeg: veel duikaanvallen, bukken loont
			"n": 6, "pct": 60, "kills": 8, "both": true, "staart": 22,
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["ba", 30, 2],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["gp", 9, 1],
				["fl", 28, {"rats": 1, "power": "purple"}],
				["ba", 30, 3],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 26, {"rats": 1}],
				["st", [17, 14], {"power": "blue", "bat": true}],
				["fl", 26, {"snakes": 1, "coins": 5, "block": true}],
				["gp", 13, 2],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["ba", 32, 3],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["hr", 34, 12, {"power": "orange"}],
				["fl", 26, {"rats": 1, "coins": 4}],
				["gp", 5],
				["fl", 24, {"coins": 4}],
			],
		},
		{
			# L7 — pilaarsprongen: drie brede oversteken
			"n": 7, "pct": 70, "kills": 8, "both": true, "staart": 22,
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["st", [17, 14]],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["gp", 13, 2],
				["fl", 28, {"rats": 1, "power": "purple"}],
				["sr", 4],
				["fl", 26, {"snakes": 1, "bats": 1}],
				["gp", 17, 3],
				["fl", 30, {"checkpoint": true, "rats": 1, "coins": 4}],
				["st", [17, 14, 11], {"power": "blue", "bat": true}],
				["fl", 26, {"snakes": 1, "coins": 5, "block": true}],
				["gp", 13, 2],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["hr", 36, 12, {"power": "orange", "spikes": true}],
				["fl", 26, {"snakes": 1, "coins": 5}],
				["gp", 17, 3],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L8 — stekel-spitsroede: lange stekelvelden, route via platforms
			"n": 8, "pct": 70, "kills": 8, "both": true, "staart": 22,
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["sr", 4],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["sr", 4, "long_wood"],
				["fl", 26, {"rats": 1, "power": "purple"}],
				["gp", 9, 1],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["hr", 38, 12, {"power": "blue", "spikes": true, "variant": "long_wood"}],
				["fl", 26, {"rats": 1, "bats": 1}],
				["sr", 5, "long_wood"],
				["fl", 26, {"snakes": 1, "coins": 5, "block": true}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["sr", 4],
				["fl", 26, {"snakes": 1, "coins": 5}],
				["gp", 13, 2],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L9 — finale-mix: alles samen, langste level
			"n": 9, "pct": 80, "kills": 10, "both": true, "staart": 22,
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["st", [17, 14, 11], {"power": "purple"}],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["gp", 13, 2],
				["fl", 26, {"rats": 1}],
				["sr", 4, "long_wood"],
				["fl", 26, {"snakes": 1, "bats": 1}],
				["hr", 38, 12, {"spikes": true}],
				["fl", 28, {"checkpoint": true, "rats": 1, "coins": 4}],
				["gp", 17, 3],
				["fl", 26, {"snakes": 1, "block": true}],
				["ba", 30, 3],
				["fl", 26, {"rats": 1, "coins": 5}],
				["st", [17, 14], {"power": "blue", "bat": true}],
				["fl", 26, {"snakes": 1}],
				["sr", 5, "long_wood"],
				["fl", 28, {"rats": 1, "checkpoint": true, "coins": 5}],
				["gp", 13, 2],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["hr", 36, 11, {"power": "orange", "spikes": true, "variant": "long_wood"}],
				["fl", 26, {"rats": 1, "coins": 4}],
				["gp", 5],
				["fl", 24, {"coins": 4}],
			],
		},
		{
			# L10 — bosslevel: aanloop met opwarmertjes, dan de ForestBoss-arena
			"n": 10, "pct": 0, "kills": 1, "both": false, "staart": 70, "boss": true,
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["st", [17], {"power": "purple"}],
				["fl", 24, {"snakes": 1, "coins": 4}],
				["sr", 3],
				["fl", 24, {"checkpoint": true, "coins": 4}],
				["st", [17], {"power": "orange"}],
				["fl", 20, {"rats": 1}],
			],
		},
	]
