extends SceneTree

## Genereert scenes/levels/world1/W1L1..L10.tscn uit ontwerpdata.
## Coördinaten in tegels van 32px. Grond-bovenkant = rij 20 (y=640).
##
## Elk level heeft een eigen LOOK (tileset-variant + decor-set) en een eigen
## "ding": vallende platforms, ladders, vijver, bewegend platform, springveer,
## klimtoren, verborgen tunnel… Niet alles in elk level — juist afwisseling.
##
## Levelspec: n, pct (munten-eis %), both, tileset ("default"/"sunny"/"hedge"/
## "teal"), decor (lijst met namen uit DECOR), secret (geheime hoek links van
## de start), hint (HUD-tekst bij de start), staart, boss, secties.
## De vijanden-eis is een percentage van álle vijanden in het level:
## 40% in L1 oplopend tot 80% in L10 (zie _kill_pct).
##
## Secties (zie _levels() onderaan):
##   ["fl", lengte, opties]  — vlakke grond; opties: rats, snakes, coins, block,
##                             power ("purple"/"blue"/"orange"), checkpoint, bats
##   ["st", [rijen], opties] — platform-trap boven de grond (rij 17 → 14 → 11);
##                             opties: power, bat, coins (standaard aan)
##   ["gp", breedte, pilaren]— gat in de grond; pilaren = stapstenen (top rij 18)
##   ["hr", lengte, rij, opties] — hoge route: ladder + lang platform; optie spikes
##   ["sr", periodes, variant]   — stekelloop: om-en-om 4 veilig / 3 stekels
##   ["ba", lengte, n]       — vleermuizensteeg: n duikende vleermuizen
##   ["fp", breedte, n]      — gat met n instortende platforms (elk 6 tegels breed)
##   ["mp", breedte]         — breed gat met een heen-en-weer bewegend platform
##   ["sp", lengte, opties]  — springveer naar een hoog platform (rij 12) met
##                             munten; optie power
##   ["pd", breedte, opties] — vijver: gat vol water om doorheen te zwemmen,
##                             munt op de bodem; optie coins
##   ["tw", opties]          — klimtoren: ladder + zigzag-platforms omhoog tot
##                             rij 8, munten op elke trede; optie power (bovenop)
##   ["cv", lengte, opties]  — verborgen tunnel onder een stekelveld door,
##                             schat (munten, optie block) binnenin; in- en
##                             uitgang zijn schachten van 2 tegels breed
##
## Sprongregels (SPEED 180, JUMP -550, GRAVITY 980):
##   max ~4,8 tegels omhoog; ontwerp: max 3 omhoog per sprong
##   horizontaal gat: ≤5 vlak, ≤4 bij 1-2 omhoog, ≤3 bij 3 omhoog, ≤6 omlaag
## Een validatiepas dwingt deze regels af; bij een fout wordt niets weggeschreven.

const OUT_DIR := "/Users/wb-antal/claude-projecten/Flint-Game/scenes/levels/world1/"
const GROUND_Y := 20
## 7 rijen diep (was 4): zo blijft er grond in beeld als de camera in een
## vijver of tunnel iets zakt.
const GROUND_DEPTH := 7
const POND_TOP_PX := 652      # wateroppervlak 12px onder de oever
const POND_FLOOR_ROW := 24    # vijverbodem (y=768)
const TUNNEL_ROWS := [21, 22, 23]

const MAX_UP := 3
const MAX_GAP_FLAT := 5
const MAX_GAP_DOWN := 6

const LENGTH_SCALE := 0.8

