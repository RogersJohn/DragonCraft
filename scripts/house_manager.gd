extends Node

var _houses: Array = []
var _settler_food_cost: int = 50
var _settler_unlock_day: int = 10


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	var fallback := {
		"houses": [
			{"id": 1, "name": "House 1", "capacity": 5, "founding_day": 0},
			{"id": 2, "name": "House 2", "capacity": 5, "founding_day": 0},
			{"id": 3, "name": "House 3", "capacity": 5, "founding_day": 0},
			{"id": 4, "name": "House 4", "capacity": 5, "founding_day": 0},
			{"id": 5, "name": "House 5", "capacity": 5, "founding_day": 0}
		],
		"settler_food_cost": 50,
		"settler_unlock_day": 10
	}
	if not FileAccess.file_exists("res://data/houses.json"):
		push_error("houses.json not found — using fallback house data")
		_apply_data(fallback)
		return
	var file := FileAccess.open("res://data/houses.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("houses.json failed to parse — using fallback house data")
		_apply_data(fallback)
		return
	_apply_data(parsed)


func _apply_data(data: Dictionary) -> void:
	_settler_food_cost = int(data["settler_food_cost"])
	_settler_unlock_day = int(data.get("settler_unlock_day", 10))
	_houses = data["houses"].duplicate(true)
	for h in _houses:
		if not h.has("founding_day"):
			h["founding_day"] = 0


func get_house(id: int) -> Dictionary:
	for h in _houses:
		if int(h["id"]) == id:
			return h
	return {}


func get_capacity(house_id: int) -> int:
	var h := get_house(house_id)
	if h.is_empty():
		return 0
	return int(h["capacity"])


func get_max_population() -> int:
	var total := 0
	for h in _houses:
		total += int(h["capacity"])
	return total


func get_settler_food_cost() -> int:
	return _settler_food_cost


func is_house_unlocked(house_id: int) -> bool:
	var h := get_house(house_id)
	if h.is_empty():
		return false
	return GameClock.get_current_day() >= int(h["founding_day"]) + _settler_unlock_day


func get_unlock_day(house_id: int) -> int:
	var h := get_house(house_id)
	if h.is_empty():
		return _settler_unlock_day
	return int(h["founding_day"]) + _settler_unlock_day
