extends Control

## Title screen — shows title art with Start/Continue buttons

func _ready() -> void:
	# Load title background
	var bg: TextureRect = $Background
	for path in ["res://assets/backgrounds/title_screen.png"]:
		var tex := _load_texture(path)
		if tex:
			bg.texture = tex
			break

	if not bg.texture:
		var fallback := GradientTexture2D.new()
		var grad := Gradient.new()
		grad.set_color(0, Color(0.12, 0.08, 0.04))
		grad.set_color(1, Color(0.06, 0.04, 0.02))
		fallback.gradient = grad
		fallback.width = 640
		fallback.height = 480
		bg.texture = fallback

	# Connect buttons
	$VBox/StartButton.pressed.connect(_on_start_pressed)
	_style_start_button($VBox/StartButton)

	# Add Continue button if save exists
	if FileAccess.file_exists("user://savegame.dat"):
		var continue_btn := _make_button("Continue")
		$VBox.add_child(continue_btn)
		$VBox.move_child(continue_btn, 0)  # Put it above Start
		continue_btn.pressed.connect(_on_continue_pressed)
		_style_title_button(continue_btn)

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

func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.25))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.4))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.5))
	btn.add_theme_font_size_override("font_size", 14)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.55, 0.41, 0.1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 24
	style.content_margin_top = 8
	style.content_margin_right = 24
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = Color(0.18, 0.12, 0.06, 0.95)
	hover.border_color = Color(0.8, 0.6, 0.2)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	return btn

func _style_start_button(btn: Button) -> void:
	# Start button: styled to match the title placard — parchment-cream
	# background with dark engraved-brown serif text.
	var bg := {"normal": Color("eccd7f"), "hover": Color("f3d992"),
			"pressed": Color("e0bb6a"), "focus": Color("eccd7f")}
	for state in bg:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg[state]
		sb.set_corner_radius_all(3)
		sb.set_border_width_all(2)
		sb.border_color = Color("8a6a34")
		sb.set_content_margin(SIDE_LEFT, 18)
		sb.set_content_margin(SIDE_RIGHT, 18)
		sb.set_content_margin(SIDE_TOP, 5)
		sb.set_content_margin(SIDE_BOTTOM, 9)
		btn.add_theme_stylebox_override(state, sb)
	var brown := Color("2f1d11")
	btn.add_theme_color_override("font_color", brown)
	btn.add_theme_color_override("font_hover_color", brown)
	btn.add_theme_color_override("font_pressed_color", brown)
	btn.add_theme_color_override("font_focus_color", brown)
	# Slab-serif font to match the baked "THE IRON WAKE" title lettering.
	var font := FontFile.new()
	font.load_dynamic_font("res://assets/fonts/ZillaSlab-Medium.ttf")
	if font.get_font_name() != "":
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 17)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _style_title_button(btn: Button) -> void:
	if not GameState.use_new_assets:
		return
	var normal := _make_plaque(false)
	var lit := _make_plaque(true)
	if normal:
		btn.add_theme_stylebox_override("normal", normal)
	if lit:
		btn.add_theme_stylebox_override("hover", lit)
		btn.add_theme_stylebox_override("pressed", lit)
	btn.add_theme_color_override("font_color", Color("e2be6e"))
	btn.add_theme_color_override("font_hover_color", Color("ffe6a8"))
	btn.add_theme_color_override("font_pressed_color", Color("fff0c8"))
	btn.add_theme_font_size_override("font_size", 15)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_plaque(selected: bool) -> StyleBox:
	var tex := _load_texture("res://assets_new/ui/%s" % ("verb_selected.png" if selected else "verb_normal.png"))
	if tex == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	# Match the new baked plate's frame (thin top rail, heavier bottom lip,
	# angular side brackets) so the 9-slice doesn't distort it.
	sb.set_texture_margin(SIDE_LEFT, 18)
	sb.set_texture_margin(SIDE_RIGHT, 18)
	sb.set_texture_margin(SIDE_TOP, 6)
	sb.set_texture_margin(SIDE_BOTTOM, 9)
	# Symmetric L/R so the label is horizontally centred; the min button width
	# stays under the title VBox so the plate doesn't drift right. Top < bottom
	# nudges the label onto the copper face's visual centre (heavier bottom lip).
	sb.set_content_margin(SIDE_LEFT, 16)
	sb.set_content_margin(SIDE_RIGHT, 16)
	sb.set_content_margin(SIDE_TOP, 4)
	sb.set_content_margin(SIDE_BOTTOM, 13)
	return sb

func _load_texture(res_path: String) -> Texture2D:
	res_path = GameState.resolve_asset(res_path)
	if ResourceLoader.exists(res_path):
		return load(res_path)
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

func _fade_out_and_load(scene_path: String) -> void:
	var music := get_node_or_null("MusicPlayer")
	if music:
		var music_tw := create_tween()
		music_tw.tween_property(music, "volume_db", -40.0, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

func _on_start_pressed() -> void:
	GameState.reset()
	await _fade_out_and_load("res://scenes/main.tscn")

func _on_continue_pressed() -> void:
	if GameState.load_game():
		var room := GameState.current_room
		# Map room_name to scene path
		var scene_map := {
			"blackwake_harbor": "res://scenes/main.tscn",
			"customs_shack": "res://scenes/rooms/customs_shack.tscn",
			"salvage_warehouse": "res://scenes/rooms/salvage_warehouse.tscn",
			"brass_bazaar": "res://scenes/rooms/brass_bazaar.tscn",
			"tibbit_workshop": "res://scenes/rooms/tibbit_workshop.tscn",
			"harbor_cliffs": "res://scenes/rooms/harbor_cliffs.tscn",
			"lighthouse_exterior": "res://scenes/rooms/lighthouse_exterior.tscn",
			"lighthouse_chamber": "res://scenes/rooms/lighthouse_chamber.tscn",
			"smuggler_path": "res://scenes/rooms/smuggler_path.tscn",
			"brackmarsh": "res://scenes/rooms/brackmarsh.tscn",
			"relay_tower": "res://scenes/rooms/relay_tower.tscn",
			"sunken_waystation": "res://scenes/rooms/sunken_waystation.tscn",
			"ironwind_airdock": "res://scenes/rooms/ironwind_airdock.tscn",
			"fogwound_ruins": "res://scenes/rooms/fogwound_ruins.tscn",
			"transit_vault": "res://scenes/rooms/transit_vault.tscn",
			"cinderglass_valley": "res://scenes/rooms/cinderglass_valley.tscn",
			"mountain_breach": "res://scenes/rooms/mountain_breach.tscn",
			"undersea_transit": "res://scenes/rooms/undersea_transit.tscn",
			"wake_passage": "res://scenes/rooms/wake_passage.tscn",
			"isle_auric": "res://scenes/rooms/isle_auric.tscn",
			"harmonic_gate": "res://scenes/rooms/harmonic_gate.tscn",
		}
		var target: String = scene_map.get(room, "res://scenes/main.tscn")
		await _fade_out_and_load(target)
	else:
		# Save corrupted or missing — just start fresh
		GameState.reset()
		await _fade_out_and_load("res://scenes/main.tscn")
