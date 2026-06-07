## 笔仙小游戏 - 工作台场景
## 量表游戏完成后进入，依次经历：全景工作台 → 近景 → 拾笔 → 以笔照镜 → 触发笔仙地图视角
## 状态机驱动，背景随状态切换，透明热区覆盖可交互物件。
extends Control

# ─── 状态枚举 ─────────────────────────────────────────────────────────────────
enum State {
	WORKBENCH,           ## 初始全景：工作台远景
	CLOSE_TO_WORKBENCH,  ## 近景：可点击笔和镜子
	MIRROR_NO_PEN,       ## 无笔点击镜子（提示文字，点任意处返回）
	PICK_UP_PEN,         ## 拾取笔的过渡帧（短暂停留后回近景）
	PEN_AND_MIRROR,      ## 持笔点击镜子（等待3秒自动推进）
	PEN_AND_MIRROR_3S,   ## 3秒后：地图浮现，点击进入俯视场景
}

# ─── 资源路径 ──────────────────────────────────────────────────────────────────
const _ASSET_DIR := "res://assets/Pen_God_AI/"
const _MAP_SCENE  := "res://pen_god_game/MapScene.tscn"

## 各状态对应的背景图
const _BG_PATH: Dictionary = {
	State.WORKBENCH:          _ASSET_DIR + "workbench.png",
	State.CLOSE_TO_WORKBENCH: _ASSET_DIR + "close_to_the workbench.png",
	State.MIRROR_NO_PEN:      _ASSET_DIR + "click_mirror_without_pen.png",
	State.PICK_UP_PEN:        _ASSET_DIR + "click_the_pen.png",
	State.PEN_AND_MIRROR:     _ASSET_DIR + "click_pen_and_mirror.png",
	State.PEN_AND_MIRROR_3S:  _ASSET_DIR + "click_pen_and_mirror_3s后.png",
}

# ─── 热区比例坐标（锚点+尺寸，均为 0~1 相对于窗口）─────────────────────────
## 需根据实际美术像素位置微调，当前为估算值
const _MIRROR_POS  := Vector2(0.56, 0.12)  ## 镜子区域左上角比例
const _MIRROR_SIZE := Vector2(0.20, 0.42)  ## 镜子区域宽高比例
const _PEN_POS     := Vector2(0.20, 0.52)  ## 笔区域左上角比例
const _PEN_SIZE    := Vector2(0.18, 0.14)  ## 笔区域宽高比例
const _MAP_POS     := Vector2(0.35, 0.68)  ## 地图按钮左上角比例
const _MAP_SIZE    := Vector2(0.30, 0.22)  ## 地图按钮宽高比例

# ─── 子节点引用 ────────────────────────────────────────────────────────────────
var _bg:         TextureRect
var _mirror_btn: Button
var _pen_btn:    Button
var _map_btn:    Button
var _hint_label: Label
var _fade_rect:  ColorRect

# ─── 运行时变量 ────────────────────────────────────────────────────────────────
var _current_state: State = State.WORKBENCH
var _has_pen: bool = false


func _ready() -> void:
	_build_ui()
	_set_state(State.WORKBENCH)


# ─── UI 构建 ───────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# 全屏背景
	_bg = TextureRect.new()
	_bg.name = "Background"
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.gui_input.connect(_on_bg_gui_input)
	add_child(_bg)

	# 镜子热区按钮
	_mirror_btn = _make_hotspot("MirrorHot", _MIRROR_POS, _MIRROR_SIZE)
	_mirror_btn.pressed.connect(_on_mirror_pressed)
	add_child(_mirror_btn)

	# 笔热区按钮
	_pen_btn = _make_hotspot("PenHot", _PEN_POS, _PEN_SIZE)
	_pen_btn.pressed.connect(_on_pen_pressed)
	add_child(_pen_btn)

	# 地图热区按钮（初始隐藏）
	_map_btn = _make_hotspot("MapHot", _MAP_POS, _MAP_SIZE)
	_map_btn.modulate.a = 0.0
	_map_btn.pressed.connect(_on_map_pressed)
	add_child(_map_btn)

	# 底部提示文字
	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top    = -72.0
	_hint_label.offset_bottom = -12.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 26)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 0.9))
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)

	# 场景切换时用的黑色遮罩
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)


## 创建透明热区按钮（锚点布局，自动跟随窗口缩放）
func _make_hotspot(btn_name: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.name           = btn_name
	btn.anchor_left    = pos.x
	btn.anchor_top     = pos.y
	btn.anchor_right   = pos.x + sz.x
	btn.anchor_bottom  = pos.y + sz.y
	btn.flat           = true
	btn.modulate.a     = 0.0   # 视觉透明，但仍可接收点击
	return btn


# ─── 状态机 ────────────────────────────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	_current_state = new_state

	# 切换背景纹理
	if _BG_PATH.has(new_state):
		_bg.texture = load(_BG_PATH[new_state])

	# 先隐藏所有热区，再按状态开启
	_mirror_btn.visible = false
	_pen_btn.visible    = false

	match new_state:
		State.WORKBENCH:
			_hint_label.text = "点击任意地方靠近工作台……"

		State.CLOSE_TO_WORKBENCH:
			_mirror_btn.visible = true
			_pen_btn.visible    = not _has_pen
			_hint_label.text    = "（点击镜子查看）" if not _has_pen else "（持笔，再次点击镜子）"

		State.MIRROR_NO_PEN:
			_hint_label.text = "镜面空无一物……\n点击任意地方返回"

		State.PICK_UP_PEN:
			_has_pen         = true
			_hint_label.text = "捡起了一支笔……"
			get_tree().create_timer(1.2).timeout.connect(
				func() -> void: _set_state(State.CLOSE_TO_WORKBENCH), CONNECT_ONE_SHOT
			)

		State.PEN_AND_MIRROR:
			_hint_label.text = "笔尖轻触镜面……"
			get_tree().create_timer(3.0).timeout.connect(
				func() -> void: _set_state(State.PEN_AND_MIRROR_3S), CONNECT_ONE_SHOT
			)

		State.PEN_AND_MIRROR_3S:
			_hint_label.text = "一张地图浮现出来……\n点击地图，跟随笔仙"
			# 地图热区淡入
			var tw := create_tween()
			tw.tween_property(_map_btn, "modulate:a", 1.0, 0.8)


# ─── 输入回调 ──────────────────────────────────────────────────────────────────
func _on_bg_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	match _current_state:
		State.WORKBENCH:
			_set_state(State.CLOSE_TO_WORKBENCH)
		State.MIRROR_NO_PEN:
			_set_state(State.CLOSE_TO_WORKBENCH)


func _on_mirror_pressed() -> void:
	if _current_state != State.CLOSE_TO_WORKBENCH:
		return
	_set_state(State.PEN_AND_MIRROR if _has_pen else State.MIRROR_NO_PEN)


func _on_pen_pressed() -> void:
	if _current_state == State.CLOSE_TO_WORKBENCH and not _has_pen:
		_set_state(State.PICK_UP_PEN)


func _on_map_pressed() -> void:
	# 淡出后跳转到俯视地图场景
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.5)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file(_MAP_SCENE)
	)
