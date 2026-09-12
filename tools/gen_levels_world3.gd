extends SceneTree

## Genereert scenes/levels/world3/W3L1..L11.tscn uit ontwerpdata (Wereld 3: Grot).
## Coördinaten in tegels van 32px. De grondrij is hier VARIABEL: `up`/`dn`-
## secties laten de vloer stijgen of dalen (klim-/daallevels), de rots loopt
## onder elke vloer door tot rij BOTTOM. Een plafond (rots op rij -8..1, met
## stalactieten eronder) geeft het grot-gevoel; klimlevels laten het weg.
##
## Levelspec: n, pct, both, tileset ("grotto"/"crystal"/"rock"/"brick"),
## decor (namen uit DECOR, grond), ceil_decor (namen, hangend), ceiling
## (standaard true), dark (donker level met lichtschijnsel), start_row
## (grondrij bij de start, standaard 20), hint, staart, boss, secties.
##
## Secties (gy = huidige grondrij):
##   ["fl", lengte, opties]   — vlak; opties: slimes, zombies, bats, coins,
##                              block, power, checkpoint
##   ["gp", breedte, pilaren] — gat; pilaren = stapstenen (top gy-2)
##   ["st", [rel...], opties] — platform-trapje rel rijen boven de grond (3,6,9)
##   ["hr", lengte, rel, o]   — hoge route: ladder + lang platform (rel ≈ 8)
##   ["sr", periodes, variant]— stekelloop (small_metal/long_metal/...)
##   ["ba", lengte, n]        — vleermuizensteeg (duikende vleermuizen)
##   ["fp", breedte, n]       — instortende platforms over een gat
##   ["mp", breedte]          — heen-en-weer bewegend platform over een gat
##   ["sp", lengte, opties]   — springveer → hoog platform (gy-8)
##   ["pd", breedte, opties]  — vijver (4 diep) om doorheen te zwemmen
##   ["lk", breedte, opties]  — ondergronds meer (6 diep); opties: arch (rots-
##                              overhang: eronderdoor duiken), piranhas, coins
##   ["tw", opties]           — klimtoren (ladder + zigzag omhoog)
##   ["cv", lengte, opties]   — verborgen tunnel onder een stekelveld
##   ["up", k, wijze]         — vloer k rijen OMHOOG: "step" (k≤3), "stairs"
##                              (platform-trap), "spring" (springveer, k≤10),
##                              "lift" (verticaal bewegend platform, k≤12)
##   ["dn", k]                — vloer k rijen OMLAAG (klif; springen/vallen)
##   ["sw", lengte, n]        — ZWERM: n vleermuizen razen op stahoogte door de
##                              gang zodra je de sectie binnenkomt; enige
##                              dekking = de kuil (3 breed, 3 diep) even verderop
##
## Sprongregels als W1: max 3 rijen omhoog per sprong; gat ≤5 vlak, ≤4 bij
## 1-2 omhoog, ≤3 bij 3 omhoog, ≤6 omlaag. Validatiepas dwingt ze af.
## Draaien: Godot --headless --path . --script tools/gen_levels_world3.gd

const OUT_DIR := "/Users/wb-antal/claude-projecten/Flint-Game/scenes/levels/world3/"
const BASE_ROW := 20
const BOTTOM := 30              # rots t/m rij 29
const CEIL_TOP := -8
const CEIL_BOTTOM := 2          # plafond = rijen -8..1; rij 2 is vrij
const CEIL_PX := CEIL_BOTTOM * 32
const POND_DEPTH := 4
const LAKE_DEPTH := 6
const WATER_DROP := 12          # wateroppervlak 12px onder de oever

const MAX_UP := 3
const MAX_GAP_FLAT := 5
const MAX_GAP_DOWN := 6
const LENGTH_SCALE := 0.8
const N_LEVELS := 11

const G := "res://assets/sprites/tiles/world3_cave/grotto_source.png"
const R := "res://assets/sprites/tiles/world3_cave/rotting_source.png"
const P := "res://assets/sprites/tiles/world3_cave/props/"

## naam → [texture, regio of null, schaal, z_index, anker ("ground"/"ceiling")]
const DECOR: Dictionary = {
	"pillar":      [G, [128, 64, 48, 96], 2, -1, "ground"],
	"gate":        [G, [200, 64, 140, 112], 2, -1, "ground"],
	"stalagmites": [G, [32, 176, 80, 48], 2, -1, "ground"],
	"plant":       [P + "plant.png", null, 2, -1, "ground"],
	"plant_big":   [P + "plant-big.png", null, 2, -1, "ground"],
	"palm":        [P + "palm.png", null, 2, -1, "ground"],
	"mush_teal":   [R, [80, 128, 32, 16], 2, -1, "ground"],
	"mush_purple": [R, [80, 144, 32, 16], 2, -1, "ground"],
	"gem_red":     [R, [0, 160, 16, 16], 2, -1, "ground"],
	"gem_green":   [R, [16, 160, 16, 16], 2, -1, "ground"],
	"gem_blue":    [R, [32, 160, 16, 16], 2, -1, "ground"],
	"gem_orange":  [R, [48, 160, 16, 16], 2, -1, "ground"],
	"sign":        [R, [48, 144, 16, 16], 2, -1, "ground"],
	"rock_small":  [R, [32, 144, 16, 16], 2, -1, "ground"],
	"stal_small":  [R, [96, 160, 16, 16], 2, -1, "ground"],
	"chain":       [R, [64, 128, 16, 48], 2, -1, "ceiling"],
	"stal_tall":   [R, [112, 128, 16, 32], 2, -1, "ceiling"],
	"stal_cluster":[G, [32, 176, 80, 48], 2, -1, "ceiling_flip"],
}

const TILESETS: Dictionary = {
	"grotto":  "res://scenes/levels/world3_tileset_grotto.tres",
	"crystal": "res://scenes/levels/world3_tileset_crystal.tres",
	"rock":    "res://scenes/levels/world3_tileset_rock.tres",
	"brick":   "res://scenes/levels/world3_tileset_brick.tres",
}

var L: Dictionary = {}
var _cx := 0
var _gy := BASE_ROW
var _g_start := 0
var _fail := false
var _rng := RandomNumberGenerator.new()
var _decor_names: Array = []
var _ceil_names: Array = []

func _init() -> void:
	for spec: Dictionary in _levels():
		_build(spec)
	if _fail:
		push_error("GEFAALD: validatiefouten, zie hierboven")
	else:
		print("KLAAR: %d levels gegenereerd" % N_LEVELS)
	quit(1 if _fail else 0)

## Vijanden-eis: 40% (L1) → 80% (laatste level) van alle vijanden.
func _kill_pct(n: int) -> float:
	return 0.4 + 0.4 * (n - 1) / float(N_LEVELS - 1)

# ---------------------------------------------------------------- secties ---

