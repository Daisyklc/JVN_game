# 特写场景内的返回按钮，点击后调用 ZoomManager.zoom_out() 退出当前特写层
extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	get_node("/root/ZoomManager").zoom_out()
