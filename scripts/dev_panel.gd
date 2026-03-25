class_name DevPanel
extends Control

# Reference set in _ready by walking up the scene tree
var _main: Node2D

# Built programmatically
var _panel: PanelContainer
var _toggle_btn: Button
var _pause_btn: Button
var _stats_label: Label
var _pause_overlay: Label

# Config spinboxes / checkbox
var _sb_ants: SpinBox
var _sb_food_sources: SpinBox
var _sb_food_qty: SpinBox
var _sb_fight_range: SpinBox
var _cb_random_pos: CheckBox

const PANEL_WIDTH := 245.0


func _ready() -> void:
	# Walk up: DevPanel → UI (CanvasLayer) → Main
	_main = get_parent().get_parent() as Node2D
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_pause_overlay()
	_build_toggle_button()
	_build_panel()


func _process(_delta: float) -> void:
	if _stats_label != null and _panel.visible:
		_update_stats_label()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	match (event as InputEventKey).keycode:
		KEY_F1:    _toggle_panel()
		KEY_SPACE: _toggle_pause()
		KEY_R:     _do_restart()


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_pause_overlay() -> void:
	_pause_overlay = Label.new()
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_overlay.text = "PAUSED"
	_pause_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_overlay.add_theme_font_size_override("font_size", 48)
	_pause_overlay.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_pause_overlay.anchor_left = 0.0
	_pause_overlay.anchor_top = 0.0
	_pause_overlay.anchor_right = 1.0
	_pause_overlay.anchor_bottom = 1.0
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.hide()
	add_child(_pause_overlay)


func _build_toggle_button() -> void:
	_toggle_btn = Button.new()
	_toggle_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_toggle_btn.text = "DEV  F1"
	_toggle_btn.anchor_left = 0.0
	_toggle_btn.anchor_top = 1.0
	_toggle_btn.anchor_right = 0.0
	_toggle_btn.anchor_bottom = 1.0
	_toggle_btn.offset_left = 10.0
	_toggle_btn.offset_top = -38.0
	_toggle_btn.offset_right = 90.0
	_toggle_btn.offset_bottom = -10.0
	_toggle_btn.pressed.connect(_toggle_panel)
	add_child(_toggle_btn)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.anchor_left = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -PANEL_WIDTH
	_panel.offset_right = 0.0
	_panel.hide()
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.custom_minimum_size.x = PANEL_WIDTH - 20.0
	margin.add_child(vbox)

	_add_title(vbox, "Dev Tools")
	_add_separator(vbox)

	# --- Controls section ---
	_add_section_label(vbox, "Controls")

	var ctrl_row := HBoxContainer.new()
	vbox.add_child(ctrl_row)

	_pause_btn = Button.new()
	_pause_btn.text = "Pause"
	_pause_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_btn.pressed.connect(_toggle_pause)
	ctrl_row.add_child(_pause_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart  R"
	restart_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_btn.pressed.connect(_do_restart)
	ctrl_row.add_child(restart_btn)

	_add_section_label(vbox, "Speed")
	var speed_row := HBoxContainer.new()
	vbox.add_child(speed_row)
	for spd: float in [0.5, 1.0, 2.0, 4.0]:
		var btn := Button.new()
		btn.text = "%.0fx" % spd if spd >= 1.0 else "0.5x"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void: Engine.time_scale = spd)
		speed_row.add_child(btn)

	_add_separator(vbox)

	# --- Config section ---
	_add_section_label(vbox, "Config  (restart to apply)")

	_sb_ants = _add_spinbox(vbox, "Starting ants / colony", 5, 50, _main.cfg_initial_ants)
	_sb_ants.value_changed.connect(func(v: float) -> void: _main.cfg_initial_ants = int(v))

	_sb_food_sources = _add_spinbox(vbox, "Food sources", 1, 15, _main.cfg_food_source_count)
	_sb_food_sources.value_changed.connect(func(v: float) -> void: _main.cfg_food_source_count = int(v))

	_sb_food_qty = _add_spinbox(vbox, "Food qty / source", 10, 200, _main.cfg_food_quantity, 5)
	_sb_food_qty.value_changed.connect(func(v: float) -> void: _main.cfg_food_quantity = int(v))

	_sb_fight_range = _add_spinbox(vbox, "Fight range (px)", 2, 40, _main.cfg_fight_range)
	_sb_fight_range.value_changed.connect(func(v: float) -> void: _main.cfg_fight_range = v)

	var pos_row := HBoxContainer.new()
	vbox.add_child(pos_row)
	var pos_lbl := Label.new()
	pos_lbl.text = "Random positions"
	pos_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pos_lbl.add_theme_font_size_override("font_size", 13)
	pos_row.add_child(pos_lbl)
	_cb_random_pos = CheckBox.new()
	_cb_random_pos.button_pressed = _main.cfg_random_positions
	_cb_random_pos.toggled.connect(func(v: bool) -> void: _main.cfg_random_positions = v)
	pos_row.add_child(_cb_random_pos)

	_add_separator(vbox)

	# --- Resolution section ---
	_add_section_label(vbox, "Resolution  (standalone only)")
	const PRESETS: Array[Dictionary] = [
		{"label": "800 x 500",   "size": Vector2i(800,  500)},
		{"label": "1280 x 800",  "size": Vector2i(1280, 800)},
		{"label": "1920 x 1080", "size": Vector2i(1920, 1080)},
		{"label": "2560 x 1440", "size": Vector2i(2560, 1440)},
	]
	for preset: Dictionary in PRESETS:
		var btn := Button.new()
		btn.text = preset.label
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var size: Vector2i = preset.size
		btn.pressed.connect(func() -> void: _set_resolution(size))
		vbox.add_child(btn)

	_add_separator(vbox)

	# --- Stats section ---
	_add_section_label(vbox, "Live Stats")

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 13)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	vbox.add_child(_stats_label)