func _reset(spec: Dictionary) -> void:
	L = {
		"n": spec["n"], "pct": spec["pct"], "both": spec["both"],
		"hint": spec.get("hint", ""), "tileset": spec.get("tileset", "grotto"),
		"ceiling": spec.get("ceiling", true), "dark": spec.get("dark", false),
		"start_row": spec.get("start_row", BASE_ROW),
		"ground": [], "plats": [], "pillars": [], "ladders": [], "extra_rects": [],
		"no_grass": [], "spikes": [], "coin_rows": [], "coins_free": [],
		"slimes": [], "zombies": [], "bats": [], "swarm": [], "piranhas": [],
		"blocks": [], "power": [], "checkpoints": [], "decor": [], "hints": [],
		"falling": [], "moving": [], "springs": [], "ponds": [], "spring_plats": [],
		"rises": [], "cabin": [0, BASE_ROW], "boss": null, "deep": 0,
	}
	_cx = 0
	_gy = L["start_row"]
	_g_start = 0
	_rng.seed = 3000 + int(spec["n"])
	_decor_names = spec.get("decor", ["plant", "rock_small"])
	_ceil_names = spec.get("ceil_decor", ["stal_tall"])

func _close_ground() -> void:
	if _cx > _g_start:
		L["ground"].append([_g_start, _cx, _gy])
	_g_start = _cx

func _len(raw: int, minimum: int) -> int:
	return maxi(minimum, roundi(raw * LENGTH_SCALE))

func _fl(len_raw: int, o: Dictionary = {}) -> void:
	var len_t := _len(len_raw, 6)
	var x0 := _cx
	for i: int in o.get("slimes", 0):
		L["slimes"].append([x0 + (i + 1) * len_t / (o.get("slimes", 0) + 1), _gy])
	for i: int in o.get("zombies", 0):
		L["zombies"].append([x0 + 2 + (i + 1) * len_t / (o.get("zombies", 0) + 1), _gy])
	for i: int in o.get("bats", 0):
		L["bats"].append([x0 + (i + 1) * len_t / (o.get("bats", 0) + 1), _bat_row(_gy - 11)])
	var coins: int = o.get("coins", 0)
	if coins > 0:
		L["coin_rows"].append([x0 + 2, _gy - 1, coins])
	if o.get("block", false):
		L["blocks"].append([x0 + len_t / 3, _gy * 32 - 16])
	if o.has("power"):
		L["power"].append([o["power"], x0 + 2 * len_t / 3, _gy - 3])
	if o.get("checkpoint", false):
		L["checkpoints"].append([x0 + len_t / 2, _gy])
	var n_decor: int = 1 if len_t < 16 else 2
	for i: int in n_decor:
		var dx: int = x0 + 1 + _rng.randi_range(0, maxi(0, len_t - 5))
		L["decor"].append([dx, _pick(_decor_names), _gy])
	if L["ceiling"] and not _ceil_names.is_empty() and len_t >= 10:
		L["decor"].append([x0 + _rng.randi_range(2, len_t - 3), _pick(_ceil_names), CEIL_BOTTOM])
	_cx += len_t

func _pick(names: Array) -> String:
	return names[_rng.randi_range(0, names.size() - 1)]

## Vleermuizen niet in het plafond hangen.
func _bat_row(row: int) -> int:
	return maxi(row, CEIL_BOTTOM + 3) if L["ceiling"] else row

func _st(rels: Array, o: Dictionary = {}) -> void:
	var plen := 4
	var x := _cx + 2
	for i: int in rels.size():
		var row: int = _gy - int(rels[i])
		L["plats"].append([x, row, plen])
		if o.get("coins", true):
			L["coin_rows"].append([x, row - 2, 2])
		if i == rels.size() - 1:
			if o.has("power"):
				L["power"].append([o["power"], x + plen / 2, row - 3])
			if o.get("bat", false):
				L["bats"].append([x + plen, _bat_row(row - 4)])
		x += plen + 3
	_cx = x - 3 + 2

func _gp(w_raw: int, pillars: int = 0) -> void:
	var w := _len(w_raw, 2)
	_close_ground()
	for i: int in pillars:
		L["pillars"].append([_cx + (i + 1) * w / (pillars + 1), _gy - 2])
	_cx += w
	_g_start = _cx

func _hr(len_raw: int, rel: int, o: Dictionary = {}) -> void:
	var len_t := _len(len_raw, 16)
	var x0 := _cx
	var row := _gy - rel
	L["ladders"].append([x0 + 1, row, _gy])
	L["plats"].append([x0 + 3, row, len_t - 6])
	L["coin_rows"].append([x0 + 4, row - 2, mini(4, (len_t - 6) / 2)])
	L["bats"].append([x0 + len_t / 2, _bat_row(row - 4)])
	if o.has("power"):
		L["power"].append([o["power"], x0 + len_t - 5, row - 3])
	if o.get("spikes", false):
		L["spikes"].append([x0 + 6, len_t - 10, o.get("variant", "small_metal"), _gy])
	_cx += len_t

func _sr(periods_raw: int, variant: String = "small_metal") -> void:
	var periods: int = maxi(2, roundi(periods_raw * LENGTH_SCALE))
	for i: int in periods:
		var p := _cx + i * 7
		L["spikes"].append([p + 4, 3, variant, _gy])
		var coin_x: int
		var coin_row: int
		match i % 3:
			0: coin_x = p + 4; coin_row = _gy - 3
			1: coin_x = p + 6; coin_row = _gy - 3
			_: coin_x = p + 5; coin_row = _gy - 4
		L["coin_rows"].append([coin_x, coin_row, 1])
	_cx += periods * 7 + 2

func _ba(len_raw: int, n: int) -> void:
	var len_t: int = maxi(4 * (n + 1), roundi(len_raw * LENGTH_SCALE))
	var x0 := _cx
	for i: int in n:
		L["bats"].append([x0 + (i + 1) * len_t / (n + 1), _bat_row(_gy - 12)])
	L["coin_rows"].append([x0 + 2, _gy - 1, mini(6, len_t / 4)])
	_cx += len_t

func _fp(w_raw: int, n: int) -> void:
	var w: int = maxi(6 * n + 2, roundi(w_raw * LENGTH_SCALE))
	_close_ground()
	var seg := float(w) / n
	for i: int in n:
		var center := _cx + seg * (i + 0.5)
		L["falling"].append([center * 32.0, _gy * 32 - 12])
		L["coins_free"].append([int(center), _gy - 2])
	_cx += w
	_g_start = _cx

func _mp(w_raw: int) -> void:
	var w := _len(w_raw, 8)
	_close_ground()
	var from_x := (_cx + 2.0) * 32.0
	var to_x := (_cx + w - 2.0) * 32.0
	L["moving"].append([from_x, _gy * 32 - 10, to_x - from_x, 0.0, w * 0.35])
	L["coins_free"].append([_cx + w / 2, _gy - 3])
	_cx += w
	_g_start = _cx

func _sp(len_raw: int, o: Dictionary = {}) -> void:
	var len_t := _len(len_raw, 14)
	var x0 := _cx
	var sx := x0 + len_t / 3
	L["springs"].append([sx, _gy])
	var px := sx + 2
	var prow := _gy - 8
	L["spring_plats"].append([px, prow, 5])
	L["coin_rows"].append([px, prow - 2, 3])
	if o.has("power"):
		L["power"].append([o["power"], px + 2, prow - 3])
	for i: int in o.get("slimes", 0):
		L["slimes"].append([x0 + len_t - 4, _gy])
	L["decor"].append([x0 + len_t - 3, _decor_names[0], _gy])
	_cx += len_t

