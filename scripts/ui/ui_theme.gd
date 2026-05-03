extends Object

static func apply_gold_button(button: Button, font_size: int = 16, highlight: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.06, 0.03)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.85, 0.2) if highlight else Color(0.75, 0.55, 0.05)
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
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled_box)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	button.add_theme_color_override("font_color_disabled", Color(0.5, 0.4, 0.1))
	button.add_theme_font_size_override("font_size", font_size)


static func apply_speed_button(button: Button, is_active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	var hover := StyleBoxFlat.new()
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	var focus := StyleBoxEmpty.new()
	if is_active:
		normal.bg_color = Color(0.75, 0.55, 0.05)
		normal.border_color = Color(1.0, 0.78, 0.15)
		hover.bg_color = Color(0.85, 0.65, 0.08)
		hover.border_color = Color(1.0, 0.85, 0.2)
		button.add_theme_color_override("font_color", Color(0.08, 0.06, 0.03))
	else:
		normal.bg_color = Color(0.08, 0.06, 0.03)
		normal.border_color = Color(0.75, 0.55, 0.05)
		hover.bg_color = Color(0.14, 0.10, 0.04)
		hover.border_color = Color(1.0, 0.78, 0.15)
		button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.08))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_font_size_override("font_size", 14)


static func apply_invisible_zone(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.2, 0.15)
	var focus := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
