extends AdventureRoom

## Blackwake Harbor — Act 1, Room 1
## The storm-lashed beach where the ancient relic washed ashore.
## PUZZLE 1: Activate the Relic
##   1. Pick up Spyglass from crate
##   2. Use Spyglass on Relic → dries wet sand in recess
##   3. Talk to Crowd → provoke Fishmonger → distracts Pindle
##   4. Pick up Stamp (while Pindle distracted)
##   5. Use Stamp on Relic → scrapes dried sand out
##   6. Medallion auto-inserts → relic partially activates
##   7. Use Steam Valve → resonance tone fully activates relic
##   8. Memory vision cutscene → receive Brass Strip → go to Customs Shack

const SceneBuilder = preload("res://scripts/scene_builder.gd")

# NEW version: the ancient relic shows a distinct visual for each story beat so
# the player can read the puzzle's progress at a glance. (Original keeps the
# single static capsule sprite.)
const RELIC_STATES := {
	"dormant": "res://assets_new/props/relic/dormant.png",
	"dried": "res://assets_new/props/relic/dried.png",
	"scraped": "res://assets_new/props/relic/scraped.png",
	"medallion": "res://assets_new/props/relic/medallion.png",
	"active": "res://assets_new/props/relic/active.png",
}

func _relic_state() -> String:
	if GameState.has_flag("relic_activated"):
		return "active"
	if GameState.has_flag("medallion_inserted"):
		return "medallion"
	if GameState.has_flag("recess_scraped"):
		return "scraped"
	if GameState.has_flag("relic_dried"):
		return "dried"
	return "dormant"

func _update_relic_visual() -> void:
	if not GameState.use_new_assets or not ancient_relic:
		return
	var spr: Sprite2D = ancient_relic.get_node_or_null("Sprite")
	if spr == null:
		return
	var tex := _load_texture(RELIC_STATES[_relic_state()])
	if tex == null:
		return
	spr.texture = tex
	# Size the relic to sit over the painted dome in the background.
	var target_w := 152.0
	var s := target_w / tex.get_size().x
	spr.scale = Vector2(s, s)
	spr.position = Vector2(0, -10)

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
var stamp_prop: Area2D

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

func _get_music_path() -> String:
	return "res://assets/music/harbor_ambient.wav"