func _pd(w_raw: int, o: Dictionary = {}) -> void:
	var w := _len(w_raw, 5)
	_close_ground()
	var floor_row := _gy + POND_DEPTH
	L["ponds"].append([_cx, w, _gy, floor_row])
	L["extra_rects"].append([_cx, floor_row, w, BOTTOM - floor_row])
	L["deep"] = maxi(L["deep"], floor_row)
	var n_c: int = o.get("coins", 2)
	for i: int in n_c:
		L["coins_free"].append([_cx + 1 + (i * (w - 2)) / maxi(1, n_c - 1) if n_c > 1 else _cx + w / 2, floor_row - 1])
	_cx += w
	_g_start = _cx

## Ondergronds meer: 6 diep; optie arch = rotsoverhang in het midden (van de
## oeverrij tot 2 rijen diep, 4 breed) waar je onderdoor moet duiken;
## piranha's zwemmen onderin.
func _lk(w_raw: int, o: Dictionary = {}) -> void:
	var w := _len(w_raw, 10)
	_close_ground()
	var floor_row := _gy + LAKE_DEPTH
	L["ponds"].append([_cx, w, _gy, floor_row])
	L["extra_rects"].append([_cx, floor_row, w, BOTTOM - floor_row])
	L["deep"] = maxi(L["deep"], floor_row)
	if o.get("arch", false):
		var ax := _cx + w / 2 - 2
		L["extra_rects"].append([ax, _gy - 1, 4, 4])   # steekt 1 rij boven de oever uit
		L["no_grass"].append([ax, _gy, 4, 3])
	var n_c: int = o.get("coins", 3)
	for i: int in n_c:
		L["coins_free"].append([_cx + 1 + (i * (w - 2)) / maxi(1, n_c - 1) if n_c > 1 else _cx + w / 2, floor_row - 1])
	for i: int in o.get("piranhas", 0):
		L["piranhas"].append([_cx + 2 + (i + 1) * (w - 4) / (o.get("piranhas", 0) + 1), floor_row - 2, _gy, 90.0])
	_cx += w
	_g_start = _cx

func _tw(o: Dictionary = {}) -> void:
	var x0 := _cx
	L["ladders"].append([x0 + 2, _gy - 6, _gy])
	L["plats"].append([x0 + 1, _gy - 6, 4])
	L["plats"].append([x0 + 7, _gy - 9, 4])
	L["plats"].append([x0 + 1, _gy - 12, 4])
	L["coin_rows"].append([x0 + 1, _gy - 8, 2])
	L["coin_rows"].append([x0 + 7, _gy - 11, 2])
	L["coin_rows"].append([x0 + 1, _gy - 14, 2])
	if o.has("power"):
		L["power"].append([o["power"], x0 + 3, _gy - 15])
	if o.get("bat", false):
		L["bats"].append([x0 + 9, _bat_row(_gy - 13)])
	_cx += 13

func _cv(len_raw: int, o: Dictionary = {}) -> void:
	var len_t := _len(len_raw, 18)
	var x0 := _cx
	var t0 := _gy + 1
	L["extra_rects"].append(["cut", x0 + 1, _gy, 2, 4])
	L["extra_rects"].append(["cut", x0 + 3, t0, len_t - 6, 3])
	L["extra_rects"].append(["cut", x0 + len_t - 3, _gy, 2, 4])
	L["no_grass"].append([x0 + 1, _gy + 4, len_t - 2, 1])
	L["deep"] = maxi(L["deep"], _gy + 4)
	L["spikes"].append([x0 + 5, len_t - 10, o.get("variant", "small_metal"), _gy])
	var n_c: int = mini(6, (len_t - 8) / 2)
	L["coin_rows"].append([x0 + 4, t0 + 1, n_c])
	if o.get("block", false):
		L["blocks"].append([x0 + len_t / 2, (t0 + 2) * 32 + 16])
	L["coins_free"].append([x0 + 1, t0 + 1])
	L["decor"].append([x0 + len_t / 2, _pick(_decor_names), _gy])
	_cx += len_t

## Vloer k rijen omhoog.
func _up(k: int, mode: String = "step") -> void:
	var x0 := _cx
	match mode:
		"step":
			_close_ground()
			_gy -= k
		"stairs":
			var steps: int = int(ceil(k / 3.0))
			for i in range(1, steps):
				L["plats"].append([x0 + 1 + (i - 1) * 4, _gy - 3 * i, 3])
				L["coins_free"].append([x0 + 2 + (i - 1) * 4, _gy - 3 * i - 2])
			_cx = x0 + 1 + (steps - 1) * 4
			_close_ground()
			L["rises"].append([x0, _cx])
			_gy -= k
		"spring":
			L["springs"].append([x0 + 1, _gy])
			for i in 3:
				L["coins_free"].append([x0 + 1 + i, _gy - 4 - 3 * i])
			_cx = x0 + 5
			_close_ground()
			L["rises"].append([x0, _cx])
			_gy -= k
		"lift":
			_close_ground()
			var w := 6
			L["moving"].append([(x0 + w / 2.0) * 32.0, _gy * 32 - 10, 0.0, -k * 32.0, k * 0.55 + 3.0])
			L["coins_free"].append([x0 + w / 2, _gy - k / 2])
			_cx = x0 + w
			_g_start = _cx
			L["rises"].append([x0, _cx])
			_gy -= k

## Vloer k rijen omlaag (klif).
func _dn(k: int) -> void:
	_close_ground()
	_gy += k

## Zwerm: hint-trigger en kuil; n vleermuizen wachten ver rechts (buiten beeld).
func _sw(len_raw: int, n: int) -> void:
	var len_t := _len(len_raw, 16)
	var x0 := _cx
	var pit_x := x0 + 7
	L["extra_rects"].append(["cut", pit_x, _gy, 3, 3])
	L["no_grass"].append([pit_x, _gy + 3, 3, 1])
	L["deep"] = maxi(L["deep"], _gy + 3)
	L["coins_free"].append([pit_x, _gy + 2])
	L["coins_free"].append([pit_x + 2, _gy + 2])
	L["hints"].append([x0 + 1, "Een zwerm vleermuizen! Spring snel in de kuil!"])
	L["swarm"].append([x0 + 1, x0 + 32, x0 - 14, _gy, n])
	L["decor"].append([x0 + 3, _pick(_decor_names), _gy])
	_cx += len_t

func _finish(tail_raw: int, boss: bool = false) -> void:
	var tail: int = maxi(12, roundi(tail_raw * LENGTH_SCALE))
	if boss:
		L["boss"] = [_cx + tail / 2, _gy, (_cx + 3) * 32, (_cx + tail - 8) * 32]
	L["cabin"] = [_cx + tail - 6, _gy]
	_cx += tail
	_close_ground()
	L["w"] = _cx

# ------------------------------------------------------------- validatie ---

