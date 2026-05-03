extends Node

signal egg_discovered(egg_data: Dictionary)
signal nearby_changed(is_nearby: bool)

const DISCOVERY_RADIUS := 50.0
const NEARBY_RADIUS := 150.0
const TOTAL_EGGS := 10

const SPECIES: Array = ["forest_drake", "stone_drake", "ember_drake", "sea_drake", "gold_drake"]
const SPECIES_WEIGHTS: Array = [0.30, 0.30, 0.20, 0.15, 0.05]

const SPECIES_COLOURS := {
	"forest_drake": Color(0.2, 0.6, 0.15),
	"stone_drake":  Color(0.5, 0.45, 0.38),
	"ember_drake":  Color(0.85, 0.25, 0.1),
	"sea_drake":    Color(0.1, 0.4, 0.75),
	"gold_drake":   Color(0.85, 0.7, 0.1),
	"unknown":      Color(0.4, 0.4, 0.4)
}

# Biome regions as normalised [x_min, y_min, x_max, y_max]
const BIOMES: Dictionary = {
	"plains":    [0.20, 0.40, 0.70, 0.75],
	"mountains": [0.00, 0.00, 0.35, 0.45],
	"forest":    [0.55, 0.15, 0.95, 0.55],
	"beach":     [0.15, 0.75, 0.55, 0.95],
	"ocean":     [0.80, 0.60, 0.98, 0.98]
}
const VILLAGE_NORM_X := 0.42
const VILLAGE_NORM_Y := 0.33
const NEAR_VILLAGE_RADIUS_PX := 100.0

var _eggs: Array = []
var _explorer_node: Node = null
var _map_size: Vector2 = Vector2(1280.0, 720.0)
var _markers: Dictionary = {}
var _pickup_markers: Dictionary = {}
var _initialized: bool = false
var _check_timer: Timer = null


func _ready() -> void:
	_check_timer = Timer.new()
	_check_timer.wait_time = 0.5
	_check_timer.autostart = true
	_check_timer.timeout.connect(_on_discovery_check)
	add_child(_check_timer)


func init(map_size: Vector2, explorer_node: Node) -> void:
	_map_size = map_size
	_explorer_node = explorer_node
	if SaveManager.has_eggs_save():
		_eggs = SaveManager.load_eggs()
	else:
		_generate_eggs()
		SaveManager.save_eggs(_eggs)
	_rebuild_markers()
	_initialized = true


func _generate_eggs() -> void:
	_eggs.clear()
	var egg_count := 1
	for i in range(2):
		_eggs.append(_make_egg("egg_%03d" % egg_count, _random_near_village(), "plains"))
		egg_count += 1
	for i in range(3):
		_eggs.append(_make_egg("egg_%03d" % egg_count, _random_in_biome("plains"), "plains"))
		egg_count += 1
	for biome in ["mountains", "forest", "beach"]:
		_eggs.append(_make_egg("egg_%03d" % egg_count, _random_in_biome(biome), biome))
		egg_count += 1
	var ocean_egg: Dictionary = _make_egg("egg_%03d" % egg_count, Vector2(0.88, 0.82), "ocean")
	ocean_egg["requires_boat"] = true
	_eggs.append(ocean_egg)
	egg_count += 1
	var extra_biomes: Array = ["mountains", "forest", "beach"]
	var extra_biome: String = extra_biomes[randi() % extra_biomes.size()]
	_eggs.append(_make_egg("egg_%03d" % egg_count, _random_in_biome(extra_biome), extra_biome))


func _make_egg(egg_id: String, norm_pos: Vector2, biome: String) -> Dictionary:
	return {
		"id": egg_id,
		"position_x": norm_pos.x,
		"position_y": norm_pos.y,
		"biome": biome,
		"species": "unknown",
		"discovered": false,
		"picked_up": false,
		"flagged": false,
		"requires_boat": false
	}


func _random_near_village() -> Vector2:
	var village_px := Vector2(VILLAGE_NORM_X, VILLAGE_NORM_Y) * _map_size
	var angle := randf() * TAU
	var r := randf() * NEAR_VILLAGE_RADIUS_PX
	var pos_px := village_px + Vector2(cos(angle) * r, sin(angle) * r)
	pos_px = pos_px.clamp(Vector2.ZERO, _map_size)
	return pos_px / _map_size


