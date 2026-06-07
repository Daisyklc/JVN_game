extends Control
## 关卡选择页面
## 仿照插画风格：墙面房间内，左门=第一章（可进入），中间电视=短片，右门=第二章（锁定）。
## 点击第一章自动设置 Golbal.pending_timeline 并跳转到 run_page.tscn 开始 gl 故事线。

const MAIN_MENU         := "res://scenes/main_menu.tscn"
const RUN_PAGE          := "res://scenes/run_page.tscn"
const CHAPTER1_TIMELINE := "sc000_接受委托"

# ─── 调色板（与插画参考色相近）────────────────────────────────────────────────
const C_WALL        := Color(0.890, 0.882, 0.875, 1.0)
const C_FLOOR       := Color(0.498, 0.380, 0.243, 1.0)
const C_FLOOR_LINE  := Color(0.420, 0.310, 0.188, 1.0)
const C_DOOR_FRAME  := Color(0.529, 0.408, 0.247, 1.0)
const C_DOOR_FACE   := Color(0.631, 0.494, 0.318, 1.0)
const C_DOOR_PANEL  := Color(0.698, 0.557, 0.376, 1.0)
const C_DOOR_HOVER  := Color(0.718, 0.576, 0.396, 1.0)
const C_KNOB        := Color(0.255, 0.196, 0.118, 1.0)
const C_TV_BODY     := Color(0.259, 0.224, 0.196, 1.0)
const C_TV_SCREEN   := Color(0.118, 0.149, 0.176, 1.0)
const C_TV_SCREEN_H := Color(0.180, 0.220, 0.260, 1.0)
const C_TV_BTN      := Color(0.200, 0.180, 0.165, 1.0)
const C_STAND_TOP   := Color(0.310, 0.224, 0.145, 1.0)
const C_STAND_LEG   := Color(0.247, 0.173, 0.102, 1.0)
const C_TEXT        := Color(0.180, 0.149, 0.118, 1.0)
const C_LOCK_BG     := Color(0, 0, 0, 0.22)
const C_PIC_FRAME   := Color(0.600, 0.490, 0.310, 1.0)
const C_PIC_MAT     := Color(0.941, 0.929, 0.910, 1.0)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_background()
	_build_wall_decoration()
	_build_items()
	_build_back_button()
	_build_vignette()


# ─── 背景：墙面 + 地板 ──────────────────────────────────────────────────────

func _build_background() -> void:
	var wall := ColorRect.new()
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.color = C_WALL
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)

	var floor_cr := ColorRect.new()
	_anchor_fill(floor_cr, 0.0, 0.68, 1.0, 1.0)
	floor_cr.color = C_FLOOR
	floor_cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_cr)

	# 地板木纹线
	for i in 3:
		var line := ColorRect.new()
		var frac: float = 0.68 + float(i + 1) * 0.32 / 4.0
		_anchor_fill(line, 0.0, frac, 1.0, frac)
		line.set_offset(SIDE_BOTTOM, 1)
		line.color = C_FLOOR_LINE
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)

	# 踢脚线
	var base := ColorRect.new()
	_anchor_fill(base, 0.0, 0.68, 1.0, 0.68)
	base.set_offset(SIDE_BOTTOM, 6)
	base.color = C_DOOR_FRAME
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)


# ─── 墙面挂画（在 TV 正上方）────────────────────────────────────────────────

func _build_wall_decoration() -> void:
	var outer := Panel.new()
	_anchor_center(outer, -42, 60, 42, 130)
	var outer_s := _flat_style(C_PIC_FRAME, 2)
	outer.add_theme_stylebox_override("panel", outer_s)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outer)

	var inner := Panel.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.set_offset(SIDE_LEFT,   6)
	inner.set_offset(SIDE_TOP,    6)
	inner.set_offset(SIDE_RIGHT, -6)
	inner.set_offset(SIDE_BOTTOM,-6)
	inner.add_theme_stylebox_override("panel", _flat_style(C_PIC_MAT))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(inner)


# ─── 主体：三个交互项目 ──────────────────────────────────────────────────────

func _build_items() -> void:
	var center := CenterContainer.new()
	_anchor_fill(center, 0.0, 0.06, 1.0, 0.80)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 90)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(hbox)

	# 第一章（解锁）
	hbox.add_child(_make_column(
		_make_door_graphic(false, _on_chapter1_pressed),
		"第一章"
	))

	# 短片
	hbox.add_child(_make_column(
		_make_tv_graphic(_on_film_pressed),
		"短片"
	))

	# 第二章（锁定）
	hbox.add_child(_make_column(
		_make_door_graphic(true, Callable()),
		"第二章"
	))