func _validate() -> PackedStringArray:
	var errs := PackedStringArray()
	var grounds: Array = L["ground"]

	# 1. Overgangen tussen grondstukken.
	for i: int in grounds.size() - 1:
		var a: Array = grounds[i]
		var b: Array = grounds[i + 1]
		var g_end: int = a[1]
		var g_next: int = b[0]
		if _bridged(g_end, g_next) or _is_rise(g_end, g_next):
			continue
		var dh: int = int(a[2]) - int(b[2])   # >0 = volgende stuk hoger
		if g_end == g_next:
			if dh > MAX_UP:
				errs.append("klif omhoog bij x=%d: %d rijen (max %d zonder trap/veer/lift)" % [g_end, dh, MAX_UP])
			continue
		var xs: Array = [[g_end - 1, int(a[2])]]
		for pi: Array in L["pillars"]:
			if pi[0] >= g_end and pi[0] < g_next:
				xs.append([pi[0], pi[1]])
				if pi[1] < int(a[2]) - MAX_UP or pi[1] > int(a[2]) - 1:
					errs.append("pilaar op x=%d: top rij %d niet binnen 1..3 boven de grond" % [pi[0], pi[1]])
		xs.append([g_next, int(b[2])])
		for j: int in xs.size() - 1:
			var empty: int = xs[j + 1][0] - xs[j][0] - 1
			var up: int = xs[j][1] - xs[j + 1][1]
			var limit := MAX_GAP_FLAT
			if up == 3:
				limit = 3
			elif up > 0:
				limit = 4
			elif up < 0:
				limit = MAX_GAP_DOWN
			if up > MAX_UP:
				errs.append("sprong bij x=%d: %d rijen omhoog" % [xs[j][0], up])
			if empty > limit:
				errs.append("gat bij x=%d: %d tegels leeg (max %d)" % [xs[j][0], empty, limit])
	# 1b. Instortende platforms: tussenruimtes ≤ 3.
	for i: int in grounds.size() - 1:
		var g_end: int = grounds[i][1]
		var g_next: int = grounds[i + 1][0]
		var edges: Array = []
		for f: Array in L["falling"]:
			var cx: float = f[0] / 32.0
			if cx > g_end and cx < g_next:
				edges.append([cx - 3.0, cx + 3.0])
		if edges.is_empty():
			continue
		edges.sort_custom(func(a, b): return a[0] < b[0])
		var prev_end: float = g_end
		for e: Array in edges:
			if e[0] - prev_end > 3.0:
				errs.append("instortend platform bij x=%.0f: sprong van %.0f tegels" % [e[0], e[0] - prev_end])
			prev_end = e[1]
		if g_next - prev_end > 3.0:
			errs.append("instortend platform: laatste sprong naar x=%d te groot" % g_next)
	# 1c. Stijgingen: veer ≤ 10 rijen, lift ≤ 12, trap-ledge ≤ 3 boven het laatste platform.
	for i: int in grounds.size() - 1:
		var a: Array = grounds[i]
		var b: Array = grounds[i + 1]
		if not _is_rise(a[1], b[0]):
			continue
		var dh: int = int(a[2]) - int(b[2])
		var by_spring := false
		for sp: Array in L["springs"]:
			if sp[0] >= a[1] - 6 and sp[0] < b[0]:
				by_spring = true
		var by_lift := false
		for m: Array in L["moving"]:
			if m[3] < 0.0 and m[0] / 32.0 > a[1] and m[0] / 32.0 < b[0]:
				by_lift = true
		if by_spring and dh > 10:
			errs.append("veer-stijging bij x=%d: %d rijen (max 10)" % [b[0], dh])
		elif by_lift and dh > 12:
			errs.append("lift-stijging bij x=%d: %d rijen (max 12)" % [b[0], dh])
		elif not by_spring and not by_lift:
			var best: int = int(a[2])
			for p: Array in L["plats"]:
				if p[0] + p[2] >= a[1] - 1 and p[0] <= b[0] and p[1] < best:
					best = p[1]
			if best - int(b[2]) > MAX_UP:
				errs.append("trap-stijging bij x=%d: ledge %d rijen boven het hoogste platform" % [b[0], best - int(b[2])])

	# 2. Platform-bereikbaarheid (BFS).
	var supports: Array = []
	for g: Array in grounds:
		supports.append({"x": g[0], "end": g[1], "row": g[2], "ok": true})
	for pi: Array in L["pillars"]:
		supports.append({"x": pi[0], "end": pi[0] + 1, "row": pi[1], "ok": true})
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

	# 3. Objecten op vaste grond (en op de juiste rij).
	var named: Dictionary = {
		"checkpoint": L["checkpoints"], "slime": L["slimes"], "zombie": L["zombies"],
		"spring": L["springs"],
	}
	for what: String in named:
		for it: Array in named[what]:
			if _ground_row(it[0], grounds) != it[1]:
				errs.append("%s op x=%d staat niet op de grond (rij %d)" % [what, it[0], it[1]])
	for b: Array in L["blocks"]:
		if _ground_row(b[0], grounds) < 0:
			errs.append("block op x=%d staat niet boven grond" % b[0])
	if _ground_row(L["cabin"][0], grounds) != L["cabin"][1]:
		errs.append("cabin op x=%d staat niet op de grond" % L["cabin"][0])
	if L["boss"] != null and _ground_row(L["boss"][0], grounds) != L["boss"][1]:
		errs.append("boss op x=%d staat niet op de grond" % L["boss"][0])
	for sp: Array in L["spikes"]:
		if _ground_row(sp[0], grounds) != sp[3] or _ground_row(sp[0] + sp[1] - 1, grounds) != sp[3]:
			errs.append("stekels op x=%d..%d hangen boven een gat" % [sp[0], sp[0] + sp[1] - 1])
	for lad: Array in L["ladders"]:
		if _ground_row(lad[0], grounds) != lad[2]:
			errs.append("ladder op x=%d staat niet op de grond" % lad[0])

	# 4. Power-blokken springend te pakken.
	for p: Array in L["power"]:
		var ok := false
		for s: Dictionary in supports:
			if s["x"] - 1 <= p[1] and p[1] < s["end"] + 1 and s["row"] > p[2] and s["row"] - p[2] <= 5:
				ok = true
		if not ok:
			errs.append("power-up op x=%d rij %d is niet te pakken" % [p[1], p[2]])

	# 5. Vijanden en checkpoints.
	if L["slimes"].size() + L["zombies"].size() + L["bats"].size() + L["piranhas"].size() == 0:
		errs.append("level heeft geen (telbare) vijanden")
	if L["checkpoints"].size() < 1:
		errs.append("level heeft geen checkpoint")

	# 6. Munten niet in stekels.
	for row: Array in L["coin_rows"]:
		var cx0: int = row[0]
		var cx1: int = cx0 + maxi(0, row[2] - 1) * 2
		for sp: Array in L["spikes"]:
			if row[1] >= sp[3] - 2 and row[1] < sp[3] and cx0 <= sp[0] + sp[1] - 1 and sp[0] <= cx1:
				errs.append("munt(en) x=%d..%d rij %d overlapt stekels" % [cx0, cx1, row[1]])

	# 7. Plafond-vrijheid.
	if L["ceiling"]:
		for s: Dictionary in supports:
			if s["row"] < CEIL_BOTTOM + 3:
				errs.append("steunpunt x=%d rij %d zit te dicht onder het plafond" % [s["x"], s["row"]])
		for c: Array in L["bats"]:
			if c[1] < CEIL_BOTTOM + 2:
				errs.append("vleermuis x=%d rij %d hangt in het plafond" % [c[0], c[1]])
	return errs

func _bridged(g_end: int, g_next: int) -> bool:
	for p: Array in L["ponds"]:
		if p[0] == g_end:
			return true
	for m: Array in L["moving"]:
		var mx: float = m[0] / 32.0
		if mx > g_end - 1 and mx < g_next:
			return true
	for f: Array in L["falling"]:
		var fx: float = f[0] / 32.0
		if fx > g_end and fx < g_next:
			return true
	return false

