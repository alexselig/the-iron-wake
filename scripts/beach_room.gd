extends AdventureRoom

## Blackwake Harbor — Act 1, Room 1
## The storm-lashed beach where the ancient relic washed ashore.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

# Room-specific clickables
var ancient_relic: Area2D
var spyglass_crate: Area2D
var steam_valve: Area2D
var warning_placard: Area2D
var crowd: Area2D
var docks: Area2D
var customs_shack: Area2D
var seawall: Area2D
var tibbit_npc: Area2D
var pindle_npc: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	for path in ["res://assets/backgrounds/act1_01_blackwake_harbor.png",
				  "res://assets/backgrounds/blackwake_harbor.png",
				  "res://assets/backgrounds/beach_ai.png",
				  "res://assets/backgrounds/beach.png"]:
		var tex := _load_texture(path)
		if tex:
			bg.texture = tex
			break

func _build_room() -> void:
	SceneBuilder.build_all(self)

func _on_room_ready() -> void:
	room_name = "blackwake_harbor"

	# Get built node references
	ancient_relic = $Props/AncientRelic
	spyglass_crate = $Props/SpyglassCrate
	steam_valve = $Props/SteamValve
	warning_placard = $Props/WarningPlacard
	docks = $Hotspots/Docks
	customs_shack = $Hotspots/CustomsShack
	seawall = $Hotspots/Seawall
	tibbit_npc = $Props/TibbitNPC
	pindle_npc = $Props/PindleNPC
	crowd = $Props/Crowd

	# Connect clickables
	for node in [ancient_relic, spyglass_crate, steam_valve, warning_placard,
				 docks, customs_shack, seawall, tibbit_npc, pindle_npc, crowd]:
		if node:
			connect_clickable(node)

	# Map speaker names to NPC nodes for talk animations
	speaker_to_node = {
		"TIBBIT": "TibbitNPC",
		"PINDLE": "PindleNPC",
	}

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"customs_shack":
			return Vector2(550, 290)
		_:
			return Vector2(200, 290)

# ============================================================
# INTRO SEQUENCE
# ============================================================

func _play_intro() -> void:
	var cs := CutscenePlayer.new(self)
	cs.face_player("right")

	# Walk in from left
	player.global_position = Vector2(-30, 290)
	fade_overlay.color = Color.BLACK
	fade_overlay.visible = true

	is_busy = true
	_in_scripted_sequence = true

	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 2.0)
	await tween.finished
	fade_overlay.visible = false
	await get_tree().create_timer(0.5).timeout

	await _say_as("PINDLE", "Stand back! No one is to touch the object until it has been documented, classified, categorized, and denied!")
	await _say_as("TIBBIT", "That's a machine.")
	await _say_as("PINDLE", "That's a liability.")

	await player.walk_to_and_wait(Vector2(200, 290))
	await _say_as("ROWAN", "What's all this?")
	await _say_as("TIBBIT", "Mystery. Bureaucracy. Possibly treasure. In that order.")

	await _say_as("PINDLE", "Citizen, step away from the object.")
	await _say_as("ROWAN", "I wasn't stepping toward it.")

	await get_tree().create_timer(0.3).timeout
	await _say_as("ROWAN", "That seems like a flaw in your profession.")
	await _say_as("PINDLE", "It is a cornerstone.")

	await get_tree().create_timer(0.5).timeout
	await _say_as("TIBBIT", "Well that's new. Usually ancient mystery junk only explodes for me.")

	await _say_as("ROWAN", "...I've had this thing since I was a child.")
	await _say_as("PINDLE", "Excellent. Then under salvage law, you are now personally responsible for whatever catastrophe this becomes.")
	await _say_as("ROWAN", "Marvelous.")

	await _show_controls_tutorial()

	GameState.set_flag("intro_complete")
	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# CONTROLS TUTORIAL
# ============================================================

func _show_controls_tutorial() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -180
	panel.offset_top = -80
	panel.offset_right = 180
	panel.offset_bottom = 80

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.55, 0.41, 0.1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "THE IRON WAKE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.25))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	for line in ["Select a VERB then click an object",
				 "RIGHT CLICK to quick-examine anything",
				 "ENTER or SPACE to advance dialogue",
				 "Click items in INVENTORY to use them"]:
		var lbl := Label.new()
		lbl.text = line
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		lbl.add_theme_font_size_override("font_size", 9)
		vbox.add_child(lbl)

	var hint := Label.new()
	hint.text = "Click to begin"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.4, 0.25))
	hint.add_theme_font_size_override("font_size", 8)
	vbox.add_child(hint)

	panel.add_child(vbox)
	overlay.add_child(panel)
	$UI.add_child(overlay)

	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	await tween.finished

	var clicked := false
	while not clicked:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("examine") \
				or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			clicked = true

	var tween2 := create_tween()
	tween2.tween_property(overlay, "modulate:a", 0.0, 0.3)
	await tween2.finished
	overlay.queue_free()

