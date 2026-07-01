extends AdventureRoom

## Undercliff Smuggler Path — Act 2, Room 9
## Narrow trail below Blackwake. Puzzle 1: Cross the Tide Bridge.

const SceneBuilder = preload("res://scripts/scene_builder.gd")

var cliff_lift: Area2D
var signal_lantern: Area2D
var contraband_crate: Area2D
var rope_bridge: Area2D
var smuggler_graffiti: Area2D
var speaking_tube: Area2D
var path_back: Area2D
var path_forward: Area2D

func _load_room_background() -> void:
	var bg: Sprite2D = $Background
	var tex := _load_texture("res://assets/backgrounds/act2_01_smuggler_path.png")
	if tex:
		bg.texture = tex

func _build_room() -> void:
	var props := $Props
	var hotspots := $Hotspots
	SceneBuilder.build_player_sprite($Player)

	SceneBuilder.build_prop(props, "CliffLift", Vector2(380, 250),
		"the cliff lift", "res://assets/props/chain_hoist.png",
		Vector2(-20, 25), false, false, Vector2(44, 50))

	SceneBuilder.build_prop(props, "SignalLantern", Vector2(200, 240),
		"a signal lantern", "res://assets/props/signal_lantern.png",
		Vector2(15, 30), false, false, Vector2(28, 36))

	SceneBuilder.build_prop(props, "ContrabandCrate", Vector2(140, 275),
		"a contraband crate", "res://assets/props/lighthouse_crate.png",
		Vector2(15, 10), false, false, Vector2(40, 32))

	SceneBuilder.build_hotspot(props, "RopeBridge", Vector2(450, 260),
		"the rope bridge", Vector2(-30, 15), Vector2(80, 30))

	SceneBuilder.build_hotspot(props, "SmugglerGraffiti", Vector2(100, 220),
		"smuggler graffiti", Vector2(20, 45), Vector2(40, 30))

	SceneBuilder.build_hotspot(props, "SpeakingTube", Vector2(300, 230),
		"an old speaking tube", Vector2(0, 35), Vector2(24, 30))

	SceneBuilder.build_hotspot(hotspots, "PathBack", Vector2(60, 270),
		"the lighthouse stairs", Vector2(30, 10), Vector2(40, 60))

	SceneBuilder.build_hotspot(hotspots, "PathForward", Vector2(580, 260),
		"the marsh path", Vector2(-30, 15), Vector2(40, 60))

	# Hide forward path until bridge is crossed
	if not GameState.has_flag("bridge_crossed"):
		path_forward = $Hotspots/PathForward
		if path_forward:
			path_forward.hide_object()

func _get_music_path() -> String:
	return "res://assets/music/lighthouse_ambient.wav"

func _on_room_ready() -> void:
	room_name = "smuggler_path"

	cliff_lift = $Props/CliffLift
	signal_lantern = $Props/SignalLantern
	contraband_crate = $Props/ContrabandCrate
	rope_bridge = $Props/RopeBridge
	smuggler_graffiti = $Props/SmugglerGraffiti
	speaking_tube = $Props/SpeakingTube
	path_back = $Hotspots/PathBack
	path_forward = $Hotspots/PathForward

	speaker_to_node = {}

	for node in [cliff_lift, signal_lantern, contraband_crate, rope_bridge,
				 smuggler_graffiti, speaking_tube, path_back, path_forward]:
		if node:
			connect_clickable(node)

	if GameState.has_item("ceramic_bottles") and contraband_crate:
		contraband_crate.description = "an empty contraband crate"

func _get_entry_position() -> Vector2:
	match GameState.previous_room:
		"brackmarsh":
			return Vector2(550, 285)
		_:
			return Vector2(120, 290)

func _play_intro() -> void:
	is_busy = true
	_in_scripted_sequence = true

	if fade_overlay:
		var tw := create_tween()
		tw.tween_property(fade_overlay, "color:a", 0.0, 0.8)
		await tw.finished
		fade_overlay.visible = false

	if not GameState.has_flag("act2_intro_seen"):
		# Act 2 opening
		await _say_as("TIBBIT", "Well. Either destiny just waved at us, or the ocean has developed sarcasm.")
		await _say("I'm beginning to suspect that runs in my family.")
		await _say("I check the Map Plate. Three tower marks glow. The first pulses inland.")
		await _say("That one.")
		await _say_as("TIBBIT", "Excellent. I was hoping fate would provide directions, because I packed enthusiasm and almost nothing useful.")
		GameState.set_flag("act2_intro_seen")
	else:
		await _say("The smuggler path. Salt spray, rusty lifts, and a bridge that's seen better centuries.")

	_in_scripted_sequence = false
	is_busy = false

# ============================================================
# VERB ACTIONS
# ============================================================

