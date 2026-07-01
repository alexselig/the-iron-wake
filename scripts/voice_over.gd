extends Node
## VoiceOver — plays pre-generated ElevenLabs dialogue clips.
##
## Clips live at res://assets/voice/<sha1(speaker|text)>.mp3 and are produced by
## tools/generate_voiceover.py. The API key is used ONLY by that build-time
## script and never ships in the game — only the resulting audio does.
##
## When a line appears, DialogueBox.show_dialogue() calls VoiceOver.play(speaker,
## text). We recompute the same hash the generator used and play the clip. A
## missing clip is a silent no-op, so unvoiced rooms behave exactly as before.

const VOICE_DIR := "res://assets/voice/"
const SETTINGS_PATH := "user://voice_settings.cfg"

var enabled := true
var volume_db := 0.0

var _player: AudioStreamPlayer
var _cache: Dictionary = {}    # hash -> AudioStream (loaded clips)
var _missing: Dictionary = {}  # hash -> true (clips known to be absent)

static var _ws_re: RegEx

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_load_settings()
	_player.volume_db = volume_db

## Collapse ASCII whitespace runs and trim ends.
## MUST stay byte-identical to normalize() in tools/generate_voiceover.py.
static func _normalize(text: String) -> String:
	if _ws_re == null:
		_ws_re = RegEx.new()
		_ws_re.compile("[ \t\r\n]+")
	return _ws_re.sub(text, " ", true).strip_edges()

## sha1(speaker + "|" + normalized_text) as lowercase hex — matches the generator.
static func line_hash(speaker: String, text: String) -> String:
	return (speaker + "|" + _normalize(text)).sha1_text()

func play(speaker: String, text: String) -> void:
	if not enabled or text.strip_edges() == "":
		return
	var h := line_hash(speaker, text)
	if _missing.has(h):
		return
	var stream: AudioStream = _cache.get(h)
	if stream == null:
		stream = _load_clip(h)
		if stream == null:
			_missing[h] = true
			return
		_cache[h] = stream
	_player.stream = stream
	_player.play()

func stop() -> void:
	if _player and _player.playing:
		_player.stop()

func _load_clip(h: String) -> AudioStream:
	var res_path := VOICE_DIR + h + ".mp3"
	# Prefer the imported resource when present (exported builds).
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is AudioStream:
			return res
	# Fall back to reading raw bytes — works without an editor reimport, matching
	# the .wav loading pattern used elsewhere in the project.
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var f := FileAccess.open(abs_path, FileAccess.READ)
		if f:
			var stream := AudioStreamMP3.new()
			stream.data = f.get_buffer(f.get_length())
			return stream
	return null

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()
	_save_settings()

func toggle() -> void:
	set_enabled(not enabled)

func set_volume_db(db: float) -> void:
	volume_db = db
	if _player:
		_player.volume_db = db
	_save_settings()

func _unhandled_input(event: InputEvent) -> void:
	# "V" toggles voiceover. Nothing else binds V, and using _unhandled_input
	# means dialogue clicks / Space / Enter (which mark input handled) win first.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		toggle()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		enabled = bool(cfg.get_value("voice", "enabled", true))
		volume_db = float(cfg.get_value("voice", "volume_db", 0.0))

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("voice", "enabled", enabled)
	cfg.set_value("voice", "volume_db", volume_db)
	cfg.save(SETTINGS_PATH)
