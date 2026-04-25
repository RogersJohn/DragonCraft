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
	var empty := StyleBoxEmpty.new()
	_zone.add_theme_stylebox_override("normal", empty)
	_zone.add_theme_stylebox_override("hover", empty)
	_zone.add_theme_stylebox_override("pressed", empty)
	_zone.add_theme_stylebox_override("focus", empty)
