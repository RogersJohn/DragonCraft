extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal closed
signal dragon_added(dragon_name: String, species: String)

var _incubation_manager: Node = null
var _person_manager: Node = null
var _refresh_timer: Timer = null
var _egg_picker: Panel = null

@onready var _close_button: Button = $CloseButton
@onready var _title_label: Label = $TitleLabel
@onready var _background: TextureRect = $Background
@onready var _nest1: Panel = $NestsContainer/Nest1Panel
@onready var _nest2: Panel = $NestsContainer/Nest2Panel
@onready var _nest3: Panel = $NestsContainer/Nest3Panel


func _ready() -> void:
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_title_label.add_theme_font_size_override("font_size", 24)
	UITheme.apply_gold_button(_close_button)
	_close_button.pressed.connect(func(): closed.emit())
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 1.0
	_refresh_timer.autostart = false
	_refresh_timer.timeout.connect(refresh)
	add_child(_refresh_timer)


func setup(incubation_manager: Node, person_manager: Node) -> void:
	_incubation_manager = incubation_manager
	_person_manager = person_manager
	var bg_tex: Texture2D = load("res://assets/images/dragon_school_Interior.png") as Texture2D
	if bg_tex != null:
		_background.texture = bg_tex
	var nest_panels: Array[Panel] = [_nest1, _nest2, _nest3]
	for panel in nest_panels:
		_style_nest_panel(panel)
	refresh()
	_refresh_timer.start()


func refresh() -> void:
	if _incubation_manager == null:
		return
	var slots: Array = _incubation_manager.get_all_slots()
	var nest_panels: Array[Panel] = [_nest1, _nest2, _nest3]
	for i in range(min(slots.size(), nest_panels.size())):
		_rebuild_slot(nest_panels[i], slots[i] as Dictionary)


func _style_nest_panel(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.05, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.75, 0.55, 0.05)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)


func _rebuild_slot(panel: Panel, slot: Dictionary) -> void:
	for child in panel.get_children():
		child.free()
	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10.0
	vbox.offset_top = 10.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -10.0
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Nest %d" % int(slot["slot_id"])
	title.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sep := HSeparator.new()
	vbox.add_child(sep)
	match str(slot.get("state", "empty")):
		"empty":
			_build_empty_slot(vbox, int(slot["slot_id"]))
		"incubating":
			_build_incubating_slot(vbox, slot)
		"hatched":
			_build_hatched_slot(vbox, slot)


