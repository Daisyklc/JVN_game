extends Node
## 将 Dialogic 时间线与场景演出衔接的桥接脚本。
## 挂到任意场景节点上，在 _ready 里调用 start_timeline 或在编辑器中设置 timeline_to_play。
## 根据时间线里发出的 signal 做黑幕、睁眼、幻觉、CG 等演出。

## 进入场景时自动播放的 timeline 名（留空则不自动播放）
@export var timeline_to_play: String = ""
## 若为 true，会在 _ready 时自动播放 timeline_to_play
@export var auto_play_on_ready: bool = false

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	if auto_play_on_ready and not timeline_to_play.is_empty():
		start_timeline(timeline_to_play)


## 开始播放指定时间线（如 "sc001_合唱室傍晚" 或 "sc002_两人独处"）
func start_timeline(timeline_name: String) -> void:
	if timeline_name.is_empty():
		return
	Dialogic.start(timeline_name)


func _on_dialogic_signal(argument: Variant) -> void:
	var sig: String = str(argument)
	match sig:
		# 黑幕 / 睁眼 —— 时间线中以 FX_ 前缀发出
		"FX_blackout":
			_do_blackout()
		"FX_open_eyes":
			_do_open_eyes()
		# 幻觉进入 / 退出
		"FX_enter_hallucination":
			_do_enter_hallucination()
		"exit_hallucination":
			_do_exit_hallucination()
		# CG 显示
		"show_cg":
			_do_show_cg()
		"CG01_传达到的心愿天使":
			_do_show_cg_01()
		# 幻觉音效演出
		"FX_HY_fisheye_rounded":
			_do_hallucination_taunt()
		# 场景链接信号 —— 时间线中以 _end 后缀发出
		"sc001_end":
			_on_sc001_finished()
		"sc002_end":
			_on_sc002_finished()
		_:
			pass


func _on_timeline_ended() -> void:
	pass


# --- 演出占位：在子类或场景中重写或连接节点实现 ---

func _do_blackout() -> void:
	pass

func _do_open_eyes() -> void:
	pass

func _do_enter_hallucination() -> void:
	pass

func _do_exit_hallucination() -> void:
	pass

func _do_show_cg() -> void:
	pass

func _do_show_cg_01() -> void:
	pass

func _do_hallucination_taunt() -> void:
	pass

func _on_sc001_finished() -> void:
	pass

func _on_sc002_finished() -> void:
	pass