func _is_rise(g_end: int, g_next: int) -> bool:
	for r: Array in L["rises"]:
		if g_next == r[1] and g_end <= r[1] and g_end >= r[0]:
			return true
	return false

func _ground_row(x: int, grounds: Array) -> int:
	for g: Array in grounds:
		if x >= g[0] and x < g[1]:
			return g[2]
	return -1

# ------------------------------------------------------------ scene-write ---

func _build(spec: Dictionary) -> void:
	_reset(spec)
	for sec: Array in spec["secties"]:
		match sec[0]:
			"fl": _fl(sec[1], sec[2] if sec.size() > 2 else {})
			"st": _st(sec[1], sec[2] if sec.size() > 2 else {})
			"gp": _gp(sec[1], sec[2] if sec.size() > 2 else 0)
			"hr": _hr(sec[1], sec[2], sec[3] if sec.size() > 3 else {})
			"sr": _sr(sec[1], sec[2] if sec.size() > 2 else "small_metal")
			"ba": _ba(sec[1], sec[2])
			"fp": _fp(sec[1], sec[2] if sec.size() > 2 else 1)
			"mp": _mp(sec[1])
			"sp": _sp(sec[1], sec[2] if sec.size() > 2 else {})
			"pd": _pd(sec[1], sec[2] if sec.size() > 2 else {})
			"lk": _lk(sec[1], sec[2] if sec.size() > 2 else {})
			"tw": _tw(sec[1] if sec.size() > 1 else {})
			"cv": _cv(sec[1], sec[2] if sec.size() > 2 else {})
			"up": _up(sec[1], sec[2] if sec.size() > 2 else "step")
			"dn": _dn(sec[1])
			"sw": _sw(sec[1], sec[2] if sec.size() > 2 else 8)
			_: push_error("onbekende sectie %s" % sec[0])
	_finish(spec.get("staart", 20), spec.get("boss", false))

	var errs := _validate()
	if not errs.is_empty():
		_fail = true
		for e: String in errs:
			printerr("W3L%d: %s" % [L["n"], e])
		return
	_write_level()

func _rects() -> Array:
	var cells: Dictionary = {}
	for g: Array in L["ground"]:
		for x in range(g[0], g[1]):
			for y in range(g[2], BOTTOM):
				cells[Vector2i(x, y)] = true
	if L["ceiling"]:
		for x in range(0, L["w"]):
			for y in range(CEIL_TOP, CEIL_BOTTOM):
				cells[Vector2i(x, y)] = true
	for r in L["extra_rects"]:
		if r[0] is String:
			for x in range(r[1], r[1] + r[3]):
				for y in range(r[2], r[2] + r[4]):
					cells.erase(Vector2i(x, y))
		else:
			for x in range(r[0], r[0] + r[2]):
				for y in range(r[1], r[1] + r[3]):
					cells[Vector2i(x, y)] = true
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
	for pi: Array in L["pillars"]:
		out.append([pi[0], pi[1], 1, BOTTOM - pi[1]])
	return out

func _esc(s: String) -> String:
	return s.replace("\\", "\\\\").replace('"', '\\"')

