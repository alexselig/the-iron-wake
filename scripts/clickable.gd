@tool
class_name Clickable
extends Area2D

## Base class for all interactive objects in the scene

signal clicked(node: Clickable)
signal right_clicked(node: Clickable)
signal item_used(node: Clickable, item_name: String)

@export var description: String = ""
@export var walk_to_offset: Vector2 = Vector2.ZERO  ## Where Elara walks to (relative to this node)
@export var is_collectible: bool = false
@export var starts_hidden: bool = false

var hover_highlight := false
var _bob_time := 0.0
var _base_y := 0.0
var _bob_enabled := false

func _ready() -> void:
	if starts_hidden:
		visible = false
		set_deferred("monitorable", false)
		set_deferred("monitoring", false)
		input_pickable = false

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Enable subtle bobbing on collectible items
	if is_collectible and not starts_hidden:
		_bob_enabled = true
		_base_y = position.y

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Subtle bobbing animation for collectible props
	if _bob_enabled and visible:
		_bob_time += delta * 2.0
		position.y = _base_y + sin(_bob_time) * 1.5

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(self)

func _on_mouse_entered() -> void:
	hover_highlight = true
	# Warm brass glow on hover
	modulate = Color(1.4, 1.3, 1.0)

func _on_mouse_exited() -> void:
	hover_highlight = false
	modulate = Color.WHITE

func get_walk_position() -> Vector2:
	return global_position + walk_to_offset

func show_object() -> void:
	visible = true
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)
	input_pickable = true
	if is_collectible:
		_bob_enabled = true
		_base_y = position.y

func hide_object() -> void:
	visible = false
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	input_pickable = false
	_bob_enabled = false
