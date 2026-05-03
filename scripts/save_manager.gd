extends Node

const SAVE_DIR := "user://saves/"
const MANUAL_SAVE_PATH := SAVE_DIR + "manualsave.json"
const AUTOSAVE_INDEX_PATH := SAVE_DIR + "autosave_index.json"
const EGGS_SAVE_PATH := SAVE_DIR + "eggs.json"
const MAX_AUTOSAVE_SLOTS := 10


func save_game(state: Dictionary, slot: String) -> void:
	_ensure_save_dir()
	var data := state.duplicate()
	data["timestamp"] = Time.get_unix_time_from_system()
	if slot == "manual":
		_write_json(MANUAL_SAVE_PATH, data)
	else:
		var idx := _get_next_autosave_index()
		_write_json(SAVE_DIR + "autosave_%02d.json" % idx, data)
		_set_next_autosave_index((idx % MAX_AUTOSAVE_SLOTS) + 1)


func load_game() -> Dictionary:
	var candidates: Array = []
	if FileAccess.file_exists(MANUAL_SAVE_PATH):
		var d := _read_json(MANUAL_SAVE_PATH)
		if not d.is_empty():
			candidates.append(d)
	for i in range(1, MAX_AUTOSAVE_SLOTS + 1):
		var path := SAVE_DIR + "autosave_%02d.json" % i
		if FileAccess.file_exists(path):
			var d := _read_json(path)
			if not d.is_empty():
				candidates.append(d)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a, b): return float(a.get("timestamp", 0)) > float(b.get("timestamp", 0)))
	return candidates[0]


func has_saves() -> bool:
	if FileAccess.file_exists(MANUAL_SAVE_PATH):
		return true
	for i in range(1, MAX_AUTOSAVE_SLOTS + 1):
		if FileAccess.file_exists(SAVE_DIR + "autosave_%02d.json" % i):
			return true
	return false


func get_save_slot_path(slot: String, index: int) -> String:
	if slot == "manual":
		return MANUAL_SAVE_PATH
	return SAVE_DIR + "autosave_%02d.json" % index


func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: cannot open user:// directory")
		return
	if not dir.dir_exists("saves"):
		var err := dir.make_dir("saves")
		if err != OK:
			push_error("SaveManager: failed to create saves directory")


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open for writing: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open for reading: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("SaveManager: failed to parse JSON in: %s" % path)
		return {}
	return parsed


func save_eggs(eggs: Array) -> void:
	_ensure_save_dir()
	_write_json(EGGS_SAVE_PATH, {"eggs": eggs})


func load_eggs() -> Array:
	if not FileAccess.file_exists(EGGS_SAVE_PATH):
		return []
	var d: Dictionary = _read_json(EGGS_SAVE_PATH)
	var result = d.get("eggs", [])
	if result is Array:
		return result
	return []


func has_eggs_save() -> bool:
	return FileAccess.file_exists(EGGS_SAVE_PATH)


func clear_all_saves() -> void:
	_delete_file(MANUAL_SAVE_PATH)
	for i in range(1, MAX_AUTOSAVE_SLOTS + 1):
		_delete_file(SAVE_DIR + "autosave_%02d.json" % i)
	_delete_file(AUTOSAVE_INDEX_PATH)
	_delete_file(EGGS_SAVE_PATH)


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SaveManager: failed to delete: %s" % path)


func _get_next_autosave_index() -> int:
	if not FileAccess.file_exists(AUTOSAVE_INDEX_PATH):
		return 1
	var d := _read_json(AUTOSAVE_INDEX_PATH)
	return int(d.get("index", 1))


func _set_next_autosave_index(index: int) -> void:
	_write_json(AUTOSAVE_INDEX_PATH, {"index": index})