func _make_column(graphic: Control, label_text: String) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(graphic)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	return vbox


# ─── 门图形 ──────────────────────────────────────────────────────────────────

func _make_door_graphic(locked: bool, on_press: Callable) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(170, 300)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ── 门框 ──
	var frame_panel := Panel.new()
	frame_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var frame_s := _flat_style(C_DOOR_FRAME)
	frame_s.corner_radius_top_left     = 6
	frame_s.corner_radius_top_right    = 6
	frame_panel.add_theme_stylebox_override("panel", frame_s)
	frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(frame_panel)

	# ── 门面 ──
	var face_panel := Panel.new()
	face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	face_panel.set_offset(SIDE_LEFT,  10)
	face_panel.set_offset(SIDE_RIGHT,-10)
	var face_s := _flat_style(C_DOOR_FACE)
	face_panel.add_theme_stylebox_override("panel", face_s)
	face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_panel.add_child(face_panel)

	# ── 上/下内面板 ──
	_add_door_inner_panel(face_panel, 14, 18, -14, 118)
	_add_door_inner_panel(face_panel, 14, 138, -14, 272)

	# ── 门把手（解锁门把手在右侧，锁定门在左侧）──
	var knob_x_anchor: float = 0.72 if not locked else 0.28
	var knob := Panel.new()
	knob.set_anchor(SIDE_LEFT,   knob_x_anchor - 0.05)
	knob.set_anchor(SIDE_RIGHT,  knob_x_anchor + 0.05)
	knob.set_anchor(SIDE_TOP,    0.0)
	knob.set_anchor(SIDE_BOTTOM, 0.0)
	knob.set_offset(SIDE_TOP,    164)
	knob.set_offset(SIDE_BOTTOM, 180)
	var knob_s := _flat_style(C_KNOB)
	knob_s.corner_radius_top_left     = 8
	knob_s.corner_radius_top_right    = 8
	knob_s.corner_radius_bottom_left  = 8
	knob_s.corner_radius_bottom_right = 8
	knob.add_theme_stylebox_override("panel", knob_s)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_panel.add_child(knob)

	# ── 锁定：遮罩 + 锁图标 ──
	if locked:
		var overlay := ColorRect.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.color = C_LOCK_BG
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(overlay)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 22)
		lock_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
		lock_lbl.set_offset(SIDE_TOP, -32)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(lock_lbl)

	# ── 透明点击按钮（置于最顶层）──
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	if locked or not on_press.is_valid():
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(on_press)
		btn.mouse_entered.connect(func(): face_s.bg_color = C_DOOR_HOVER)
		btn.mouse_exited.connect(func(): face_s.bg_color = C_DOOR_FACE)
	wrapper.add_child(btn)

	return wrapper


func _add_door_inner_panel(parent: Panel, l: float, t: float, r: float, b: float) -> void:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.set_offset(SIDE_LEFT,   l)
	p.set_offset(SIDE_TOP,    t)
	p.set_offset(SIDE_RIGHT,  r)
	p.set_offset(SIDE_BOTTOM, b)
	var s := _flat_style(C_DOOR_PANEL)
	s.border_color        = C_DOOR_FRAME
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)


# ─── 电视图形 ─────────────────────────────────────────────────────────────────