func _write_level() -> void:
	var n: int = L["n"]
	var width_px: int = L["w"] * 32
	var total_enemies: int = L["slimes"].size() + L["zombies"].size() + L["bats"].size() + L["piranhas"].size()
	var kills: int = maxi(1, int(ceil(total_enemies * _kill_pct(n))))
	var level_height: int = maxi(720, int(L["deep"]) * 32 + 80)

	var ext := ""
	ext += '[ext_resource type="Script"      path="res://scripts/levels/LevelBase.gd"             id="1"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/player/Player.tscn"               id="2"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/ui/HUD.tscn"                      id="3"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Slime.tscn"        id="4"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Zombie.tscn"       id="5"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Bat.tscn"          id="6"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Coin.tscn"                id="7"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/SpecialBlock.tscn"        id="8"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Cabin.tscn"               id="9"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockPurple.tscn"    id="10"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockBlue.tscn"      id="11"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/ParallaxBGCave.tscn"      id="12"]\n'
	ext += '[ext_resource type="TileSet"     path="%s"       id="13"]\n' % TILESETS[L["tileset"]]
	ext += '[ext_resource type="Script"      path="res://scripts/levels/Terrain.gd"               id="14"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spikes.tscn"              id="15"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Ladder.tscn"              id="16"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Checkpoint.tscn"          id="17"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockOrange.tscn"    id="18"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/world3/StoneGolem.tscn"   id="19"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/FallingPlatform.tscn"     id="20"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/MovingPlatform.tscn"      id="21"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spring.tscn"              id="22"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Water.tscn"               id="23"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/SwarmBat.tscn"     id="24"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/common/Piranha.tscn"      id="25"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/HintTrigger.tscn"         id="26"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Darkness.tscn"            id="27"]\n'
	var tex_ids: Dictionary = {}
	var next_id := 30
	for d: Array in L["decor"]:
		var path: String = DECOR[d[1]][0]
		if not tex_ids.has(path):
			tex_ids[path] = next_id
			ext += '[ext_resource type="Texture2D"   path="%s" id="%d"]\n' % [path, next_id]
			next_id += 1
	var load_steps := 28 + tex_ids.size() + 1

	var s := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	s += ext + "\n"
	s += '[sub_resource type="RectangleShape2D" id="1"]\n'
	s += "size = Vector2(32.0, 300.0)\n\n"

	s += '[node name="W3L%d" type="Node2D"]\n' % n
	s += 'script = ExtResource("1")\n'
	s += "level_width = %d\n" % width_px
	s += "level_height = %d\n" % level_height
	s += "coins_needed_pct = %d\n" % L["pct"]
	s += "enemies_needed = %d\n" % kills
	s += "require_both = %s\n" % ("true" if L["both"] else "false")
	s += "world_number = 3\n"
	s += "level_number = %d\n" % n
	if not String(L["hint"]).is_empty():
		s += 'intro_hint = "%s"\n' % _esc(L["hint"])
	s += "\n"

	s += '[node name="ParallaxBGCave" parent="." instance=ExtResource("12")]\n\n'
	s += '[node name="HUD" parent="." instance=ExtResource("3")]\n\n'
	s += '[node name="Player" parent="." instance=ExtResource("2")]\n'
	s += "position = Vector2(120.0, %d.0)\n\n" % (int(L["start_row"]) * 32)

	# --- Decor ---
	s += '[node name="Decor" type="Node2D" parent="."]\n\n'
	var idx := 1
	for d: Array in L["decor"]:
		var spec: Array = DECOR[d[1]]
		var tid: int = tex_ids[spec[0]]
		var sc: int = spec[2]
		var region = spec[1]
		var h: int = int(region[3]) if region != null else _tex_height(spec[0])
		var anchor: String = spec[4]
		s += '[node name="Prop%d" type="Sprite2D" parent="Decor"]\n' % idx
		s += "z_index = %d\n" % spec[3]
		s += "centered = false\n"
		s += 'texture = ExtResource("%d")\n' % tid
		if region != null:
			s += "region_enabled = true\n"
			s += "region_rect = Rect2(%d, %d, %d, %d)\n" % [region[0], region[1], region[2], region[3]]
		if anchor == "ground":
			s += "scale = Vector2(%d.0, %d.0)\n" % [sc, sc]
			s += "position = Vector2(%d.0, %d.0)\n\n" % [int(d[0]) * 32, int(d[2]) * 32 - h * sc + 4]
		elif anchor == "ceiling_flip":
			# Stalagmieten-cluster ondersteboven aan het plafond.
			s += "scale = Vector2(%d.0, -%d.0)\n" % [sc, sc]
			s += "position = Vector2(%d.0, %d.0)\n\n" % [int(d[0]) * 32, CEIL_PX + h * sc - 4]
		else:
			s += "scale = Vector2(%d.0, %d.0)\n" % [sc, sc]
			s += "position = Vector2(%d.0, %d.0)\n\n" % [int(d[0]) * 32, CEIL_PX - 4]
		idx += 1

	# --- Terrain ---
	var rects: Array[String] = []
	for r: Array in _rects():
		rects.append("Rect2i(%d, %d, %d, %d)" % [r[0], r[1], r[2], r[3]])
	var ng: Array[String] = []
	if L["ceiling"]:
		ng.append("Rect2i(0, %d, %d, %d)" % [CEIL_TOP, L["w"], CEIL_BOTTOM - CEIL_TOP])
	for r: Array in L["no_grass"]:
		ng.append("Rect2i(%d, %d, %d, %d)" % [r[0], r[1], r[2], r[3]])
	s += '[node name="Terrain" type="TileMapLayer" parent="."]\n'
	s += "scale = Vector2(2.0, 2.0)\n"
	s += 'tile_set = ExtResource("13")\n'
	s += 'script = ExtResource("14")\n'
	s += "solid_rects = Array[Rect2i]([%s])\n" % ", ".join(rects)
	if not ng.is_empty():
		s += "no_grass_rects = Array[Rect2i]([%s])\n" % ", ".join(ng)
	s += "\n"

	# --- Water ---
	idx = 1
	for p: Array in L["ponds"]:
		var w_px: int = int(p[1]) * 32
		var top_px: int = int(p[2]) * 32 + WATER_DROP
		var h_px: int = int(p[3]) * 32 - top_px
		s += '[node name="Water%d" parent="." instance=ExtResource("23")]\n' % idx
		s += "position = Vector2(%.1f, %.1f)\n" % [int(p[0]) * 32 + w_px / 2.0, top_px + h_px / 2.0]
		s += "size = Vector2(%d.0, %d.0)\n\n" % [w_px, h_px]
		idx += 1

	# --- Vijanden ---
	s += '[node name="Enemies" type="Node2D" parent="."]\n\n'
	idx = 1
	for c: Array in L["slimes"]:
		s += '[node name="Slime%d" parent="Enemies" instance=ExtResource("4")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [c[0] * 32, c[1] * 32]
		idx += 1
	idx = 1
	for c: Array in L["zombies"]:
		s += '[node name="Zombie%d" parent="Enemies" instance=ExtResource("5")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [c[0] * 32, c[1] * 32]
		idx += 1
	idx = 1
	for c: Array in L["bats"]:
		s += '[node name="Bat%d" parent="Enemies" instance=ExtResource("6")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [c[0] * 32, c[1] * 32]
		idx += 1
	idx = 1
	for pr: Array in L["piranhas"]:
		s += '[node name="Piranha%d" parent="Enemies" instance=ExtResource("25")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(pr[0]) * 32 + 16, int(pr[1]) * 32 + 16]
		s += "patrol_range = %.1f\n" % pr[3]
		s += "water_top_y = %d.0\n\n" % (int(pr[2]) * 32 + WATER_DROP)
		idx += 1
	idx = 1
	for sw: Array in L["swarm"]:
		var n_b: int = sw[4]
		for i: int in n_b:
			var fy: int = int(sw[3]) * 32 - (40 if i % 2 == 0 else 72)
			s += '[node name="SwarmBat%d" parent="Enemies" instance=ExtResource("24")]\n' % idx
			s += "position = Vector2(%d.0, %d.0)\n" % [int(sw[1]) * 32 + i * 24, fy]
			s += "trigger_x = %d.0\n" % (int(sw[0]) * 32)
			s += "end_x = %d.0\n" % (int(sw[2]) * 32)
			s += "delay = %.2f\n\n" % (i * 0.22)
			idx += 1
	if L["boss"] != null:
		s += '[node name="StoneGolem" parent="Enemies" instance=ExtResource("19")]\n'
		s += "position = Vector2(%d.0, %d.0)\n" % [int(L["boss"][0]) * 32, int(L["boss"][1]) * 32]
		s += "arena_left = %d.0\n" % L["boss"][2]
		s += "arena_right = %d.0\n\n" % L["boss"][3]

	# --- Objecten ---
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
	for sp: Array in L["spikes"]:
		s += '[node name="Spikes%d" parent="Objects" instance=ExtResource("15")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(sp[0]) * 32 + int(sp[1]) * 16, int(sp[3]) * 32]
		s += "width = %d\n" % (int(sp[1]) * 32)
		s += 'variant = "%s"\n\n' % sp[2]
		idx += 1
	idx = 1
	for lad: Array in L["ladders"]:
		var top_px: int = int(lad[1]) * 32
		s += '[node name="Ladder%d" parent="Objects" instance=ExtResource("16")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(lad[0]) * 32 + 16, top_px]
		s += "height = %d\n\n" % (int(lad[2]) * 32 - top_px)
		idx += 1
	idx = 1
	for f: Array in L["falling"]:
		s += '[node name="FallingPlatform%d" parent="Objects" instance=ExtResource("20")]\n' % idx
		s += "position = Vector2(%.1f, %.1f)\n\n" % [f[0], f[1]]
		idx += 1
	idx = 1
	for m: Array in L["moving"]:
		s += '[node name="MovingPlatform%d" parent="Objects" instance=ExtResource("21")]\n' % idx
		s += "position = Vector2(%.1f, %.1f)\n" % [m[0], m[1]]
		s += "offset = Vector2(%.1f, %.1f)\n" % [m[2], m[3]]
		s += "period = %.1f\n\n" % m[4]
		idx += 1
	idx = 1
	for sp: Array in L["springs"]:
		s += '[node name="Spring%d" parent="Objects" instance=ExtResource("22")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(sp[0]) * 32 + 16, int(sp[1]) * 32]
		idx += 1
	idx = 1
	for h: Array in L["hints"]:
		s += '[node name="Hint%d" parent="Objects" instance=ExtResource("26")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(h[0]) * 32, BASE_ROW * 32 - 200]
		s += 'text = "%s"\n\n' % _esc(h[1])
		idx += 1

	idx = 1
	for cp: Array in L["checkpoints"]:
		s += '[node name="Checkpoint%d" parent="." instance=ExtResource("17")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(cp[0]) * 32, int(cp[1]) * 32]
		idx += 1

	var cab_y: int = int(L["cabin"][1]) * 32
	s += '[node name="Cabin" parent="." instance=ExtResource("9")]\n'
	s += "position = Vector2(%d.0, %d.0)\n\n" % [int(L["cabin"][0]) * 32, cab_y]

	var wall_x: int = (int(L["cabin"][0]) + 2) * 32
	s += '[node name="CabinWall" type="StaticBody2D" parent="."]\n'
	s += "position = Vector2(%d.0, %d.0)\n" % [wall_x, cab_y - 150]
	s += "collision_layer = 1\n"
	s += "collision_mask = 0\n\n"
	s += '[node name="CollisionShape2D" type="CollisionShape2D" parent="CabinWall"]\n'
	s += 'shape = SubResource("1")\n\n'

	if L["dark"]:
		# Als laatste kind: bij _ready staan speler, checkpoints en cabin er al.
		s += '[node name="Darkness" parent="." instance=ExtResource("27")]\n'

	var f := FileAccess.open(OUT_DIR + "W3L%d.tscn" % n, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("geschreven: W3L%d.tscn (%d tegels, %d px, %d/%d vijanden vereist, tiles=%s, hoogte=%d)" % [n, L["w"], width_px, kills, total_enemies, L["tileset"], level_height])

func _tex_height(path: String) -> int:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return img.get_height() if img != null else 32

# ----------------------------------------------------------- ontwerpdata ---

func _levels() -> Array:
	return [
		{
			# L1 — De ingang: rustig, horizontaal. Slijm en de eerste zombie,
			# één instortende brug, paddenstoelen en stalactieten.
			"n": 1, "pct": 40, "both": false, "staart": 18,
			"tileset": "grotto", "decor": ["mush_teal", "plant", "rock_small", "stal_small"],
			"ceil_decor": ["stal_tall", "chain"],
			"hint": "Welkom in de grot. Slijm heeft stekels: niet op springen, boksen!",
			"secties": [
				["fl", 24, {"coins": 4}],
				["fl", 34, {"coins": 6, "slimes": 1, "block": true}],
				["gp", 3],
				["fl", 30, {"slimes": 1, "coins": 5, "power": "purple"}],
				["st", [3]],
				["fl", 28, {"checkpoint": true, "zombies": 1, "coins": 4}],
				["fp", 8, 1],
				["fl", 30, {"slimes": 1, "block": true}],
				["gp", 4],
				["fl", 28, {"zombies": 1, "coins": 4, "checkpoint": true}],
				["fl", 26, {"slimes": 1, "bats": 1, "coins": 4}],
				["fl", 24, {"coins": 4}],
			],
		},
		{
			# L2 — Kristalgrot: DIAGONAAL omhoog met springveren en trappen;
			# geen plafond (je klimt tot ver boven de startvloer).
			"n": 2, "pct": 50, "both": false, "staart": 20,
			"tileset": "crystal", "ceiling": false,
			"decor": ["gem_red", "gem_green", "gem_blue", "gem_orange", "plant"],
			"hint": "Kristalgrot: het gaat hier omhoog. Springveren brengen je naar de volgende richel.",
			"secties": [
				["fl", 28, {"coins": 4, "slimes": 1}],
				["up", 3, "step"],
				["fl", 22, {"coins": 4, "block": true}],
				["up", 6, "stairs"],
				["fl", 24, {"slimes": 1, "coins": 4, "checkpoint": true}],
				["up", 8, "spring"],
				["fl", 26, {"zombies": 1, "power": "purple"}],
				["gp", 4],
				["fl", 22, {"coins": 4}],
				["up", 2, "step"],
				["fl", 22, {"slimes": 1, "checkpoint": true, "block": true}],
				["up", 9, "spring"],
				["fl", 26, {"bats": 1, "coins": 5}],
				["sp", 20, {"power": "blue"}],
				["fl", 24, {"zombies": 1, "coins": 4}],
			],
		},
		{
			# L3 — Ondergronds meer: veel water in de grot, piranha's, een
			# rotsboog waar je onderdoor moet duiken.
			"n": 3, "pct": 50, "both": false, "staart": 20,
			"tileset": "rock", "decor": ["plant_big", "mush_teal", "rock_small"],
			"ceil_decor": ["stal_tall", "stal_cluster"],
			"hint": "Hier staat de grot onder water. Springknop = slag omhoog, omlaag = duiken.",
			"secties": [
				["fl", 26, {"coins": 4, "slimes": 1}],
				["pd", 9, {"coins": 3}],
				["fl", 24, {"coins": 4, "block": true}],
				["lk", 20, {"coins": 4, "piranhas": 1}],
				["fl", 26, {"checkpoint": true, "zombies": 1, "coins": 4}],
				["gp", 4],
				["fl", 22, {"slimes": 1, "power": "orange"}],
				["lk", 26, {"coins": 5, "piranhas": 2, "arch": true}],
				["fl", 26, {"checkpoint": true, "coins": 4, "block": true}],
				["st", [3, 6], {"bat": true}],
				["fl", 22, {"slimes": 1}],
				["lk", 22, {"coins": 4, "piranhas": 2}],
				["fl", 24, {"zombies": 1, "coins": 4}],
			],
		},
		{
			# L4 — Ruïnes: metselwerk, tempelpoort en pilaren; ladders, hoge
			# routes, metalen stekels, meer zombies.
			"n": 4, "pct": 60, "both": true, "staart": 22,
			"tileset": "brick", "decor": ["pillar", "gate", "sign", "plant"],
			"ceil_decor": ["chain"],
			"secties": [
				["fl", 30, {"coins": 4, "zombies": 1, "block": true}],
				["st", [3, 6]],
				["fl", 24, {"slimes": 1, "coins": 4}],
				["hr", 34, 8, {"power": "purple"}],
				["fl", 26, {"checkpoint": true, "zombies": 1, "coins": 4}],
				["sr", 3, "small_metal"],
				["fl", 26, {"slimes": 1, "block": true}],
				["gp", 9, 1],
				["fl", 24, {"zombies": 1, "coins": 5}],
				["hr", 38, 8, {"power": "blue", "spikes": true, "variant": "long_metal"}],
				["fl", 26, {"checkpoint": true, "slimes": 1}],
				["sr", 4, "long_metal"],
				["fl", 24, {"zombies": 1, "coins": 4}],
				["st", [3, 6], {"power": "orange", "bat": true}],
				["fl", 24, {"coins": 4, "bats": 1}],
			],
		},
		{
			# L5 — Vleermuisgrot: ZWERMEN die door de gang razen (dekking in
			# de kuil), plus duikende vleermuizen.
			"n": 5, "pct": 60, "both": true, "staart": 22,
			"tileset": "grotto", "decor": ["stalagmites", "rock_small", "mush_purple"],
			"ceil_decor": ["stal_tall", "stal_cluster", "chain"],
			"hint": "Hoor je dat gefladder? Als een zwerm komt: zoek dekking in een kuil!",
			"secties": [
				["fl", 28, {"coins": 4, "slimes": 1, "block": true}],
				["ba", 26, 2],
				["fl", 24, {"zombies": 1, "coins": 4, "checkpoint": true}],
				["sw", 26, 9],
				["fl", 26, {"slimes": 1, "power": "purple"}],
				["gp", 4],
				["fl", 24, {"zombies": 1, "coins": 4}],
				["ba", 30, 3],
				["fl", 26, {"checkpoint": true, "coins": 4, "block": true}],
				["sw", 26, 12],
				["fl", 26, {"slimes": 1, "coins": 5}],
				["st", [3, 6], {"power": "blue", "bat": true}],
				["fl", 24, {"zombies": 1, "coins": 4}],
			],
		},
		{
			# L6 — De donkere grot: alleen je eigen lichtschijnsel; checkpoints
			# en het huisje gloeien als bakens. Overzichtelijke opbouw.
			"n": 6, "pct": 60, "both": true, "staart": 22, "dark": true,
			"tileset": "rock", "decor": ["mush_purple", "mush_teal", "rock_small"],
			"ceil_decor": ["stal_tall"],
			"hint": "Het is hier stikdonker… loop voorzichtig en volg de lichtjes.",
			"secties": [
				["fl", 28, {"coins": 4, "slimes": 1}],
				["gp", 3],
				["fl", 26, {"zombies": 1, "coins": 4, "block": true}],
				["st", [3]],
				["fl", 26, {"checkpoint": true, "slimes": 1, "coins": 4}],
				["sr", 3, "small_metal"],
				["fl", 24, {"zombies": 1, "power": "purple"}],
				["gp", 9, 1],
				["fl", 26, {"slimes": 1, "coins": 4, "checkpoint": true}],
				["fp", 14, 2],
				["fl", 26, {"zombies": 1, "coins": 4, "block": true}],
				["ba", 26, 2],
				["fl", 24, {"slimes": 1, "coins": 4, "power": "orange"}],
			],
		},
		{
			# L7 — De machinekamer: overal beweging — pendelende platforms,
			# liften omhoog en omlaag, instortende bruggen.
			"n": 7, "pct": 70, "both": true, "staart": 22,
			"tileset": "brick", "decor": ["pillar", "chain", "sign"],
			"ceil_decor": ["chain"],
			"hint": "Alles beweegt hier. Wacht op het juiste moment en spring!",
			"secties": [
				["fl", 26, {"coins": 4, "zombies": 1, "block": true}],
				["mp", 12],
				["fl", 22, {"slimes": 1, "coins": 4}],
				["up", 6, "lift"],
				["fl", 24, {"checkpoint": true, "coins": 4, "power": "purple"}],
				["mp", 16],
				["fl", 22, {"zombies": 1}],
				["fp", 14, 2],
				["fl", 22, {"slimes": 1, "coins": 4, "checkpoint": true}],
				["dn", 6],
				["fl", 22, {"coins": 4, "block": true}],
				["mp", 14],
				["fl", 22, {"zombies": 1, "bats": 1}],
				["up", 8, "lift"],
				["fl", 24, {"coins": 5, "power": "blue"}],
				["fp", 20, 3],
				["fl", 24, {"slimes": 1, "coins": 4}],
			],
		},
		{
			# L8 — De afdaling: je begint hoog en daalt af via kliffen en
			# instortende platforms; onderin verborgen tunnels met schatten.
			"n": 8, "pct": 70, "both": true, "staart": 22, "start_row": 6,
			"tileset": "crystal", "ceiling": false,
			"decor": ["gem_blue", "gem_orange", "plant", "stalagmites"],
			"hint": "Diep de grot in… en niet alles wat glimt ligt bovenop.",
			"secties": [
				["fl", 22, {"coins": 4, "slimes": 1}],
				["dn", 4],
				["fl", 22, {"coins": 4, "block": true}],
				["fp", 8, 1],
				["fl", 20, {"zombies": 1, "checkpoint": true}],
				["dn", 5],
				["fl", 24, {"slimes": 1, "coins": 4, "power": "purple"}],
				["gp", 4],
				["fl", 20, {"coins": 4}],
				["dn", 5],
				["fl", 24, {"zombies": 1, "checkpoint": true, "block": true}],
				["cv", 30, {"block": true}],
				["fl", 22, {"slimes": 1, "coins": 4}],
				["sr", 3, "long_metal"],
				["fl", 22, {"zombies": 1, "bats": 1}],
				["cv", 32, {"variant": "long_metal"}],
				["fl", 24, {"coins": 4, "power": "orange"}],
			],
		},
		{
			# L9 — Klimtorens en liften: op en neer door een hoge grot.
			"n": 9, "pct": 80, "both": true, "staart": 22,
			"tileset": "grotto", "ceiling": false,
			"decor": ["pillar", "plant_big", "palm", "rock_small"],
			"secties": [
				["fl", 26, {"coins": 4, "slimes": 1, "block": true}],
				["tw", {"power": "purple"}],
				["fl", 22, {"zombies": 1, "coins": 4}],
				["up", 9, "stairs"],
				["fl", 24, {"checkpoint": true, "slimes": 1}],
				["hr", 32, 8, {"spikes": true, "variant": "small_metal"}],
				["fl", 22, {"coins": 4, "block": true}],
				["dn", 7],
				["fl", 22, {"zombies": 1, "coins": 4}],
				["up", 10, "lift"],
				["fl", 24, {"checkpoint": true, "coins": 4, "power": "blue"}],
				["tw", {"power": "orange", "bat": true}],
				["fl", 22, {"slimes": 1}],
				["gp", 9, 1],
				["fl", 24, {"zombies": 1, "coins": 5, "bats": 1}],
			],
		},
		{
			# L10 — De grote grot: bonus-level met álles — meer, zwerm, liften,
			# stekels, tunnel, torens.
			"n": 10, "pct": 80, "both": true, "staart": 22,
			"tileset": "rock", "decor": ["stalagmites", "mush_teal", "gem_green", "pillar"],
			"ceil_decor": ["stal_tall", "stal_cluster", "chain"],
			"hint": "De grote grot. Alles wat je geleerd hebt, komt hier terug.",
			"secties": [
				["fl", 26, {"coins": 4, "slimes": 1, "block": true}],
				["st", [3, 6, 9], {"power": "purple"}],
				["fl", 22, {"zombies": 1, "coins": 4}],
				["lk", 20, {"coins": 4, "piranhas": 2, "arch": true}],
				["fl", 22, {"slimes": 1, "checkpoint": true}],
				["sr", 4, "long_metal"],
				["fl", 22, {"zombies": 1, "bats": 1}],
				["mp", 16],
				["fl", 24, {"coins": 4, "block": true}],
				["sw", 26, 12],
				["fl", 24, {"slimes": 1, "checkpoint": true, "coins": 4}],
				["up", 6, "lift"],
				["fl", 22, {"zombies": 1, "power": "blue"}],
				["fp", 20, 3],
				["fl", 22, {"coins": 5}],
				["dn", 6],
				["fl", 22, {"slimes": 1, "checkpoint": true}],
				["cv", 30, {"block": true}],
				["fl", 22, {"zombies": 1, "coins": 4}],
				["tw", {"power": "orange", "bat": true}],
				["fl", 24, {"slimes": 1, "coins": 4, "bats": 1}],
			],
		},
		{
			# L11 — De Stenen Golem: korte aanloop door de ruïnes, dan de arena.
			"n": 11, "pct": 0, "both": false, "staart": 70, "boss": true,
			"tileset": "brick", "decor": ["pillar", "gate", "gem_red", "rock_small"],
			"ceil_decor": ["chain", "stal_tall"],
			"secties": [
				["fl", 30, {"coins": 5, "zombies": 1, "block": true}],
				["sp", 20, {"power": "purple"}],
				["fl", 22, {"slimes": 1, "coins": 4}],
				["gp", 4],
				["fl", 24, {"checkpoint": true, "coins": 4}],
				["mp", 12],
				["fl", 20, {"bats": 1}],
				["sr", 3, "small_metal"],
				["fl", 24, {"checkpoint": true, "zombies": 1}],
				["st", [3], {"power": "orange"}],
				["fl", 18, {"slimes": 1}],
			],
		},
	]
