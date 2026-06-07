# 物品栏 UI，固定 4 个格子，监听 GameManager.inventory_updated 信号并刷新显示
extends HBoxContainer

const SLOT_COUNT := 4

var _gm: Node
var _labels: Array = []

func _ready() -> void:
	_gm = get_node("/root/GameManager")
	# 收集各格子内的 Label 引用（子节点顺序：Slot0~Slot3，每个 Slot 下有一个 Label）
	for slot in get_children():
		var label := slot.get_node("Label") as Label
		_labels.append(label)
	_gm.inventory_updated.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var inv: Array = _gm.inventory
	for i in range(SLOT_COUNT):
		_labels[i].text = inv[i] if i < inv.size() else ""
