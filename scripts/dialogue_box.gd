extends Control

## Overhead dialogue — text floats above the speaking character.
## Popochiu-style: colored text with black outline, no background box.

signal dialogue_finished()
signal text_revealed()  # Emitted when word-by-word reveal completes

var rich_text: RichTextLabel
var is_showing := false
var plain_text := ""  # The actual message without BBCode
var color_hex := "#f2ead1"  # Current speaker color as hex
var word_timer := 0.0
const WORD_SPEED := 0.08  # seconds per word
var words: PackedStringArray = []
var current_word_index := 0
var skip_requested := false
var _pitch_offset := 0  # Random start offset per dialogue line

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
var _blip_player: AudioStreamPlayer
var _voice: Node  # VoiceOver autoload (may be null if disabled)

func _ready() -> void:
	# VoiceOver autoload — plays pre-generated dialogue clips (no-op if missing)
	_voice = get_node_or_null("/root/VoiceOver")

	# Dialogue blip sound — subtle melodic pluck
	_blip_player = AudioStreamPlayer.new()
	_blip_player.bus = "Master"
	_blip_player.volume_db = -21.0
	add_child(_blip_player)
	var blip_stream := _load_audio("res://assets/sfx/dialogue_blip.wav")
	if blip_stream:
		_blip_player.stream = blip_stream

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
	var prev_index := current_word_index
	while word_timer >= WORD_SPEED and current_word_index < words.size():
		current_word_index += 1
		word_timer -= WORD_SPEED
	if current_word_index > prev_index and _blip_player and _blip_player.stream:
		# Blip every 2nd word — balanced cadence
		if current_word_index % 2 == 1:
			var pitches := [0.75, 0.85, 0.9, 1.0, 1.1]
			_blip_player.pitch_scale = pitches[(current_word_index + _pitch_offset) % pitches.size()]
			_blip_player.play()
	_update_display()

var _text_revealed_emitted := false

func _update_display() -> void:
	var visible_text := " ".join(words.slice(0, current_word_index))
	rich_text.text = "[center][color=%s]%s[/color][/center]" % [color_hex, visible_text]
	if current_word_index >= words.size() and not _text_revealed_emitted:
		_text_revealed_emitted = true
		text_revealed.emit()

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

func show_dialogue(speaker: String, text: String, voice_speaker: String = "") -> void:
	var color: Color = SPEAKER_COLORS.get(speaker, DEFAULT_COLOR)
	color_hex = "#" + color.to_html(false)
	plain_text = text
	_pitch_offset = randi() % 5  # Random starting note per line
	words = PackedStringArray(text.split(" "))
	current_word_index = 0
	word_timer = 0.0

	rich_text.text = ""
	bg_panel.visible = true
	is_showing = true
	skip_requested = false
	_text_revealed_emitted = false

	# Speak the line (pre-generated ElevenLabs clip, if one exists). voice_speaker
	# lets one on-screen character use a different voice/style for some lines while
	# keeping the same name colour — e.g. Rowan's narration (ROWAN_VO) vs his
	# spoken dialogue (ROWAN). Falls back to the display speaker when unset.
	if _voice:
		_voice.play(voice_speaker if voice_speaker != "" else speaker, text)

	if name_label:
		name_label.visible = false

	_reposition()

func show_dialogue_at(speaker: String, text: String, world_pos: Vector2, voice_speaker: String = "") -> void:
	target_screen_pos = world_pos - Vector2(0, 60)
	show_dialogue(speaker, text, voice_speaker)

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
	if _voice:
		_voice.stop()
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

func _load_audio(res_path: String) -> AudioStream:
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var stream := AudioStreamWAV.new()
		var file := FileAccess.open(abs_path, FileAccess.READ)
		if file:
			file.seek(44)
			stream.data = file.get_buffer(file.get_length() - 44)
			stream.format = AudioStreamWAV.FORMAT_16_BITS
			stream.mix_rate = 44100
			stream.stereo = false
			return stream
	return null