# --- Widget helpers ---

func _add_title(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	parent.add_child(lbl)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	parent.add_child(lbl)


func _add_separator(parent: VBoxContainer) -> void:
	parent.add_child(HSeparator.new())


func _add_spinbox(parent: VBoxContainer, label: String,
		min_val: float, max_val: float, current: float, step: float = 1.0) -> SpinBox:
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13)
	parent.add_child(lbl)
	var sb := SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = step
	sb.value = current
	sb.suffix = ""
	parent.add_child(sb)
	return sb


# --- Actions ---

func _toggle_panel() -> void:
	_panel.visible = not _panel.visible


func _toggle_pause() -> void:
	if _main.is_paused():
		_main.resume_sim()
		_pause_btn.text = "Pause"
		_pause_overlay.hide()
	else:
		_main.pause_sim()
		_pause_btn.text = "Resume"
		_pause_overlay.show()


func _do_restart() -> void:
	if _main.is_paused():
		_main.resume_sim()
		_pause_btn.text = "Pause"
		_pause_overlay.hide()
	_main.restart()


# --- Live stats ---

func _set_resolution(size: Vector2i) -> void:
	if OS.has_feature("editor"):
		return
	DisplayServer.window_set_size(size)
	var screen_pos := DisplayServer.screen_get_position()
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position(screen_pos + (screen_size - size) / 2)


func _update_stats_label() -> void:
	var cols: Array[Colony] = _main._colonies
	var total_secs := int(_main.sim_time)
	var mm := total_secs / 60
	var ss := total_secs % 60
	var fps := Engine.get_frames_per_second()

	var total_ants := 0
	for col: Colony in cols:
		total_ants += col.population

	var lines: PackedStringArray = []
	lines.append("Time: %02d:%02d   FPS: %d" % [mm, ss, fps])
	lines.append("Total ants: %d   Fights: %d" % [total_ants, _main.combat_events])
	lines.append("")

	for col: Colony in cols:
		var c_name := "Colony %d" % (col.colony_id + 1)
		if col.is_alive:
			lines.append("%s  Pop:%d  Food:%d" % [c_name, col.population, col.food_collected])
			lines.append("  Spawned:%d  Lost:%d" % [col.ants_spawned, col.combat_losses])
		else:
			lines.append("%s  ELIMINATED" % c_name)
		lines.append("")

	_stats_label.text = "\n".join(lines)
