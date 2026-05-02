extends Node

signal speed_changed(multiplier: float, paused: bool)

var _speed: float = 1.0
var _paused: bool = false


func get_speed_multiplier() -> float:
	return 0.0 if _paused else _speed


func is_paused() -> bool:
	return _paused


func set_speed(multiplier: float) -> void:
	_speed = multiplier
	speed_changed.emit(get_speed_multiplier(), _paused)


func pause() -> void:
	if _paused:
		return
	_paused = true
	speed_changed.emit(0.0, true)


func resume() -> void:
	if not _paused:
		return
	_paused = false
	speed_changed.emit(_speed, false)


func toggle_pause() -> void:
	if _paused:
		resume()
	else:
		pause()
