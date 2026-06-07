extends Control
## 量表小游戏：郝悦填写 Zung 抑郁自评量表（26题）
## 特殊题目演出：
##   Q7  — 光标浮动锁定在"是"选项上
##   Q16 — 点击任意选项后满屏红字"啊啊啊啊！"
##   Q17 — 所有选项均显示"没有问题"
##   Q24 — 所有选项均显示"为什么问这个？"
##   Q25 — 所有选项均显示"好的"
##   Q26 — 仅"是/否"两项；选"否"则重复此题直到选"是"

signal survey_completed

const STANDARD_OPTIONS: Array[String] = [
	"很少有\n(A Little)",
	"有时有\n(Some)",
	"大部分时间\n(Good Part)",
	"绝大部分时间\n(Most)",
]

const QUESTIONS: Array = [
	{"id":  1, "text": "我感到情绪低落、郁闷",                          "type": "normal"},
	{"id":  2, "text": "早晨是我心情最好的时候",                          "type": "normal"},
	{"id":  3, "text": "我想哭或感到想哭",                                "type": "normal"},
	{"id":  4, "text": "我夜间睡眠不好",                                  "type": "normal"},
	{"id":  5, "text": "我吃饭像平时一样多",                              "type": "normal"},
	{"id":  6, "text": "我仍旧期盼着被神明救赎",                          "type": "normal"},
	{"id":  7, "text": "我的神明是项涟漪。",                              "type": "cursor_lock"},
	{"id":  8, "text": "我注意到我的体重在减轻",                          "type": "normal"},
	{"id":  9, "text": "我有便秘的苦恼",                                  "type": "normal"},
	{"id": 10, "text": "我心跳比平时快",                                  "type": "normal"},
	{"id": 11, "text": "我无缘无故地感到疲乏",                            "type": "normal"},
	{"id": 12, "text": "我从不漫无目的地闲逛",                            "type": "normal"},
	{"id": 13, "text": "我重复做一样的事情，用不着别人指导",               "type": "normal"},
	{"id": 14, "text": "我做事情像平时一样顺利",                          "type": "normal"},
	{"id": 15, "text": "我坐卧不安，难以保持平静",                        "type": "normal"},
	{"id": 16, "text": "我想要尖叫",                                      "type": "scream"},
	{"id": 17, "text": "我怀疑这个量表有问题。",                          "type": "no_problem"},
	{"id": 18, "text": "我比平时更容易激怒",                              "type": "normal"},
	{"id": 19, "text": "我觉得决定事情很容易",                            "type": "normal"},
	{"id": 20, "text": "我觉得自己有用，被需要",                          "type": "normal"},
	{"id": 21, "text": "我的生活过得很充实",                              "type": "normal"},
	{"id": 22, "text": "我觉得如果我死了，□□们也不会在意。",              "type": "normal"},
	{"id": 23, "text": "即使这样。我仍旧想要放声歌唱",                    "type": "normal"},
	{"id": 24, "text": "所见就是真实吗？",                                "type": "why_ask"},
	{"id": 25, "text": "不要提和心理测试无关的东西。",                    "type": "ok"},
	{"id": 26, "text": "我想要结束这个量表",                              "type": "exit_choice"},
]

@onready var progress_label: Label = \
	$CenterContainer/SurveyPanel/MarginContainer/VBox/HeaderBox/ProgressLabel
@onready var question_label: Label = \
	$CenterContainer/SurveyPanel/MarginContainer/VBox/QuestionLabel
@onready var options_container: HBoxContainer = \
	$CenterContainer/SurveyPanel/MarginContainer/VBox/OptionsContainer
@onready var scream_overlay: CanvasLayer = $ScreamOverlay

var _current_idx: int = 0
var _option_btns: Array[Button] = []
var _cursor_lock_active: bool = false
var _cursor_lock_btn: Button = null
var _scream_pending: bool = false


func _ready() -> void:
	_create_option_buttons()
	_show_question(0)


func _process(_delta: float) -> void:
	if _cursor_lock_active and _cursor_lock_btn and is_instance_valid(_cursor_lock_btn):
		var center: Vector2 = _cursor_lock_btn.get_global_rect().get_center()
		Input.warp_mouse(center)


# ─── Button pool ──────────────────────────────────────────────────────────────

func _create_option_buttons() -> void:
	for i: int in 4:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(168, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		options_container.add_child(btn)
		btn.pressed.connect(_on_btn_pressed.bind(i))
		_option_btns.append(btn)


# ─── Question display ─────────────────────────────────────────────────────────

func _show_question(idx: int) -> void:
	_current_idx = idx
	_cursor_lock_active = false
	_cursor_lock_btn = null
	_scream_pending = false

	var q: Dictionary = QUESTIONS[idx]
	progress_label.text = "%d / 26" % (idx + 1)
	question_label.text = q["text"]

	# Highlight special questions with a faint tint on the question label
	var is_special: bool = q["type"] != "normal"
	question_label.add_theme_color_override(
		"font_color",
		Color(0.18, 0.18, 0.22, 1) if not is_special else Color(0.15, 0.18, 0.38, 1)
	)

	match q["type"] as String:
		"normal":
			_setup_4_options(STANDARD_OPTIONS)
		"cursor_lock":
			_setup_4_options(["不是", "不是", "不是", "是"])
			_cursor_lock_btn = _option_btns[3]
			_cursor_lock_active = true
		"scream":
			_setup_4_options(STANDARD_OPTIONS)
			_scream_pending = true
		"no_problem":
			_setup_4_options(["没有问题", "没有问题", "没有问题", "没有问题"])
		"why_ask":
			_setup_4_options(["为什么问这个？", "为什么问这个？", "为什么问这个？", "为什么问这个？"])
		"ok":
			_setup_4_options(["好的", "好的", "好的", "好的"])
		"exit_choice":
			_setup_2_options(["是", "否"])


func _setup_4_options(labels: Array) -> void:
	for i: int in 4:
		_option_btns[i].text = labels[i]
		_option_btns[i].show()


func _setup_2_options(labels: Array) -> void:
	_option_btns[0].text = labels[0]
	_option_btns[1].text = labels[1]
	_option_btns[0].show()
	_option_btns[1].show()
	_option_btns[2].hide()
	_option_btns[3].hide()


# ─── Button callbacks ─────────────────────────────────────────────────────────

func _on_btn_pressed(btn_index: int) -> void:
	var q_type: String = QUESTIONS[_current_idx]["type"]
	match q_type:
		"scream":
			_trigger_scream()
		"exit_choice":
			if btn_index == 0:
				_finish()
			else:
				_show_question(_current_idx)
		_:
			_advance()


func _advance() -> void:
	_cursor_lock_active = false
	_cursor_lock_btn = null
	var next: int = _current_idx + 1
	if next >= QUESTIONS.size():
		_finish()
	else:
		_show_question(next)


func _finish() -> void:
	_cursor_lock_active = false
	survey_completed.emit()


# ─── Q16 Scream effect ────────────────────────────────────────────────────────

func _trigger_scream() -> void:
	if scream_overlay:
		scream_overlay.visible = true


func _input(event: InputEvent) -> void:
	if scream_overlay and scream_overlay.visible:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			scream_overlay.visible = false
			get_viewport().set_input_as_handled()
			_advance()
