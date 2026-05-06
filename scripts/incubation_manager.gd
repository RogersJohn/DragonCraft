extends Node

signal slot_changed(slot_id: int)

const BASE_TICK: float = 1.0

var _slots: Array = []
var _dragon_names: Array = []
var _name_index: int = 0
var _incubation_duration: float = 180.0
var _max_slots: int = 3
var _timer: Timer = null


func _ready() -> void:
	_load_config()
	_load_dragon_names()
	for i in range(1, _max_slots + 1):
		_slots.append({
			"slot_id": i,
			"state": "empty",
			"egg_id": "",
			"species": "",
			"dragon_name": "",
			"elapsed": 0.0,
			"duration": _incubation_duration
		})
	_timer = Timer.new()
	_timer.wait_time = BASE_TICK
	_timer.autostart = true
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	TimeController.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(
		TimeController.get_speed_multiplier(),
		TimeController.is_paused()
	)


func _load_config() -> void:
	if not FileAccess.file_exists("res://data/dragons.json"):
		push_error("dragons.json not found — using fallback incubation config")
		return
	var file := FileAccess.open("res://data/dragons.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("dragons.json failed to parse — using fallback incubation config")
		return
	_incubation_duration = float(parsed.get("incubation_seconds", 180))
	_max_slots = int(parsed.get("max_incubation_slots", 3))


func _load_dragon_names() -> void:
	var fallback := [
		"Pyreth", "Sylvara", "Thornyx", "Embris", "Coralis",
		"Stonefang", "Verdun", "Auros", "Thalyx", "Mireya",
		"Cindrel", "Wavecrest", "Glacius", "Ferrus", "Brimsol",
		"Oakhide", "Duskwing", "Seraphel", "Voltan", "Crysta"
	]
	if not FileAccess.file_exists("res://data/dragons.json"):
		_dragon_names = fallback
		return
	var file := FileAccess.open("res://data/dragons.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed.has("dragon_names"):
		_dragon_names = fallback
		return
	_dragon_names = parsed["dragon_names"]


func _on_tick() -> void:
	for slot in _slots:
		if str(slot["state"]) == "incubating":
			slot["elapsed"] = float(slot["elapsed"]) + BASE_TICK
			if float(slot["elapsed"]) >= float(slot["duration"]):
				slot["elapsed"] = slot["duration"]
				slot["state"] = "hatched"
				slot_changed.emit(int(slot["slot_id"]))


func _on_speed_changed(multiplier: float, paused: bool) -> void:
	if paused:
		_timer.paused = true
	else:
		_timer.paused = false
		_timer.wait_time = BASE_TICK / multiplier


func place_egg(slot_id: int, egg_id: String, species: String) -> bool:
	var idx := _find_slot(slot_id)
	if idx == -1 or str(_slots[idx]["state"]) != "empty":
		return false
	_slots[idx]["egg_id"] = egg_id
	_slots[idx]["species"] = species
	_slots[idx]["dragon_name"] = _pick_dragon_name()
	_slots[idx]["elapsed"] = 0.0
	_slots[idx]["duration"] = _incubation_duration
	_slots[idx]["state"] = "incubating"
	slot_changed.emit(slot_id)
	return true


func clear_slot(slot_id: int) -> void:
	var idx := _find_slot(slot_id)
	if idx == -1:
		return
	_slots[idx]["state"] = "empty"
	_slots[idx]["egg_id"] = ""
	_slots[idx]["species"] = ""
	_slots[idx]["dragon_name"] = ""
	_slots[idx]["elapsed"] = 0.0
	_slots[idx]["duration"] = _incubation_duration
	slot_changed.emit(slot_id)


func get_slot(slot_id: int) -> Dictionary:
	var idx := _find_slot(slot_id)
	if idx == -1:
		return {}
	return _slots[idx].duplicate()


func get_all_slots() -> Array:
	var result := []
	for s in _slots:
		result.append(s.duplicate())
	return result


func to_dict() -> Dictionary:
	var slots_data := []
	for s in _slots:
		slots_data.append(s.duplicate())
	return {
		"slots": slots_data,
		"name_index": _name_index
	}


func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	_name_index = int(data.get("name_index", 0))
	for slot_data in data.get("slots", []):
		var sid := int(slot_data.get("slot_id", 0))
		var idx := _find_slot(sid)
		if idx == -1:
			continue
		_slots[idx]["state"] = str(slot_data.get("state", "empty"))
		_slots[idx]["egg_id"] = str(slot_data.get("egg_id", ""))
		_slots[idx]["species"] = str(slot_data.get("species", ""))
		_slots[idx]["dragon_name"] = str(slot_data.get("dragon_name", ""))
		_slots[idx]["elapsed"] = float(slot_data.get("elapsed", 0.0))
		_slots[idx]["duration"] = float(slot_data.get("duration", _incubation_duration))


func _find_slot(slot_id: int) -> int:
	for i in range(_slots.size()):
		if int(_slots[i]["slot_id"]) == slot_id:
			return i
	return -1


func _pick_dragon_name() -> String:
	if _dragon_names.is_empty():
		return "Dragon"
	var n: String = str(_dragon_names[_name_index % _dragon_names.size()])
	_name_index += 1
	return n
