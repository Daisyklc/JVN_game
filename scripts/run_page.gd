extends "res://scripts/DialogicSceneBridge.gd"
## 运行页面：进入后自动播放 sc001_合唱室傍晚，
## 响应时间线中的 FX 信号做黑幕、幻觉、红染等演出效果，
## 并在右上角动态生成 VN 系统控制按钮（购买的 gameUIset_red 素材）。

## 背景图片路径前缀
const BG_DIR: String = "res://assets/UI/gameUIset_red/bg/"

## 信号名 → 背景文件名映射表
const BG_MAP: Dictionary = {
	"BG_choir_room":    "bg_choir_room.png",
	"BG_hallucination": "bg_choir_room_hallucination_jumpscare.png",
	"BG_road":          "bg_road.png",
	"BG_hospital":      "bg_houzhenwaiting.png",
	"BG_outpatient":    "bg_outpatientCharge.png",
	"BG_testroom":      "bg_testroom.png",
	"BG_waiting":       "bg_houzhenwaiting01.png",
	"BG_restroom":      "bg_room_restroom.png",
	"BG_anxiety_room":  "bg_room_yiyujiaolv.png",
}

## 信号名 → CG 文件名映射表（全屏叠加 CG，点击关闭）
const CG_MAP: Dictionary = {
	"CG_DyingHY":           "bg_bedInHeaven.png",
	"show_cg":              "bg_ChildhoodBrokenBowl.png",
	"CG01_传达到的心愿天使": "bg_bedInHeaven.png",
}

## 黑幕淡入/淡出时长（秒）
@export var blackout_duration: float = 0.3
## 幻觉层淡入/淡出时长（秒）
@export var hallucination_duration: float = 0.4
## 红染效果持续时长（秒）
@export var red_tint_duration: float = 0.3
## 背景交叉淡入时长（秒）
@export var bg_fade_duration: float = 0.5
## CG 淡入/淡出时长（秒）
@export var cg_fade_duration: float = 0.6
## 画面抖动强度（像素）
@export var shake_strength: float = 6.0
## 画面抖动持续时长（秒）
@export var shake_duration: float = 0.4

@onready var blackout_overlay: ColorRect = $OverlayLayer/BlackoutOverlay
@onready var hallucination_overlay: ColorRect = $OverlayLayer/HallucinationOverlay
@onready var red_tint_overlay: ColorRect = $OverlayLayer/RedTintOverlay
@onready var bg_texture: TextureRect = $Background/BgTexture
@onready var cg_layer: CanvasLayer = $CGLayer
@onready var cg_texture: TextureRect = $CGLayer/CGTexture
@onready var cg_close_btn: Button = $CGLayer/CGCloseBtn

var _auto_mode: bool = false
var _skip_mode: bool = false
var _auto_btn_ref: TextureButton = null
var _skip_btn_ref: TextureButton = null
var _shake_tween: Tween = null
var _current_bg: String = ""
var _survey_layer: CanvasLayer = null
var _pause_layer: CanvasLayer = null


func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	_init_overlays()
	_init_cg_layer()
	_setup_system_buttons()
	var tl_to_play := timeline_to_play
	if not Golbal.pending_timeline.is_empty():
		tl_to_play = Golbal.pending_timeline
		Golbal.pending_timeline = ""
	if auto_play_on_ready and not tl_to_play.is_empty():
		start_timeline(tl_to_play)


func _init_overlays() -> void:
	for overlay: ColorRect in [blackout_overlay, hallucination_overlay, red_tint_overlay]:
		if overlay:
			overlay.modulate.a = 0.0
			overlay.visible = true


func _init_cg_layer() -> void:
	if cg_layer:
		cg_layer.visible = false
	if cg_texture:
		cg_texture.modulate.a = 0.0
	if cg_close_btn:
		cg_close_btn.pressed.connect(_do_hide_cg)


# ─── 动态创建系统按钮面板 ────────────────────────────────────────────────────

