extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal back_to_map
signal state_snapshot(state: Dictionary)

const HOUSE_MANAGER_SCRIPT := preload("res://scripts/house_manager.gd")
const PERSON_MANAGER_SCRIPT := preload("res://scripts/person_manager.gd")
const HOUSE_POPUP_SCENE := preload("res://scenes/ui/HousePopup.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/InventoryPanel.tscn")
const DRAGON_SCHOOL_PANEL_SCENE := preload("res://scenes/ui/DragonSchoolPanel.tscn")
const INCUBATION_MANAGER_SCRIPT := preload("res://scripts/incubation_manager.gd")
const AUTOSAVE_INTERVAL := 300.0

@onready var _season_label: Label = $HUD/Panel/VBox/SeasonLabel
@onready var _day_label: Label = $HUD/Panel/VBox/DayLabel
@onready var _food_label: Label = $HUD/Panel/VBox/FoodLabel
@onready var _gold_label: Label = $HUD/Panel/VBox/GoldLabel
@onready var _wood_label: Label = $HUD/Panel/VBox/WoodLabel
@onready var _people_label: Label = $HUD/Panel/VBox/PeopleLabel
@onready var _back_button: Button = $HUD/BackButton
@onready var _timer: Timer = $ResourceTimer
@onready var _save_label: Label = $HUD/SaveLabel

var _food: float = 0.0
var _gold: float = 0.0
var _wood: float = 0.0
var _base_tick_food: float = 0.0
var _base_tick_gold: float = 0.0
var _base_tick_wood: float = 0.0
var _tick_multiplier: float = 1.0
var _food_tick_mult: float = 1.0
var _wood_tick_mult: float = 1.0
var _gold_tick_mult: float = 1.0
var _base_tick_interval: float = 5.0
var _house_manager: Node = null
var _person_manager: Node = null
var _active_popup: Node = null
var _active_popup_house_id: int = 0
var _active_inventory_panel: Node = null
var _active_inventory_person_id: int = -1
var _save_tween: Tween = null
var _notify_label: Label = null
var _notify_tween: Tween = null
var _incubation_manager: Node = null
var _active_school_panel: Node = null
var _school_tooltip: Control = null
var _school_tooltip_label: Label = null


func _ready() -> void:
	_house_manager = HOUSE_MANAGER_SCRIPT.new()
	add_child(_house_manager)
	_person_manager = PERSON_MANAGER_SCRIPT.new()
	add_child(_person_manager)
	_person_manager.init(_house_manager)
	var res = _load_resources()
	_food = res.food.starting_value
	_gold = res.gold.starting_value
	_wood = res.wood.starting_value
	_base_tick_food = res.food.tick_amount
	_base_tick_gold = res.gold.tick_amount
	_base_tick_wood = res.wood.tick_amount
	_base_tick_interval = res.food.tick_interval_seconds
	_timer.wait_time = _base_tick_interval
	_timer.timeout.connect(_on_tick)
	_timer.start()
	_save_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_save_label.modulate.a = 0.0
	UITheme.apply_gold_button(_back_button)
	_back_button.pressed.connect(_on_back_pressed)
	_connect_house_zones()
	var autosave_timer := Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_on_autosave)
	add_child(autosave_timer)
	SeasonManager.season_changed.connect(_on_season_changed)
	SeasonManager.season_tick.connect(_on_season_tick)
	GameClock.day_changed.connect(_on_day_changed)
	TimeController.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(TimeController.get_speed_multiplier(), TimeController.is_paused())
	_person_manager.role_changed.connect(_on_role_changed)
	_notify_label = Label.new()
	_notify_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_notify_label.add_theme_font_size_override("font_size", 14)
	_notify_label.modulate.a = 0.0
	_notify_label.anchor_left = 0.0
	_notify_label.anchor_right = 1.0
	_notify_label.offset_top = 240.0
	_notify_label.offset_bottom = 265.0
	_notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$HUD.add_child(_notify_label)
	_on_season_changed(SeasonManager.get_current_season())
	_update_season_label(SeasonManager.get_current_season(), SeasonManager.get_time_remaining())
	_day_label.text = "📅 Day %d" % GameClock.get_current_day()
	_update_hud()
	_incubation_manager = INCUBATION_MANAGER_SCRIPT.new()
	add_child(_incubation_manager)
	_incubation_manager.slot_changed.connect(_on_slot_changed)
	_connect_school_zone()
	_create_school_tooltip()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			_do_save("manual")


