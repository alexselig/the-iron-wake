class_name NPC
extends Area2D

## An NPC character in a room. Has a sprite, talk animation, and can be clicked.

signal clicked(node: Clickable)
signal right_clicked(node: Clickable)

@export var npc_name: String = ""
@export var description: String = ""
@export var walk_to_offset: Vector2 = Vector2.ZERO

var sprite: AnimatedSprite2D
var facing_right := true
var hover_highlight := false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(p_name: String, p_description: String, pos: Vector2,
		p_walk_offset: Vector2, sprite_path: String = "",
		collision_size: Vector2 = Vector2(40, 50)) -> void:
	npc_name = p_name
	description = p_description
	position = pos
	walk_to_offset = p_walk_offset

	# Collision
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	collision.shape = shape
	add_child(collision)

	# Sprite (if path provided)
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var spr := Sprite2D.new()
		spr.name = "Sprite"
		spr.texture = load(sprite_path)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(spr)

func load_animated_sprite(frames_path: String, animations: Array[String] = []) -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	if animations.is_empty():
		animations = ["idle_right", "idle_left", "talk_right", "talk_left"]

	for anim_name in animations:
		frames.add_animation(anim_name)
		var is_talk: bool = anim_name.contains("talk")
		frames.set_animation_speed(anim_name, 4.0 if is_talk else 2.0)
		frames.set_animation_loop(anim_name, true)
		var count := 2
		for i in range(count):
			var path := "%s/%s_%d.png" % [frames_path, anim_name, i]
			if ResourceLoader.exists(path):
				frames.add_frame(anim_name, load(path))

	if frames.has_animation("default"):
		frames.remove_animation("default")

	sprite.sprite_frames = frames
	sprite.animation = "idle_right"
	sprite.play()
	add_child(sprite)

func play_talk() -> void:
	if sprite:
		var anim := "talk_right" if facing_right else "talk_left"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

func play_idle() -> void:
	if sprite:
		var anim := "idle_right" if facing_right else "idle_left"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

func face_left() -> void:
	facing_right = false
	play_idle()

func face_right() -> void:
	facing_right = true
	play_idle()

func face_position(pos: Vector2) -> void:
	if pos.x < global_position.x:
		face_left()
	else:
		face_right()

func get_walk_position() -> Vector2:
	return global_position + walk_to_offset

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(self)

func _on_mouse_entered() -> void:
	hover_highlight = true
	modulate = Color(1.4, 1.3, 1.0)

func _on_mouse_exited() -> void:
	hover_highlight = false
	modulate = Color.WHITE
