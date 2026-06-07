extends Control

@export var script_data: Array[Dictionary] = []
@export var typing_speed: float = 0.05
@onready var text_label = $RichTextLabel
@onready var name_label = $"../NameLabel"
@onready var char_manager = $"../PanelsContainer" # 指向立绘管理器所在的节点

var current_index: int = 0
var is_typing: bool = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	if script_data.size() > 0:
		play_current_step()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			finish_typing()
		else:
			next_step()

func play_current_step():
	var data = script_data[current_index]
	
	name_label.text = data.get("name", "")
	text_label.text = data.get("text", "")
	
	if data.has("position") and data.has("sprite"):
		char_manager.change_character(data["position"], data["sprite"])
	
	start_typing()

func start_typing():
	text_label.visible_ratio = 0
	is_typing = true
	var tween = create_tween()
	var duration = text_label.text.length() * typing_speed
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func finish_typing():
	is_typing = false
	text_label.visible_ratio = 1.0

func next_step():
	current_index += 1
	if current_index < script_data.size():
		play_current_step()
	else:
		print("本场景剧情结束")
