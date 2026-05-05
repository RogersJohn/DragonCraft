extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

signal item_dropped(person_id: int, item_id: String)
signal explorer_toggled(person_id: int, is_explorer: bool)
signal closed

var _person_id: int = 0
var _is_explorer: bool = false

@onready var _close_button: Button = $CloseButton
@onready var _name_label: Label = $PopupPanel/VBox/PersonNameLabel
@onready var _role_label: Label = $PopupPanel/VBox/RoleLabel
@onready var _house_label: Label = $PopupPanel/VBox/HouseLabel
@onready var _slot_container: VBoxContainer = $PopupPanel/VBox/SlotContainer
@onready var _explorer_button: Button = $PopupPanel/VBox/ExplorerButton
@onready var _close_inner: Button = $PopupPanel/VBox/CloseInnerButton


func _ready() -> void:
	_close_button.pressed.connect(func(): closed.emit())
	_close_inner.pressed.connect(func(): closed.emit())
	_explorer_button.pressed.connect(_on_explorer_pressed)
	UITheme.apply_gold_button(_explorer_button)
	UITheme.apply_gold_button(_close_inner)


func setup(snapshot: Dictionary) -> void:
	_person_id = int(snapshot["id"])
	_is_explorer = bool(snapshot.get("is_explorer", false))
	_name_label.text = str(snapshot["name"])
	_role_label.text = str(snapshot.get("role", "villager")).capitalize()
	_house_label.text = str(snapshot.get("house_name", ""))
	_refresh_explorer_button()
	_refresh_slots(snapshot.get("inventory", []))


func _refresh_slots(inventory: Array) -> void:
	for child in _slot_container.get_children():
		child.free()
	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Empty"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		_slot_container.add_child(empty_label)
	else:
		for item in inventory:
			var row := HBoxContainer.new()
			var item_label := Label.new()
			var species := str(item.get("species", ""))
			if species != "" and species != "unknown":
				item_label.text = "%s (%s)" % [str(item.get("type", "item")).capitalize(), species]
			else:
				item_label.text = str(item.get("type", "item")).capitalize()
			item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var drop_btn := Button.new()
			drop_btn.text = "Drop"
			var item_id := str(item.get("id", ""))
			drop_btn.pressed.connect(func(): item_dropped.emit(_person_id, item_id))
			row.add_child(item_label)
			row.add_child(drop_btn)
			_slot_container.add_child(row)


func _refresh_explorer_button() -> void:
	_explorer_button.text = "Resign as Explorer" if _is_explorer else "Set as Explorer"


func watch_for_explorer_promotion(person_manager: Node) -> void:
	person_manager.role_changed.connect(func(pid: int, new_role: String):
		if pid == _person_id and new_role == "explorer":
			closed.emit()
	)


func _on_explorer_pressed() -> void:
	explorer_toggled.emit(_person_id, not _is_explorer)
