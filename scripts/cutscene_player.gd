class_name CutscenePlayer
extends RefCounted

## Plays scripted sequences — walk, say, face, wait, fade, give item, etc.
## Used for intros, memory visions, act endings.
##
## Usage:
##   var cs := CutscenePlayer.new(room)
##   cs.say_as("PINDLE", "Halt! Papers!")
##   cs.walk_player_to(Vector2(300, 280))
##   cs.say("What papers?")
##   cs.wait(0.5)
##   cs.fade_out()
##   await cs.play()

var room: Node  # The AdventureRoom instance
var steps: Array[Dictionary] = []

func _init(p_room: Node) -> void:
	room = p_room

# ============================================================
# STEP BUILDERS (chainable)
# ============================================================

func say(text: String) -> CutscenePlayer:
	steps.append({"type": "say", "text": text})
	return self

func say_as(speaker: String, text: String) -> CutscenePlayer:
	steps.append({"type": "say_as", "speaker": speaker, "text": text})
	return self

func walk_player_to(pos: Vector2) -> CutscenePlayer:
	steps.append({"type": "walk_player", "position": pos})
	return self

func face_player(direction: String) -> CutscenePlayer:
	## "left" or "right"
	steps.append({"type": "face_player", "direction": direction})
	return self

func face_player_at(pos: Vector2) -> CutscenePlayer:
	steps.append({"type": "face_player_at", "position": pos})
	return self

func wait(seconds: float) -> CutscenePlayer:
	steps.append({"type": "wait", "duration": seconds})
	return self

func fade_out(duration: float = 0.8) -> CutscenePlayer:
	steps.append({"type": "fade_out", "duration": duration})
	return self

func fade_in(duration: float = 0.8) -> CutscenePlayer:
	steps.append({"type": "fade_in", "duration": duration})
	return self

func give_item(item_name: String) -> CutscenePlayer:
	steps.append({"type": "give_item", "item": item_name})
	return self

func set_flag(flag_name: String, value: Variant = true) -> CutscenePlayer:
	steps.append({"type": "set_flag", "flag": flag_name, "value": value})
	return self

func go_to_room(scene_path: String) -> CutscenePlayer:
	steps.append({"type": "go_to_room", "path": scene_path})
	return self

func call_func(callable: Callable) -> CutscenePlayer:
	steps.append({"type": "call_func", "callable": callable})
	return self

func npc_say(npc_node_name: String, speaker: String, text: String) -> CutscenePlayer:
	steps.append({"type": "npc_say", "npc": npc_node_name, "speaker": speaker, "text": text})
	return self

func npc_face(npc_node_name: String, direction: String) -> CutscenePlayer:
	steps.append({"type": "npc_face", "npc": npc_node_name, "direction": direction})
	return self

# ============================================================
# EXECUTION
# ============================================================

func play() -> void:
	room.is_busy = true
	room._in_scripted_sequence = true

	for step in steps:
		match step.type:
			"say":
				await room._say(step.text)
			"say_as":
				await room._say_as(step.speaker, step.text)
			"walk_player":
				await room.player.walk_to_and_wait(step.position)
			"face_player":
				if step.direction == "left":
					room.player.face_left()
				else:
					room.player.face_right()
			"face_player_at":
				room.player.face_position(step.position)
			"wait":
				await room.get_tree().create_timer(step.duration).timeout
			"fade_out":
				if room.fade_overlay:
					room.fade_overlay.visible = true
					room.fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
					var tween := room.create_tween()
					tween.tween_property(room.fade_overlay, "color:a", 1.0, step.duration)
					await tween.finished
			"fade_in":
				if room.fade_overlay:
					room.fade_overlay.visible = true
					var tween := room.create_tween()
					tween.tween_property(room.fade_overlay, "color:a", 0.0, step.duration)
					await tween.finished
					room.fade_overlay.visible = false
			"give_item":
				room.give_item(step.item)
			"set_flag":
				GameState.set_flag(step.flag, step.value)
			"go_to_room":
				await room.go_to_room(step.path)
				return  # Room is gone, stop executing
			"call_func":
				await step.callable.call()
			"npc_say":
				var npc = room.get_node_or_null("Props/" + step.npc)
				if npc and npc.has_method("play_talk"):
					npc.play_talk()
				await room._say_as(step.speaker, step.text)
				if npc and npc.has_method("play_idle"):
					npc.play_idle()
			"npc_face":
				var npc = room.get_node_or_null("Props/" + step.npc)
				if npc:
					if step.direction == "left":
						npc.face_left()
					else:
						npc.face_right()

	room._in_scripted_sequence = false
	room.is_busy = false
