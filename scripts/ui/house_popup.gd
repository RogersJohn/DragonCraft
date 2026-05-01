extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal settler_requested(house_id: int)
signal closed

var _house_id: int = 0
var _settler_cost: int = 50
var _house_manager: Node = null

@onready var _close_button: Button = $CloseButton
@onready var _name_label: Label = $PopupPanel/VBox/HouseNameLabel
@onready var _occupants_label: Label = $PopupPanel/VBox/OccupantsLabel
@onready var _cost_label: Label = $PopupPanel/VBox/CostLabel
@onready var _settler_button: Button = $PopupPanel/VBox/SettlerButton
@onready var _reason_label: Label = $PopupPanel/VBox/ReasonLabel


func _ready() -> void:
	_close_button.pressed.connect(func(): closed.emit())
	_settler_button.pressed.connect(_on_settler_button_pressed)
	UITheme.apply_gold_button(_settler_button)


func setup(house_data: Dictionary, food: float, settler_cost: int, house_manager: Node) -> void:
	_house_id = int(house_data["id"])
	_settler_cost = settler_cost
	_house_manager = house_manager
	_name_label.text = str(house_data["name"])
	_cost_label.text = "Cost: %d Food" % settler_cost
	refresh(house_data, food)


func refresh(house_data: Dictionary, food: float) -> void:
	var occupants := int(house_data["occupants"])
	var capacity := int(house_data["capacity"])
	var reason := _get_disable_reason(occupants, capacity, food)
	_occupants_label.text = "%d / %d" % [occupants, capacity]
	_settler_button.disabled = reason != ""
	_reason_label.text = reason


func _get_disable_reason(occupants: int, capacity: int, food: float) -> String:
	if _house_manager != null and not _house_manager.is_house_unlocked(_house_id):
		return "Available on day %d" % _house_manager.get_unlock_day(_house_id)
	if not SeasonManager.is_population_growth_allowed():
		return "Winter — no growth"
	if food < float(_settler_cost):
		return "Not enough food"
	if occupants >= capacity:
		return "House is full"
	return ""


func _on_settler_button_pressed() -> void:
	settler_requested.emit(_house_id)
