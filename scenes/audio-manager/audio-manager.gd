extends Node

@onready var ui_button_click: AudioStreamPlayer = $sfx_ui_button_click
@onready var ui_hover: AudioStreamPlayer = $sfx_ui_button_hover
@onready var ui_back: AudioStreamPlayer = $sfx_ui_back

func play_ui_button_click() -> void:
	if ui_button_click:
		ui_button_click.play()

func play_ui_hover() -> void:
	if ui_hover:
		ui_hover.play()

func play_ui_back() -> void:
	if ui_back:
		ui_back.play()