func _setup_system_buttons() -> void:
	var sys_layer: CanvasLayer = $SystemUILayer
	if not sys_layer:
		return

	# 全屏根 Control，本身不捕获鼠标
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sys_layer.add_child(root_ctrl)

	# 右上角横向按钮条
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

	# 按钮定义：[素材名后缀, 回调方法]
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

		# 尝试加载三态贴图（normal / hover / pressed）
		var tex_normal: Texture2D = _try_load_tex("sysbtn_01_%s.png" % key)
		var tex_hover:  Texture2D = _try_load_tex("sysbtn_01_%s_hover.png" % key)
		var tex_press:  Texture2D = _try_load_tex("sysbtn_01_%s_click.png" % key)

		if tex_normal: btn.texture_normal  = tex_normal
		if tex_hover:  btn.texture_hover   = tex_hover
		if tex_press:  btn.texture_pressed = tex_press

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
	# 背景切换信号（BG_ 前缀）
	if BG_MAP.has(sig):
		_set_background(BG_MAP[sig])
		return
	# CG 叠加显示信号
	if CG_MAP.has(sig):
		Golbal.unlock_cg(sig)
		_do_show_cg(CG_MAP[sig])
		return
	match sig:
		"FX_blackout":
			_do_blackout()
		"FX_open_eyes":
			_do_open_eyes()
		"FX_enter_hallucination":
			_do_enter_hallucination()
		"exit_hallucination":
			_do_exit_hallucination()
		"FX_turn_red":
			_do_red_tint()
		"FX_shake_left_right", "FX_earthquake":
			_do_screen_shake()
		"FX_HY_fisheye_rounded":
			_do_hallucination_fisheye()
		"GAME_show_survey":
			_show_survey_game()
		"sc000_end":
			_on_sc000_finished()
		"sc001_end":
			_on_sc001_finished()
		"sc002_end":
			_on_sc002_finished()
		"sc003_end":
			_on_sc003_finished()
		"sc004_end":
			_on_sc004_finished()
		"sc005_end":
			_on_sc005_finished()
		"sc006_end":
			_on_sc006_finished()
		_:
			pass


func _on_timeline_ended() -> void:
	pass


# ─── 演出实现 ─────────────────────────────────────────────────────────────────

func _do_blackout() -> void:
	if not blackout_overlay:
		return
	var tw := create_tween()
	tw.tween_property(blackout_overlay, "modulate:a", 1.0, blackout_duration)


func _do_open_eyes() -> void:
	if not blackout_overlay:
		return
	var tw := create_tween()
	tw.tween_property(blackout_overlay, "modulate:a", 0.0, blackout_duration)


func _do_enter_hallucination() -> void:
	if not hallucination_overlay:
		return
	hallucination_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(hallucination_overlay, "modulate:a", 1.0, hallucination_duration)
	# 切换到幻觉背景
	_set_background("bg_choir_room_hallucination_jumpscare.png")


func _do_exit_hallucination() -> void:
	if not hallucination_overlay:
		return
	var tw := create_tween()
	tw.tween_property(hallucination_overlay, "modulate:a", 0.0, hallucination_duration)
	tw.tween_callback(func(): hallucination_overlay.visible = false)
	# 恢复正常合唱室背景
	_set_background(_current_bg if not _current_bg.is_empty() else "bg_choir_room.png")


func _do_red_tint() -> void:
	if not red_tint_overlay:
		return
	red_tint_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(red_tint_overlay, "modulate:a", 1.0, red_tint_duration)
	tw.tween_interval(1.5)
	tw.tween_property(red_tint_overlay, "modulate:a", 0.0, red_tint_duration)
	tw.tween_callback(func(): red_tint_overlay.visible = false)


func _do_screen_shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		return
	var bg: ColorRect = $Background
	if not bg:
		return
	_shake_tween = create_tween()
	var steps := int(shake_duration / 0.04)
	for i in steps:
		var ox := randf_range(-shake_strength, shake_strength)
		var oy := randf_range(-shake_strength * 0.4, shake_strength * 0.4)
		_shake_tween.tween_property(bg, "position", Vector2(ox, oy), 0.02)
	_shake_tween.tween_property(bg, "position", Vector2.ZERO, 0.06)


func _do_hallucination_fisheye() -> void:
	# 幻觉中镜头扭曲感：用 hallucination_overlay 做一次脉冲闪烁
	if not hallucination_overlay:
		return
	var tw := create_tween()
	tw.tween_property(hallucination_overlay, "modulate:a", 0.65, 0.15)
	tw.tween_property(hallucination_overlay, "modulate:a", 0.2,  0.15)
	tw.tween_property(hallucination_overlay, "modulate:a", 0.65, 0.15)
	tw.tween_property(hallucination_overlay, "modulate:a", 0.0,  0.2)


