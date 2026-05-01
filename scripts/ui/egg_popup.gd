extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal pick_up_requested
signal leave_requested

@onready var _species_label: Label = $PopupPanel/VBox/SpeciesLabel
@onready var _message_label: Label = $PopupPanel/VBox/MessageLabel
@onready var _pick_up_button: Button = $PopupPanel/VBox/PickUpButton
@onready var _leave_button: Button = $PopupPanel/VBox/LeaveButton


func _ready() -> void:
	_pick_up_button.pressed.connect(func(): pick_up_requested.emit())
	_leave_button.pressed.connect(func(): leave_requested.emit())
	UITheme.apply_gold_button(_pick_up_button)
	UITheme.apply_gold_button(_leave_button)


func setup(species: String, can_pick_up: bool) -> void:
	_species_label.text = "[%s egg]" % species.replace("_", " ").capitalize()
	_pick_up_button.disabled = not can_pick_up
	_message_label.text = "" if can_pick_up else "No explorer has inventory space"