# ============================================================
# VERB ACTIONS (room-specific)
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"AncientRelic":
			await _say("Smooth, seamless, and smug. I've met wealthy people less polished than this.")
		"SpyglassCrate":
			await _say("A sailor's spyglass. Lens cracked, brass cheap, still more trustworthy than most officials.")
		"SteamValve":
			await _say("One of Blackwake's many wheels for deciding whether pipes are happy.")
		"WarningPlacard":
			await _say("'NO UNAUTHORIZED RESONANCE EVENTS.' That's not reassuring. That's advertising.")
		"Docks":
			await _say("Fishing boats and salvage barges. The two honest trades of Blackwake.")
		"CustomsShack":
			await _say("A shack small enough to be humble but official enough to be dangerous.")
		"Seawall":
			await _say("Brick, steam, and ambition holding back the tide. Barely.")
		"TibbitNPC":
			await _say("A man whose hair appears to be having an independent adventure.")
		"PindleNPC":
			await _say("A uniform containing a small man and a large sense of jurisdiction.")
		"Crowd":
			await _say("Opportunists, mystics, and people pretending they were here first.")
		_:
			await _say("Nothing remarkable about that.")

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"TibbitNPC":
			var tree := _build_tibbit_dialogue()
			await run_dialogue_tree(tree)
		"PindleNPC":
			var tree := _build_pindle_dialogue()
			await run_dialogue_tree(tree)
		"Crowd":
			await _say("The crowd seems very busy having opinions. I don't think I'd improve things.")
		"AncientRelic":
			await _say("I'm not saying it bit me. I'm saying we now have a hostile understanding.")
		_:
			await _say("Talking to that seems optimistic.")

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"SpyglassCrate":
			if not GameState.has_item("spyglass"):
				await _say("A cracked spyglass. Might still focus enough light to be useful.")
				give_item("spyglass")
				spyglass_crate.hide_object()
			else:
				await _say("I already have it.")
		"WarningPlacard":
			await _say("It's bolted to the seawall. Blackwake takes its warnings very seriously and its safety not at all.")
		"AncientRelic":
			await _say("It's the size of a horse and embedded in sand. I'll need a different approach.")
		_:
			await _say("I can't pick that up.")

func _use(obj: Clickable) -> void:
	match obj.name:
		"SteamValve":
			if GameState.has_flag("relic_cleaned"):
				await _say("Let's see if a resonance tone wakes it.")
				# Puzzle progression — valve activates the relic
				GameState.set_flag("relic_activated")
				await _say_as("TIBBIT", "It's humming! That's either progress or a countdown.")
			else:
				await _say("The crane horn blares. Gulls scatter. Nothing else happens.")
				await _say_as("TIBBIT", "Excellent. We have successfully alarmed the seagulls.")
		"AncientRelic":
			await _say("Use what on it? I should pick a specific item first.")
		"CustomsShack":
			if GameState.has_flag("has_permit"):
				await _say("Time to see if Pindle's own bureaucracy can be used against him.")
				go_to_room("res://scenes/rooms/customs_shack.tscn")
			else:
				await _say_as("PINDLE", "That shack is for authorized personnel. Which you are not.")
		_:
			await _say("I don't know how to use that on its own.")

func _open(obj: Clickable) -> void:
	match obj.name:
		"SpyglassCrate":
			if not GameState.has_item("spyglass"):
				await _say("Inside the crate: a cracked spyglass and the lingering scent of disappointment.")
				give_item("spyglass")
				spyglass_crate.hide_object()
			else:
				await _say("Already emptied that.")
		"AncientRelic":
			await _say("It doesn't have a lid. It has intent.")
		_:
			await _say("That doesn't open.")

