# 挂在 Main.tscn 的 ZoomLayer 节点上，场景就绪时将自身注入 ZoomManager
extends CanvasLayer

func _ready() -> void:
	get_node("/root/ZoomManager").set_zoom_layer(self)
