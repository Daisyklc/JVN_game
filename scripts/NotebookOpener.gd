extends Button

@onready var notebook_popup = $"../../SubWindows/notebookPop"

func _ready():
	if notebook_popup:
		notebook_popup.hide()
		notebook_popup.visible = false

func _pressed():
	if notebook_popup:
		notebook_popup.show()
		notebook_popup.grab_focus()
