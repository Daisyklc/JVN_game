## 笔仙小游戏 - 医院俯视地图场景
## 笔仙（羽毛图标）在医院地图上颤抖游走，依次触发各房间剧情时间线。
## 先遍历2F心身医学科，再切换至1F门诊大厅，最终到达出口结束游戏。
extends Control

# ─── 楼层枚举 ──────────────────────────────────────────────────────────────────
enum Floor { F2, F1 }

# ─── 资源路径 ──────────────────────────────────────────────────────────────────
const _ASSET  := "res://assets/Pen_God_AI/"
const _MAP_2F := _ASSET + "Map_hospital_2F.png"
const _MAP_1F := _ASSET + "Map_hospital_1F.png"
const _PEN_TEX := _ASSET + "PenGod_feather_tran80.png"

## Dialogic 按时间线名检索（与项目其他时间线调用方式保持一致，无需路径前缀）

# ─── 地点序列 ──────────────────────────────────────────────────────────────────
## 按剧情顺序排列。pos 为相对地图图片的比例坐标（0~1），需根据实际地图美术微调。
## timeline 为空字符串表示该地点无剧情，直接继续移动。
## switch_to_f1=true 表示到达此地点后切换地图至1楼。
const _SEQUENCE: Array = [
	# ── 2F 心身医学科 ──────────────────────────────────────────────────────────
	{ "name": "量表室",           "pos": Vector2(0.55, 0.30), "floor": Floor.F2, "timeline": "",                    "switch_to_f1": false },
	{ "name": "卫生间",           "pos": Vector2(0.18, 0.62), "floor": Floor.F2, "timeline": "room_restroom",       "switch_to_f1": false },
	{ "name": "心身门诊（青少年）", "pos": Vector2(0.42, 0.48), "floor": Floor.F2, "timeline": "room_childteens",    "switch_to_f1": false },
	{ "name": "楼梯",             "pos": Vector2(0.82, 0.72), "floor": Floor.F2, "timeline": "3F_chiorroom",        "switch_to_f1": false },
	{ "name": "心身门诊 抑郁焦虑", "pos": Vector2(0.38, 0.38), "floor": Floor.F2, "timeline": "room_yiyujiaolv",    "switch_to_f1": false },
	{ "name": "心身门诊 睡眠障碍", "pos": Vector2(0.50, 0.58), "floor": Floor.F2, "timeline": "room_sleepdiscorder","switch_to_f1": false },
	{ "name": "楼梯（下楼）",      "pos": Vector2(0.82, 0.72), "floor": Floor.F2, "timeline": "",                   "switch_to_f1": true  },
	# ── 1F 门诊大厅 ────────────────────────────────────────────────────────────
	{ "name": "楼梯",             "pos": Vector2(0.78, 0.35), "floor": Floor.F1, "timeline": "",                       "switch_to_f1": false },
	{ "name": "门诊收费",          "pos": Vector2(0.28, 0.68), "floor": Floor.F1, "timeline": "room_outpatientCharge",  "switch_to_f1": false },
	{ "name": "候诊区",           "pos": Vector2(0.55, 0.78), "floor": Floor.F1, "timeline": "room_houzhenwaiting",    "switch_to_f1": false },
	{ "name": "出口",             "pos": Vector2(0.88, 0.88), "floor": Floor.F1, "timeline": "",                       "switch_to_f1": false },
]

# ─── 抖动参数 ──────────────────────────────────────────────────────────────────
## 震抖步数（越多越混乱）
const _SHAKE_STEPS    := 18
## 单步最短/最长时长（秒）
const _SHAKE_STEP_MIN := 0.06
const _SHAKE_STEP_MAX := 0.16
## 最大抖动半径（像素）
const _JITTER_MAX     := 70.0
## 最终收敛动画时长
const _SETTLE_DURATION := 0.45

# ─── 子节点引用 ────────────────────────────────────────────────────────────────
var _map_bg:        TextureRect
var _pen_icon:      TextureRect
var _location_label: Label
var _floor_label:   Label
var _fade_rect:     ColorRect

# ─── 运行时状态 ────────────────────────────────────────────────────────────────
var _seq_idx:      int   = 0
var _cur_floor:    Floor = Floor.F2
var _tl_pending:   bool  = false


func _ready() -> void:
	_build_ui()
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	# 从第1个地点（量表室）的位置开始，无需移动动画
	_place_pen_at_index(0)
	call_deferred("_advance")


