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

func _on_start_pressed() -> void:
	# Fade out then load game
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
