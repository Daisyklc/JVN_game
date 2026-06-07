extends Control
## CG 图鉴页面
## 展示游戏中可解锁的 CG 图像，使用 gameUIset_red 素材包。
## 解锁状态由 Golbal.unlocked_cgs 持久化管理。

const UI_DIR  := "res://assets/UI/gameUIset_red/"
const BG_DIR  := "res://assets/UI/gameUIset_red/bg/"
const MAIN_MENU := "res://scenes/main_menu.tscn"

## CG 条目：key 对应 run_page.gd 里的 CG_MAP 键（用于解锁判断）
const CG_ENTRIES: Array[Dictionary] = [
	{ "key": "CG_DyingHY",           "file": "bg_bedInHeaven.png",        "title": "天国之梦"    },
	{ "key": "show_cg",              "file": "bg_ChildhoodBrokenBowl.png","title": "童年·破碗"   },
	{ "key": "CG01_传达到的心愿天使", "file": "bg_bedInHeaven.png",        "title": "传达到的心愿" },
]

const THUMB_W := 300
const THUMB_H := 200
const THUMB_LABEL_H := 32

@onready var _back_btn: TextureButton = $BackBtn
@onready var _cg_grid: GridContainer  = $CgScrollContainer/CgGrid

var _viewer_layer: CanvasLayer = null


func _ready() -> void:
	_back_btn.pressed.connect(_on_back_pressed)
	_style_title()
	_populate_grid()


# ─── 标题字体样式 ──────────────────────────────────────────────────────────────

func _style_title() -> void:
	var lbl: Label = $PageTitle
	if not lbl:
		return
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


# ─── 填充 CG 缩略图网格 ────────────────────────────────────────────────────────

func _populate_grid() -> void:
	var unlocked: Array = Golbal.unlocked_cgs
	var locked_tex: Texture2D = _try_load_ui("thumbnail.png")

	for entry: Dictionary in CG_ENTRIES:
		var key:   String = entry["key"]
		var file:  String = entry["file"]
		var title: String = entry["title"]
		var is_unlocked: bool = key in unlocked

		# 外层容器：缩略图 + 标题
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# 缩略图按钮
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(THUMB_W, THUMB_H)
		btn.ignore_texture_size  = true
		btn.stretch_mode         = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		if is_unlocked:
			var tex: Texture2D = _try_load_bg(file)
			if tex:
				btn.texture_normal = tex
				btn.texture_hover  = tex
			elif locked_tex:
				btn.texture_normal = locked_tex
			btn.modulate = Color.WHITE
			btn.pressed.connect(_on_cg_clicked.bind(file, title))
		else:
			if locked_tex:
				btn.texture_normal = locked_tex
			btn.disabled = true
			btn.modulate  = Color(0.25, 0.25, 0.25, 1.0)

		# 标题标签
		var lbl := Label.new()
		lbl.text                    = title if is_unlocked else "???"
		lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size     = Vector2(THUMB_W, THUMB_LABEL_H)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9, 1.0) if is_unlocked else Color(0.45, 0.45, 0.45, 1.0))

		vbox.add_child(btn)
		vbox.add_child(lbl)
		_cg_grid.add_child(vbox)


# ─── CG 查看器 ─────────────────────────────────────────────────────────────────

func _on_cg_clicked(filename: String, _title: String) -> void:
	_show_viewer(filename)


func _show_viewer(filename: String) -> void:
	if _viewer_layer:
		return
	var tex: Texture2D = _try_load_bg(filename)
	if not tex:
		return

	_viewer_layer = CanvasLayer.new()
	_viewer_layer.layer = 20
	add_child(_viewer_layer)

	# 半透明黑色遮罩
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewer_layer.add_child(overlay)

	# 全屏 CG 图像
	var img_rect := TextureRect.new()
	img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	img_rect.texture      = tex
	img_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_layer.add_child(img_rect)

	# 关闭按钮（右上角）
	var close_btn := TextureButton.new()
	close_btn.set_anchor(SIDE_LEFT,   1.0)
	close_btn.set_anchor(SIDE_RIGHT,  1.0)
	close_btn.set_anchor(SIDE_TOP,    0.0)
	close_btn.set_anchor(SIDE_BOTTOM, 0.0)
	close_btn.set_offset(SIDE_LEFT,   -64.0)
	close_btn.set_offset(SIDE_RIGHT,  -16.0)
	close_btn.set_offset(SIDE_TOP,    16.0)
	close_btn.set_offset(SIDE_BOTTOM, 64.0)
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	var c_n := _try_load_ui("sysbtn_01_close.png")
	var c_h := _try_load_ui("sysbtn_01_close_hover.png")
	var c_p := _try_load_ui("sysbtn_01_close_click.png")
	if c_n: close_btn.texture_normal  = c_n
	if c_h: close_btn.texture_hover   = c_h
	if c_p: close_btn.texture_pressed = c_p
	close_btn.pressed.connect(_close_viewer)
	_viewer_layer.add_child(close_btn)

	# 点击遮罩也关闭
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_viewer()
	)

	# 淡入动画
	img_rect.modulate.a = 0.0
	overlay.modulate.a  = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay,  "modulate:a", 1.0, 0.25)
	tw.tween_property(img_rect, "modulate:a", 1.0, 0.35)


func _close_viewer() -> void:
	if not _viewer_layer:
		return
	var layer := _viewer_layer
	var tw := create_tween()
	tw.tween_property(layer, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		layer.queue_free()
	)
	_viewer_layer = null


# ─── 导航 ──────────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)


# ─── 资源加载工具 ──────────────────────────────────────────────────────────────

func _try_load_ui(filename: String) -> Texture2D:
	var path := UI_DIR + filename
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _try_load_bg(filename: String) -> Texture2D:
	var path := BG_DIR + filename
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
