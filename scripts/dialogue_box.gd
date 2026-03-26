extends PanelContainer

## Displays character dialogue with typewriter effect above the game scene.

signal dialogue_finished()

@onready var label: RichTextLabel = $MarginContainer/Label
var name_label: Label  # Set by room controller

var is_showing := false
var full_text := ""
var char_timer := 0.0
const CHAR_SPEED := 0.025
var current_char_index := 0
var skip_requested := false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not is_showing:
		return
	if skip_requested:
		label.text = full_text
		current_char_index = full_text.length()
		skip_requested = false
		return
	char_timer += delta
	while char_timer >= CHAR_SPEED and current_char_index < full_text.length():
		current_char_index += 1
		label.text = full_text.substr(0, current_char_index)
		char_timer -= CHAR_SPEED

func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed:
		advance = true
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		advance = true
	if advance:
		if current_char_index < full_text.length():
			skip_requested = true
		else:
			hide_dialogue()
		get_viewport().set_input_as_handled()

func show_dialogue(speaker: String, text: String) -> void:
	full_text = text
	current_char_index = 0
	label.text = ""
	if name_label:
		name_label.text = speaker
		name_label.visible = true
	visible = true
	is_showing = true
	skip_requested = false

func hide_dialogue() -> void:
	visible = false
	is_showing = false
	if name_label:
		name_label.visible = false
	dialogue_finished.emit()

func is_text_complete() -> bool:
	return current_char_index >= full_text.length()

func force_dismiss() -> void:
	if is_showing:
		hide_dialogue()
