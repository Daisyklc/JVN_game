extends "res://scripts/DialogicSceneBridge.gd"
## 测试页面：实现 剧情(part1) → 小游戏 → 剧情(part2) → CG 的完整测试流程。
## 使用时间线 test_timeline_part1 和 test_timeline_part2。
## 继承 DialogicSceneBridge，在上面叠加测试流程的专属逻辑。

@export var cg_display_duration: float = 3.0

@onready var blackout_overlay: ColorRect = $OverlayLayer/BlackoutOverlay
@onready var cg_overlay: Control      = $OverlayLayer/CGOverlay

var _auto_mode: bool = false
var _skip_mode: bool = false
var _auto_btn_ref: TextureButton = null
var _skip_btn_ref: TextureButton = null


func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	_init_overlays()
	_setup_system_buttons()

	if Golbal.test_page_phase == "part2":
		# 从小游戏返回，播放第二部分剧情
		Golbal.test_page_phase = ""
		auto_play_on_ready = false
		start_timeline("test_timeline_part2")
	elif auto_play_on_ready and not timeline_to_play.is_empty():
		start_timeline(timeline_to_play)


func _init_overlays() -> void:
	if blackout_overlay:
		blackout_overlay.modulate.a = 0.0
		blackout_overlay.visible = true
	if cg_overlay:
		cg_overlay.modulate.a = 0.0
		cg_overlay.visible = true


# ─── 动态创建系统按钮（与 run_page 保持一致的风格）───────────────────────────

func _setup_system_buttons() -> void:
	var sys_layer: CanvasLayer = $SystemUILayer
	if not sys_layer:
		return

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sys_layer.add_child(root_ctrl)

	var hbox := HBoxContainer.new()
	hbox.set_anchor(SIDE_RIGHT, 1.0)
	hbox.set_anchor(SIDE_TOP, 0.0)
	hbox.set_anchor(SIDE_LEFT, 1.0)
	hbox.set_anchor(SIDE_BOTTOM, 0.0)
	hbox.set_offset(SIDE_RIGHT, -10.0)
	hbox.set_offset(SIDE_LEFT, -510.0)
	hbox.set_offset(SIDE_TOP, 10.0)
	hbox.set_offset(SIDE_BOTTOM, 50.0)
	hbox.add_theme_constant_override("separation", 4)
	root_ctrl.add_child(hbox)

	var btn_configs: Array = [
		["auto",  _on_auto_pressed],
		["skip",  _on_skip_pressed],
		["log",   _on_log_pressed],
		["save",  _on_save_pressed],
		["load",  _on_load_pressed],
		["menu",  _on_menu_pressed],
	]

	for cfg in btn_configs:
		var key: String = cfg[0]
		var callback: Callable = cfg[1]
		var btn := TextureButton.new()
		btn.name = key.capitalize() + "Btn"
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(80.0, 36.0)

		var tex_n: Texture2D = _try_load_tex("sysbtn_01_%s.png" % key)
		var tex_h: Texture2D = _try_load_tex("sysbtn_01_%s_hover.png" % key)
		var tex_p: Texture2D = _try_load_tex("sysbtn_01_%s_click.png" % key)

		if tex_n: btn.texture_normal  = tex_n
		if tex_h: btn.texture_hover   = tex_h
		if tex_p: btn.texture_pressed = tex_p

		btn.pressed.connect(callback)
		hbox.add_child(btn)
		if key == "auto": _auto_btn_ref = btn
		elif key == "skip": _skip_btn_ref = btn


func _try_load_tex(filename: String) -> Texture2D:
	var path := "res://assets/UI/gameUIset_red/" + filename
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ─── Dialogic 信号分发 ────────────────────────────────────────────────────────

func _on_dialogic_signal(argument: Variant) -> void:
	var sig: String = str(argument)
	match sig:
		"to_minigame":
			_on_to_minigame()
		"to_cg":
			_on_to_cg()
		"FX_blackout":
			_do_blackout()
		"FX_open_eyes":
			_do_open_eyes()
		_:
			pass


func _on_timeline_ended() -> void:
	# 测试流程整体结束，可在此返回主菜单
	pass


# ─── 测试流程处理 ─────────────────────────────────────────────────────────────

func _on_to_minigame() -> void:
	Golbal.test_page_phase = "part2"
	get_tree().change_scene_to_file("res://scenes/minigame_page.tscn")


func _on_to_cg() -> void:
	_show_cg()


func _show_cg() -> void:
	if not cg_overlay:
		return
	cg_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(cg_overlay, "modulate:a", 1.0, 0.5)
	tw.tween_interval(cg_display_duration)
	tw.tween_property(cg_overlay, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		cg_overlay.visible = false
		# CG 播放完毕后返回主菜单
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)


# ─── 黑幕演出（轻量实现，test_page 自用）───────────────────────────────────────

func _do_blackout() -> void:
	if not blackout_overlay:
		return
	var tw := create_tween()
	tw.tween_property(blackout_overlay, "modulate:a", 1.0, 0.3)


func _do_open_eyes() -> void:
	if not blackout_overlay:
		return
	var tw := create_tween()
	tw.tween_property(blackout_overlay, "modulate:a", 0.0, 0.3)


# ─── VN 系统按钮回调 ──────────────────────────────────────────────────────────

func _on_auto_pressed() -> void:
	_auto_mode = !_auto_mode
	Dialogic.Inputs.auto_advance.enabled_forced = _auto_mode
	if _auto_btn_ref:
		_auto_btn_ref.modulate = Color(1.0, 1.0, 0.45, 1.0) if _auto_mode else Color.WHITE


func _on_skip_pressed() -> void:
	_skip_mode = !_skip_mode
	Dialogic.Inputs.auto_skip.enabled = _skip_mode
	if _skip_btn_ref:
		_skip_btn_ref.modulate = Color(1.0, 1.0, 0.45, 1.0) if _skip_mode else Color.WHITE


func _on_log_pressed() -> void:
	Dialogic.History.open_history()


func _on_save_pressed() -> void:
	Dialogic.Save.save("slot_quick")


func _on_load_pressed() -> void:
	Dialogic.Save.load("slot_quick")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
