extends Control

const MEME_SCENE_PATH = "res://scenes/deepseek_scene.tscn"

const LOCATION_MAP = {
	"魔法使常光顾的书店": "res://assets/UI/sence/书店.png",
	"修建在露珠上的花店": "res://assets/UI/sence/花店.png",
	"试衣镜会说话的服装店": "res://assets/UI/sence/服装店.png",
	"吟游诗人的CD唱片店": "res://assets/UI/sence/CD店.png",
	"每次配方都不一样的药店": "res://assets/UI/sence/药品店.png",
	"传说能挡一次厄运的饰品店": "res://assets/UI/sence/Gemini_Generated_Image_mdxajumdxajumdxa.png"
}

@onready var vbox_container = $ChoicePanel/VBoxContainer

func _ready():
	for location_node in vbox_container.get_children():
		var button = location_node.get_node("Button")
		if button is Button:
			button.pressed.connect(_on_location_button_pressed.bind(button))

func _on_location_button_pressed(button: Button):
	var location_text = button.text
	
	# 1. 记录地点名称
	Golbal.selected_location_name = location_text
	
	# 2. 获取对应的背景图路径并存入全局变量
	if LOCATION_MAP.has(location_text):
		Golbal.selected_bg_path = LOCATION_MAP[location_text]
	else:
		# 如果没找到，可以设置一个默认图
		Golbal.selected_bg_path = "res://assets/backgrounds/default.png"
	
	print("准备跳转，背景路径为: ", Golbal.selected_bg_path)
	get_tree().change_scene_to_file(MEME_SCENE_PATH)
