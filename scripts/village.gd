extends Control

@onready var _food_label: Label = $HUD/Panel/VBox/FoodLabel
@onready var _gold_label: Label = $HUD/Panel/VBox/GoldLabel
@onready var _wood_label: Label = $HUD/Panel/VBox/WoodLabel
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


func _update_hud() -> void:
	_food_label.text = "🍖 Food: %d" % _food
	_gold_label.text = "💰 Gold: %d" % _gold
	_wood_label.text = "🪵 Wood: %d" % _wood
