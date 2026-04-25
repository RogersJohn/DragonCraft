extends Control

signal back_to_map

@onready var _food_label: Label = $HUD/Panel/VBox/FoodLabel
@onready var _gold_label: Label = $HUD/Panel/VBox/GoldLabel
@onready var _wood_label: Label = $HUD/Panel/VBox/WoodLabel
@onready var _back_button: Button = $HUD/BackButton
@onready var _timer: Timer = $ResourceTimer

var _food := 0
var _gold := 0
var _wood := 0
var _tick_food := 0
var _tick_gold := 0
var _tick_wood := 0


func _ready() -> void:
	var res = _load_resources()
	_food = res.food.starting_value
	_gold = res.gold.starting_value
	_wood = res.wood.starting_value
	_tick_food = res.food.tick_amount
	_tick_gold = res.gold.tick_amount
	_tick_wood = res.wood.tick_amount
	_timer.wait_time = res.food.tick_interval_seconds
	_timer.timeout.connect(_on_tick)
	_timer.start()
	_update_hud()
	_style_back_button()
	_back_button.pressed.connect(_on_back_pressed)


func _load_resources():
	var file := FileAccess.open("res://data/resources.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed["resources"]


func _on_tick() -> void:
	_food += _tick_food
	_gold += _tick_gold
	_wood += _tick_wood
	_update_hud()


func _on_back_pressed() -> void:
	_back_button.disabled = true
	back_to_map.emit()


func _update_hud() -> void:
	_food_label.text = "🍖 Food: %d" % _food
	_gold_label.text = "💰 Gold: %d" % _gold
	_wood_label.text = "🪵 Wood: %d" % _wood


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
