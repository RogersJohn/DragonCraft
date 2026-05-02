extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

@onready var _pause_button: Button = $HBox/PauseButton
@onready var _speed_1x: Button = $HBox/Speed1x
@onready var _speed_5x: Button = $HBox/Speed5x
@onready var _speed_10x: Button = $HBox/Speed10x


func _ready() -> void:
	_pause_button.pressed.connect(func(): TimeController.toggle_pause())
	_speed_1x.pressed.connect(func(): TimeController.set_speed(1.0))
	_speed_5x.pressed.connect(func(): TimeController.set_speed(5.0))
	_speed_10x.pressed.connect(func(): TimeController.set_speed(10.0))
	TimeController.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(TimeController.get_speed_multiplier(), TimeController.is_paused())


func _on_speed_changed(multiplier: float, paused: bool) -> void:
	_pause_button.text = "▶" if paused else "⏸"
	UITheme.apply_speed_button(_pause_button, paused)
	UITheme.apply_speed_button(_speed_1x, not paused and multiplier == 1.0)
	UITheme.apply_speed_button(_speed_5x, not paused and multiplier == 5.0)
	UITheme.apply_speed_button(_speed_10x, not paused and multiplier == 10.0)


func show_controls() -> void:
	visible = true


func hide_controls() -> void:
	visible = false
