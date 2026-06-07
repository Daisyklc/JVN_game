extends Control
## 光点：可点击，被点击时发出 burst 信号

signal burst

@export var glow_color: Color = Color(1.0, 0.9, 0.6, 1.0)

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if rect:
		rect.color = glow_color


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			burst.emit()
			accept_event()
