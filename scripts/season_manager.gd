extends Node

signal season_changed(season_data: Dictionary)
signal season_tick(time_remaining: float)

var _seasons: Array = []
var _season_duration: float = 900.0
var _season_index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	_load_data()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)


func _load_data() -> void:
	var file := FileAccess.open("res://data/seasons.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	_season_duration = float(parsed["season_duration_seconds"])
	_seasons = parsed["seasons"]


func _on_tick() -> void:
	_elapsed += 1.0
	if _elapsed >= _season_duration:
		_season_index = (_season_index + 1) % _seasons.size()
		_elapsed = 0.0
		season_changed.emit(get_current_season())
	season_tick.emit(_season_duration - _elapsed)


func get_current_season() -> Dictionary:
	return _seasons[_season_index]


func get_time_remaining() -> float:
	return _season_duration - _elapsed


func is_population_growth_allowed() -> bool:
	return _seasons[_season_index]["population_growth_allowed"]