## Decor: naam → [texture-pad, regio (of null = hele texture), schaal, z_index]
## z_index -1 = achter de speler, 2 = ervoor (verbergt iets).
const DECOR: Dictionary = {
	"tree_big":     ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [88, 2, 65, 94], 2, -1],
	"tree_small":   ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [171, 12, 57, 84], 2, -1],
	"bush":         ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [1, 43, 30, 21], 2, -1],
	"bush_flowers": ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [33, 43, 30, 21], 2, -1],
	"mushrooms":    ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [1, 5, 15, 11], 2, -1],
	"shrooms_brown":["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [33, 5, 14, 11], 2, -1],
	"fern":         ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [64, 1, 16, 15], 2, -1],
	"rock":         ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [18, 20, 13, 12], 2, -1],
	"sl_tree":      ["res://assets/sprites/tiles/world1_forest/decor/sl_tree.png", null, 2, -1],
	"sl_bush":      ["res://assets/sprites/tiles/world1_forest/decor/sl_bush.png", null, 2, -1],
	"sl_shrooms":   ["res://assets/sprites/tiles/world1_forest/decor/sl_shrooms.png", null, 2, -1],
	"sl_rock":      ["res://assets/sprites/tiles/world1_forest/decor/sl_rock.png", null, 2, -1],
	"sl_sign":      ["res://assets/sprites/tiles/world1_forest/decor/sl_sign.png", null, 2, -1],
	"sl_skulls":    ["res://assets/sprites/tiles/world1_forest/decor/sl_skulls.png", null, 2, -1],
	"cover_bush":   ["res://assets/sprites/tiles/world1_forest/decor/forest_decorations.png", [1, 43, 30, 21], 3, 2],
}

const TILESETS: Dictionary = {
	"default": "res://scenes/levels/world1_tileset.tres",
	"sunny":   "res://scenes/levels/world1_tileset_sunny.tres",
	"hedge":   "res://scenes/levels/world1_tileset_hedge.tres",
	"teal":    "res://scenes/levels/world1_tileset_teal.tres",
}

var L: Dictionary = {}
var _cx := 0
var _g_start := 0
var _fail := false
var _rng := RandomNumberGenerator.new()
var _decor_names: Array = []

func _init() -> void:
	for spec: Dictionary in _levels():
		_build(spec)
	if _fail:
		push_error("GEFAALD: validatiefouten, zie hierboven")
	else:
		print("KLAAR: 10 levels gegenereerd")
	quit(1 if _fail else 0)

## Vijanden-eis: 40% (L1) → 80% (L10) van alle vijanden in het level.
func _kill_pct(n: int) -> float:
	return 0.4 + 0.4 * (n - 1) / 9.0

# ---------------------------------------------------------------- secties ---

func _reset(spec: Dictionary) -> void:
	L = {
		"n": spec["n"], "pct": spec["pct"], "both": spec["both"],
		"hint": spec.get("hint", ""), "tileset": spec.get("tileset", "default"),
		"secret": spec.get("secret", false),
		"ground": [], "plats": [], "pillars": [], "ladders": [], "extra_rects": [],
		"no_grass": [], "spikes_g": [], "spikes_p": [], "coin_rows": [], "coins_free": [],
		"rats": [], "snakes": [], "bats": [],
		"blocks": [], "power": [], "checkpoints": [], "decor": [],
		"falling": [], "moving": [], "springs": [], "ponds": [], "spring_plats": [],
		"cabin": 0, "boss": -1, "cave": false,
	}
	_cx = 0
	_g_start = 0
	_rng.seed = 1000 + int(spec["n"])
	_decor_names = spec.get("decor", ["tree_big", "bush"])
	if L["secret"]:
		# Geheime hoek: speler start op tegel 11; tegels 0..8 zijn een verborgen
		# hoekje met munten achter een struik (decor vóór de speler).
		L["coin_rows"].append([1, 19, 3])
		L["coins_free"].append([2, 17])
		L["decor"].append([8, "cover_bush"])

func _fl(len_t_raw: int, o: Dictionary = {}) -> void:
	var len_t: int = maxi(6, roundi(len_t_raw * LENGTH_SCALE))
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
	# Decor: 1–2 stuks per vlak stuk uit de decor-set van dit level.
	var n_decor: int = 1 if len_t < 16 else 2
	for i: int in n_decor:
		var dx: int = x0 + 1 + _rng.randi_range(0, maxi(0, len_t - 5))
		L["decor"].append([dx, _decor_names[_rng.randi_range(0, _decor_names.size() - 1)]])
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

func _gp(w_raw: int, pillars: int = 0) -> void:
	var w: int = maxi(2, roundi(w_raw * LENGTH_SCALE))
	L["ground"].append([_g_start, _cx])
	for i: int in pillars:
		L["pillars"].append([_cx + (i + 1) * w / (pillars + 1), 18])
	_cx += w
	_g_start = _cx

func _hr(len_t_raw: int, row: int, o: Dictionary = {}) -> void:
	var len_t: int = maxi(16, roundi(len_t_raw * LENGTH_SCALE))
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

