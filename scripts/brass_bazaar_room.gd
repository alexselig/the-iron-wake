extends AdventureRoom

## Brass Bazaar — Act 1, Room 4
## Cluttered market maze. Mirelle Soot has the Focusing Disc.
## PUZZLE 3: Bazaar Bluff — eavesdrop jargon, get badge + teacup, bluff Mirelle.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var mirelle_npc: Area2D
var mech_parrot: Area2D
var copper_masks: Area2D
var fake_springs: Area2D
var guild_badge: Area2D
var fancy_teacup: Area2D
var noble_stall: Area2D
var door_warehouse: Area2D
var door_workshop: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act1_04_brass_bazaar.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	# Mirelle Soot — center of her stall
	SceneBuilder.build_npc(props, "MirelleNPC", Vector2(320, 275),
		"Mirelle Soot", "mirelle", Vector2(-25, 10), true, Vector2(45, 55))

	# Mechanical Parrot — on a perch above
	SceneBuilder.build_hotspot(props, "MechParrot", Vector2(380, 220),
		"the mechanical parrot", Vector2(-10, 45), Vector2(30, 30))

	# Pile of copper masks
	SceneBuilder.build_hotspot(props, "CopperMasks", Vector2(180, 265),
		"a pile of copper masks", Vector2(15, 15), Vector2(40, 30))

	# Box of fake springs
	SceneBuilder.build_hotspot(props, "FakeSprings", Vector2(460, 270),
		"a box of 'Authentic Ancient Springs'", Vector2(-15, 10), Vector2(35, 30))

	# Broken guild badge — on the ground near a stall
	SceneBuilder.build_prop(props, "GuildBadge", Vector2(140, 290),
		"a broken guild badge", "res://assets/props/broken_gear.png",
		Vector2(15, 0), true, false, Vector2(24, 24))

	# Fancy teacup — on a merchant's table
	SceneBuilder.build_prop(props, "FancyTeacup", Vector2(500, 260),
		"a fancy teacup", "res://assets/props/oilskin_pouch.png",
		Vector2(-15, 15), true, false, Vector2(24, 24))

	# Noble stall — eavesdropping spot
	SceneBuilder.build_hotspot(props, "NobleStall", Vector2(240, 240),
		"a stall with well-dressed customers", Vector2(20, 35), Vector2(50, 40))

	# Exits
	SceneBuilder.build_hotspot(hotspots, "DoorWarehouse", Vector2(60, 270),
		"back to the warehouse", Vector2(30, 10), Vector2(40, 50))

	SceneBuilder.build_hotspot(hotspots, "DoorWorkshop", Vector2(600, 270),
		"toward Tibbit's workshop", Vector2(-30, 10), Vector2(40, 50))

func _get_music_path() -> String:
	return "res://assets/music/bazaar_ambient.wav"

