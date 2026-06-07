# 挂在 Area2D 上的热区控制器，负责鼠标悬停光标切换和左键点击响应
extends Area2D

@export var config: HotspotConfig

var _hovered := false

func _ready() -> void:
	input_pickable = true
	# PICKUP 类型：若物品已在背包则自消除，避免重进房间后热区复现
	if config != null and config.action == HotspotConfig.HotspotAction.PICKUP:
		if get_node("/root/GameManager").has_item(config.item_id):
			queue_free()
			return
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _unhandled_input(event: InputEvent) -> void:
	if not _hovered:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if config == null:
			push_warning("Hotspot: config 未设置，节点名 = %s" % name)
			return
		var action_name: String = HotspotConfig.HotspotAction.keys()[config.action]
		print("[Hotspot] label='%s'  action=%s" % [config.label, action_name])
		match config.action:
			HotspotConfig.HotspotAction.ZOOM:
				get_node("/root/ZoomManager").zoom_in(config.zoom_scene)
			HotspotConfig.HotspotAction.PICKUP:
				get_node("/root/GameManager").pick_up_item(config.item_id)
				queue_free()
		get_viewport().set_input_as_handled()
