extends Control

const PRESETS := [
	{"label": "800 × 500",   "size": Vector2i(800,  500)},
	{"label": "1280 × 800",  "size": Vector2i(1280, 800)},
	{"label": "1920 × 1080", "size": Vector2i(1920, 1080)},
	{"label": "2560 × 1440", "size": Vector2i(2560, 1440)},
]

@onready var panel: Panel = $Panel


func _ready() -> void:
	panel.hide()
	var vbox: VBoxContainer = $Panel/VBoxContainer
	for preset in PRESETS:
		var btn := Button.new()
		btn.text = preset.label
		btn.pressed.connect(_set_resolution.bind(preset.size))
		vbox.add_child(btn)


func _on_toggle_pressed() -> void:
	panel.visible = not panel.visible


func _set_resolution(size: Vector2i) -> void:
	panel.hide()
	# DisplayServer.window_set_size() cannot resize the editor's embedded window.
	# It works correctly when the project is run standalone (outside the editor).
	if OS.has_feature("editor"):
		return
	DisplayServer.window_set_size(size)
	var screen_pos := DisplayServer.screen_get_position()
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position(screen_pos + (screen_size - size) / 2)
