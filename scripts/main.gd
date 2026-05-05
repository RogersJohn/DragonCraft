extends Node

const TITLE_SCREEN_SCENE := preload("res://scenes/TitleScreen.tscn")
const WORLD_MAP_SCENE := preload("res://scenes/WorldMap.tscn")
const VILLAGE_SCENE := preload("res://scenes/Village.tscn")
const TIME_CONTROLS_SCENE := preload("res://scenes/ui/TimeControls.tscn")
const FADE_HALF := 0.75

var _overlay: ColorRect
var _current: Node
var _time_controls: Node = null
var _pending_state: Dictionary = {}
var _explorer_snapshot: Array = []
var _pending_egg_pickups: Array = []
var _pending_egg_transfers: Array = []


func _ready() -> void:
	_overlay = $Overlay
	_time_controls = TIME_CONTROLS_SCENE.instantiate()
	add_child(_time_controls)
	_spawn_title_screen()


func _ensure_overlay_on_top() -> void:
	move_child(_overlay, get_child_count() - 1)
	move_child(_time_controls, get_child_count() - 2)


func _crossfade_to(spawn_fn: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_HALF)
	tween.tween_callback(func():
		_current.queue_free()
		spawn_fn.call()
	)
	tween.tween_property(_overlay, "color:a", 0.0, FADE_HALF)


func _spawn_title_screen() -> void:
	_current = TITLE_SCREEN_SCENE.instantiate()
	add_child(_current)
	_ensure_overlay_on_top()
	_time_controls.hide_controls()
	TimeController.pause()
	_current.new_game_requested.connect(_on_new_game_requested)
	_current.continue_requested.connect(_on_continue_requested)


func _on_new_game_requested() -> void:
	SaveManager.clear_all_saves()
	TimeController.set_speed(1.0)
	TimeController.resume()
	_crossfade_to(_spawn_world_map)


func _on_continue_requested() -> void:
	var state := SaveManager.load_game()
	if not state.is_empty():
		_pending_state = state
		SeasonManager.restore_season(
			int(state.get("season_index", 0)),
			float(state.get("season_elapsed", 0.0))
		)
		_explorer_snapshot = _extract_explorer_snapshot(state)
	_crossfade_to(_spawn_world_map)


func _extract_explorer_snapshot(state: Dictionary) -> Array:
	var result := []
	var pm_data: Dictionary = state.get("person_manager", {})
	for p in pm_data.get("people", []):
		if str(p.get("role", "")) == "explorer":
			var inv = p.get("inventory", [])
			var inv_size: int = inv.size() if inv is Array else 0
			result.append({
				"id": int(p.get("id", 0)),
				"name": str(p.get("name", "")),
				"inventory_size": inv_size
			})
	return result


func _spawn_world_map() -> void:
	_current = WORLD_MAP_SCENE.instantiate()
	add_child(_current)
	move_child(_current, 0)
	_ensure_overlay_on_top()
	_current.init_explorer(_explorer_snapshot)
	_current.enter_village.connect(func(egg_transfers: Array):
		_pending_egg_transfers = egg_transfers
		_crossfade_to(_spawn_village)
	)
	_current.egg_picked_up.connect(_on_egg_picked_up)
	_time_controls.show_controls()
	TimeController.resume()


func _on_egg_picked_up(egg_data: Dictionary, person_id: int) -> void:
	_pending_egg_pickups.append({"egg_data": egg_data, "person_id": person_id})


func _spawn_village() -> void:
	_current = VILLAGE_SCENE.instantiate()
	add_child(_current)
	move_child(_current, 0)
	_ensure_overlay_on_top()
	_time_controls.show_controls()
	_current.back_to_map.connect(func():
		_explorer_snapshot = _current.get_explorer_snapshot()
		_crossfade_to(_spawn_world_map)
	)
	if not _pending_state.is_empty():
		_current.restore_state(_pending_state)
		_pending_state = {}
	if not _pending_egg_pickups.is_empty():
		_current.apply_pending_pickups(_pending_egg_pickups)
		_pending_egg_pickups = []
	if not _explorer_snapshot.is_empty():
		_current.receive_explorer_returns(_explorer_snapshot, _pending_egg_transfers)
		_explorer_snapshot = []
	_pending_egg_transfers = []
