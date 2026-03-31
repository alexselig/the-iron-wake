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

const VERB_COLORS = {
	"normal": Color(0.65, 0.5, 0.2),
	"hover": Color(0.85, 0.7, 0.3),
	"selected": Color(1.0, 0.85, 0.4),
}

func _ready() -> void:
	columns = 3
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for verb_id in VERBS:
		var btn := Button.new()
		btn.text = VERBS[verb_id]
		btn.name = verb_id
		btn.custom_minimum_size = Vector2(90, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", VERB_COLORS.normal)
		btn.add_theme_color_override("font_hover_color", VERB_COLORS.hover)
		btn.add_theme_color_override("font_pressed_color", VERB_COLORS.selected)
		btn.add_theme_color_override("font_focus_color", VERB_COLORS.selected)

		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.12, 0.08, 0.04)
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color(0.4, 0.3, 0.1)
		style_normal.corner_radius_top_left = 2
		style_normal.corner_radius_top_right = 2
		style_normal.corner_radius_bottom_right = 2
		style_normal.corner_radius_bottom_left = 2
		btn.add_theme_stylebox_override("normal", style_normal)

		var style_hover := style_normal.duplicate()
		style_hover.border_color = Color(0.6, 0.45, 0.15)
		btn.add_theme_stylebox_override("hover", style_hover)

		var style_pressed := style_normal.duplicate()
		style_pressed.bg_color = Color(0.2, 0.14, 0.06)
		style_pressed.border_color = Color(0.8, 0.6, 0.2)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", style_pressed)

		btn.pressed.connect(_on_verb_pressed.bind(verb_id))
		add_child(btn)
		verb_buttons[verb_id] = btn

	# Default to "look_at" selected
	_highlight_verb("look_at")

func _on_verb_pressed(verb_id: String) -> void:
	current_verb = verb_id
	_highlight_verb(verb_id)
	verb_selected.emit(verb_id)

func _highlight_verb(verb_id: String) -> void:
	for vid in verb_buttons:
		var btn: Button = verb_buttons[vid]
		if vid == verb_id:
			btn.add_theme_color_override("font_color", VERB_COLORS.selected)
		else:
			btn.add_theme_color_override("font_color", VERB_COLORS.normal)

func get_verb_text() -> String:
	return VERBS.get(current_verb, "")