func _on_room_ready() -> void:
	room_name = "blackwake_harbor"

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
	stamp_prop = $Props/StampProp

	for node in [ancient_relic, spyglass_crate, steam_valve, warning_placard,
				 docks, customs_shack, seawall, tibbit_npc, pindle_npc, crowd, stamp_prop]:
		if node:
			connect_clickable(node)

	speaker_to_node = {
		"TIBBIT": "TibbitNPC",
		"PINDLE": "PindleNPC",
	}

	# Hide spyglass crate if already picked up
	if GameState.has_item("spyglass") and spyglass_crate:
		spyglass_crate.hide_object()

	# Show stamp if Pindle is distracted and not yet picked up
	if GameState.has_flag("pindle_distracted") and not GameState.has_item("stamp") and stamp_prop:
		stamp_prop.show_object()

	# Hide stamp if already picked up
	if GameState.has_item("stamp") and stamp_prop:
		stamp_prop.hide_object()

	# Give player the medallion at start (it's Rowan's)
	if not GameState.has_item("medallion") and not GameState.has_flag("medallion_inserted"):
		give_item("medallion")

	# NEW: set the relic to the right story-state visual (also restores it on revisit).
	_update_relic_visual()

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

	await get_tree().create_timer(0.3).timeout
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
	style.bg_color = Color(0, 0, 0, 0.8)
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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	title.add_theme_font_size_override("font_size", 20)
	# Fake-bold: matching outline thickens the strokes (project has no bold font)
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.95, 0.8, 0.35))
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
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.4)
	await tw.finished

	var clicked := false
	while not clicked:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("examine") \
				or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE):
			clicked = true

	var tw2 := create_tween()
	tw2.tween_property(overlay, "modulate:a", 0.0, 0.3)
	await tw2.finished
	overlay.queue_free()

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"AncientRelic":
			if GameState.has_flag("relic_activated"):
				await _say("It's open now. Geometric patterns pulse softly. It looks... expectant.")
			elif GameState.has_flag("medallion_inserted"):
				await _say("The medallion is in place. The relic hums faintly but needs something more.")
			elif GameState.has_flag("recess_scraped"):
				await _say("The recess is clean. Something circular fits here. Something old and familiar.")
			elif GameState.has_flag("relic_dried"):
				await _say("The sand is dry and cracked. I could scrape it out with something flat.")
			else:
				await _say("Smooth, seamless, and smug. I've met wealthy people less polished than this.")
				if not GameState.has_examined("relic_recess"):
					await _say("There's a circular recess packed with wet sand and fine salt crust.")
					GameState.mark_examined("relic_recess")
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
			if GameState.has_flag("pindle_distracted"):
				await _say("Pindle is deep in a furious debate about fish ownership. Good.")
			else:
				await _say("A uniform containing a small man and a large sense of jurisdiction.")
		"Crowd":
			await _say("Opportunists, mystics, and people pretending they were here first.")
			if not GameState.has_examined("fishmonger"):
				await _say("A fishmonger near the front looks particularly territorial.")
				GameState.mark_examined("fishmonger")
		"StampProp":
			await _say("Pindle's inspection stamp. A block of wood on a handle. The chosen scepter of tiny authority.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"TibbitNPC":
			var tree := _build_tibbit_dialogue()
			await run_dialogue_tree(tree)
		"PindleNPC":
			if GameState.has_flag("pindle_distracted"):
				await _say_as("PINDLE", "NOT NOW! This man claims fish have property rights!")
			else:
				var tree := _build_pindle_dialogue()
				await run_dialogue_tree(tree)
		"Crowd":
			if not GameState.has_flag("pindle_distracted"):
				var tree := _build_crowd_dialogue()
				await run_dialogue_tree(tree)
				# If Pindle just got distracted, reveal the stamp
				if GameState.has_flag("pindle_distracted") and stamp_prop and not GameState.has_item("stamp"):
					stamp_prop.show_object()
					await _say("Pindle's stamp is sitting unattended on his crate. Interesting.")
			else:
				await _say("The crowd is enjoying the Pindle-Fishmonger show. Best entertainment all week.")
		"AncientRelic":
			await _say("I'm not saying it bit me. I'm saying we now have a hostile understanding.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

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
		"StampProp":
			if not GameState.has_item("stamp"):
				await _say("I grab the stamp while Pindle's busy arguing. He won't miss it for minutes.")
				give_item("stamp")
				stamp_prop.hide_object()
			else:
				await _say("I already have it.")
		"PindleNPC":
			await _say("I can't pick up an entire bureaucrat. Tempting though.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"Docks":
			if GameState.has_flag("has_permit"):
				await _say("Time to check the salvage warehouse.")
				go_to_room("res://scenes/rooms/salvage_warehouse.tscn")
			else:
				await _say("The docks lead to the salvage warehouse, but I need a permit first.")
		"SteamValve":
			if GameState.has_flag("medallion_inserted"):
				await _say("Let's see if a resonance tone wakes it.")
				await _play_relic_activation()
			elif GameState.has_flag("recess_scraped"):
				await _say("The valve blares. The relic shudders but nothing happens. Something needs to go in that recess first.")
			else:
				await _say("The crane horn blares. Gulls scatter. Nothing else happens.")
				await _say_as("TIBBIT", "Excellent. We have successfully alarmed the seagulls.")
		"AncientRelic":
			await _say("Use what on it? I should pick a specific item first.")
		"CustomsShack":
			if GameState.has_flag("has_permit"):
				go_to_room("res://scenes/rooms/customs_shack.tscn")
			else:
				await _say_as("PINDLE", "That shack is for authorized personnel. Which you are not.")
		_:
			await _say(_random_response(_USE_RESPONSES))

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
		"CustomsShack":
			if GameState.has_flag("has_permit"):
				go_to_room("res://scenes/rooms/customs_shack.tscn")
			else:
				await _say_as("PINDLE", "Door stays shut until paperwork opens it.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"AncientRelic":
			await _say("That was for confidence. Mine, not its.")
		"PindleNPC":
			await _say("Tempting, but assault on officials requires paperwork I don't have.")
		"Crowd":
			await _say("Pushing through this lot would require a permit. Probably.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

# ============================================================
# USE ITEM ON
# ============================================================

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"AncientRelic":
			match item_name:
				"spyglass":
					if not GameState.has_flag("relic_dried"):
						await _say("The cracked lens focuses the morning sun onto the wet sand in the recess.")
						await _say("It starts to dry and crack. Good.")
						GameState.set_flag("relic_dried")
						_update_relic_visual()
						return true
					else:
						await _say("The sand is already dry. I need to scrape it out now.")
						return true
				"stamp":
					if GameState.has_flag("relic_dried") and not GameState.has_flag("recess_scraped"):
						await _say("The flat edge of the stamp handle scrapes the dried sand out of the recess perfectly.")
						await _say("Underneath: a circular groove with geometric patterns. My medallion would fit.")
						GameState.set_flag("recess_scraped")
						_update_relic_visual()
						return true
					elif not GameState.has_flag("relic_dried"):
						await _say("The sand is still wet. The stamp just smears it around. I need to dry it first.")
						return true
					else:
						await _say("The recess is already clean.")
						return true
				"medallion":
					if GameState.has_flag("recess_scraped"):
						await _say("The medallion slides into the groove with a satisfying click.")
						await _say("The relic hums. Faint lines of blue-white light trace across its surface.")
						await _say_as("TIBBIT", "That's new! That's very new! What did you do?")
						await _say("Something I've apparently been meant to do since childhood.")
						GameState.set_flag("medallion_inserted")
						take_item("medallion")
						_update_relic_visual()
						return true
					elif GameState.has_flag("relic_dried"):
						await _say("I'm not grinding a mystery heirloom into dried sand. I should scrape the recess clean first.")
						return true
					else:
						await _say("I'm not grinding a mystery heirloom into wet beach paste.")
						return true
				_:
					await _say("The relic doesn't respond to that.")
					return true
		"SteamValve":
			await _say("The valve works on its own. I just need to pull it.")
			return true
		"CustomsShack":
			match item_name:
				"fake_permit":
					await _say("Let's see if Pindle respects his own paperwork.")
					GameState.set_flag("has_permit")
					go_to_room("res://scenes/rooms/customs_shack.tscn")
					return true
		"PindleNPC":
			match item_name:
				"stamp":
					await _say("Giving it back seems counterproductive.")
					return true
	return false

func _on_combine_items(item_a: String, item_b: String) -> bool:
	# Stamp + Medallion doesn't make sense
	return false

# ============================================================
# RELIC ACTIVATION CUTSCENE
# ============================================================

func _play_relic_activation() -> void:
	_in_scripted_sequence = true

	await _say_as("TIBBIT", "It's humming! That's either progress or a countdown.")

	GameState.set_flag("relic_activated")
	_update_relic_visual()

	# Relic opens — memory vision
	await get_tree().create_timer(0.5).timeout
	await _say("The relic unfolds. White lines spiral outward. A hovering map fragment appears.")

	# Fade to memory vision
	fade_overlay.visible = true
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color", Color(1, 1, 1, 1), 1.0)
	await tw.finished

	# Allow clicks through so dialogue can be advanced during the vision
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().create_timer(0.5).timeout
	await _say("White stone steps. Children running. A woman fastens the medallion on young Rowan.")
	await _say("'When the sea remembers, you must return.'")

	# Fade back
	var tw2 := create_tween()
	tw2.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 1.0)
	await tw2.finished
	fade_overlay.visible = false

	await get_tree().create_timer(0.3).timeout
	await _say_as("TIBBIT", "You vanished for a second.")
	await _say("I was standing right here.")
	await _say_as("TIBBIT", "Physically, yes. Spiritually, your expression went somewhere expensive.")

	# Relic ejects items
	give_item("brass_strip")
	give_item("medallion")
	await _say("The relic ejects the medallion and an engraved brass strip. Symbols match the map fragment.")
	await _say("Good. The sea has started giving me homework.")

	await _say_as("TIBBIT", "The warehouse has salvage records. We might find a match for those symbols.")
	await _say_as("TIBBIT", "But Pindle won't let you in without a permit. Which he also won't give you.")
	await _say("So I need to make my own. Charming.")

	GameState.set_flag("need_permit")
	_in_scripted_sequence = false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_tibbit_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "ROWAN", "What do you make of this thing?")
	tree.add_choice("start", "Ask about the relic", "relic_q")
	tree.add_choice("start", "Ask about Pindle", "pindle_q")
	tree.add_choice("start", "Ask about the medallion", "medallion_q", "recess_scraped")

	tree.add_node("relic_q", "TIBBIT", "It's old. Real old. Older than anyone has a right to be and still look that good.")
	tree.add_node("relic_2", "TIBBIT", "See those grooves? Those aren't decorative. That's a lock. Or a dial. Or a very elaborate bottle opener.")
	tree.add_node("relic_3", "ROWAN", "How would I open it?")
	tree.add_node("relic_4", "TIBBIT", "Dry the sand in the recess. Scrape it clean. Then find something that fits.", "end")
	tree.nodes["relic_q"].next_id = "relic_2"
	tree.nodes["relic_2"].next_id = "relic_3"
	tree.nodes["relic_3"].next_id = "relic_4"
	tree.set_node_flag("relic_4", "tibbit_relic_hint")

	tree.add_node("pindle_q", "TIBBIT", "Pindle. Dockmaster. Professionally offended by everything that isn't a form.")
	tree.add_node("pindle_2", "TIBBIT", "He guards the customs shack like it contains the meaning of life. It contains stamps.", "end")
	tree.nodes["pindle_q"].next_id = "pindle_2"
	tree.set_node_flag("pindle_2", "tibbit_pindle_hint")

	tree.add_node("medallion_q", "TIBBIT", "That medallion you wear? Put it in the recess. Trust me.")
	tree.add_node("medallion_2", "ROWAN", "You said that too quickly.")
	tree.add_node("medallion_3", "TIBBIT", "That's how certainty sounds.", "end")
	tree.nodes["medallion_q"].next_id = "medallion_2"
	tree.nodes["medallion_2"].next_id = "medallion_3"

	tree.add_node("end", "TIBBIT", "Now if you'll excuse me, I need to poke this thing with a screwdriver before Pindle writes a law against it.")
	return tree

func _build_pindle_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "ROWAN", "Dockmaster Pindle, is it?")
	tree.add_node("pindle_1", "PINDLE", "That is correct. And you are unauthorized, unregistered, and unwelcome.")
	tree.nodes["start"].next_id = "pindle_1"
	tree.add_choice("pindle_1", "Ask about permits", "permit_q")
	tree.add_choice("pindle_1", "Ask about the stamp", "stamp_q")
	tree.add_choice("pindle_1", "Insult him gently", "insult_q")

	tree.add_node("permit_q", "PINDLE", "A salvage permit requires three forms, two signatures, one stamp, and zero imagination.")
	tree.add_node("permit_2", "ROWAN", "Where would I get the forms?")
	tree.add_node("permit_3", "PINDLE", "From the customs shack. Which you cannot enter. Without a permit.", "end")
	tree.nodes["permit_q"].next_id = "permit_2"
	tree.nodes["permit_2"].next_id = "permit_3"
	tree.set_node_flag("permit_3", "pindle_permit_hint")

	tree.add_node("stamp_q", "ROWAN", "Can I borrow your stamp?")
	tree.add_node("stamp_2", "PINDLE", "Certainly not. That stamp is for trained personnel.")
	tree.add_node("stamp_3", "ROWAN", "You stamp boxes.")
	tree.add_node("stamp_4", "PINDLE", "And yet, not everyone is qualified.", "end")
	tree.nodes["stamp_q"].next_id = "stamp_2"
	tree.nodes["stamp_2"].next_id = "stamp_3"
	tree.nodes["stamp_3"].next_id = "stamp_4"

	tree.add_node("insult_q", "ROWAN", "Has anyone ever told you that you have the warmth of a tax audit?")
	tree.add_node("insult_2", "PINDLE", "Frequently. I take it as a compliment.", "end")
	tree.nodes["insult_q"].next_id = "insult_2"

	tree.add_node("end", "PINDLE", "Now move along. This object is under official investigation, which means no one is allowed to investigate it.")
	return tree

func _build_crowd_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "ROWAN", "Anyone here have strong opinions about fish?")
	tree.add_choice("start", "Provoke the fishmonger", "provoke")
	tree.add_choice("start", "Ask about the relic", "relic_q")

	tree.add_node("provoke", "ROWAN", "Excuse me — didn't this relic land right on your fish stall?")
	tree.add_node("provoke_2", "ROWAN", "Under maritime law, that probably makes it yours.")
	tree.add_node("provoke_3", "ROWAN", "Someone should tell the Dockmaster.")
	tree.nodes["provoke"].next_id = "provoke_2"
	tree.nodes["provoke_2"].next_id = "provoke_3"
	tree.add_node("fishmonger_1", "ROWAN", "The fishmonger storms over to Pindle. This should keep him busy.")
	tree.nodes["provoke_3"].next_id = "fishmonger_1"
	tree.set_node_flag("fishmonger_1", "pindle_distracted")

	tree.add_node("relic_q", "ROWAN", "What do people think that thing is?")
	tree.add_node("relic_2", "ROWAN", "The crowd has theories. None of them agree. Several involve prophecy.")
	tree.nodes["relic_q"].next_id = "relic_2"

	return tree