# ─── UI 构建 ───────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# 地图背景
	_map_bg = TextureRect.new()
	_map_bg.name = "MapBg"
	_map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map_bg)
	_refresh_map_texture()

	# 笔仙羽毛图标
	_pen_icon = TextureRect.new()
	_pen_icon.name = "PenIcon"
	_pen_icon.texture = load(_PEN_TEX)
	_pen_icon.custom_minimum_size = Vector2(44, 76)
	_pen_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_pen_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pen_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pen_icon)

	# 左上角楼层标签
	_floor_label = Label.new()
	_floor_label.name = "FloorLabel"
	_floor_label.anchor_left   = 0.0
	_floor_label.anchor_top    = 0.0
	_floor_label.anchor_right  = 0.0
	_floor_label.anchor_bottom = 0.0
	_floor_label.offset_left   = 20.0
	_floor_label.offset_top    = 20.0
	_floor_label.offset_right  = 260.0
	_floor_label.offset_bottom = 56.0
	_floor_label.add_theme_font_size_override("font_size", 22)
	_floor_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.9))
	_floor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_floor_label)
	_refresh_floor_label()

	# 底部笔尖位置标签
	_location_label = Label.new()
	_location_label.name = "LocationLabel"
	_location_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_location_label.offset_top    = -72.0
	_location_label.offset_bottom = -12.0
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_location_label.add_theme_font_size_override("font_size", 28)
	_location_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 0.95))
	_location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_location_label)

	# 过场黑幕遮罩
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)


func _refresh_map_texture() -> void:
	_map_bg.texture = load(_MAP_2F if _cur_floor == Floor.F2 else _MAP_1F)


func _refresh_floor_label() -> void:
	_floor_label.text = "2F  心身医学科" if _cur_floor == Floor.F2 else "1F  门诊大厅"


# ─── 序列推进 ──────────────────────────────────────────────────────────────────
func _advance() -> void:
	if _seq_idx >= _SEQUENCE.size():
		_finish_game()
		return

	var loc: Dictionary = _SEQUENCE[_seq_idx]
	_location_label.text = "笔尖位置：" + loc["name"]

	# 切换楼层（含动画）
	if loc["floor"] != _cur_floor:
		await _switch_floor(loc["floor"])

	# 等一帧确保 size 已计算
	await get_tree().process_frame
	var target_px := _ratio_to_px(loc["pos"])

	# 颤抖游走到目标
	await _shaky_move_to(target_px)
	await get_tree().create_timer(0.5).timeout

	# 切换楼层标记（在抵达某地点后才切地图，对应流程图"切换1楼地图"）
	if loc.get("switch_to_f1", false):
		await get_tree().create_timer(0.6).timeout
		await _switch_floor(Floor.F1)

	# 播放关联时间线
	var tl_name: String = loc["timeline"]
	if not tl_name.is_empty():
		_tl_pending = true
		Dialogic.start(tl_name)
		# 等待 _on_timeline_ended 回调
		return

	_next()


func _next() -> void:
	_seq_idx += 1
	_advance()


func _on_timeline_ended() -> void:
	if not _tl_pending:
		return
	_tl_pending = false
	_next()


## 楼层切换：黑幕淡入→换图→淡出
func _switch_floor(new_floor: Floor) -> void:
	_cur_floor = new_floor
	var tw_in := create_tween()
	tw_in.tween_property(_fade_rect, "modulate:a", 1.0, 0.35)
	await tw_in.finished
	_refresh_map_texture()
	_refresh_floor_label()
	_floor_label.text = "切换至 " + _floor_label.text + "……"
	await get_tree().create_timer(0.5).timeout
	_refresh_floor_label()
	var tw_out := create_tween()
	tw_out.tween_property(_fade_rect, "modulate:a", 0.0, 0.35)
	await tw_out.finished


# ─── 笔仙动画 ──────────────────────────────────────────────────────────────────
## 将比例坐标转换为相对于本 Control 的像素坐标（笔图标中心点）
func _ratio_to_px(ratio: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return Vector2(ratio.x * vp.x - 22.0, ratio.y * vp.y - 38.0)


## 将笔仙图标直接放置到某个序列地点（用于初始化，不播动画）
func _place_pen_at_index(idx: int) -> void:
	await get_tree().process_frame
	var loc: Dictionary = _SEQUENCE[idx]
	_pen_icon.position = _ratio_to_px(loc["pos"])


## 颤抖游走动画：先高频随机抖动，再平滑收敛到目标坐标
func _shaky_move_to(target: Vector2) -> void:
	var start := _pen_icon.position
	for i in range(_SHAKE_STEPS):
		var t := float(i + 1) / float(_SHAKE_STEPS)
		# 渐进逼近目标，同时叠加衰减抖动
		var base := start.lerp(target, t * 0.4)
		var jitter_r := lerpf(_JITTER_MAX, 8.0, t)
		var jitter := Vector2(
			randf_range(-jitter_r, jitter_r),
			randf_range(-jitter_r, jitter_r)
		)
		var step_time := randf_range(_SHAKE_STEP_MIN, _SHAKE_STEP_MAX)
		var tw := create_tween()
		tw.tween_property(_pen_icon, "position", base + jitter, step_time)
		await tw.finished

	# 最终平滑落点
	var tw_settle := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw_settle.tween_property(_pen_icon, "position", target, _SETTLE_DURATION)
	await tw_settle.finished


# ─── 游戏结束 ──────────────────────────────────────────────────────────────────
func _finish_game() -> void:
	_location_label.text = "笔仙已离去……"
	await get_tree().create_timer(2.0).timeout
	# 淡出并返回主菜单（正式集成时改为跳转下一章场景）
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.6)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
