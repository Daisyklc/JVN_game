extends Control

func _ready():
	hide()
	visible = false

	mouse_filter = Control.MOUSE_FILTER_STOP

	# 让点击穿过子控件，落到 notebookPop 上
	for c in get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide()