func _load_resources():
	var fallback := {
		"food":   {"starting_value": 100, "tick_amount": 1, "tick_interval_seconds": 5},
		"gold":   {"starting_value": 100, "tick_amount": 1, "tick_interval_seconds": 5},
		"wood":   {"starting_value": 100, "tick_amount": 1, "tick_interval_seconds": 5},
		"people": {"starting_value": 0,   "tick_amount": 0, "tick_interval_seconds": 5}
	}
	if not FileAccess.file_exists("res://data/resources.json"):
		push_error("resources.json not found — using fallback resource values")
		return fallback
	var file := FileAccess.open("res://data/resources.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("resources.json failed to parse — using fallback resource values")
		return fallback
	return parsed["resources"]


func _connect_house_zones() -> void:
	for i in range(1, 6):
		var zone: Button = get_node("House%d" % i)
		var id := i
		zone.pressed.connect(func(): _on_house_zone_pressed(id))


func _on_speed_changed(multiplier: float, paused: bool) -> void:
	# Auto-save timer is excluded — it runs on real time regardless of speed
	if paused:
		_timer.paused = true
	else:
		_timer.paused = false
		_timer.wait_time = _base_tick_interval / multiplier


func _on_tick() -> void:
	_food += _base_tick_food * _food_tick_mult
	_gold += _base_tick_gold * _gold_tick_mult
	_wood += _base_tick_wood * _wood_tick_mult
	_update_hud()
	if _active_popup != null:
		_active_popup.refresh(_house_manager.get_house(_active_popup_house_id), _food)


func _on_season_changed(season_data: Dictionary) -> void:
	_food += float(season_data.get("food_bonus", 0))
	_gold += float(season_data.get("gold_bonus", 0))
	_wood += float(season_data.get("wood_bonus", 0))
	_tick_multiplier = float(season_data.get("tick_multiplier", 1.0))
	_food_tick_mult = float(season_data.get("food_tick_multiplier", 1.0))
	_wood_tick_mult = float(season_data.get("wood_tick_multiplier", 1.0))
	_gold_tick_mult = float(season_data.get("gold_tick_multiplier", 1.0))
	_update_hud()
	if not bool(season_data.get("population_growth_allowed", true)):
		_close_popup()


func _on_season_tick(time_remaining: float) -> void:
	_update_season_label(SeasonManager.get_current_season(), time_remaining)


func _on_day_changed(day_number: int) -> void:
	_day_label.text = "📅 Day %d" % day_number


func _on_role_changed(person_id: int, new_role: String) -> void:
	if new_role == "explorer" and _active_inventory_person_id == person_id:
		_close_inventory_panel()
	if _active_popup != null:
		var p = _person_manager.get_person(person_id)
		if p != null and p.house_id == _active_popup_house_id:
			_active_popup.refresh(_house_manager.get_house(_active_popup_house_id), _food)


func _on_house_zone_pressed(house_id: int) -> void:
	_close_popup()
	_close_school_panel()
	_active_popup = HOUSE_POPUP_SCENE.instantiate()
	_active_popup_house_id = house_id
	$HUD.add_child(_active_popup)
	_active_popup.setup(
		_house_manager.get_house(house_id),
		_food,
		_house_manager.get_settler_food_cost(),
		_house_manager,
		_person_manager
	)
	_active_popup.settler_requested.connect(_on_settler_requested)
	_active_popup.person_selected.connect(_on_person_selected)
	_active_popup.closed.connect(_close_popup)


func _close_popup() -> void:
	_close_inventory_panel()
	if _active_popup != null:
		_active_popup.queue_free()
		_active_popup = null
		_active_popup_house_id = 0


func _on_settler_requested(house_id: int) -> void:
	if not SeasonManager.is_population_growth_allowed():
		return
	if _food < float(_house_manager.get_settler_food_cost()):
		return
	if _person_manager.add_settler(house_id) == null:
		return
	_food -= float(_house_manager.get_settler_food_cost())
	_update_hud()
	if _active_popup != null:
		_active_popup.refresh(_house_manager.get_house(house_id), _food)


func _on_person_selected(person_id: int) -> void:
	_close_inventory_panel()
	var p = _person_manager.get_person(person_id)
	if p == null:
		return
	var house_data: Dictionary = _house_manager.get_house(p.house_id)
	_active_inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	_active_inventory_person_id = person_id
	$HUD.add_child(_active_inventory_panel)
	_active_inventory_panel.setup(_build_person_snapshot(p, house_data))
	_active_inventory_panel.watch_for_explorer_promotion(_person_manager)
	_active_inventory_panel.item_dropped.connect(_on_item_dropped)
	_active_inventory_panel.explorer_toggled.connect(_on_explorer_toggled)
	_active_inventory_panel.closed.connect(_close_inventory_panel)


func _close_inventory_panel() -> void:
	if _active_inventory_panel != null:
		_active_inventory_panel.queue_free()
		_active_inventory_panel = null
	_active_inventory_person_id = -1


func _on_item_dropped(person_id: int, item_id: String) -> void:
	_person_manager.drop_item(person_id, item_id)
	_refresh_inventory_panel(person_id)


func _on_explorer_toggled(person_id: int, is_explorer: bool) -> void:
	_person_manager.set_role(person_id, "explorer" if is_explorer else "villager")
	_refresh_inventory_panel(person_id)


func _refresh_inventory_panel(person_id: int) -> void:
	if _active_inventory_panel == null:
		return
	var p = _person_manager.get_person(person_id)
	if p == null:
		return
	var house_data: Dictionary = _house_manager.get_house(p.house_id)
	_active_inventory_panel.setup(_build_person_snapshot(p, house_data))


func _build_person_snapshot(p: Object, house_data: Dictionary) -> Dictionary:
	return {
		"id": p.id,
		"name": p.name,
		"role": p.role,
		"house_name": str(house_data.get("name", "")),
		"inventory": p.inventory.duplicate(true),
		"is_explorer": p.is_explorer
	}


func get_explorer_snapshot() -> Array:
	return _person_manager.get_explorer_snapshot()


func apply_pending_pickups(pickups: Array) -> void:
	for pickup in pickups:
		_person_manager.apply_egg_pickup(
			pickup.get("egg_data", {}),
			int(pickup.get("person_id", -1))
		)


func receive_explorer_returns(explorer_data: Array, _egg_transfers: Array) -> void:
	for e in explorer_data:
		var pid: int = int(e.get("id", -1))
		if pid == -1:
			continue
		var p = _person_manager.get_person(pid)
		if p == null:
			continue
		_person_manager.set_role(pid, "villager")
		_show_return_notification(str(e.get("name", "Explorer")))


func _show_return_notification(explorer_name: String) -> void:
	if _notify_label == null:
		return
	if _notify_tween != null:
		_notify_tween.kill()
	_notify_label.text = "%s has returned to the village!" % explorer_name
	_notify_label.modulate.a = 1.0
	_notify_tween = create_tween()
	_notify_tween.tween_interval(3.0)
	_notify_tween.tween_property(_notify_label, "modulate:a", 0.0, 1.0)


func _on_autosave() -> void:
	_do_save("auto")


func _do_save(slot: String) -> void:
	SaveManager.save_game(_build_save_state(), slot)
	_show_save_label("Game Saved" if slot == "manual" else "Auto-saved")


func _build_save_state() -> Dictionary:
	var houses := []
	for i in range(1, 6):
		var h: Dictionary = _house_manager.get_house(i)
		houses.append({
			"id": int(h["id"]),
			"founding_day": int(h.get("founding_day", 0))
		})
	return {
		"food": _food,
		"gold": _gold,
		"wood": _wood,
		"houses": houses,
		"person_manager": _person_manager.to_dict(),
		"incubation": _incubation_manager.to_dict(),
		"season_index": SeasonManager.get_season_index(),
		"season_elapsed": SeasonManager.get_elapsed(),
		"game_clock_elapsed": GameClock.get_elapsed_seconds(),
		"speed_multiplier": TimeController.get_speed_multiplier(),
		"is_paused": TimeController.is_paused(),
		"current_scene": "village"
	}


func restore_state(state: Dictionary) -> void:
	_food = float(state.get("food", _food))
	_gold = float(state.get("gold", _gold))
	_wood = float(state.get("wood", _wood))
	for h_state in state.get("houses", []):
		var h: Dictionary = _house_manager.get_house(int(h_state["id"]))
		if not h.is_empty():
			h["founding_day"] = int(h_state.get("founding_day", 0))
	_person_manager.restore(state.get("person_manager", {}))
	_incubation_manager.restore(state.get("incubation", {}))
	GameClock.restore(float(state.get("game_clock_elapsed", 0.0)))
	_day_label.text = "📅 Day %d" % GameClock.get_current_day()
	var saved_speed := float(state.get("speed_multiplier", 1.0))
	TimeController.set_speed(saved_speed if saved_speed > 0.0 else 1.0)
	if bool(state.get("is_paused", false)):
		TimeController.pause()
	_update_hud()


func _show_save_label(msg: String) -> void:
	if _save_tween != null:
		_save_tween.kill()
	_save_label.text = msg
	_save_label.modulate.a = 1.0
	_save_tween = create_tween()
	_save_tween.tween_property(_save_label, "modulate:a", 0.0, 2.0)


func _update_season_label(season: Dictionary, time_remaining: float) -> void:
	var total_secs := int(time_remaining)
	var mins := total_secs / 60
	var secs := total_secs % 60
	_season_label.text = "%s %s  %02d:%02d" % [season["emoji"], season["name"], mins, secs]


func _on_back_pressed() -> void:
	_back_button.disabled = true
	state_snapshot.emit(_build_save_state())
	back_to_map.emit()


func _update_hud() -> void:
	_food_label.text = "🍖 Food: %d" % int(_food)
	_gold_label.text = "💰 Gold: %d" % int(_gold)
	_wood_label.text = "🪵 Wood: %d" % int(_wood)
	_people_label.text = "👥 People: %d / %d" % [
		_person_manager.get_population(),
		_person_manager.get_max_population()
	]


func _connect_school_zone() -> void:
	var zone: Button = $DragonSchool
	UITheme.apply_invisible_zone(zone)
	zone.pressed.connect(_on_school_zone_pressed)
	zone.mouse_entered.connect(_on_school_hover_enter)
	zone.mouse_exited.connect(_on_school_hover_exit)


func _on_school_zone_pressed() -> void:
	_close_popup()
	_active_school_panel = DRAGON_SCHOOL_PANEL_SCENE.instantiate()
	$HUD.add_child(_active_school_panel)
	_active_school_panel.setup(_incubation_manager, _person_manager)
	_active_school_panel.closed.connect(_close_school_panel)
	_active_school_panel.dragon_added.connect(_on_dragon_added)


func _close_school_panel() -> void:
	if _active_school_panel != null:
		_active_school_panel.queue_free()
		_active_school_panel = null


func _on_slot_changed(_slot_id: int) -> void:
	_update_school_tooltip()
	if _active_school_panel != null:
		_active_school_panel.refresh()


func _on_dragon_added(dragon_name: String, species: String) -> void:
	_show_return_notification("%s the %s has joined the village!" % [dragon_name, _format_species(species)])


func _create_school_tooltip() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.02, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.75, 0.55, 0.05)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	_school_tooltip_label = Label.new()
	_school_tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_school_tooltip_label.add_theme_font_size_override("font_size", 12)
	margin.add_child(_school_tooltip_label)
	panel.visible = false
	$HUD.add_child(panel)
	_school_tooltip = panel


