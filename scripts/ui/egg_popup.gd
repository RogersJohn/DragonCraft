extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

const SPECIES_COLOURS := {
	"forest_drake": Color(0.2, 0.6, 0.15),
	"stone_drake":  Color(0.5, 0.45, 0.38),
	"ember_drake":  Color(0.85, 0.25, 0.1),
	"sea_drake":    Color(0.1, 0.4, 0.75),
	"gold_drake":   Color(0.85, 0.7, 0.1),
	"unknown":      Color(0.4, 0.4, 0.4)
}

signal pick_up_requested
signal leave_requested

@onready var _species_color_panel: Panel = $PopupPanel/VBox/SpeciesColorPanel
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
	var colour: Color = SPECIES_COLOURS.get(species, SPECIES_COLOURS["unknown"])
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_species_color_panel.add_theme_stylebox_override("panel", style)
	_species_label.text = _format_species(species)
	_pick_up_button.disabled = not can_pick_up
	_message_label.text = "" if can_pick_up else "No explorer has inventory space"


static func _format_species(raw: String) -> String:
	if raw == "unknown":
		return "Unknown Species"
	var words := raw.replace("_", " ").split(" ")
	var result := ""
	for w in words:
		result += w.capitalize() + " "
	return result.strip_edges()
