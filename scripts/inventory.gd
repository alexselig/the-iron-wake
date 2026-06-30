extends GridContainer

## Inventory grid — 4 columns of item slots in the bottom-right panel

signal item_selected(item_name: String)
signal item_deselected()
signal items_combined(item_a: String, item_b: String)

var items: Array[String] = []
var selected_item: String = ""
var item_textures: Dictionary = {}
var item_buttons: Dictionary = {}
var _slot_normal: Texture2D
var _slot_selected: Texture2D

const SLOT_SIZE := Vector2(36, 36)
const MAX_SLOTS := 8

func _ready() -> void:
	var icon_dir := "res://assets/inventory_icons/"
	var icon_names := [
		"magnifying_lens", "copper_wire", "oilskin_pouch",
		"broken_gear", "seashell", "brass_key",
		"cipher_plates", "repaired_gear",
		# Act 1 — Beach / Customs Shack
		"medallion", "spyglass", "stamp",
		"brass_strip", "blank_form", "filled_form", "fake_permit",
		# Act 1 — Salvage Warehouse
		"black_shard", "automaton_hand",
		# Act 1 — Brass Bazaar
		"fancy_teacup", "guild_badge", "focusing_disc",
		# Act 1 — Tibbit's Workshop
		"clock_spring", "whistle", "lens_frame", "memory_lens",
		# Act 1 — Lighthouse
		"relay_key", "map_plate", "salt_paste",
		# Act 2 items
		"ceramic_bottles", "transit_sigil_fragment", "tone_cylinder",
		"message_strip", "second_relay_core", "aerial_transit_prism",
		"white_civic_signet_half", "scaffold_pipe",
		# Act 3 items
		"reflective_cinderglass", "complete_civic_signet",
		"inspection_stamp",
		# Cross-act items
		"coil_line", "brass_curtain_rod", "chapel_hand_mirror",
		"lantern", "valve_pin",
	]
	for icon_name in icon_names:
		var path: String = icon_dir + icon_name + ".png"
		var tex := _load_texture(path)
		if tex:
			item_textures[icon_name] = tex

	_slot_normal = _load_texture("res://assets/ui/slot_normal.png")
	_slot_selected = _load_texture("res://assets/ui/slot_selected.png")

	_rebuild_ui()

func add_item(item_name: String) -> void:
	if item_name in items:
		return
	items.append(item_name)
	_rebuild_ui()

func remove_item(item_name: String) -> void:
	items.erase(item_name)
	if selected_item == item_name:
		selected_item = ""
		item_deselected.emit()
	_rebuild_ui()

func has_item(item_name: String) -> bool:
	return item_name in items

func _rebuild_ui() -> void:
	for child in get_children():
		child.queue_free()
	item_buttons.clear()

	# Fill slots — items first, then empty slots
	for i in range(MAX_SLOTS):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

		if i < items.size():
			var item_name: String = items[i]
			slot.add_theme_stylebox_override("panel", _make_slot_style(item_name == selected_item))

			var btn := TextureButton.new()
			btn.custom_minimum_size = Vector2(28, 28)
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			btn.ignore_texture_size = true
			btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if item_name in item_textures:
				btn.texture_normal = item_textures[item_name]
			btn.tooltip_text = item_name.replace("_", " ").capitalize()
			btn.pressed.connect(_on_item_clicked.bind(item_name))
			slot.add_child(btn)
			item_buttons[item_name] = btn
		else:
			slot.add_theme_stylebox_override("panel", _make_slot_style(false))

		add_child(slot)

func _make_slot_style(selected: bool) -> StyleBox:
	var tex: Texture2D = _slot_selected if selected else _slot_normal
	if tex == null:
		# Fallback to flat styling if the textures are missing
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.15, 0.1, 0.06)
		s.set_border_width_all(2 if selected else 1)
		s.border_color = Color("f1c878") if selected else Color("5a4322")
		s.set_corner_radius_all(2)
		return s
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 6)
		# Content margins must be set explicitly: otherwise the slot
		# PanelContainer inherits the texture margins and inflates to
		# (margin + icon + margin), overflowing the bar's bottom row.
		sb.set_content_margin(side, 4)
	return sb

func _load_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.new()
	if img.load(abs_path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _on_item_clicked(item_name: String) -> void:
	if selected_item == "":
		selected_item = item_name
		item_selected.emit(item_name)
		_rebuild_ui()
	elif selected_item == item_name:
		selected_item = ""
		item_deselected.emit()
		_rebuild_ui()
	else:
		items_combined.emit(selected_item, item_name)
		selected_item = ""
		item_deselected.emit()
		_rebuild_ui()
