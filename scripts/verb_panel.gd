extends GridContainer

## Classic verb panel — Look at, Talk to, Pick up, Use, Open, Push

signal verb_selected(verb: String)

var current_verb: String = "look_at"
var verb_buttons: Dictionary = {}

const VERBS = {
	"look_at": "Look at",
	"talk_to": "Talk to",
	"pick_up": "Pick up",
	"use": "Use",
	"open": "Open",
	"push": "Push",
}

# Brass label palette (GODOT_INTEGRATION.md §2/§7)
const COLOR_LABEL_IDLE := Color("caa256")
const COLOR_LABEL_HOVER := Color("d8b15f")
const COLOR_LABEL_ACTIVE := Color("ffe6a8")

# Nine-patch margins in texture px. Assets are stored at 1x logical size,
# so these are the §5 values (28/28/24/30) halved.
const VERB_MARGIN := {"l": 14, "r": 14, "t": 12, "b": 15}

var _tex_normal: Texture2D
var _tex_selected: Texture2D

func _ready() -> void:
	columns = 3
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_tex_normal = _load_texture("res://assets/ui/verb_normal.png")
	_tex_selected = _load_texture("res://assets/ui/verb_selected.png")

	for verb_id in VERBS:
		var btn := Button.new()
		btn.text = VERBS[verb_id]
		btn.name = verb_id
		btn.custom_minimum_size = Vector2(96, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_color_override("font_color", COLOR_LABEL_IDLE)
		btn.add_theme_color_override("font_hover_color", COLOR_LABEL_HOVER)
		btn.add_theme_color_override("font_pressed_color", COLOR_LABEL_ACTIVE)
		btn.add_theme_color_override("font_focus_color", COLOR_LABEL_ACTIVE)

		# pressed/focus always show the lit "lamp"; normal/hover are set
		# per-state in _highlight_verb so the active verb stays lit.
		btn.add_theme_stylebox_override("pressed", _make_stylebox(true))
		btn.add_theme_stylebox_override("focus", _make_stylebox(true))

		btn.pressed.connect(_on_verb_pressed.bind(verb_id))
		add_child(btn)
		verb_buttons[verb_id] = btn

	# Default to "look_at" selected
	_highlight_verb("look_at")

func _make_stylebox(selected: bool, brightness: float = 1.0) -> StyleBox:
	var tex: Texture2D = _tex_selected if selected else _tex_normal
	if tex == null:
		# Fallback to flat brass styling if the textures are missing
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("43301a") if selected else Color("211609")
		flat.set_border_width_all(1)
		flat.border_color = Color("f1c878") if selected else Color("5d4622")
		flat.set_corner_radius_all(4)
		return flat
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin(SIDE_LEFT, VERB_MARGIN.l)
	sb.set_texture_margin(SIDE_RIGHT, VERB_MARGIN.r)
	sb.set_texture_margin(SIDE_TOP, VERB_MARGIN.t)
	sb.set_texture_margin(SIDE_BOTTOM, VERB_MARGIN.b)
	# Keep the label clear of the corner rivets and centered on the copper face.
	# Symmetric top/bottom margins so the text is vertically centred; the NEW
	# forged plates have a thicker frame so the label is inset a little more.
	if GameState.use_new_assets:
		sb.set_content_margin(SIDE_LEFT, 13)
		sb.set_content_margin(SIDE_RIGHT, 13)
		sb.set_content_margin(SIDE_TOP, 7)
		sb.set_content_margin(SIDE_BOTTOM, 7)
	else:
		sb.set_content_margin(SIDE_LEFT, 6)
		sb.set_content_margin(SIDE_RIGHT, 6)
		sb.set_content_margin(SIDE_TOP, 4)
		sb.set_content_margin(SIDE_BOTTOM, 4)
	if brightness != 1.0:
		sb.modulate_color = Color(brightness, brightness, brightness)
	return sb

func _on_verb_pressed(verb_id: String) -> void:
	current_verb = verb_id
	_highlight_verb(verb_id)
	verb_selected.emit(verb_id)

func _highlight_verb(verb_id: String) -> void:
	for vid in verb_buttons:
		var btn: Button = verb_buttons[vid]
		var is_active: bool = vid == verb_id
		btn.add_theme_stylebox_override("normal", _make_stylebox(is_active))
		btn.add_theme_stylebox_override("hover", _make_stylebox(is_active, 1.12))
		btn.add_theme_color_override("font_color", COLOR_LABEL_ACTIVE if is_active else COLOR_LABEL_IDLE)

func get_verb_text() -> String:
	return VERBS.get(current_verb, "")

func _load_texture(res_path: String) -> Texture2D:
	res_path = GameState.resolve_asset(res_path)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null