func _on_room_ready() -> void:
	room_name = "brass_bazaar"

	mirelle_npc = $Props/MirelleNPC
	mech_parrot = $Props/MechParrot
	copper_masks = $Props/CopperMasks
	fake_springs = $Props/FakeSprings
	guild_badge = $Props/GuildBadge
	fancy_teacup = $Props/FancyTeacup
	noble_stall = $Props/NobleStall
	door_warehouse = $Hotspots/DoorWarehouse
	door_workshop = $Hotspots/DoorWorkshop

	for node in [mirelle_npc, mech_parrot, copper_masks, fake_springs,
				 guild_badge, fancy_teacup, noble_stall, door_warehouse, door_workshop]:
		if node:
			connect_clickable(node)

	speaker_to_node = {
		"MIRELLE": "MirelleNPC",
	}

	if GameState.has_item("guild_badge") and guild_badge:
		guild_badge.hide_object()
	if GameState.has_item("fancy_teacup") and fancy_teacup:
		fancy_teacup.hide_object()

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"tibbit_workshop":
			return Vector2(560, 290)
		_:
			return Vector2(80, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	await _say("The Brass Bazaar. Where junk becomes treasure and treasure becomes junk, depending on how convincing you are.")
	await _say_as("MIRELLE", "Welcome to Soot and Sundries. Buy quickly, doubt later.")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"MirelleNPC":
			await _say("Mirelle Soot. Dealer in things that fell off other things. Sharp eyes, sharper prices.")
		"MechParrot":
			# Parrot shouts random gossip — useful clue source
			var lines := [
				"ROOK BUYS QUIETLY. ROOK PAYS POORLY.",
				"THIRD CONSERVATORY CIRCLE MEETING POSTPONED.",
				"LIGHTHOUSE PARTS IN DEMAND. PRICE UP.",
				"PROVISIONAL SURVEY CLASS NOW BOARDING.",
			]
			var idx := randi() % lines.size()
			await _say("The mechanical parrot squawks:")
			await _say_as("ROWAN", lines[idx])
			if not GameState.has_flag("heard_parrot"):
				await _say("Finally, a bird with editorial standards.")
				GameState.set_flag("heard_parrot")
			# The parrot gives jargon clues
			if "CONSERVATORY" in lines[idx] or "SURVEY" in lines[idx]:
				GameState.set_flag("heard_jargon")
		"CopperMasks":
			await _say("Theatrical, unsettling, and somehow already judging me.")
		"FakeSprings":
			await _say("These were made last week and insultingly so.")
		"GuildBadge":
			await _say("A broken guild badge. The crest is scratched but the arrogance is intact.")
		"FancyTeacup":
			await _say("An ornate teacup. The kind carried by people who want you to know they own an ornate teacup.")
		"NobleStall":
			if not GameState.has_flag("eavesdropped"):
				await _say("Two well-dressed merchants haggle over something I can't see.")
				await _say("I catch phrases: 'Third Conservatory Circle,' 'provisional survey class,' 'preservation review.'")
				await _say("Those sound like words that could open doors. Or at least impress people who open doors.")
				GameState.set_flag("eavesdropped")
				GameState.set_flag("heard_jargon")
			else:
				await _say("The merchants are still negotiating. This could take all day.")
		"DoorWarehouse":
			await _say("Back toward the salvage warehouse.")
		"DoorWorkshop":
			await _say("The path to Tibbit's workshop cart.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"MirelleNPC":
			var tree := _build_mirelle_dialogue()
			await run_dialogue_tree(tree)
		"MechParrot":
			await _look_at(obj)  # Parrot "talks" via look
		"NobleStall":
			await _say("I'd rather listen than announce myself. Eavesdropping is the polite word for research.")
			if not GameState.has_flag("eavesdropped"):
				await _look_at(obj)
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"GuildBadge":
			if not GameState.has_item("guild_badge"):
				await _say("I pocket the badge. It's broken, but confidence is a glue.")
				give_item("guild_badge")
				guild_badge.hide_object()
			else:
				await _say("I already have it.")
		"FancyTeacup":
			if not GameState.has_item("fancy_teacup"):
				await _say("I borrow the teacup. Its previous owner seems to have left in a hurry or a huff.")
				give_item("fancy_teacup")
				fancy_teacup.hide_object()
			else:
				await _say("One cup of pretension is enough.")
		"MechParrot":
			await _say("I reach for the parrot. It snaps at me. Fair enough.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"DoorWarehouse":
			go_to_room("res://scenes/rooms/salvage_warehouse.tscn")
		"DoorWorkshop":
			go_to_room("res://scenes/rooms/tibbit_workshop.tscn")
		"MirelleNPC":
			if _can_bluff():
				await _attempt_bluff()
			else:
				await _say("I need to be more convincing before approaching Mirelle with a deal.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"DoorWarehouse":
			go_to_room("res://scenes/rooms/salvage_warehouse.tscn")
		"DoorWorkshop":
			go_to_room("res://scenes/rooms/tibbit_workshop.tscn")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"MechParrot":
			await _say("I nudge the parrot. It shrieks. Several customers glare.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

# ============================================================
# USE ITEM ON
# ============================================================

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"MirelleNPC":
			if item_name == "guild_badge" and GameState.has_flag("heard_jargon") and GameState.has_item("fancy_teacup"):
				await _attempt_bluff()
				return true
			elif item_name == "guild_badge":
				await _say_as("MIRELLE", "That badge is upside down and from a stove manufacturer.")
				return true
			elif item_name == "fancy_teacup":
				await _say_as("MIRELLE", "Pretty cup. Doesn't buy you anything except tea, which I don't sell.")
				return true
	return false

# ============================================================
# PUZZLE 3: BAZAAR BLUFF
# ============================================================

func _can_bluff() -> bool:
	return GameState.has_item("guild_badge") and GameState.has_item("fancy_teacup") and GameState.has_flag("heard_jargon")

func _attempt_bluff() -> void:
	is_busy = true
	_in_scripted_sequence = true

	await _say("Third Conservatory Circle. Provisional survey class. We're reclaiming the Hushlight apparatus for preservation review.")
	await _say_as("MIRELLE", "And the cup?")
	await _say("Status hydration.")

	await get_tree().create_timer(0.3).timeout
	await _say_as("MIRELLE", "Ha! You're either very brave or very desperate. Either way, I'm entertained.")

	# Get the focusing disc
	give_item("focusing_disc")
	take_item("guild_badge")
	take_item("fancy_teacup")

	await _say_as("MIRELLE", "One focusing disc. Handle with more care than you've shown so far.")

	await get_tree().create_timer(0.3).timeout
	await _say_as("MIRELLE", "One warning, darling. People have started asking after those old lighthouse parts.")
	await _say_as("MIRELLE", "Wealthy people. Calm people. The worst kind.")

	GameState.set_flag("got_focusing_disc")
	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# DIALOGUE TREES
# ============================================================

func _build_mirelle_dialogue() -> DialogueTree:
	var tree := DialogueTree.new()

	tree.add_node("start", "MIRELLE", "What can I get you? And don't say 'a deal.' Everyone says that.")
	tree.add_choice("start", "I need a lighthouse lens", "lens_q")
	tree.add_choice("start", "What do you know about Rook?", "rook_q")
	tree.add_choice("start", "Attempt the bluff", "bluff_q", "heard_jargon")

	tree.add_node("lens_q", "MIRELLE", "Of course you do. Everybody does eventually. Mostly after falling.")
	tree.add_node("lens_2", "ROWAN", "How much?")
	tree.add_node("lens_3", "MIRELLE", "For you? Not money. Something rarer.")
	tree.add_node("lens_4", "ROWAN", "Reasonable behavior?")
	tree.add_node("lens_5", "MIRELLE", "No, I'm stocked on that. I want something prestigious enough to be pointless.", "end")
	tree.nodes["lens_q"].next_id = "lens_2"
	tree.nodes["lens_2"].next_id = "lens_3"
	tree.nodes["lens_3"].next_id = "lens_4"
	tree.nodes["lens_4"].next_id = "lens_5"
	tree.set_node_flag("lens_5", "mirelle_wants_prestige")

	tree.add_node("rook_q", "MIRELLE", "Commodore Rook? Buys quiet. Pays poorly. Wants everything old and shiny.")
	tree.add_node("rook_2", "MIRELLE", "He's been buying lighthouse parts for weeks. Doesn't say why. Never does.", "end")
	tree.nodes["rook_q"].next_id = "rook_2"
	tree.set_node_flag("rook_2", "mirelle_rook_hint")

	tree.add_node("bluff_q", "ROWAN", "Third Conservatory Circle. Provisional survey class.")
	tree.nodes["bluff_q"].next_id = "bluff_check"

	# This triggers the bluff if they have the items
	tree.add_node("bluff_check", "MIRELLE", "That sounds official. What's the cup for?")
	tree.nodes["bluff_check"].next_id = "end"

	tree.add_node("end", "MIRELLE", "Come back when you have something worth trading. Or at least worth laughing at.")

	return tree
