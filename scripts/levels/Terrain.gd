class_name Terrain
extends TileMapLayer

## Schildert grond en platforms op basis van rechthoeken in tegel-coördinaten.
## De TileSet (world1_tileset.tres) levert de collision via physics layer 0.
## Tegelgrenzen: 1 tegel = 16px × schaal van deze node (standaard 2 → 32px).

@export var solid_rects: Array[Rect2i] = []

# Atlas-coördinaten in world1_tileset.tres
const TOP_LEFT   := Vector2i(1, 5)
const TOP_MID    := Vector2i(2, 5)
const TOP_RIGHT  := Vector2i(3, 5)
const MID_LEFT   := Vector2i(1, 6)
const MID_MID    := Vector2i(2, 6)
const MID_RIGHT  := Vector2i(3, 6)
const LOW_LEFT   := Vector2i(1, 7)
const LOW_MID    := Vector2i(2, 7)
const LOW_RIGHT  := Vector2i(3, 7)
const SOLID      := Vector2i(5, 5)
const PILLAR_TOP := Vector2i(1, 1)
const PILLAR_MID := Vector2i(1, 2)
const PILLAR_LOW := Vector2i(1, 3)

func _ready() -> void:
	_paint()

func _paint() -> void:
	var cells: Dictionary = {}
	for r in solid_rects:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				cells[Vector2i(x, y)] = true

	for cell: Vector2i in cells:
		set_cell(cell, 0, _pick_atlas(cell, cells))

func _pick_atlas(c: Vector2i, cells: Dictionary) -> Vector2i:
	var up      := cells.has(c + Vector2i.UP)
	var left    := cells.has(c + Vector2i.LEFT)
	var right   := cells.has(c + Vector2i.RIGHT)

	# Smalle kolom (1 tegel breed) → pilaar-tegels
	if not left and not right:
		if not up:
			return PILLAR_TOP
		if not cells.has(c + Vector2i.UP * 2):
			return PILLAR_MID
		return PILLAR_LOW

	var depth := 0
	while depth < 3 and cells.has(c + Vector2i.UP * (depth + 1)):
		depth += 1

	match depth:
		0:
			if not left:  return TOP_LEFT
			if not right: return TOP_RIGHT
			return TOP_MID
		1:
			if not left:  return MID_LEFT
			if not right: return MID_RIGHT
			return MID_MID
		2:
			if not left:  return LOW_LEFT
			if not right: return LOW_RIGHT
			return LOW_MID
		_:
			return SOLID
