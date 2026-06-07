# 热区行为配置数据，作为 Resource 挂在 Hotspot 节点上，描述该热区被点击后的意图
class_name HotspotConfig
extends Resource

enum HotspotAction {
	ZOOM,       # 放大进入子场景
	PICKUP,     # 拾取物品
	GOTO_ROOM,  # 切换到另一个房间
}

@export var action: HotspotAction = HotspotAction.ZOOM
@export var zoom_scene: PackedScene       # action == ZOOM 时使用
@export var item_id: String = ""          # action == PICKUP 时使用
@export var target_room: int = 0          # action == GOTO_ROOM 时使用
@export var label: String = ""            # 备注，仅供编辑器阅读