func _look_at(obj: Clickable) -> void:
	match obj.name:
		"CliffLift":
			await _say("Held together by rope, optimism, and previous owners' lies.")
			if not GameState.has_flag("examined_lift"):
				await _say("The counterweight basket is empty. Without ballast, the lift can't tension the bridge cable.")
				GameState.set_flag("examined_lift")
		"SignalLantern":
			await _say("A brass signal lantern with shuttered panels. The shutter bracket looks detachable.")
			if not GameState.has_flag("examined_lantern"):
				await _say("Could be useful for locking something in place.")
				GameState.set_flag("examined_lantern")
		"ContrabandCrate":
			if GameState.has_item("ceramic_bottles"):
				await _say("Empty now. The bottles served a better purpose as ballast.")
			else:
				await _say("A crate wedged into an alcove. Smuggler's cache, probably.")
				if not GameState.has_flag("opened_crate"):
					await _say("It's nailed shut but the wood is rotten.")
		"RopeBridge":
			if GameState.has_flag("bridge_crossed"):
				await _say("The bridge holds steady now. My engineering career peaks here.")
			else:
				await _say("The rope bridge is broken halfway across. Planks dangle over surf.")
				await _say("The lift cable connects to the bridge tension system. If the lift had counterweight...")
		"SmugglerGraffiti":
			await _say("'NO KING BUT PROFIT.' Charming. History always begins with someone believing theft is philosophy.")
		"SpeakingTube":
			await _say("A pipe for shouting at distances. Blackwake's second favorite civic institution.")
		"PathBack":
			await _say("The stairs back up to the lighthouse.")
		"PathForward":
			await _say("The path continues into the marshes.")
		_:
			await _say(_random_response(_LOOK_RESPONSES))

func _talk_to(obj: Clickable) -> void:
	match obj.name:
		"SpeakingTube":
			await _say("Hello? ... The tube responds with the distant sound of dripping. Riveting conversation.")
		_:
			await _say(_random_response(_TALK_RESPONSES))

func _pick_up(obj: Clickable) -> void:
	match obj.name:
		"SignalLantern":
			await _say("It's bolted to the cliff face. But the shutter bracket is loose...")
		"ContrabandCrate":
			if not GameState.has_item("ceramic_bottles") and not GameState.has_flag("opened_crate"):
				await _say("I pry open the rotten wood. Inside: dense ceramic bottles. Heavy. Perfect ballast.")
				give_item("ceramic_bottles")
				GameState.set_flag("opened_crate")
			elif GameState.has_item("ceramic_bottles"):
				await _say("Already emptied it.")
			else:
				await _say("Nothing left in the crate.")
		_:
			await _say(_random_response(_PICK_UP_RESPONSES))

func _use(obj: Clickable) -> void:
	match obj.name:
		"PathBack":
			go_to_room("res://scenes/rooms/lighthouse_chamber.tscn")
		"PathForward":
			if GameState.has_flag("bridge_crossed"):
				go_to_room("res://scenes/rooms/brackmarsh.tscn")
			else:
				await _say("The bridge is broken. I need to fix it first.")
		"RopeBridge":
			if GameState.has_flag("bridge_crossed"):
				go_to_room("res://scenes/rooms/brackmarsh.tscn")
			else:
				await _say("I support boldness in theory. In practice, I prefer not to become a cautionary splash.")
		"CliffLift":
			if GameState.has_flag("lift_loaded") and GameState.has_flag("line_redirected") and GameState.has_flag("line_locked"):
				await _say("The lift descends. The cable tightens. The bridge groans... and holds.")
				await _say("Ancient markings visible on the inner cliff face. Same sequence from the lighthouse.")
				await _say("Someone built this route over something older.")
				await _say_as("TIBBIT", "Blackwake in one sentence.")
				GameState.set_flag("bridge_crossed")
				if path_forward:
					path_forward.show_object()
			elif not GameState.has_flag("lift_loaded"):
				await _say("The lift basket is empty. I need something heavy for counterweight.")
			elif not GameState.has_flag("line_redirected"):
				await _say("The ballast is loaded but the cable goes the wrong way. I need to redirect it to the bridge.")
			elif not GameState.has_flag("line_locked"):
				await _say("Almost. The redirected line needs to be locked in place.")
		"SignalLantern":
			await _say("I flip the shutters. The lantern winks into the fog. Nobody answers. Typical.")
		_:
			await _say(_random_response(_USE_RESPONSES))

func _open(obj: Clickable) -> void:
	match obj.name:
		"ContrabandCrate":
			await _pick_up(obj)
		"PathBack":
			go_to_room("res://scenes/rooms/lighthouse_chamber.tscn")
		"PathForward":
			if GameState.has_flag("bridge_crossed"):
				go_to_room("res://scenes/rooms/brackmarsh.tscn")
			else:
				await _say("The bridge is out. Can't get across.")
		_:
			await _say(_random_response(_OPEN_RESPONSES))

func _push(obj: Clickable) -> void:
	match obj.name:
		"CliffLift":
			await _say("It needs counterweight and cable work, not brute force.")
		"ContrabandCrate":
			await _say("Pushing a crate off a cliff might be satisfying but it won't help me cross.")
		_:
			await _say(_random_response(_PUSH_RESPONSES))

func _on_use_item(item_name: String, target: Clickable) -> bool:
	match target.name:
		"CliffLift":
			if item_name == "ceramic_bottles":
				await _say("I load the heavy ceramic bottles into the lift basket. Good ballast.")
				take_item("ceramic_bottles")
				GameState.set_flag("lift_loaded")
				return true
			if item_name == "coil_line":
				if GameState.has_flag("lift_loaded"):
					await _say("I hook the coil line to the lift cable and redirect it toward the bridge tension system.")
					GameState.set_flag("line_redirected")
					return true
				else:
					await _say("The lift needs ballast first. The line would just hang slack.")
					return true
		"SignalLantern":
			if item_name == "coil_line":
				if GameState.has_flag("line_redirected"):
					await _say("I use the lantern's shutter bracket to lock the redirected line in place. Solid.")
					GameState.set_flag("line_locked")
					return true
				else:
					await _say("I don't have anything to lock yet.")
					return true
		"RopeBridge":
			if item_name == "ceramic_bottles":
				await _say("Throwing bottles at a bridge is not the engineering solution I had in mind.")
				return true
	return false