func _sr(periods_raw: int, variant: String = "small_wood") -> void:
	var periods: int = maxi(2, roundi(periods_raw * LENGTH_SCALE))
	for i: int in periods:
		var p := _cx + i * 7
		L["spikes_g"].append([p + 4, 3, variant])
		var coin_x: int
		var coin_row: int
		match i % 3:
			0: coin_x = p + 4; coin_row = 17
			1: coin_x = p + 6; coin_row = 17
			_: coin_x = p + 5; coin_row = 16
		L["coin_rows"].append([coin_x, coin_row, 1])
	_cx += periods * 7 + 2

func _ba(len_t_raw: int, n: int) -> void:
	var len_t: int = maxi(4 * (n + 1), roundi(len_t_raw * LENGTH_SCALE))
	var x0 := _cx
	for i: int in n:
		L["bats"].append([x0 + (i + 1) * len_t / (n + 1), 8])
	L["coin_rows"].append([x0 + 2, 19, mini(6, len_t / 4)])
	_cx += len_t

## Gat met n instortende platforms (6 tegels breed, op grondhoogte).
func _fp(w_raw: int, n: int) -> void:
	var w: int = maxi(6 * n + 2, roundi(w_raw * LENGTH_SCALE))
	L["ground"].append([_g_start, _cx])
	var seg := float(w) / n
	for i: int in n:
		var center := _cx + seg * (i + 0.5)
		L["falling"].append([center * 32.0, GROUND_Y * 32 - 12])
		L["coins_free"].append([int(center), 18])
	_cx += w
	_g_start = _cx

## Breed gat met een bewegend platform (3 tegels breed) dat heen en weer pendelt.
func _mp(w_raw: int) -> void:
	var w: int = maxi(8, roundi(w_raw * LENGTH_SCALE))
	L["ground"].append([_g_start, _cx])
	var from_x := (_cx + 2.0) * 32.0
	var to_x := (_cx + w - 2.0) * 32.0
	L["moving"].append([from_x, GROUND_Y * 32 - 10, to_x - from_x, w * 0.35])
	L["coins_free"].append([_cx + w / 2, 17])
	_cx += w
	_g_start = _cx

## Springveer op de grond → hoog platform (rij 12) met munten (en evt. power-up).
func _sp(len_t_raw: int, o: Dictionary = {}) -> void:
	var len_t: int = maxi(14, roundi(len_t_raw * LENGTH_SCALE))
	var x0 := _cx
	var sx := x0 + len_t / 3
	L["springs"].append(sx)
	var px := sx + 2
	L["spring_plats"].append([px, 12, 5])
	L["coin_rows"].append([px, 10, 3])
	if o.has("power"):
		L["power"].append([o["power"], px + 2, 9])
	for i: int in o.get("rats", 0):
		L["rats"].append(x0 + len_t - 4)
	L["decor"].append([x0 + len_t - 3, _decor_names[0]])
	_cx += len_t

## Vijver: gat vol water met een bodem op rij 24; munt op de bodem.
func _pd(w_raw: int, o: Dictionary = {}) -> void:
	var w: int = maxi(5, roundi(w_raw * LENGTH_SCALE))
	L["ground"].append([_g_start, _cx])
	L["ponds"].append([_cx, w])
	L["extra_rects"].append([_cx, POND_FLOOR_ROW, w, GROUND_Y + GROUND_DEPTH - POND_FLOOR_ROW])
	var n_c: int = o.get("coins", 2)
	for i: int in n_c:
		L["coins_free"].append([_cx + 1 + (i * (w - 2)) / maxi(1, n_c - 1) if n_c > 1 else _cx + w / 2, 23])
	_cx += w
	_g_start = _cx

## Klimtoren: ladder naar rij 14, dan zigzag-platforms tot rij 8.
func _tw(o: Dictionary = {}) -> void:
	var x0 := _cx
	L["ladders"].append([x0 + 2, 14])
	L["plats"].append([x0 + 1, 14, 4])
	L["plats"].append([x0 + 7, 11, 4])
	L["plats"].append([x0 + 1, 8, 4])
	L["coin_rows"].append([x0 + 1, 12, 2])
	L["coin_rows"].append([x0 + 7, 9, 2])
	L["coin_rows"].append([x0 + 1, 6, 2])
	if o.has("power"):
		L["power"].append([o["power"], x0 + 3, 5])
	if o.get("bat", false):
		L["bats"].append([x0 + 9, 7])
	_cx += 13

