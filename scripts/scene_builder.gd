extends Node

## Builds all dynamic scene elements for the current room.

const Clickable = preload("res://scripts/clickable.gd")

static func build_player_sprite(player: CharacterBody2D) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	var base_path := "res://assets/characters/frames/"

	for anim_name in ["idle_right", "idle_left", "walk_right", "walk_left", "talk_right", "talk_left"]:
		frames.add_animation(anim_name)
		var is_walk: bool = anim_name.contains("walk")
		var is_talk: bool = anim_name.contains("talk")
		frames.set_animation_speed(anim_name, 8.0 if is_walk else 4.0 if is_talk else 2.0)
		frames.set_animation_loop(anim_name, true)
		var count := 4 if is_walk else 2
		for i in range(count):
			var tex := _load_texture(base_path + "%s_%d.png" % [anim_name, i])
			if tex:
				frames.add_frame(anim_name, tex)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	sprite.sprite_frames = frames
	sprite.animation = "idle_right"
	sprite.play()
	player.add_child(sprite)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 12)
	collision.shape = shape
	collision.position = Vector2(0, 36)
	player.add_child(collision)

	return sprite

static func build_prop(parent: Node2D, prop_name: String, pos: Vector2,
		desc: String, texture_path: String, walk_offset: Vector2,
		collectible: bool = false, hidden: bool = false,
		collision_size: Vector2 = Vector2(40, 40)) -> Area2D:
	var prop := Area2D.new()
	prop.name = prop_name
	prop.position = pos
	prop.set_script(Clickable)
	prop.description = desc
	prop.walk_to_offset = walk_offset
	prop.is_collectible = collectible
	prop.starts_hidden = hidden

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex := _load_texture(texture_path)
	if tex:
		sprite.texture = tex
	prop.add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.shape = shape
	prop.add_child(collision)

	parent.add_child(prop)
	return prop

static func build_hotspot(parent: Node2D, hotspot_name: String, pos: Vector2,
		desc: String, walk_offset: Vector2,
		collision_size: Vector2 = Vector2(60, 40)) -> Area2D:
	var hotspot := Area2D.new()
	hotspot.name = hotspot_name
	hotspot.position = pos
	hotspot.set_script(Clickable)
	hotspot.description = desc
	hotspot.walk_to_offset = walk_offset

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.shape = shape
	hotspot.add_child(collision)

	parent.add_child(hotspot)
	return hotspot

static func build_npc(parent: Node2D, npc_name: String, pos: Vector2,
		desc: String, char_folder: String, walk_offset: Vector2,
		facing_left: bool = false,
		collision_size: Vector2 = Vector2(40, 50)) -> Area2D:
	## Build an NPC with animated sprite from assets/characters/<char_folder>/
	var npc := Area2D.new()
	npc.name = npc_name
	npc.position = pos
	npc.set_script(Clickable)
	npc.description = desc
	npc.walk_to_offset = walk_offset

	# Animated sprite
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	var base_path := "res://assets/characters/%s/" % char_folder

	for anim_name in ["idle_right", "idle_left", "talk_right", "talk_left"]:
		frames.add_animation(anim_name)
		var is_talk: bool = anim_name.contains("talk")
		frames.set_animation_speed(anim_name, 4.0 if is_talk else 2.0)
		frames.set_animation_loop(anim_name, true)
		for i in range(2):
			var tex := _load_texture(base_path + "%s_%d.png" % [anim_name, i])
			if tex:
				frames.add_frame(anim_name, tex)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	sprite.sprite_frames = frames
	var start_anim := "idle_left" if facing_left else "idle_right"
	sprite.animation = start_anim
	sprite.play()
	npc.add_child(sprite)

	# Collision
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.shape = shape
	npc.add_child(collision)

	parent.add_child(npc)
	return npc

static func _load_texture(res_path: String) -> Texture2D:
	res_path = GameState.resolve_asset(res_path)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null

static func build_all(scene: Node2D) -> void:
	var props := scene.get_node("Props")
	var hotspots := scene.get_node("Hotspots")
	var player := scene.get_node("Player")

	build_player_sprite(player)

	# === BLACKWAKE HARBOR PROPS ===

	# The Ancient Relic — center of the scene
	build_prop(props, "AncientRelic", Vector2(320, 260),
		"the ancient relic", "res://assets/props/capsule_frames/closed.png",
		Vector2(-25, 25), false, false, Vector2(80, 60))

	# Spyglass in a crate
	build_prop(props, "SpyglassCrate", Vector2(120, 280),
		"a salvage crate", "res://assets/props/magnifying_lens.png",
		Vector2(0, 15), true, false, Vector2(32, 32))

	# Steam valve on seawall
	build_prop(props, "SteamValve", Vector2(520, 250),
		"the steam valve", "res://assets/props/broken_gear.png",
		Vector2(-15, 30), false, false, Vector2(36, 36))

	# Warning placard
	build_prop(props, "WarningPlacard", Vector2(440, 230),
		"a warning placard", "res://assets/props/cipher_plates.png",
		Vector2(0, 40), false, false, Vector2(40, 24))

	# Crowd (visible prop, non-collectible) — left of the relic so they don't overlap it
	build_prop(props, "Crowd", Vector2(190, 270),
		"the crowd", "res://assets/props/crowd.png",
		Vector2(0, 20), false, false, Vector2(110, 55))

	# Tibbit NPC — animated sprite, facing right (toward relic); near the relic so he overlaps less with the crowd
	build_npc(props, "TibbitNPC", Vector2(290, 285),
		"Tibbit Wrench", "tibbit", Vector2(20, 5), false, Vector2(40, 50))

	# Pindle NPC — animated sprite, facing left (toward crowd)
	build_npc(props, "PindleNPC", Vector2(380, 280),
		"Dockmaster Pindle", "pindle", Vector2(-20, 5), true, Vector2(40, 50))

	# Pindle's inspection stamp — right of Pindle so it doesn't overlap him; starts hidden until he's distracted
	build_prop(props, "StampProp", Vector2(430, 295),
		"Pindle's inspection stamp", "res://assets/props/stamp.png",
		Vector2(-10, -5), true, true, Vector2(20, 20))

	# === HOTSPOTS ===

	build_hotspot(hotspots, "Docks", Vector2(80, 260),
		"the docks", Vector2(30, 25), Vector2(80, 50))

	build_hotspot(hotspots, "CustomsShack", Vector2(560, 265),
		"the customs shack", Vector2(-30, 20), Vector2(70, 50))

	build_hotspot(hotspots, "Seawall", Vector2(320, 220),
		"the seawall", Vector2(0, 55), Vector2(200, 30))