func _make_tv_graphic(on_press: Callable) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(130, 300)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 桌面
	var stand_top := Panel.new()
	stand_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	stand_top.set_offset(SIDE_TOP,    196)
	stand_top.set_offset(SIDE_BOTTOM, 212)
	stand_top.add_theme_stylebox_override("panel", _flat_style(C_STAND_TOP))
	stand_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(stand_top)

	# 桌腿
	for leg_ax in [0.15, 0.35, 0.65, 0.85]:
		var leg := Panel.new()
		leg.set_anchor(SIDE_LEFT,   leg_ax - 0.04)
		leg.set_anchor(SIDE_RIGHT,  leg_ax + 0.04)
		leg.set_anchor(SIDE_TOP,    0.0)
		leg.set_anchor(SIDE_BOTTOM, 0.0)
		leg.set_offset(SIDE_TOP,    212)
		leg.set_offset(SIDE_BOTTOM, 300)
		leg.add_theme_stylebox_override("panel", _flat_style(C_STAND_LEG))
		leg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(leg)

	# 机身
	var body := Panel.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.set_offset(SIDE_TOP,    60)
	body.set_offset(SIDE_BOTTOM, 200)
	var body_s := _flat_style(C_TV_BODY)
	body_s.corner_radius_top_left     = 6
	body_s.corner_radius_top_right    = 6
	body_s.corner_radius_bottom_left  = 4
	body_s.corner_radius_bottom_right = 4
	body.add_theme_stylebox_override("panel", body_s)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(body)

	# 屏幕
	var screen := Panel.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.set_offset(SIDE_LEFT,   10)
	screen.set_offset(SIDE_TOP,    12)
	screen.set_offset(SIDE_RIGHT, -30)
	screen.set_offset(SIDE_BOTTOM,-12)
	var scr_s := _flat_style(C_TV_SCREEN)
	scr_s.corner_radius_top_left     = 4
	scr_s.corner_radius_top_right    = 4
	scr_s.corner_radius_bottom_left  = 4
	scr_s.corner_radius_bottom_right = 4
	screen.add_theme_stylebox_override("panel", scr_s)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(screen)

	# 侧面按钮
	for i in 3:
		var sb := Panel.new()
		sb.set_anchor(SIDE_LEFT,   1.0)
		sb.set_anchor(SIDE_RIGHT,  1.0)
		sb.set_anchor(SIDE_TOP,    0.0)
		sb.set_anchor(SIDE_BOTTOM, 0.0)
		sb.set_offset(SIDE_LEFT,  -22)
		sb.set_offset(SIDE_RIGHT,  -8)
		sb.set_offset(SIDE_TOP,   24 + i * 20)
		sb.set_offset(SIDE_BOTTOM,36 + i * 20)
		var sb_s := _flat_style(C_TV_BTN)
		sb_s.corner_radius_top_left     = 3
		sb_s.corner_radius_top_right    = 3
		sb_s.corner_radius_bottom_left  = 3
		sb_s.corner_radius_bottom_right = 3
		sb.add_theme_stylebox_override("panel", sb_s)
		sb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(sb)

	# 透明点击按钮
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if on_press.is_valid():
		btn.pressed.connect(on_press)
	btn.mouse_entered.connect(func(): scr_s.bg_color = C_TV_SCREEN_H)
	btn.mouse_exited.connect(func(): scr_s.bg_color = C_TV_SCREEN)
	wrapper.add_child(btn)

	return wrapper


# ─── 返回按钮 ────────────────────────────────────────────────────────────────

func _build_back_button() -> void:
	var btn := Button.new()
	btn.text = "◀  返回"
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.set_offset(SIDE_LEFT,   20)
	btn.set_offset(SIDE_TOP,    20)
	btn.set_offset(SIDE_RIGHT,  130)
	btn.set_offset(SIDE_BOTTOM, 52)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_back_pressed)
	add_child(btn)


# ─── 暗角 Shader ────────────────────────────────────────────────────────────

func _build_vignette() -> void:
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color.TRANSPARENT
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float v = 1.0 - smoothstep(0.5, 1.2, length(uv * vec2(0.85, 1.0)));
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - v) * 0.42);
}
"""
	sm.shader = sh
	vignette.material = sm
	add_child(vignette)


# ─── 工具函数 ────────────────────────────────────────────────────────────────

## 用锚点将节点填充到父节点的指定比例区域（不设置 layout_mode）
func _anchor_fill(node: Control, al: float, at: float, ar: float, ab: float) -> void:
	node.set_anchor(SIDE_LEFT,   al)
	node.set_anchor(SIDE_TOP,    at)
	node.set_anchor(SIDE_RIGHT,  ar)
	node.set_anchor(SIDE_BOTTOM, ab)


## 将节点锚定到父节点水平居中位置，偏移量以像素为单位
func _anchor_center(node: Control, ol: float, ot: float, or_: float, ob: float) -> void:
	node.set_anchor(SIDE_LEFT,   0.5)
	node.set_anchor(SIDE_TOP,    0.0)
	node.set_anchor(SIDE_RIGHT,  0.5)
	node.set_anchor(SIDE_BOTTOM, 0.0)
	node.set_offset(SIDE_LEFT,   ol)
	node.set_offset(SIDE_TOP,    ot)
	node.set_offset(SIDE_RIGHT,  or_)
	node.set_offset(SIDE_BOTTOM, ob)


## 创建一个纯色 StyleBoxFlat（可选圆角半径）
func _flat_style(color: Color, corner_radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	if corner_radius > 0:
		s.corner_radius_top_left     = corner_radius
		s.corner_radius_top_right    = corner_radius
		s.corner_radius_bottom_left  = corner_radius
		s.corner_radius_bottom_right = corner_radius
	return s


# ─── 交互回调 ────────────────────────────────────────────────────────────────

func _on_chapter1_pressed() -> void:
	Golbal.pending_timeline = CHAPTER1_TIMELINE
	get_tree().change_scene_to_file(RUN_PAGE)


func _on_film_pressed() -> void:
	var popup := AcceptDialog.new()
	popup.title = "短片"
	popup.dialog_text = "短片内容即将开放，敬请期待。"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