## Verborgen tunnel: stekelveld bovenop, tunnel (rij 21..23) eronder met schat.
func _cv(len_t_raw: int, o: Dictionary = {}) -> void:
	var len_t: int = maxi(18, roundi(len_t_raw * LENGTH_SCALE))
	var x0 := _cx
	L["cave"] = true
	# De grondrect blijft doorlopen; de tunnel wordt eruit "geknipt" via
	# cave_cuts (zie _rects). In- en uitgang: schachten van 2 breed.
	L["extra_rects"].append(["cut", x0 + 1, GROUND_Y, 2, 4])                  # ingang-schacht (rij 20..23)
	L["extra_rects"].append(["cut", x0 + 3, TUNNEL_ROWS[0], len_t - 6, 3])   # tunnel
	L["extra_rects"].append(["cut", x0 + len_t - 3, GROUND_Y, 2, 4])         # uitgang-schacht
	L["no_grass"].append([x0 + 1, POND_FLOOR_ROW, len_t - 2, 1])
	# Stekels op het oppervlak boven de tunnel (met veilige randen bij de schachten).
	L["spikes_g"].append([x0 + 5, len_t - 10, o.get("variant", "small_wood")])
	# Schat in de tunnel.
	var n_c: int = mini(6, (len_t - 8) / 2)
	L["coin_rows"].append([x0 + 4, 22, n_c])
	if o.get("block", false):
		L["blocks"].append(["tunnel", x0 + len_t / 2])
	L["coins_free"].append([x0 + 1, 22])
	L["decor"].append([x0 + len_t / 2, _decor_names[_rng.randi_range(0, _decor_names.size() - 1)]])
	_cx += len_t

func _finish(tail_raw: int, boss: bool = false) -> void:
	var tail: int = maxi(12, roundi(tail_raw * LENGTH_SCALE))
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
	#    Vijvers, instortende en bewegende platforms overbruggen hun gat zelf.
	for i: int in grounds.size() - 1:
		var g_end: int = grounds[i][1]
		var g_next: int = grounds[i + 1][0]
		if _bridged(g_end, g_next):
			continue
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
	# 1b. Instortende platforms: tussenruimtes ≤ 3 tegels.
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

	# 2. Platform-bereikbaarheid (BFS vanaf grond, pilaren en ladders).
	var supports: Array = []
	for g: Array in grounds:
		supports.append({"x": g[0], "end": g[1], "row": GROUND_Y, "ok": true})
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

	# 3. Objecten die op vaste grond moeten staan.
	var named: Dictionary = {
		"checkpoint": L["checkpoints"], "rat": L["rats"], "snake": L["snakes"],
		"spring": L["springs"],
	}
	for what: String in named:
		for x: int in named[what]:
			if not _on_ground(x, grounds):
				errs.append("%s op x=%d staat niet boven grond" % [what, x])
	for b in L["blocks"]:
		var bx: int = b[1] if b is Array else b
		if not _on_ground(bx, grounds):
			errs.append("block op x=%d staat niet boven grond" % bx)
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

	# 5. Vijanden-eis haalbaar.
	var total: int = L["rats"].size() + L["snakes"].size() + L["bats"].size()
	if total == 0:
		errs.append("level heeft geen vijanden")
	if L["checkpoints"].size() < 1:
		errs.append("level heeft geen checkpoint")

	# 6. Munten mogen nooit op dezelfde hoogte overlappen met stekels.
	for row: Array in L["coin_rows"]:
		var cx0: int = row[0]
		var crow: int = row[1]
		var cx1: int = cx0 + maxi(0, row[2] - 1) * 2
		if crow >= GROUND_Y - 2 and crow < GROUND_Y:
			for sp: Array in L["spikes_g"]:
				var sx0: int = sp[0]
				var sx1: int = sp[0] + sp[1] - 1
				if cx0 <= sx1 and sx0 <= cx1:
					errs.append("munt(en) x=%d..%d rij %d overlapt stekels x=%d..%d" % [cx0, cx1, crow, sx0, sx1])
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
			"fp": _fp(sec[1], sec[2] if sec.size() > 2 else 1)
			"mp": _mp(sec[1])
			"sp": _sp(sec[1], sec[2] if sec.size() > 2 else {})
			"pd": _pd(sec[1], sec[2] if sec.size() > 2 else {})
			"tw": _tw(sec[1] if sec.size() > 1 else {})
			"cv": _cv(sec[1], sec[2] if sec.size() > 2 else {})
	_finish(spec.get("staart", 20), spec.get("boss", false))

	var errs := _validate()
	if not errs.is_empty():
		_fail = true
		for e: String in errs:
			printerr("W1L%d: %s" % [L["n"], e])
		return
	_write_level()

