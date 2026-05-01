extends Node

signal day_changed(day_number: int)

var _day_duration_seconds: float = 120.0
var _elapsed_seconds: float = 0.0
var _last_day: int = 0


func _ready() -> void:
	_load_day_duration()
	var tick_timer := Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)


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


func get_current_day() -> int:
	return int(_elapsed_seconds / _day_duration_seconds)


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func restore(elapsed_seconds: float) -> void:
	_elapsed_seconds = elapsed_seconds
	_last_day = get_current_day()
