extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal back_to_map

const HOUSE_MANAGER_SCRIPT := preload("res://scripts/house_manager.gd")
const PERSON_MANAGER_SCRIPT := preload("res://scripts/person_manager.gd")
const HOUSE_POPUP_SCENE := preload("res://scenes/ui/HousePopup.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/InventoryPanel.tscn")
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
var _house_manager: Node = null
var _person_manager: Node = null
var _active_popup: Node = null
var _active_popup_house_id: int = 0
var _active_inventory_panel: Node = null
var _save_tween: Tween = null


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
	_timer.wait_time = res.food.tick_interval_seconds
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
	_on_season_changed(SeasonManager.get_current_season())
	_update_season_label(SeasonManager.get_current_season(), SeasonManager.get_time_remaining())
	_day_label.text = "📅 Day %d" % GameClock.get_current_day()
	_update_hud()


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


func _on_tick() -> void:
	_food += _base_tick_food * _tick_multiplier
	_gold += _base_tick_gold * _tick_multiplier
	_wood += _base_tick_wood * _tick_multiplier
	_update_hud()
	if _active_popup != null:
		_active_popup.refresh(_house_manager.get_house(_active_popup_house_id), _food)


func _on_season_changed(season_data: Dictionary) -> void:
	_food += float(season_data.get("food_bonus", 0))
	_gold += float(season_data.get("gold_bonus", 0))
	_wood += float(season_data.get("wood_bonus", 0))
	_tick_multiplier = float(season_data.get("tick_multiplier", 1.0))
	_update_hud()
	if not bool(season_data.get("population_growth_allowed", true)):
		_close_popup()


func _on_season_tick(time_remaining: float) -> void:
	_update_season_label(SeasonManager.get_current_season(), time_remaining)


func _on_day_changed(day_number: int) -> void:
	_day_label.text = "📅 Day %d" % day_number


func _on_house_zone_pressed(house_id: int) -> void:
	_close_popup()
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
	$HUD.add_child(_active_inventory_panel)
	_active_inventory_panel.setup(_build_person_snapshot(p, house_data))
	_active_inventory_panel.item_dropped.connect(_on_item_dropped)
	_active_inventory_panel.explorer_toggled.connect(_on_explorer_toggled)
	_active_inventory_panel.closed.connect(_close_inventory_panel)


func _close_inventory_panel() -> void:
	if _active_inventory_panel != null:
		_active_inventory_panel.queue_free()
		_active_inventory_panel = null


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
		"season_index": SeasonManager.get_season_index(),
		"season_elapsed": SeasonManager.get_elapsed(),
		"game_clock_elapsed": GameClock.get_elapsed_seconds(),
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
	GameClock.restore(float(state.get("game_clock_elapsed", 0.0)))
	_day_label.text = "📅 Day %d" % GameClock.get_current_day()
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
	back_to_map.emit()


func _update_hud() -> void:
	_food_label.text = "🍖 Food: %d" % int(_food)
	_gold_label.text = "💰 Gold: %d" % int(_gold)
	_wood_label.text = "🪵 Wood: %d" % int(_wood)
	_people_label.text = "👥 People: %d / %d" % [
		_person_manager.get_population(),
		_person_manager.get_max_population()
	]
