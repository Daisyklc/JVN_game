extends Control
## 加载游戏页面
## 展示 Dialogic 存档槽，允许玩家选择并加载已有存档。
## 存档数据由 Dialogic.Save 子系统管理，存于 user://dialogic/saves/。

const UI_DIR    := "res://assets/UI/gameUIset_red/"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const RUN_PAGE  := "res://scenes/run_page.tscn"

## 固定展示的存档槽数量
const MAX_SLOTS  := 6
const SLOT_PREFIX := "slot_"

const SLOT_W := 380
const SLOT_H := 240

@onready var _back_btn:  TextureButton = $BackBtn
@onready var _slot_grid: GridContainer = $SlotScrollContainer/SlotGrid


func _ready() -> void:
	_back_btn.pressed.connect(_on_back_pressed)
	_style_title()
	_populate_slots()


# ─── 标题字体样式 ───────────────────────────────────────────────────────────────

func _style_title() -> void:
	var lbl: Label = $PageTitle
	if not lbl:
		return
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


# ─── 填充存档槽网格 ─────────────────────────────────────────────────────────────

func _populate_slots() -> void:
	var slot_tex:       Texture2D = _try_load_ui("saveslot.png")
	var slot_hover_tex: Texture2D = _try_load_ui("saveslot_hover.png")
	var empty_icon_tex: Texture2D = _try_load_ui("icon_new_01.png")

	for i in range(1, MAX_SLOTS + 1):
		var slot_name: String   = SLOT_PREFIX + str(i)
		var has_save:  bool     = Dialogic.Save.has_slot(slot_name)

		var thumb_tex:  ImageTexture = null
		var info_text:  String       = "空档位"
		var date_text:  String       = ""

		if has_save:
			thumb_tex = Dialogic.Save.get_slot_thumbnail(slot_name)
			var info: Dictionary = Dialogic.Save.get_slot_info(slot_name)
			info_text = info.get("title", "存档 " + str(i))
			date_text = info.get("date", "")

		# ── 外层容器 ──
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# ── 槽位按钮 ──
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		btn.ignore_texture_size = true
		btn.stretch_mode        = TextureButton.STRETCH_SCALE
		btn.clip_contents       = true

		if slot_tex:       btn.texture_normal  = slot_tex
		if slot_hover_tex: btn.texture_hover   = slot_hover_tex

		if not has_save:
			btn.modulate = Color(0.65, 0.65, 0.65, 1.0)

		# ── 缩略图（按钮内部全覆盖） ──
		var thumb_rect := TextureRect.new()
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if has_save and thumb_tex:
			thumb_rect.texture      = thumb_tex
			thumb_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		elif not has_save and empty_icon_tex:
			thumb_rect.texture      = empty_icon_tex
			thumb_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		# ── 底部半透明遮罩（便于文字可读） ──
		var overlay := ColorRect.new()
		overlay.set_anchor(SIDE_LEFT,   0.0)
		overlay.set_anchor(SIDE_TOP,    0.58)
		overlay.set_anchor(SIDE_RIGHT,  1.0)
		overlay.set_anchor(SIDE_BOTTOM, 1.0)
		overlay.color        = Color(0.0, 0.0, 0.0, 0.60)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# ── 槽内存档标题标签 ──
		var info_lbl := Label.new()
		info_lbl.set_anchor(SIDE_LEFT,   0.0)
		info_lbl.set_anchor(SIDE_TOP,    0.60)
		info_lbl.set_anchor(SIDE_RIGHT,  1.0)
		info_lbl.set_anchor(SIDE_BOTTOM, 0.82)
		info_lbl.text                = info_text
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		info_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		info_lbl.add_theme_font_size_override("font_size", 18)
		info_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.95, 0.85, 1.0) if has_save else Color(0.55, 0.55, 0.55, 0.85))

		# ── 日期标签 ──
		var date_lbl := Label.new()
		date_lbl.set_anchor(SIDE_LEFT,   0.0)
		date_lbl.set_anchor(SIDE_TOP,    0.82)
		date_lbl.set_anchor(SIDE_RIGHT,  1.0)
		date_lbl.set_anchor(SIDE_BOTTOM, 1.0)
		date_lbl.text                = date_text
		date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		date_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		date_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		date_lbl.add_theme_font_size_override("font_size", 13)
		date_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.9))

		btn.add_child(thumb_rect)
		btn.add_child(overlay)
		btn.add_child(info_lbl)
		btn.add_child(date_lbl)

		# ── 槽号标签（按钮下方） ──
		var num_lbl := Label.new()
		num_lbl.text                = "存档 " + str(i)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.custom_minimum_size  = Vector2(SLOT_W, 28)
		num_lbl.add_theme_font_size_override("font_size", 15)
		num_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.95, 0.9, 1.0) if has_save else Color(0.5, 0.5, 0.5, 1.0))

		if has_save:
			btn.pressed.connect(_on_slot_clicked.bind(slot_name, i))
		else:
			btn.disabled = true

		vbox.add_child(btn)
		vbox.add_child(num_lbl)
		_slot_grid.add_child(vbox)


