extends Control

signal settler_requested(house_id: int)
signal closed

var _house_id: int = 0
var _settler_cost: int = 20

@onready var _close_button: Button = $CloseButton
@onready var _name_label: Label = $PopupPanel/VBox/HouseNameLabel
@onready var _occupants_label: Label = $PopupPanel/VBox/OccupantsLabel
@onready var _cost_label: Label = $PopupPanel/VBox/CostLabel
@onready var _settler_button: Button = $PopupPanel/VBox/SettlerButton
@onready var _reason_label: Label = $PopupPanel/VBox/ReasonLabel


func _ready() -> void:
	_close_button.pressed.connect(func(): closed.emit())
	_settler_button.pressed.connect(_on_settler_button_pressed)
	_style_button()


func setup(house_data: Dictionary, food: float, settler_cost: int) -> void:
	_house_id = int(house_data["id"])
	_settler_cost = settler_cost
	_name_label.text = str(house_data["name"])
	_cost_label.text = "Cost: %d Food" % settler_cost
	refresh(house_data, food)


func refresh(house_data: Dictionary, food: float) -> void:
	var occupants := int(house_data["occupants"])
	var capacity := int(house_data["capacity"])
	_occupants_label.text = "%d / %d" % [occupants, capacity]
	var reason := _get_disable_reason(occupants, capacity, food)
	_settler_button.disabled = reason != ""
	_reason_label.text = reason


func _get_disable_reason(occupants: int, capacity: int, food: float) -> String:
	if not SeasonManager.is_population_growth_allowed():
		return "Winter — no growth"
	if food < float(_settler_cost):
		return "Not enough food"
	if occupants >= capacity:
		return "House is full"
	return ""


func _on_settler_button_pressed() -> void:
	settler_requested.emit(_house_id)


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
	var disabled_box := StyleBoxFlat.new()
	disabled_box.bg_color = Color(0.05, 0.04, 0.02)
	disabled_box.border_width_left = 2
	disabled_box.border_width_top = 2
	disabled_box.border_width_right = 2
	disabled_box.border_width_bottom = 2
	disabled_box.border_color = Color(0.4, 0.3, 0.05)
	var focus := StyleBoxEmpty.new()
	_settler_button.add_theme_stylebox_override("normal", normal)
	_settler_button.add_theme_stylebox_override("hover", hover)
	_settler_button.add_theme_stylebox_override("pressed", hover)
	_settler_button.add_theme_stylebox_override("disabled", disabled_box)
	_settler_button.add_theme_stylebox_override("focus", focus)
	_settler_button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	_settler_button.add_theme_color_override("font_color_disabled", Color(0.5, 0.4, 0.1))
	_settler_button.add_theme_font_size_override("font_size", 16)
