extends Control

signal enter_village

@onready var _zone: Button = $VillageZone


func _ready() -> void:
	_style_zone()
	_zone.pressed.connect(_on_zone_pressed)


func _on_zone_pressed() -> void:
	_zone.disabled = true
	enter_village.emit()


func _style_zone() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.2, 0.25)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(1.0, 0.85, 0.2, 0.7)
	var focus := StyleBoxEmpty.new()
	_zone.add_theme_stylebox_override("normal", normal)
	_zone.add_theme_stylebox_override("hover", hover)
	_zone.add_theme_stylebox_override("pressed", hover)
	_zone.add_theme_stylebox_override("focus", focus)
	_zone.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_zone.add_theme_font_size_override("font_size", 14)
