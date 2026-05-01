extends Control

signal enter_village
signal egg_picked_up(egg_data: Dictionary, person_id: int)

const EGG_MANAGER_SCRIPT := preload("res://scripts/egg_manager.gd")
const EGG_POPUP_SCENE := preload("res://scenes/ui/EggPopup.tscn")

const EXPLORER_SPEED := 120.0
const EXPLORER_HALF := Vector2(10.0, 10.0)

@onready var _zone: Button = $VillageZone
@onready var _explorer_sprite: ColorRect = $ExplorerSprite
@onready var _no_explorer_label: Label = $NoExplorerLabel

var _egg_manager: Node = null
var _explorer_snapshot: Array = []
var _active_egg_popup: Node = null
var _pending_egg_data: Dictionary = {}
var _map_size: Vector2 = Vector2(1280.0, 720.0)
var _village_pos: Vector2 = Vector2.ZERO
var _explore_radius: float = 0.0
var _nearby_indicator: Label = null


func _ready() -> void:
	_zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_zone()
	_zone.button_down.connect(_on_zone_pressed)

	_map_size = get_viewport_rect().size
	_village_pos = Vector2(0.42 * _map_size.x, 0.33 * _map_size.y)
	_explore_radius = 0.15 * _map_size.length()

	_explorer_sprite.position = _village_pos - EXPLORER_HALF
	_explorer_sprite.visible = false

	_nearby_indicator = Label.new()
	_nearby_indicator.text = "!"
	_nearby_indicator.add_theme_font_size_override("font_size", 24)
	_nearby_indicator.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_nearby_indicator.visible = false
	add_child(_nearby_indicator)

	_egg_manager = EGG_MANAGER_SCRIPT.new()
	add_child(_egg_manager)
	_egg_manager.init(_map_size, _explorer_sprite)
	_egg_manager.egg_discovered.connect(_on_egg_discovered)
	_egg_manager.nearby_changed.connect(_on_nearby_changed)


func init_explorer(snapshot: Array) -> void:
	_explorer_snapshot = snapshot
	var has_explorer: bool = snapshot.size() > 0
	_explorer_sprite.visible = has_explorer
	_no_explorer_label.visible = not has_explorer


func _process(delta: float) -> void:
	if not _explorer_sprite.visible:
		return
	if _active_egg_popup != null:
		return
	var move_x := 0.0
	var move_y := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_y -= 1.0
	if move_x == 0.0 and move_y == 0.0:
		return
	var dir := Vector2(move_x, move_y).normalized()
	var new_pos: Vector2 = _explorer_sprite.position + dir * EXPLORER_SPEED * delta
	_explorer_sprite.position = _clamp_to_bounds(new_pos)
	if _nearby_indicator != null:
		_nearby_indicator.position = _explorer_sprite.position + Vector2(2.0, -22.0)


func _clamp_to_bounds(pos: Vector2) -> Vector2:
	var center: Vector2 = pos + EXPLORER_HALF
	center.x = clamp(center.x, 0.0, _map_size.x)
	center.y = clamp(center.y, 0.0, _map_size.y)
	var dist: float = center.distance_to(_village_pos)
	if dist > _explore_radius:
		center = _village_pos + (center - _village_pos).normalized() * _explore_radius
	return center - EXPLORER_HALF


func _on_nearby_changed(is_nearby: bool) -> void:
	if _nearby_indicator != null:
		_nearby_indicator.visible = is_nearby and _explorer_sprite.visible


func _on_egg_discovered(egg_data: Dictionary) -> void:
	_pending_egg_data = egg_data
	if _active_egg_popup != null:
		_active_egg_popup.queue_free()
	_active_egg_popup = EGG_POPUP_SCENE.instantiate()
	add_child(_active_egg_popup)
	_active_egg_popup.setup(str(egg_data.get("species", "unknown")), _has_explorer_with_space())
	_active_egg_popup.pick_up_requested.connect(_on_pick_up_requested)
	_active_egg_popup.leave_requested.connect(_on_leave_requested)


func _has_explorer_with_space() -> bool:
	for e in _explorer_snapshot:
		if int(e.get("inventory_size", 1)) < 1:
			return true
	return false


func _get_first_explorer_with_space() -> int:
	for e in _explorer_snapshot:
		if int(e.get("inventory_size", 1)) < 1:
			return int(e.get("id", -1))
	return -1


func _on_pick_up_requested() -> void:
	var person_id: int = _get_first_explorer_with_space()
	if person_id == -1:
		return
	_egg_manager.pickup_egg(str(_pending_egg_data.get("id", "")))
	egg_picked_up.emit(_pending_egg_data.duplicate(), person_id)
	for e in _explorer_snapshot:
		if int(e.get("id", -1)) == person_id:
			e["inventory_size"] = int(e.get("inventory_size", 0)) + 1
			break
	_close_egg_popup()


func _on_leave_requested() -> void:
	_egg_manager.flag_egg(str(_pending_egg_data.get("id", "")))
	_close_egg_popup()


func _close_egg_popup() -> void:
	if _active_egg_popup != null:
		_active_egg_popup.queue_free()
		_active_egg_popup = null
	_pending_egg_data = {}


func _on_zone_pressed() -> void:
	_zone.disabled = true
	enter_village.emit()


func _style_zone() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.2, 0.15)
	var focus := StyleBoxEmpty.new()
	_zone.add_theme_stylebox_override("normal", normal)
	_zone.add_theme_stylebox_override("hover", hover)
	_zone.add_theme_stylebox_override("pressed", hover)
	_zone.add_theme_stylebox_override("focus", focus)
