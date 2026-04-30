extends Control

signal back_to_map

@onready var _season_label: Label = $HUD/Panel/VBox/SeasonLabel
@onready var _food_label: Label = $HUD/Panel/VBox/FoodLabel
@onready var _gold_label: Label = $HUD/Panel/VBox/GoldLabel
@onready var _wood_label: Label = $HUD/Panel/VBox/WoodLabel
@onready var _back_button: Button = $HUD/BackButton
@onready var _timer: Timer = $ResourceTimer

var _food: float = 0.0
var _gold: float = 0.0
var _wood: float = 0.0
var _base_tick_food: float = 0.0
var _base_tick_gold: float = 0.0
var _base_tick_wood: float = 0.0
var _tick_multiplier: float = 1.0


func _ready() -> void:
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
	_update_hud()
	_style_back_button()
	_back_button.pressed.connect(_on_back_pressed)
	SeasonManager.season_changed.connect(_on_season_changed)
	SeasonManager.season_tick.connect(_on_season_tick)
	_on_season_changed(SeasonManager.get_current_season())
	_update_season_label(SeasonManager.get_current_season(), SeasonManager.get_time_remaining())


func _load_resources():
	var fallback := {"food":{"starting_value":100,"tick_amount":1,"tick_interval_seconds":5},"gold":{"starting_value":100,"tick_amount":1,"tick_interval_seconds":5},"wood":{"starting_value":100,"tick_amount":1,"tick_interval_seconds":5}}
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


func _on_tick() -> void:
	_food += _base_tick_food * _tick_multiplier
	_gold += _base_tick_gold * _tick_multiplier
	_wood += _base_tick_wood * _tick_multiplier
	_update_hud()


func _on_season_changed(season_data: Dictionary) -> void:
	_food += float(season_data.get("food_bonus", 0))
	_gold += float(season_data.get("gold_bonus", 0))
	_wood += float(season_data.get("wood_bonus", 0))
	_tick_multiplier = float(season_data.get("tick_multiplier", 1.0))
	_update_hud()


func _on_season_tick(time_remaining: float) -> void:
	_update_season_label(SeasonManager.get_current_season(), time_remaining)


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


func _style_back_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.06, 0.03)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.75, 0.55, 0.05)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.10, 0.04)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(1.0, 0.78, 0.15)
	var focus := StyleBoxEmpty.new()
	_back_button.add_theme_stylebox_override("normal", normal)
	_back_button.add_theme_stylebox_override("hover", hover)
	_back_button.add_theme_stylebox_override("pressed", hover)
	_back_button.add_theme_stylebox_override("focus", focus)
	_back_button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_back_button.add_theme_font_size_override("font_size", 16)