func _on_school_hover_enter() -> void:
	_update_school_tooltip()
	_school_tooltip.visible = true
	call_deferred("_position_school_tooltip")


func _on_school_hover_exit() -> void:
	if _school_tooltip != null:
		_school_tooltip.visible = false


func _update_school_tooltip() -> void:
	if _school_tooltip_label == null:
		return
	_school_tooltip_label.text = _build_school_tooltip_text()


func _position_school_tooltip() -> void:
	if _school_tooltip == null or not _school_tooltip.visible:
		return
	var zone_rect: Rect2 = $DragonSchool.get_global_rect()
	var tip_size: Vector2 = _school_tooltip.get_minimum_size()
	_school_tooltip.position = Vector2(
		clamp(zone_rect.position.x, 8.0, get_viewport_rect().size.x - tip_size.x - 8.0),
		max(8.0, zone_rect.position.y - tip_size.y - 8.0)
	)


func _build_school_tooltip_text() -> String:
	var lines := []
	for slot in _incubation_manager.get_all_slots():
		var state: String = str(slot.get("state", "empty"))
		if state == "incubating":
			var remaining: float = max(0.0, float(slot["duration"]) - float(slot["elapsed"]))
			var mins: int = int(remaining) / 60
			var secs: int = int(remaining) % 60
			lines.append("Nest %d: %s — %02d:%02d" % [
				int(slot["slot_id"]),
				_format_species(str(slot.get("species", ""))),
				mins, secs
			])
		elif state == "hatched":
			lines.append("Nest %d: %s — Hatched!" % [
				int(slot["slot_id"]),
				_format_species(str(slot.get("species", "")))
			])
	if lines.is_empty():
		return "Dragon Training School"
	return "\n".join(lines)


func _format_species(raw: String) -> String:
	if raw.is_empty() or raw == "unknown":
		return "Dragon"
	var parts := raw.split("_")
	var result := ""
	for part in parts:
		if result != "":
			result += " "
		result += part.substr(0, 1).to_upper() + part.substr(1)
	return result
