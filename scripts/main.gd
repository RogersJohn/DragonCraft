extends Node

const TITLE_SCREEN_SCENE := preload("res://scenes/TitleScreen.tscn")
const WORLD_MAP_SCENE := preload("res://scenes/WorldMap.tscn")
const VILLAGE_SCENE := preload("res://scenes/Village.tscn")
const FADE_HALF := 0.75

var _overlay: ColorRect
var _current: Node


func _ready() -> void:
	_overlay = $Overlay
	_spawn_title_screen()


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
	move_child(_overlay, get_child_count() - 1)
	_current.scene_transition.connect(func(): _crossfade_to(_spawn_world_map))


func _spawn_world_map() -> void:
	_current = WORLD_MAP_SCENE.instantiate()
	add_child(_current)
	move_child(_current, 0)
	_current.enter_village.connect(func(): _crossfade_to(_spawn_village))


func _spawn_village() -> void:
	_current = VILLAGE_SCENE.instantiate()
	add_child(_current)
	move_child(_current, 0)
	_current.back_to_map.connect(func(): _crossfade_to(_spawn_world_map))