func _random_in_biome(biome: String) -> Vector2:
	var b: Array = BIOMES[biome]
	return Vector2(
		float(b[0]) + randf() * (float(b[2]) - float(b[0])),
		float(b[1]) + randf() * (float(b[3]) - float(b[1]))
	)


func _rebuild_markers() -> void:
	for marker in _markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()
	for i in range(_eggs.size()):
		var egg: Dictionary = _eggs[i]
		if bool(egg.get("flagged", false)) and not bool(egg.get("picked_up", false)):
			_add_flag_marker(egg)


func _add_flag_marker(egg: Dictionary) -> void:
	var screen_pos: Vector2 = _norm_to_screen(Vector2(float(egg["position_x"]), float(egg["position_y"])))
	var container := Control.new()
	container.position = screen_pos + Vector2(-10.0, -20.0)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow := Label.new()
	shadow.text = "🚩"
	shadow.add_theme_font_size_override("font_size", 20)
	shadow.add_theme_color_override("font_color", Color(0, 0, 0))
	shadow.position = Vector2(1.0, 1.0)
	var label := Label.new()
	label.text = "🚩"
	label.add_theme_font_size_override("font_size", 20)
	get_parent().add_child(container)
	container.add_child(shadow)
	container.add_child(label)
	_markers[str(egg["id"])] = container


func _add_pickup_marker(egg: Dictionary) -> void:
	var species: String = str(egg.get("species", "unknown"))
	var colour: Color = SPECIES_COLOURS.get(species, SPECIES_COLOURS["unknown"])
	colour.a = 0.6
	var dot := ColorRect.new()
	dot.color = colour
	dot.size = Vector2(10.0, 10.0)
	var screen_pos: Vector2 = _norm_to_screen(Vector2(float(egg["position_x"]), float(egg["position_y"])))
	dot.position = screen_pos - Vector2(5.0, 5.0)
	get_parent().add_child(dot)
	_pickup_markers[str(egg["id"])] = dot


func _norm_to_screen(norm: Vector2) -> Vector2:
	return Vector2(norm.x * _map_size.x, norm.y * _map_size.y)


func _on_discovery_check() -> void:
	if not _initialized:
		return
	if _explorer_node == null or not is_instance_valid(_explorer_node):
		return
	if not _explorer_node.visible:
		nearby_changed.emit(false)
		return
	var explorer_center: Vector2 = _explorer_node.position + Vector2(10.0, 10.0)
	var any_nearby := false
	for i in range(_eggs.size()):
		var egg: Dictionary = _eggs[i]
		if bool(egg.get("discovered", false)) or bool(egg.get("picked_up", false)):
			continue
		if bool(egg.get("requires_boat", false)):
			continue
		var egg_pos: Vector2 = _norm_to_screen(Vector2(float(egg["position_x"]), float(egg["position_y"])))
		var dist: float = explorer_center.distance_to(egg_pos)
		if dist < DISCOVERY_RADIUS:
			_discover_egg(egg)
			return
		elif dist < NEARBY_RADIUS:
			any_nearby = true
	nearby_changed.emit(any_nearby)


func _discover_egg(egg: Dictionary) -> void:
	egg["discovered"] = true
	egg["species"] = _roll_species()
	SaveManager.save_eggs(_eggs)
	egg_discovered.emit(egg.duplicate())


func _roll_species() -> String:
	var r := randf()
	var cumulative := 0.0
	for i in range(SPECIES.size()):
		cumulative += float(SPECIES_WEIGHTS[i])
		if r <= cumulative:
			return str(SPECIES[i])
	return str(SPECIES[0])


func set_paused(paused: bool) -> void:
	if _check_timer != null:
		_check_timer.paused = paused


func flag_egg(egg_id: String) -> void:
	for i in range(_eggs.size()):
		var egg: Dictionary = _eggs[i]
		if str(egg["id"]) == egg_id:
			egg["flagged"] = true
			_add_flag_marker(egg)
			SaveManager.save_eggs(_eggs)
			return


func pickup_egg(egg_id: String) -> void:
	for i in range(_eggs.size()):
		var egg: Dictionary = _eggs[i]
		if str(egg["id"]) == egg_id:
			egg["picked_up"] = true
			if _markers.has(egg_id):
				if is_instance_valid(_markers[egg_id]):
					_markers[egg_id].queue_free()
				_markers.erase(egg_id)
			_add_pickup_marker(egg)
			SaveManager.save_eggs(_eggs)
			return