func _build_empty_slot(vbox: VBoxContainer, slot_id: int) -> void:
	var placeholder := Label.new()
	placeholder.text = "🥚"
	placeholder.add_theme_font_size_override("font_size", 52)
	placeholder.modulate = Color(0.35, 0.35, 0.35, 0.5)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(placeholder)
	var empty_label := Label.new()
	empty_label.text = "Empty Nest"
	empty_label.modulate = Color(0.55, 0.55, 0.55)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(empty_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	var has_eggs: bool = _person_manager != null and not _person_manager.get_all_inventory_eggs().is_empty()
	var btn := Button.new()
	btn.text = "Place Egg"
	btn.disabled = not has_eggs
	UITheme.apply_gold_button(btn, 14)
	var sid := slot_id
	btn.pressed.connect(func(): _show_egg_picker(sid))
	vbox.add_child(btn)


func _build_incubating_slot(vbox: VBoxContainer, slot: Dictionary) -> void:
	var elapsed: float = float(slot.get("elapsed", 0.0))
	var duration: float = float(slot.get("duration", 180.0))
	var progress: float = elapsed / duration if duration > 0.0 else 0.0
	var tex: Texture2D = load("res://assets/images/egg_states.png") as Texture2D
	if tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var stage_idx := 0
		if progress >= 0.67:
			stage_idx = 2
		elif progress >= 0.34:
			stage_idx = 1
		var w: float = float(tex.get_width()) / 3.0
		atlas.region = Rect2(stage_idx * w, 0.0, w, float(tex.get_height()))
		var egg_rect := TextureRect.new()
		egg_rect.texture = atlas
		egg_rect.custom_minimum_size = Vector2(80.0, 80.0)
		egg_rect.expand_mode = 1
		egg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		egg_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(egg_rect)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	var remaining: float = max(0.0, duration - elapsed)
	var mins: int = int(remaining) / 60
	var secs: int = int(remaining) % 60
	var timer_label := Label.new()
	timer_label.text = "%02d:%02d" % [mins, secs]
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	timer_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(timer_label)
	var species_label := Label.new()
	species_label.text = _format_species(str(slot.get("species", "")))
	species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	species_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(species_label)


func _build_hatched_slot(vbox: VBoxContainer, slot: Dictionary) -> void:
	var tex: Texture2D = load("res://assets/images/hatchling_dragon.png") as Texture2D
	if tex != null:
		var hatch_rect := TextureRect.new()
		hatch_rect.texture = tex
		hatch_rect.custom_minimum_size = Vector2(110.0, 110.0)
		hatch_rect.expand_mode = 1
		hatch_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hatch_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(hatch_rect)
	var species_label := Label.new()
	species_label.text = _format_species(str(slot.get("species", "")))
	species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	species_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	vbox.add_child(species_label)
	var welcome := Label.new()
	welcome.text = "Welcome %s!" % str(slot.get("dragon_name", "Dragon"))
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(welcome)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	var btn := Button.new()
	btn.text = "Add to Village"
	UITheme.apply_gold_button(btn, 14, true)
	var sid: int = int(slot["slot_id"])
	var dname: String = str(slot.get("dragon_name", "Dragon"))
	var species: String = str(slot.get("species", ""))
	btn.pressed.connect(func(): _on_add_to_village(sid, dname, species))
	vbox.add_child(btn)


func _on_add_to_village(slot_id: int, dragon_name: String, species: String) -> void:
	_incubation_manager.clear_slot(slot_id)
	dragon_added.emit(dragon_name, species)
	refresh()


func _show_egg_picker(slot_id: int) -> void:
	if _egg_picker != null:
		_egg_picker.queue_free()
		_egg_picker = null
	if _person_manager == null:
		return
	var eggs: Array = _person_manager.get_all_inventory_eggs()
	if eggs.is_empty():
		return
	_egg_picker = Panel.new()
	_egg_picker.anchor_left = 0.5
	_egg_picker.anchor_top = 0.5
	_egg_picker.anchor_right = 0.5
	_egg_picker.anchor_bottom = 0.5
	var picker_h: float = min(float(eggs.size()) * 46.0 + 80.0, 260.0)
	_egg_picker.offset_left = -150.0
	_egg_picker.offset_top = -picker_h * 0.5
	_egg_picker.offset_right = 150.0
	_egg_picker.offset_bottom = picker_h * 0.5
	_egg_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_egg_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.02, 0.97)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.85, 0.2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_egg_picker.add_theme_stylebox_override("panel", style)
	add_child(_egg_picker)
	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10.0
	vbox.offset_top = 8.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 6)
	_egg_picker.add_child(vbox)
	var pick_label := Label.new()
	pick_label.text = "Choose an egg:"
	pick_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	pick_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(pick_label)
	for egg in eggs:
		var e: Dictionary = egg as Dictionary
		var btn := Button.new()
		btn.text = "%s — %s" % [_format_species(str(e["species"])), str(e["person_name"])]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UITheme.apply_gold_button(btn, 13)
		var sid := slot_id
		btn.pressed.connect(func(): _on_egg_picked(sid, e))
		vbox.add_child(btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	UITheme.apply_gold_button(cancel_btn, 13)
	cancel_btn.pressed.connect(func():
		if is_instance_valid(_egg_picker):
			_egg_picker.queue_free()
			_egg_picker = null
	)
	vbox.add_child(cancel_btn)


func _on_egg_picked(slot_id: int, egg: Dictionary) -> void:
	_person_manager.drop_item(int(egg["person_id"]), str(egg["egg_id"]))
	_incubation_manager.place_egg(slot_id, str(egg["egg_id"]), str(egg["species"]))
	if is_instance_valid(_egg_picker):
		_egg_picker.queue_free()
		_egg_picker = null
	refresh()


static func _format_species(raw: String) -> String:
	if raw.is_empty() or raw == "unknown":
		return "Unknown"
	var parts: PackedStringArray = raw.split("_")
	var result := ""
	for part in parts:
		if result != "":
			result += " "
		result += part.substr(0, 1).to_upper() + part.substr(1)
	return result