func _push(obj: Clickable) -> void:
	match obj.name:
		"AncientRelic":
			await _say("That was for confidence. Mine, not its.")
		"PindleNPC":
			await _say("Tempting, but assault on officials requires paperwork I don't have.")
		_:
			await _say("Pushing that accomplishes nothing except proving I tried.")

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"AncientRelic":
			match item_name:
				"spyglass":
					await _say("The lens focuses the morning sun onto the wet sand in the recess. It starts to dry and crack.")
					GameState.set_flag("relic_dried")
					return true
				"medallion":
					if GameState.has_flag("relic_dried"):
						await _say("The medallion slides into the recess with a satisfying click. The relic hums.")
						GameState.set_flag("relic_cleaned")
						return true
					else:
						await _say("The recess is still caked with wet sand. I need to dry it first.")
						return true
		"SteamValve":
			match item_name:
				"copper_wire":
					await _say("I jury-rig the wire to the valve handle. Now I can redirect the steam.")
					GameState.set_flag("valve_wired")
					return true
		"CustomsShack":
			match item_name:
				"fake_permit":
					await _say("Let's see if Pindle respects his own paperwork.")
					GameState.set_flag("has_permit")
					go_to_room("res://scenes/rooms/customs_shack.tscn")
					return true
	return false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_tibbit_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	# First conversation
	tree.add_node("start", "ROWAN", "What do you make of this thing?")
	tree.add_node("tibbit_1", "TIBBIT", "A machine. Or a shrine. Or a machine people worshipped because they lacked the self-respect to read instructions.")
	tree.add_choice("start", "Ask about the relic", "relic_q")
	tree.add_choice("start", "Ask about Pindle", "pindle_q")
	tree.add_choice("start", "Ask about yourself", "self_q")

	tree.add_node("relic_q", "TIBBIT", "It's old. Real old. Older than anyone has a right to be and still look that good.")
	tree.add_node("relic_2", "TIBBIT", "See those grooves? Those aren't decorative. That's a lock. Or a dial. Or a very elaborate bottle opener.")
	tree.add_node("relic_3", "ROWAN", "How would I open it?")
	tree.add_node("relic_4", "TIBBIT", "Dry the sand in the recess. Scrape it clean. Then find something that fits. A medallion, maybe.", "end")
	tree.nodes["relic_q"].next_id = "relic_2"
	tree.nodes["relic_2"].next_id = "relic_3"
	tree.nodes["relic_3"].next_id = "relic_4"
	tree.set_node_flag("relic_4", "tibbit_relic_hint")

	tree.add_node("pindle_q", "TIBBIT", "Pindle. Dockmaster. Professionally offended by everything that isn't a form.")
	tree.add_node("pindle_2", "TIBBIT", "He guards the customs shack like it contains the meaning of life. It contains stamps.", "end")
	tree.nodes["pindle_q"].next_id = "pindle_2"
	tree.set_node_flag("pindle_2", "tibbit_pindle_hint")

	tree.add_node("self_q", "TIBBIT", "Me? I fix things. Or break them in interesting ways. The line is thin.")
	tree.add_node("self_2", "TIBBIT", "Name's Tibbit Wrench. Yes, real name. My parents were optimistic.", "end")
	tree.nodes["self_q"].next_id = "self_2"

	tree.add_node("end", "TIBBIT", "Now if you'll excuse me, I need to poke this thing with a screwdriver before Pindle writes a law against it.")

	return tree

func _build_pindle_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "ROWAN", "Dockmaster Pindle, is it?")
	tree.add_node("pindle_1", "PINDLE", "That is correct. And you are unauthorized, unregistered, and unwelcome.")
	tree.nodes["start"].next_id = "pindle_1"
	tree.add_choice("pindle_1", "Ask about the customs shack", "shack_q")
	tree.add_choice("pindle_1", "Ask about permits", "permit_q")
	tree.add_choice("pindle_1", "Insult him gently", "insult_q")

	tree.add_node("shack_q", "PINDLE", "The customs shack is for AUTHORIZED. PERSONNEL. ONLY.")
	tree.add_node("shack_2", "ROWAN", "What makes personnel authorized?")
	tree.add_node("shack_3", "PINDLE", "Paperwork. Specifically, my paperwork. Which I have and you do not.", "end")
	tree.nodes["shack_q"].next_id = "shack_2"
	tree.nodes["shack_2"].next_id = "shack_3"

	tree.add_node("permit_q", "PINDLE", "A salvage permit requires three forms, two signatures, one stamp, and zero imagination.")
	tree.add_node("permit_2", "ROWAN", "Where would I get the forms?")
	tree.add_node("permit_3", "PINDLE", "From the customs shack. Which you cannot enter. Without a permit.", "end")
	tree.nodes["permit_q"].next_id = "permit_2"
	tree.nodes["permit_2"].next_id = "permit_3"
	tree.set_node_flag("permit_3", "pindle_permit_hint")

	tree.add_node("insult_q", "ROWAN", "Has anyone ever told you that you have the warmth of a tax audit?")
	tree.add_node("insult_2", "PINDLE", "Frequently. I take it as a compliment.", "end")
	tree.nodes["insult_q"].next_id = "insult_2"

	tree.add_node("end", "PINDLE", "Now move along. This object is under official investigation, which means no one is allowed to investigate it.")

	return tree
