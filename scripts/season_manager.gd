extends Node

signal season_changed(season_data: Dictionary)
signal season_tick(time_remaining: float)

const BASE_TICK := 1.0

var _seasons: Array = []
var _season_duration: float = 900.0
var _season_index: int = 0
var _elapsed: float = 0.0
var _timer: Timer = null


func _ready() -> void:
	_load_data()
	_timer = Timer.new()
	_timer.wait_time = BASE_TICK
	_timer.autostart = true
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	TimeController.speed_changed.connect(_on_speed_changed)


func _load_data() -> void:
	var fallback := [{"name":"Spring","emoji":"🌸","food_bonus":0,"wood_bonus":0,"gold_bonus":0,"tick_multiplier":1.0,"population_growth_allowed":true}]
	if not FileAccess.file_exists("res://data/seasons.json"):
		push_error("seasons.json not found — using fallback Spring season")
		_seasons = fallback
		return
	var file := FileAccess.open("res://data/seasons.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("seasons.json failed to parse — using fallback Spring season")
		_seasons = fallback
		return
	_season_duration = float(parsed["season_duration_seconds"])
	_seasons = parsed["seasons"]


func _on_tick() -> void:
	_elapsed += 1.0
	if _elapsed >= _season_duration:
		_season_index = (_season_index + 1) % _seasons.size()
		_elapsed = 0.0
		season_changed.emit(get_current_season())
	season_tick.emit(_season_duration - _elapsed)


func _on_speed_changed(multiplier: float, paused: bool) -> void:
	if paused:
		_timer.paused = true
	else:
		_timer.paused = false
		_timer.wait_time = BASE_TICK / multiplier


func get_current_season() -> Dictionary:
	return _seasons[_season_index]


func get_time_remaining() -> float:
	return _season_duration - _elapsed


func is_population_growth_allowed() -> bool:
	return _seasons[_season_index]["population_growth_allowed"]


func get_season_index() -> int:
	return _season_index


func get_elapsed() -> float:
	return _elapsed


func restore_season(index: int, elapsed: float) -> void:
	_season_index = clampi(index, 0, _seasons.size() - 1)
	_elapsed = clampf(elapsed, 0.0, _season_duration)
