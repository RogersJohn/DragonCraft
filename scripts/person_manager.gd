extends Node

signal role_changed(person_id: int, new_role: String)

const Person = preload("res://scripts/person.gd")

var _people: Array = []
var _next_id: int = 6
var _next_name_index: int = 5
var _name_pool: Array = []
var _house_manager: Node = null


func _ready() -> void:
	pass


func init(house_manager: Node) -> void:
	_house_manager = house_manager
	_load_data()


func _load_data() -> void:
	var fallback := {
		"starting_people": [
			{"id": 1, "name": "Aldric",  "house_id": 1, "role": "villager"},
			{"id": 2, "name": "Brenna",  "house_id": 2, "role": "villager"},
			{"id": 3, "name": "Caelan",  "house_id": 3, "role": "villager"},
			{"id": 4, "name": "Dwyn",    "house_id": 4, "role": "villager"},
			{"id": 5, "name": "Eira",    "house_id": 5, "role": "villager"}
		],
		"name_pool": [
			"Aldric", "Brenna", "Caelan", "Dwyn", "Eira",
			"Fendrel", "Gilda", "Hadwin", "Isadora", "Jorah",
			"Kaela", "Leoric", "Morwen", "Niamh", "Osric",
			"Petra", "Quillan", "Rowena", "Silas", "Tara"
		],
		"next_id": 6,
		"next_name_index": 5
	}
	if not FileAccess.file_exists("res://data/people.json"):
		push_error("people.json not found — using fallback people data")
		_apply_data(fallback)
		return
	var file := FileAccess.open("res://data/people.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("people.json failed to parse — using fallback people data")
		_apply_data(fallback)
		return
	_apply_data(parsed)


func _apply_data(data: Dictionary) -> void:
	_name_pool = data.get("name_pool", [])
	_next_id = int(data.get("next_id", 6))
	_next_name_index = int(data.get("next_name_index", 5))
	_people.clear()
	for d in data.get("starting_people", []):
		_people.append(_person_from_dict(d))


func _person_from_dict(d: Dictionary) -> Object:
	var p := Person.new(
		int(d["id"]),
		str(d["name"]),
		int(d["house_id"]),
		str(d.get("role", "villager"))
	)
	for item in d.get("inventory", []):
		p.inventory.append(item.duplicate())
	return p


func get_population() -> int:
	return _people.size()


func get_max_population() -> int:
	if _house_manager == null:
		return 0
	return _house_manager.get_max_population()


func get_person(id: int) -> Object:
	for p in _people:
		if p.id == id:
			return p
	return null


func get_people_in_house(house_id: int) -> Array:
	var result := []
	for p in _people:
		if p.house_id == house_id:
			result.append(p)
	return result


func add_settler(house_id: int) -> Object:
	if _house_manager == null:
		return null
	if get_people_in_house(house_id).size() >= _house_manager.get_capacity(house_id):
		return null
	var settler_name := _pick_next_name()
	var p := Person.new(_next_id, settler_name, house_id, "villager")
	_people.append(p)
	_next_id += 1
	return p


func _pick_next_name() -> String:
	if _name_pool.is_empty():
		return "Settler %d" % _next_id
	var n: String = _name_pool[_next_name_index % _name_pool.size()]
	_next_name_index += 1
	return n


func drop_item(person_id: int, item_id: String) -> bool:
	var p := get_person(person_id)
	if p == null:
		return false
	return p.remove_item(item_id)


func set_role(person_id: int, role: String) -> void:
	var p := get_person(person_id)
	if p == null:
		return
	p.role = role
	p.is_explorer = role == "explorer"
	role_changed.emit(person_id, role)


func get_explorer_snapshot() -> Array:
	var result := []
	for p in _people:
		if p.is_explorer:
			result.append({
				"id": p.id,
				"name": p.name,
				"inventory_size": p.inventory.size()
			})
	return result


func apply_egg_pickup(egg_data: Dictionary, person_id: int) -> void:
	var p := get_person(person_id)
	if p == null:
		return
	var item := {
		"type": "egg",
		"id": str(egg_data.get("id", "")),
		"species": str(egg_data.get("species", "unknown")),
		"found_on_day": GameClock.get_current_day()
	}
	p.add_item(item)


func get_explorers() -> Array:
	var result := []
	for p in _people:
		if p.is_explorer:
			result.append(p)
	return result


func to_dict() -> Dictionary:
	var people_data := []
	for p in _people:
		people_data.append(p.to_dict())
	return {
		"people": people_data,
		"next_id": _next_id,
		"next_name_index": _next_name_index
	}


func restore(data: Dictionary) -> void:
	_people.clear()
	for d in data.get("people", []):
		_people.append(_person_from_dict(d))
	_next_id = int(data.get("next_id", _next_id))
	_next_name_index = int(data.get("next_name_index", _next_name_index))