## Terrein-rechthoeken; "cut"-rects (tunnels/schachten) worden uit de grond
## geknipt door de grondstroken op te splitsen in losse cellen-kolommen.
func _rects() -> Array:
	var cells: Dictionary = {}
	for g: Array in L["ground"]:
		for x in range(g[0], g[1]):
			for y in range(GROUND_Y, GROUND_Y + GROUND_DEPTH):
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
	# Cellen terug naar rechthoeken: per rij aaneengesloten runs.
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
		out.append([pi[0], pi[1], 1, GROUND_Y + GROUND_DEPTH - pi[1]])
	return out

func _esc(s: String) -> String:
	return s.replace("\\", "\\\\").replace('"', '\\"')

func _write_level() -> void:
	var n: int = L["n"]
	var width_px: int = L["w"] * 32
	var has_boss: bool = L["boss"] >= 0
	var total_enemies: int = L["rats"].size() + L["snakes"].size() + L["bats"].size()
	var kills: int = maxi(1, int(ceil(total_enemies * _kill_pct(n))))
	var level_height: int = 800 if L["cave"] else 720

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
	ext += '[ext_resource type="TileSet"     path="%s"       id="13"]\n' % TILESETS[L["tileset"]]
	ext += '[ext_resource type="Script"      path="res://scripts/levels/Terrain.gd"               id="14"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spikes.tscn"              id="15"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Ladder.tscn"              id="16"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Checkpoint.tscn"          id="17"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/PowerBlockOrange.tscn"    id="18"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/enemies/world1/ForestBoss.tscn"    id="19"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/FallingPlatform.tscn"     id="20"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/MovingPlatform.tscn"      id="21"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Spring.tscn"              id="22"]\n'
	ext += '[ext_resource type="PackedScene" path="res://scenes/objects/Water.tscn"               id="23"]\n'
	# Decor-texturen.
	var tex_ids: Dictionary = {}
	var next_id := 30
	for d: Array in L["decor"]:
		var path: String = DECOR[d[1]][0]
		if not tex_ids.has(path):
			tex_ids[path] = next_id
			ext += '[ext_resource type="Texture2D"   path="%s" id="%d"]\n' % [path, next_id]
			next_id += 1
	var load_steps := 24 + tex_ids.size() + 1

	var s := "[gd_scene load_steps=%d format=3]\n\n" % load_steps
	s += ext + "\n"
	s += '[sub_resource type="RectangleShape2D" id="1"]\n'
	s += "size = Vector2(32.0, 300.0)\n\n"

	s += '[node name="W1L%d" type="Node2D"]\n' % n
	s += 'script = ExtResource("1")\n'
	s += "level_width = %d\n" % width_px
	s += "level_height = %d\n" % level_height
	s += "coins_needed_pct = %d\n" % L["pct"]
	s += "enemies_needed = %d\n" % kills
	s += "require_both = %s\n" % ("true" if L["both"] else "false")
	s += "world_number = 1\n"
	s += "level_number = %d\n" % n
	if not String(L["hint"]).is_empty():
		s += 'intro_hint = "%s"\n' % _esc(L["hint"])
	s += "\n"

	s += '[node name="ParallaxBG" parent="." instance=ExtResource("12")]\n\n'
	s += '[node name="HUD" parent="." instance=ExtResource("3")]\n\n'
	s += '[node name="Player" parent="." instance=ExtResource("2")]\n'
	s += "position = Vector2(%d.0, 640.0)\n\n" % (352 if L["secret"] else 120)

	# --- Decor ---
	s += '[node name="Decor" type="Node2D" parent="."]\n\n'
	var idx := 1
	for d: Array in L["decor"]:
		var spec: Array = DECOR[d[1]]
		var tid: int = tex_ids[spec[0]]
		var sc: int = spec[2]
		var h: int
		var region = spec[1]
		s += '[node name="Prop%d" type="Sprite2D" parent="Decor"]\n' % idx
		s += "z_index = %d\n" % spec[3]
		s += "scale = Vector2(%d.0, %d.0)\n" % [sc, sc]
		s += "centered = false\n"
		s += 'texture = ExtResource("%d")\n' % tid
		if region != null:
			h = int(region[3])
			s += "region_enabled = true\n"
			s += "region_rect = Rect2(%d, %d, %d, %d)\n" % [region[0], region[1], region[2], region[3]]
		else:
			h = _tex_height(spec[0])
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(d[0]) * 32, GROUND_Y * 32 - h * sc + 4]
		idx += 1

	# --- Terrain ---
	var rects: Array[String] = []
	for r: Array in _rects():
		rects.append("Rect2i(%d, %d, %d, %d)" % [r[0], r[1], r[2], r[3]])
	var ng: Array[String] = []
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

	# --- Water (vijvers) ---
	idx = 1
	for p: Array in L["ponds"]:
		var w_px: int = int(p[1]) * 32
		var h_px: int = POND_FLOOR_ROW * 32 - POND_TOP_PX
		s += '[node name="Pond%d" parent="." instance=ExtResource("23")]\n' % idx
		s += "position = Vector2(%.1f, %.1f)\n" % [int(p[0]) * 32 + w_px / 2.0, POND_TOP_PX + h_px / 2.0]
		s += "size = Vector2(%d.0, %d.0)\n\n" % [w_px, h_px]
		idx += 1

	# --- Vijanden ---
	s += '[node name="Enemies" type="Node2D" parent="."]\n\n'
	idx = 1
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
	for c: Array in L["coins_free"]:
		s += '[node name="Coin%d" parent="Objects" instance=ExtResource("7")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [int(c[0]) * 32 + 16, int(c[1]) * 32 + 16]
		idx += 1
	idx = 1
	for b in L["blocks"]:
		var bx: int = b[1] if b is Array else b
		var by: int = 23 * 32 + 16 if b is Array else 624
		s += '[node name="SpecialBlock%d" parent="Objects" instance=ExtResource("8")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n\n" % [bx * 32, by]
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
	idx = 1
	for lad: Array in L["ladders"]:
		var top_px: int = int(lad[1]) * 32
		s += '[node name="Ladder%d" parent="Objects" instance=ExtResource("16")]\n' % idx
		s += "position = Vector2(%d.0, %d.0)\n" % [int(lad[0]) * 32 + 16, top_px]
		s += "height = %d\n\n" % (640 - top_px)
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
		s += "offset = Vector2(%.1f, 0.0)\n" % m[2]
		s += "period = %.1f\n\n" % m[3]
		idx += 1
	idx = 1
	for sx: int in L["springs"]:
		s += '[node name="Spring%d" parent="Objects" instance=ExtResource("22")]\n' % idx
		s += "position = Vector2(%d.0, 640.0)\n\n" % (sx * 32 + 16)
		idx += 1

	idx = 1
	for tx: int in L["checkpoints"]:
		s += '[node name="Checkpoint%d" parent="." instance=ExtResource("17")]\n' % idx
		s += "position = Vector2(%d.0, 640.0)\n\n" % (tx * 32)
		idx += 1

	s += '[node name="Cabin" parent="." instance=ExtResource("9")]\n'
	s += "position = Vector2(%d.0, 640.0)\n\n" % (int(L["cabin"]) * 32)

	var wall_x: int = (int(L["cabin"]) + 2) * 32
	s += '[node name="CabinWall" type="StaticBody2D" parent="."]\n'
	s += "position = Vector2(%d.0, 490.0)\n" % wall_x
	s += "collision_layer = 1\n"
	s += "collision_mask = 0\n\n"
	s += '[node name="CollisionShape2D" type="CollisionShape2D" parent="CabinWall"]\n'
	s += 'shape = SubResource("1")\n'

	var f := FileAccess.open(OUT_DIR + "W1L%d.tscn" % n, FileAccess.WRITE)
	f.store_string(s)
	f.close()
	print("geschreven: W1L%d.tscn (%d tegels, %d px, %d/%d vijanden vereist, tiles=%s)" % [n, L["w"], width_px, kills, total_enemies, L["tileset"]])