# ─── 加载确认对话框 ────────────────────────────────────────────────────────────

func _on_slot_clicked(slot_name: String, slot_index: int) -> void:
	_show_confirm_dialog(slot_name, slot_index)


func _show_confirm_dialog(slot_name: String, slot_index: int) -> void:
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 20
	add_child(overlay_layer)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color(0.0, 0.0, 0.0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(bg)

	# 对话框面板容器
	var panel := VBoxContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.5)
	panel.set_anchor(SIDE_TOP,    0.5)
	panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_BOTTOM, 0.5)
	panel.set_offset(SIDE_LEFT,  -200.0)
	panel.set_offset(SIDE_RIGHT,  200.0)
	panel.set_offset(SIDE_TOP,   -72.0)
	panel.set_offset(SIDE_BOTTOM, 72.0)
	panel.add_theme_constant_override("separation", 24)
	overlay_layer.add_child(panel)

	# 提示文字
	var msg := Label.new()
	msg.text                = "确认加载存档 %d ？" % slot_index
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 22)
	msg.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
	msg.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	msg.add_theme_constant_override("shadow_offset_x", 1)
	msg.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(msg)

	# 按钮行
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 40)
	panel.add_child(btn_row)

	var ok_btn     := _make_icon_btn("button_ok.png",     "button_ok_hover.png",     "button_ok_click.png")
	var cancel_btn := _make_icon_btn("button_cancel.png", "button_cancel_hover.png", "button_cancel_click.png")
	btn_row.add_child(ok_btn)
	btn_row.add_child(cancel_btn)

	ok_btn.pressed.connect(func() -> void:
		overlay_layer.queue_free()
		_do_load(slot_name)
	)
	cancel_btn.pressed.connect(func() -> void:
		overlay_layer.queue_free()
	)

	# 淡入动画
	bg.modulate.a    = 0.0
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg,    "modulate:a", 1.0, 0.20)
	tw.tween_property(panel, "modulate:a", 1.0, 0.28)


func _make_icon_btn(normal: String, hover: String, pressed: String) -> TextureButton:
	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(80, 48)
	btn.ignore_texture_size = true
	btn.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var n := _try_load_ui(normal)
	var h := _try_load_ui(hover)
	var p := _try_load_ui(pressed)
	if n: btn.texture_normal  = n
	if h: btn.texture_hover   = h
	if p: btn.texture_pressed = p
	return btn


# ─── 执行加载 ──────────────────────────────────────────────────────────────────

func _do_load(slot_name: String) -> void:
	var err := Dialogic.Save.load(slot_name)
	if err != OK:
		push_error("[LoadPage] 加载存档失败: %s  (error %d)" % [slot_name, err])
		return
	get_tree().change_scene_to_file(RUN_PAGE)


# ─── 导航 ──────────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)


# ─── 资源加载工具 ──────────────────────────────────────────────────────────────

func _try_load_ui(filename: String) -> Texture2D:
	var path := UI_DIR + filename
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
