extends Control

signal scene_transition

@onready var _button: Button = $EnterButton


func _ready() -> void:
	_button.modulate.a = 0.0
	_style_button()
	_button.pressed.connect(_on_button_pressed)
	await get_tree().create_timer(2.0).timeout
	var tween := create_tween()
	tween.tween_property(_button, "modulate:a", 1.0, 0.5)


func _on_button_pressed() -> void:
	_button.disabled = true
	scene_transition.emit()


func _style_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.06, 0.03)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.75, 0.55, 0.05)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.14, 0.10, 0.04)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(1.0, 0.78, 0.15)
	var focus := StyleBoxEmpty.new()
	_button.add_theme_stylebox_override("normal", normal)
	_button.add_theme_stylebox_override("hover", hover)
	_button.add_theme_stylebox_override("pressed", hover)
	_button.add_theme_stylebox_override("focus", focus)
	_button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_button.add_theme_font_size_override("font_size", 22)
