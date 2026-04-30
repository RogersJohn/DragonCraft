extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal scene_transition
signal continue_requested

@onready var _button: Button = $EnterButton
@onready var _continue_button: Button = $ContinueButton


func _ready() -> void:
	var has_saves := SaveManager.has_saves()
	_button.modulate.a = 0.0
	_continue_button.modulate.a = 0.0
	_continue_button.visible = has_saves
	UITheme.apply_gold_button(_button, 22)
	UITheme.apply_gold_button(_continue_button, 22)
	_button.pressed.connect(_on_button_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	await get_tree().create_timer(2.0).timeout
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_button, "modulate:a", 1.0, 0.5)
	if has_saves:
		tween.tween_property(_continue_button, "modulate:a", 1.0, 0.5)


func _on_button_pressed() -> void:
	_button.disabled = true
	_continue_button.disabled = true
	scene_transition.emit()


func _on_continue_pressed() -> void:
	_button.disabled = true
	_continue_button.disabled = true
	continue_requested.emit()
