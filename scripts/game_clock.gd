extends Node

signal day_changed(day_number: int)

const BASE_TICK := 1.0

var _day_duration_seconds: float = 120.0
var _elapsed_seconds: float = 0.0
var _last_day: int = 0
var _tick_timer: Timer = null


func _ready() -> void:
	_load_day_duration()
	_tick_timer = Timer.new()
	_tick_timer.wait_time = BASE_TICK
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	TimeController.speed_changed.connect(_on_speed_changed)


func _load_day_duration() -> void:
	if not FileAccess.file_exists("res://data/houses.json"):
		return
	var file := FileAccess.open("res://data/houses.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed != null and parsed.has("day_duration_seconds"):
		_day_duration_seconds = float(parsed["day_duration_seconds"])


func _on_tick() -> void:
	_elapsed_seconds += 1.0
	var current_day := get_current_day()
	if current_day != _last_day:
		_last_day = current_day
		day_changed.emit(current_day)


func _on_speed_changed(multiplier: float, paused: bool) -> void:
	if paused:
		_tick_timer.paused = true
	else:
		_tick_timer.paused = false
		_tick_timer.wait_time = BASE_TICK / multiplier


func get_current_day() -> int:
	return int(_elapsed_seconds / _day_duration_seconds)


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func restore(elapsed_seconds: float) -> void:
	_elapsed_seconds = elapsed_seconds
	_last_day = get_current_day()
