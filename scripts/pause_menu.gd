extends Control

## 暂停菜单：点击 menu 按钮后弹出的全屏覆盖层
## 包含：查看人物 / 查看物品 / 查看存档 / 返回主菜单 / 继续游戏

signal close_requested

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const LOAD_PAGE_PATH  := "res://scenes/load_page.tscn"

## 人物数据（可按需扩充）
const CHARACTER_DATA: Array = [
	{
		"name": "郝悦",
		"role": "高中生",
		"desc": "性格温柔内敛，内心承受着巨大的压力，\n对周围的人与事充满敏感而细腻的感知。"
	},
	{
		"name": "项涟漪",
		"role": "班主任教师",
		"desc": "关心学生的心理健康，善于倾听与引导，\n致力于帮助学生走出困境、重拾希望。"
	},
]

var _pages: Dictionary = {}
var _current_page: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_all_pages()
	_show_page("main")
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


# ─── 页面管理 ──────────────────────────────────────────────────────────────────

func _build_all_pages() -> void:
	var shared_bg := ColorRect.new()
	shared_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	shared_bg.color = Color(0.0, 0.0, 0.0, 0.72)
	shared_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shared_bg)

	_pages["main"]       = _build_main_page()
	_pages["characters"] = _build_characters_page()
	_pages["items"]      = _build_items_page()

	for page: Control in _pages.values():
		add_child(page)
		page.visible = false


func _show_page(page_name: String) -> void:
	for name: String in _pages:
		_pages[name].visible = (name == page_name)
	_current_page = page_name


# ─── 主菜单页 ─────────────────────────────────────────────────────────────────

func _build_main_page() -> Control:
	var root := _make_center_root()
	var panel := _make_panel(380)
	root.add_child(panel)

	var vbox := _make_vbox_in_panel(panel, 40, 40, 50, 50, 14)

	_add_title(vbox, "暂 停")
	vbox.add_child(HSeparator.new())
	vbox.add_child(_spacer(10))

	_add_btn(vbox, "查 看 人 物", func(): _show_page("characters"))
	_add_btn(vbox, "查 看 物 品", func(): _show_page("items"))
	_add_btn(vbox, "查 看 存 档", func(): _navigate_to(LOAD_PAGE_PATH))
	_add_btn(vbox, "返回主菜单", func(): _navigate_to(MAIN_MENU_PATH),
			Color(1.0, 0.75, 0.75))

	vbox.add_child(_spacer(10))
	_add_btn(vbox, "继 续 游 戏", func(): _dismiss(), Color(0.72, 0.96, 0.80))

	return root


# ─── 查看人物页 ───────────────────────────────────────────────────────────────

func _build_characters_page() -> Control:
	var root := _make_center_root()
	var panel := _make_panel(500)
	root.add_child(panel)

	var vbox := _make_vbox_in_panel(panel, 30, 30, 40, 40, 12)

	_add_title(vbox, "人物介绍")
	vbox.add_child(HSeparator.new())
	vbox.add_child(_spacer(8))

	for ch: Dictionary in CHARACTER_DATA:
		vbox.add_child(_make_character_card(ch["name"], ch["role"], ch["desc"]))
		vbox.add_child(_spacer(4))

	vbox.add_child(_spacer(10))
	_add_btn(vbox, "返 回", func(): _show_page("main"))

	return root


func _make_character_card(char_name: String, role: String, desc: String) -> Control:
	var card := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.19, 0.15, 0.25, 0.80)
	sty.border_color = Color(0.44, 0.34, 0.54, 0.70)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", sty)

	var mg := MarginContainer.new()
	for prop: String in ["margin_top","margin_bottom","margin_left","margin_right"]:
		mg.add_theme_constant_override(prop, 12)
	card.add_child(mg)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	mg.add_child(cv)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	cv.add_child(hdr)

	var name_lbl := Label.new()
	name_lbl.text = char_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.91, 0.72))
	hdr.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = role
	role_lbl.add_theme_font_size_override("font_size", 14)
	role_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.82))
	role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr.add_child(role_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.84, 0.94))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(desc_lbl)

	return card


# ─── 查看物品页 ───────────────────────────────────────────────────────────────

func _build_items_page() -> Control:
	var root := _make_center_root()
	var panel := _make_panel(460)
	root.add_child(panel)

	var vbox := _make_vbox_in_panel(panel, 30, 30, 40, 40, 12)

	_add_title(vbox, "重要物品")
	vbox.add_child(HSeparator.new())
	vbox.add_child(_spacer(8))

	var gm: Node = get_node_or_null("/root/GameManager")
	var items: Array = gm.inventory if gm else []
	if items.is_empty():
		var lbl := Label.new()
		lbl.text = "当前尚未收集到任何物品。"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.82))
		vbox.add_child(lbl)
	else:
		for item_id: String in items:
			vbox.add_child(_make_item_row(item_id))
			vbox.add_child(_spacer(4))

	vbox.add_child(_spacer(10))
	_add_btn(vbox, "返 回", func(): _show_page("main"))

	return root


func _make_item_row(item_id: String) -> Control:
	var row := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.19, 0.15, 0.25, 0.80)
	sty.border_color = Color(0.44, 0.34, 0.54, 0.70)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(6)
	row.add_theme_stylebox_override("panel", sty)

	var mg := MarginContainer.new()
	for prop: String in ["margin_top","margin_bottom","margin_left","margin_right"]:
		mg.add_theme_constant_override(prop, 10)
	row.add_child(mg)

	var lbl := Label.new()
	lbl.text = "▸  " + item_id
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.98))
	mg.add_child(lbl)

	return row


# ─── 关闭 / 跳转 ──────────────────────────────────────────────────────────────

func _dismiss() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): close_requested.emit())


func _navigate_to(path: String) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))


# ─── UI 辅助方法 ──────────────────────────────────────────────────────────────

func _make_center_root() -> CenterContainer:
	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root


func _make_panel(min_width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.10, 0.08, 0.13, 0.96)
	sty.border_color = Color(0.54, 0.42, 0.64, 1.0)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sty)
	return panel


func _make_vbox_in_panel(
		panel: PanelContainer,
		mt: int, mb: int, ml: int, mr: int,
		sep: int) -> VBoxContainer:
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_top",    mt)
	mg.add_theme_constant_override("margin_bottom", mb)
	mg.add_theme_constant_override("margin_left",   ml)
	mg.add_theme_constant_override("margin_right",  mr)
	panel.add_child(mg)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", sep)
	mg.add_child(vbox)
	return vbox


func _add_title(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 1.0))
	parent.add_child(lbl)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _add_btn(
		parent: Control,
		text: String,
		callback: Callable,
		font_color: Color = Color(0.92, 0.84, 1.0)) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 50)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color",         font_color)
	btn.add_theme_color_override("font_hover_color",   font_color.lightened(0.18))
	btn.add_theme_color_override("font_pressed_color", font_color.darkened(0.12))

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.20, 0.16, 0.27, 0.80)
	sn.border_color = Color(0.44, 0.35, 0.54, 0.70)
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.32, 0.26, 0.43, 0.96)
	sh.border_color = Color(0.68, 0.56, 0.80, 1.0)
	sh.set_border_width_all(2)
	sh.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sh)

	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.15, 0.12, 0.21, 1.0)
	sp.border_color = Color(0.54, 0.43, 0.66, 1.0)
	sp.set_border_width_all(2)
	sp.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", sp)

	btn.pressed.connect(callback)
	parent.add_child(btn)
