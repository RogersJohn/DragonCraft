extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal new_game_requested
signal continue_requested

@onready var _new_game_btn: Button = $NewGameButton
@onready var _continue_btn: Button = $ContinueButton


func _ready() -> void:
	var has_saves := SaveManager.has_saves()
	_new_game_btn.modulate.a = 0.0
	_continue_btn.modulate.a = 0.0
	_continue_btn.visible = has_saves
	UITheme.apply_gold_button(_continue_btn, 18, true)
	UITheme.apply_gold_button(_new_game_btn, 18, false)
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	await get_tree().create_timer(2.0).timeout
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_new_game_btn, "modulate:a", 1.0, 0.5)
	if has_saves:
		tween.tween_property(_continue_btn, "modulate:a", 1.0, 0.5)


func _on_new_game_pressed() -> void:
	_new_game_btn.disabled = true
	_continue_btn.disabled = true
	new_game_requested.emit()


func _on_continue_pressed() -> void:
	_new_game_btn.disabled = true
	_continue_btn.disabled = true
	continue_requested.emit()
