extends Control

const THUMB_SIZE   := Vector2(120, 92)
const IMAGE_HEIGHT := 72.0

## Zwart-wit voor werelden die nog niet speelbaar zijn.
const GRAYSCALE_SHADER := """
shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), c.a);
}
"""

@onready var _grid:     GridContainer = $VBox/WorldGrid
@onready var _back_btn: Button        = $VBox/BackButton

var _grayscale_material: ShaderMaterial

func _ready() -> void:
	_back_btn.pressed.connect(GameManager.go_to_main_menu)
	var shader := Shader.new()
	shader.code = GRAYSCALE_SHADER
	_grayscale_material = ShaderMaterial.new()
	_grayscale_material.shader = shader
	_build_grid()

func _build_grid() -> void:
	for w in range(1, 11):
		var cfg: Dictionary = WorldConfig.WORLDS[w - 1]
		var unlocked := GameManager.is_world_unlocked(w)
		_grid.add_child(_build_world_cell(w, cfg, unlocked))

func _build_world_cell(world: int, cfg: Dictionary, unlocked: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = THUMB_SIZE
	btn.disabled = not unlocked
	btn.flat = true
	btn.clip_text = true

	var thumb_path := "res://assets/sprites/backgrounds/worldmap/world%d.png" % world
	if ResourceLoader.exists(thumb_path, "Texture2D"):
		var thumb := TextureRect.new()
		thumb.texture = load(thumb_path)
		thumb.set_anchors_preset(Control.PRESET_TOP_WIDE)
		thumb.offset_bottom = IMAGE_HEIGHT
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			thumb.material = _grayscale_material
		btn.add_child(thumb)

	var label := Label.new()
	label.text = "%d. %s" % [world, cfg["name"]]
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -(THUMB_SIZE.y - IMAGE_HEIGHT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	btn.add_child(label)

	if unlocked:
		btn.pressed.connect(_on_world_pressed.bind(world))
	return btn

func _on_world_pressed(world: int) -> void:
	GameManager.go_to_world_map(world)