## 设置背景图片（淡入切换）
func _set_background(filename: String) -> void:
	if not bg_texture:
		return
	var path := BG_DIR + filename
	if not ResourceLoader.exists(path):
		push_warning("run_page: 背景图不存在: " + path)
		return
	# 记录非幻觉背景，用于退出幻觉时恢复
	if not filename.contains("hallucination"):
		_current_bg = filename
	var tex := load(path) as Texture2D
	if not tex:
		return
	var tw := create_tween()
	tw.tween_property(bg_texture, "modulate:a", 0.0, bg_fade_duration * 0.4)
	tw.tween_callback(func():
		bg_texture.texture = tex
	)
	tw.tween_property(bg_texture, "modulate:a", 1.0, bg_fade_duration * 0.6)


## 显示全屏 CG 叠加层（点击任意处关闭）
func _do_show_cg(filename: String = "") -> void:
	if filename.is_empty() or not cg_layer or not cg_texture:
		return
	var path := BG_DIR + filename
	if not ResourceLoader.exists(path):
		push_warning("run_page: CG 图不存在: " + path)
		return
	var tex := load(path) as Texture2D
	if not tex:
		return
	cg_texture.texture = tex
	cg_texture.modulate.a = 0.0
	cg_layer.visible = true
	var tw := create_tween()
	tw.tween_property(cg_texture, "modulate:a", 1.0, cg_fade_duration)


## 关闭全屏 CG 叠加层
func _do_hide_cg() -> void:
	if not cg_layer or not cg_texture:
		return
	var tw := create_tween()
	tw.tween_property(cg_texture, "modulate:a", 0.0, cg_fade_duration * 0.5)
	tw.tween_callback(func(): cg_layer.visible = false)


func _do_show_cg_01() -> void:
	_do_show_cg(CG_MAP.get("CG01_传达到的心愿天使", ""))


func _do_hallucination_taunt() -> void:
	_do_hallucination_fisheye()


# ─── 场景链接 ─────────────────────────────────────────────────────────────────

func _on_sc000_finished() -> void:
	start_timeline("sc001_合唱室傍晚")


func _on_sc001_finished() -> void:
	start_timeline("sc002_两人独处")


func _on_sc002_finished() -> void:
	start_timeline("sc003_医院_诊室_日间")


func _on_sc003_finished() -> void:
	start_timeline("sc004_医院_量表测评室")


func _on_sc004_finished() -> void:
	start_timeline("sc005_医院门口")


func _on_sc005_finished() -> void:
	start_timeline("sc006_回去的路上")


func _on_sc006_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ─── 量表小游戏 ───────────────────────────────────────────────────────────────

func _show_survey_game() -> void:
	const SURVEY_PATH := "res://scenes/survey_game.tscn"
	if not ResourceLoader.exists(SURVEY_PATH):
		push_warning("run_page: 找不到量表场景 " + SURVEY_PATH)
		return
	Dialogic.paused = true
	_survey_layer = CanvasLayer.new()
	_survey_layer.layer = 15
	add_child(_survey_layer)
	var survey_scene: PackedScene = load(SURVEY_PATH)
	var survey: Control = survey_scene.instantiate()
	survey.survey_completed.connect(_on_survey_completed)
	_survey_layer.add_child(survey)


func _on_survey_completed() -> void:
	if _survey_layer:
		_survey_layer.queue_free()
		_survey_layer = null
	Dialogic.paused = false


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
	if _pause_layer:
		return
	_show_pause_menu()


func _show_pause_menu() -> void:
	const PAUSE_PATH := "res://scenes/pause_menu.tscn"
	if not ResourceLoader.exists(PAUSE_PATH):
		push_warning("run_page: 找不到暂停菜单场景 " + PAUSE_PATH)
		return
	Dialogic.paused = true
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 20
	add_child(_pause_layer)
	var pause_scene: PackedScene = load(PAUSE_PATH)
	var pause_menu: Control = pause_scene.instantiate()
	pause_menu.close_requested.connect(_on_pause_menu_closed)
	_pause_layer.add_child(pause_menu)


func _on_pause_menu_closed() -> void:
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	Dialogic.paused = false
