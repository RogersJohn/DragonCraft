extends Node

const TITLE_SCREEN_SCENE := preload("res://scenes/TitleScreen.tscn")
const VILLAGE_SCENE := preload("res://scenes/Village.tscn")
const FADE_HALF := 0.75

var _overlay: ColorRect
var _current: Node


func _ready() -> void:
	_overlay = $Overlay
	_spawn_title_screen()


func _spawn_title_screen() -> void:
	_current = TITLE_SCREEN_SCENE.instantiate()
	add_child(_current)
	move_child(_overlay, get_child_count() - 1)
	_current.scene_transition.connect(_on_transition)


func _on_transition() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_HALF)
	tween.tween_callback(_swap_to_village)
	tween.tween_property(_overlay, "color:a", 0.0, FADE_HALF)


func _swap_to_village() -> void:
	_current.queue_free()
	_current = VILLAGE_SCENE.instantiate()
	add_child(_current)
	move_child(_current, 0)
