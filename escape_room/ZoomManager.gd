# 全局单例，维护特写场景栈，支持多级嵌套缩放；ZoomLayer 由 Main.tscn 在就绪时注入
extends Node

var _zoom_layer: CanvasLayer = null
var _stack: Array = []

# 由 ZoomLayerInit.gd 在 _ready 时调用，注入 Main.tscn 的 ZoomLayer 节点
func set_zoom_layer(layer: CanvasLayer) -> void:
	_zoom_layer = layer
	_zoom_layer.visible = false

func zoom_in(scene: PackedScene) -> void:
	if _zoom_layer == null:
		push_warning("ZoomManager: ZoomLayer 尚未注入，请确认 Main.tscn 已加载")
		return
	if scene == null:
		push_warning("ZoomManager: zoom_scene 为空，请在 HotspotConfig 中指定场景")
		return
	var instance := scene.instantiate()
	_stack.push_back(instance)
	_zoom_layer.add_child(instance)
	_zoom_layer.visible = true

func zoom_out() -> void:
	if _stack.is_empty():
		return
	var top: Node = _stack.pop_back()
	top.queue_free()
	if _stack.is_empty():
		_zoom_layer.visible = false
