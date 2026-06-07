# 全局单例，维护当前房间索引并向所有监听者广播房间切换信号
extends Node

signal room_changed(index: int)

var current_room_index: int = 0
var room_count: int = 0

func go_to_room(index: int) -> void:
	if room_count <= 0:
		return
	var clamped := clampi(index, 0, room_count - 1)
	if clamped == current_room_index:
		return
	current_room_index = clamped
	room_changed.emit(current_room_index)

# ── 物品栏 ────────────────────────────────────────────────
signal inventory_updated

var inventory: Array[String] = []

func pick_up_item(item_id: String) -> void:
	if item_id.is_empty() or has_item(item_id):
		return
	inventory.append(item_id)
	inventory_updated.emit()

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)
