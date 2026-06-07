# 挂在 Main.tscn 根节点，负责加载/卸载房间场景并根据当前索引控制翻页箭头显示
extends Node2D

@export var room_scenes: Array = []   # 元素为 PackedScene，手写 tscn 不支持 Array[T] 语法

@onready var room_container: Node2D = $RoomContainer
@onready var left_arrow: Button  = $UILayer/LeftArrow
@onready var right_arrow: Button = $UILayer/RightArrow

var _current_scene: Node = null
var _gm: Node  # GameManager AutoLoad，运行期通过路径获取，避免解析期依赖

func _ready() -> void:
	_gm = get_node("/root/GameManager")
	_gm.current_room_index = 0          # 进入场景时始终从第 0 间开始
	_gm.room_count = room_scenes.size()
	print("[RoomController] room_scenes.size() = ", room_scenes.size())
	_gm.room_changed.connect(_on_room_changed)
	left_arrow.pressed.connect(func() -> void: _gm.go_to_room(_gm.current_room_index - 1))
	right_arrow.pressed.connect(func() -> void: _gm.go_to_room(_gm.current_room_index + 1))
	_load_room(_gm.current_room_index)

func _on_room_changed(index: int) -> void:
	_load_room(index)

func _load_room(index: int) -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null

	# 先刷新箭头，再做越界校验，保证任何情况下箭头状态都正确
	left_arrow.visible  = index > 0
	right_arrow.visible = index < room_scenes.size() - 1

	if index < 0 or index >= room_scenes.size():
		return

	_current_scene = (room_scenes[index] as PackedScene).instantiate()
	room_container.add_child(_current_scene)
