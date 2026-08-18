extends CharacterBody2D

## Player character - Rowan Vale

signal arrived()

var sprite: AnimatedSprite2D

var target_position: Vector2 = Vector2.ZERO
var is_walking := false
var walk_speed := 80.0  # pixels per second
var facing_right := true

func _ready() -> void:
	target_position = global_position
	# Sprite is added by SceneBuilder - find it when available
	sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("idle_right")

func init_sprite() -> void:
	sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("idle_right")

func _physics_process(_delta: float) -> void:
	if not is_walking:
		return

	var direction := (target_position - global_position)
	var distance := direction.length()

	if distance < 2.0:
		is_walking = false
		global_position = target_position
		velocity = Vector2.ZERO
		_play_idle()
		arrived.emit()
		return

	velocity = direction.normalized() * walk_speed
	# Update facing direction
	if abs(direction.x) > 1.0:
		facing_right = direction.x > 0
	_play_walk()
	move_and_slide()

func walk_to(pos: Vector2) -> void:
	target_position = pos
	if global_position.distance_to(pos) < 3.0:
		return  # Already there
	is_walking = true

func walk_to_and_wait(pos: Vector2) -> void:
	walk_to(pos)
	if not is_walking:
		return
	await arrived

func _play_walk() -> void:
	if not sprite:
		return
	var anim := "walk_right" if facing_right else "walk_left"
	if sprite.animation != anim:
		sprite.play(anim)

func _play_idle() -> void:
	if not sprite:
		return
	var anim := "idle_right" if facing_right else "idle_left"
	if sprite.animation != anim:
		sprite.play(anim)

func _play_talk() -> void:
	if not sprite:
		return
	var anim := "talk_right" if facing_right else "talk_left"
	if sprite.animation != anim:
		sprite.play(anim)

func face_left() -> void:
	facing_right = false
	_play_idle()

func face_right() -> void:
	facing_right = true
	_play_idle()

func face_position(pos: Vector2) -> void:
	if pos.x < global_position.x:
		face_left()
	else:
		face_right()
