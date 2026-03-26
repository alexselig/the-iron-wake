extends Control

## Overhead dialogue — text floats above the speaking character.
## Popochiu-style: colored text with black outline, no background box.

signal dialogue_finished()

var rich_text: RichTextLabel
var is_showing := false
var plain_text := ""  # The actual message without BBCode
var color_hex := "#f2ead1"  # Current speaker color as hex
var word_timer := 0.0
const WORD_SPEED := 0.08  # seconds per word
var words: PackedStringArray = []
var current_word_index := 0
var skip_requested := false

# Position tracking
var target_screen_pos := Vector2.ZERO
var viewport_size := Vector2(640, 480)

# Character colors (warm steampunk palette)
const SPEAKER_COLORS := {
	"ROWAN": Color(0.95, 0.92, 0.82),     # warm white
	"TIBBIT": Color(0.6, 0.9, 0.5),        # green
	"PINDLE": Color(0.85, 0.7, 0.4),       # gold/khaki
	"MIRELLE": Color(0.95, 0.55, 0.65),    # pink
	"MARROW": Color(0.7, 0.75, 0.95),      # pale blue
	"ROOK": Color(0.85, 0.35, 0.35),       # red
	"CALIGO": Color(0.75, 0.65, 0.9),      # lavender
	"BRAM": Color(0.9, 0.75, 0.5),         # tan
}
const DEFAULT_COLOR := Color(0.9, 0.9, 0.9)

# Not used anymore but kept for compatibility
var name_label: Label

var bg_panel: PanelContainer

func _ready() -> void:
	# Semi-transparent background panel
	bg_panel = PanelContainer.new()
	bg_panel.name = "BgPanel"
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 10.0
	style.content_margin_top = 4.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 4.0
	bg_panel.add_theme_stylebox_override("panel", style)
	add_child(bg_panel)

	# Overhead text inside the panel
	rich_text = RichTextLabel.new()
	rich_text.name = "OverheadText"
	rich_text.bbcode_enabled = true
	rich_text.fit_content = true
	rich_text.scroll_active = false
	rich_text.clip_contents = false
	rich_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich_text.add_theme_font_size_override("normal_font_size", 13)
	rich_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	rich_text.add_theme_constant_override("outline_size", 4)
	rich_text.size = Vector2(280, 60)
	bg_panel.add_child(rich_text)

	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not is_showing:
		return
	if skip_requested:
		current_word_index = words.size()
		_update_display()
		skip_requested = false
		return
	word_timer += delta
	while word_timer >= WORD_SPEED and current_word_index < words.size():
		current_word_index += 1
		word_timer -= WORD_SPEED
	_update_display()

func _update_display() -> void:
	var visible_text := " ".join(words.slice(0, current_word_index))
	rich_text.text = "[center][color=%s]%s[/color][/center]" % [color_hex, visible_text]

func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed:
		advance = true
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		advance = true
	if advance:
		if current_word_index < words.size():
			skip_requested = true
		else:
			hide_dialogue()
		get_viewport().set_input_as_handled()

func show_dialogue(speaker: String, text: String) -> void:
	var color: Color = SPEAKER_COLORS.get(speaker, DEFAULT_COLOR)
	color_hex = "#" + color.to_html(false)
	plain_text = text
	words = PackedStringArray(text.split(" "))
	current_word_index = 0
	word_timer = 0.0

	rich_text.text = ""
	bg_panel.visible = true
	is_showing = true
	skip_requested = false

	if name_label:
		name_label.visible = false

	_reposition()

func show_dialogue_at(speaker: String, text: String, world_pos: Vector2) -> void:
	target_screen_pos = world_pos - Vector2(0, 60)
	show_dialogue(speaker, text)

func _reposition() -> void:
	if not bg_panel:
		return
	bg_panel.size = Vector2(290, 0)  # Width hint, height auto from content
	var x := target_screen_pos.x - bg_panel.size.x / 2.0
	var y := target_screen_pos.y - 70

	x = clampf(x, 4.0, viewport_size.x - bg_panel.size.x - 4.0)
	y = clampf(y, 4.0, viewport_size.y * 0.55)

	bg_panel.position = Vector2(x, y)

func hide_dialogue() -> void:
	bg_panel.visible = false
	is_showing = false
	dialogue_finished.emit()

func is_text_complete() -> bool:
	return current_word_index >= words.size()

func force_dismiss() -> void:
	if is_showing:
		hide_dialogue()

# Legacy compat — old code checked .is_showing on the node directly
func get_is_showing() -> bool:
	return is_showing
