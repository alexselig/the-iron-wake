extends Control

## Title screen — shows title art with a Start button

func _ready() -> void:
	# Load title background
	var bg: TextureRect = $Background
	for path in ["res://assets/backgrounds/title_screen.png"]:
		var tex := _load_texture(path)
		if tex:
			bg.texture = tex
			break

	# Fallback: dark steampunk background if no image loaded
	if not bg.texture:
		var fallback := GradientTexture2D.new()
		var grad := Gradient.new()
		grad.set_color(0, Color(0.12, 0.08, 0.04))
		grad.set_color(1, Color(0.06, 0.04, 0.02))
		fallback.gradient = grad
		fallback.width = 640
		fallback.height = 480
		bg.texture = fallback

	# Connect button
	$VBox/StartButton.pressed.connect(_on_start_pressed)

	# Title music
	var music_player := AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.volume_db = -10.0
	add_child(music_player)
	var stream := _load_audio("res://assets/music/title_theme.wav")
	if stream:
		music_player.stream = stream
		music_player.play()

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)

func _load_texture(res_path: String) -> Texture2D:
	# Try standard Godot import pipeline first
	if ResourceLoader.exists(res_path):
		return load(res_path)
	# Fallback: load raw PNG directly (bypasses import system)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null

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

func _on_start_pressed() -> void:
	# Stop music immediately, fade visuals
	var music := get_node_or_null("MusicPlayer")
	if music:
		music.stop()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
