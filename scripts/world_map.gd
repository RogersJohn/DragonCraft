extends Control

signal enter_village

@onready var _zone: Button = $VillageZone


func _ready() -> void:
	_zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_zone()
	_zone.button_down.connect(_on_zone_pressed)


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