func _tex_height(path: String) -> int:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return img.get_height() if img != null else 32

# ----------------------------------------------------------- ontwerpdata ---

func _levels() -> Array:
	return [
		{
			# L1 — intro: rustig springen, twee grondvijanden, één instortend
			# platform als eerste "verrassing", geheime hoek links van de start.
			"n": 1, "pct": 40, "both": false, "staart": 16,
			"tileset": "default", "decor": ["tree_big", "bush", "mushrooms"], "secret": true,
			"hint": "Psst… niet alles ligt op de route. Kijk ook eens achter je.",
			"secties": [
				["fl", 20, {"coins": 4}],
				["fl", 36, {"coins": 6, "rats": 1, "block": true}],
				["fl", 30, {"snakes": 1, "coins": 5}],
				["gp", 3],
				["fl", 30, {"rats": 1, "power": "purple"}],
				["st", [17]],
				["fl", 26, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["fp", 8, 1],
				["fl", 30, {"rats": 1, "block": true}],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["fl", 28, {"rats": 1, "checkpoint": true, "power": "blue"}],
				["gp", 4],
				["fl", 32, {"coins": 6, "snakes": 1}],
				["fl", 24, {"rats": 1, "coins": 4}],
			],
		},
		{
			# L2 — ladder-intro: hoge route + trapjes; zonnige look.
			"n": 2, "pct": 50, "both": false, "staart": 22,
			"tileset": "sunny", "decor": ["sl_tree", "sl_bush", "sl_sign"],
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
			# L3 — pilaar-oversteken + de eerste VIJVER (zwemmen!) + oranje power-up.
			"n": 3, "pct": 50, "both": false, "staart": 22,
			"tileset": "default", "decor": ["tree_small", "rock", "shrooms_brown"],
			"hint": "Water! Spring erin en zwem: springknop = slag omhoog, omlaag = duiken.",
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["st", [17]],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["gp", 9, 1],
				["fl", 30, {"rats": 1, "power": "orange"}],
				["pd", 9, {"coins": 3}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1}],
				["hr", 34, 12, {"power": "blue"}],
				["fl", 28, {"snakes": 1, "coins": 5, "block": true}],
				["pd", 12, {"coins": 4}],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["ba", 28, 2],
				["fl", 30, {"snakes": 1, "coins": 5}],
				["gp", 5],
				["fl", 26, {"coins": 4}],
			],
		},
		{
			# L4 — stekels serieus + instortende bruggen; herfstheg-look; beide eisen.
			"n": 4, "pct": 60, "both": true, "staart": 22,
			"tileset": "hedge", "decor": ["bush_flowers", "mushrooms", "sl_skulls"],
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["sr", 3],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["st", [17, 14], {"power": "purple"}],
				["fl", 28, {"rats": 1}],
				["fp", 14, 2],
				["fl", 30, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1, "bats": 1}],
				["hr", 36, 12, {"power": "blue", "spikes": true}],
				["fl", 28, {"snakes": 1, "coins": 5, "block": true}],
				["fp", 20, 3],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["gp", 13, 2],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L5 — klimlevel: twee klimtorens en een hoge route; blauwgroene heg.
			"n": 5, "pct": 60, "both": true, "staart": 22,
			"tileset": "teal", "decor": ["sl_tree", "fern", "rock"],
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["tw", {"power": "purple"}],
				["fl", 28, {"snakes": 1, "coins": 4}],
				["gp", 4],
				["fl", 28, {"rats": 1}],
				["hr", 38, 12, {"spikes": true}],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 28, {"rats": 1, "bats": 1}],
				["gp", 9, 1],
				["fl", 28, {"snakes": 1, "block": true}],
				["tw", {"power": "blue", "bat": true}],
				["fl", 28, {"rats": 1, "checkpoint": true, "coins": 5}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["gp", 5],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L6 — vleermuizensteeg + BEWEGENDE PLATFORMS; zonnige look.
			"n": 6, "pct": 60, "both": true, "staart": 22,
			"tileset": "sunny", "decor": ["tree_big", "sl_shrooms", "sl_rock"],
			"secties": [
				["fl", 36, {"coins": 5, "rats": 1, "block": true}],
				["ba", 30, 2],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["mp", 12],
				["fl", 28, {"rats": 1, "power": "purple"}],
				["ba", 30, 3],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["sr", 4],
				["fl", 26, {"rats": 1}],
				["st", [17, 14], {"power": "blue", "bat": true}],
				["fl", 26, {"snakes": 1, "coins": 5, "block": true}],
				["mp", 16],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["ba", 32, 3],
				["fl", 28, {"snakes": 1, "coins": 5}],
				["hr", 34, 12, {"power": "orange"}],
				["fl", 26, {"rats": 1, "coins": 4}],
				["mp", 14],
				["fl", 24, {"coins": 4}],
			],
		},
		{
			# L7 — pilaarsprongen + SPRINGVEREN naar hoge platforms.
			"n": 7, "pct": 70, "both": true, "staart": 22,
			"tileset": "default", "decor": ["sl_bush", "sl_rock", "sl_sign"],
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["sp", 22, {"power": "purple"}],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["gp", 13, 2],
				["fl", 28, {"rats": 1}],
				["sr", 4],
				["fl", 26, {"snakes": 1, "bats": 1}],
				["gp", 17, 3],
				["fl", 30, {"checkpoint": true, "rats": 1, "coins": 4}],
				["sp", 22, {"power": "blue", "rats": 1}],
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
			# L8 — stekel-spitsroede + VERBORGEN TUNNEL met schat; herfstheg.
			"n": 8, "pct": 70, "both": true, "staart": 22,
			"tileset": "hedge", "decor": ["tree_small", "mushrooms", "bush"],
			"hint": "Niet alle stekelvelden hoef je óver… soms kun je eronderdoor.",
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["sr", 4],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["cv", 30, {"block": true}],
				["fl", 26, {"rats": 1, "power": "purple"}],
				["gp", 9, 1],
				["fl", 28, {"checkpoint": true, "snakes": 1, "coins": 4}],
				["hr", 38, 12, {"power": "blue", "spikes": true, "variant": "long_wood"}],
				["fl", 26, {"rats": 1, "bats": 1}],
				["sr", 5, "long_wood"],
				["fl", 26, {"snakes": 1, "coins": 5, "block": true}],
				["st", [17, 14], {"power": "orange", "bat": true}],
				["fl", 28, {"rats": 1, "checkpoint": true}],
				["cv", 34, {"variant": "long_wood"}],
				["fl", 26, {"snakes": 1, "coins": 5}],
				["gp", 13, 2],
				["fl", 30, {"rats": 1, "coins": 4}],
				["ba", 26, 2],
			],
		},
		{
			# L9 — finale-mix: vijver, bewegend platform, klimtoren, instortende
			# brug, stekels — het langste level; blauwgroene heg.
			"n": 9, "pct": 80, "both": true, "staart": 22,
			"tileset": "teal", "decor": ["tree_big", "sl_skulls", "fern"],
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["st", [17, 14, 11], {"power": "purple"}],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["pd", 12, {"coins": 4}],
				["fl", 26, {"rats": 1}],
				["sr", 4, "long_wood"],
				["fl", 26, {"snakes": 1, "bats": 1}],
				["mp", 16],
				["fl", 28, {"checkpoint": true, "rats": 1, "coins": 4}],
				["gp", 17, 3],
				["fl", 26, {"snakes": 1, "block": true}],
				["ba", 30, 3],
				["fl", 26, {"rats": 1, "coins": 5}],
				["tw", {"power": "blue", "bat": true}],
				["fl", 26, {"snakes": 1}],
				["fp", 20, 3],
				["fl", 28, {"rats": 1, "checkpoint": true, "coins": 5}],
				["sr", 5, "long_wood"],
				["fl", 26, {"snakes": 1, "coins": 4}],
				["hr", 36, 11, {"power": "orange", "spikes": true, "variant": "long_wood"}],
				["fl", 26, {"rats": 1, "coins": 4}],
				["gp", 5],
				["fl", 24, {"coins": 4}],
			],
		},
		{
			# L10 — bosslevel: aanloop met een beetje van alles, dan de pompoen-arena.
			"n": 10, "pct": 0, "both": false, "staart": 70, "boss": true,
			"tileset": "default", "decor": ["tree_big", "sl_skulls", "mushrooms", "rock"],
			"secties": [
				["fl", 34, {"coins": 5, "rats": 1, "block": true}],
				["sp", 20, {"power": "purple"}],
				["fl", 24, {"snakes": 1, "coins": 4}],
				["pd", 9, {"coins": 3}],
				["fl", 24, {"checkpoint": true, "coins": 4}],
				["mp", 12],
				["fl", 20, {"bats": 1}],
				["sr", 3],
				["fl", 24, {"checkpoint": true, "rats": 1}],
				["st", [17], {"power": "orange"}],
				["fl", 20, {"rats": 1}],
			],
		},
	]
