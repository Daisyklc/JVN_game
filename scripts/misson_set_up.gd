extends Control

@onready var tary_button = $MainLayout/Tary 
@onready var popup_panel = $SubWindows/NewsPanelPop
@onready var text_edit = $SubWindows/NewsPanelPop/TextEdit
@onready var start_button = $MainLayout/start
@onready var use_preset_checkbox = $MainLayout/UsePresetCheckBox

func _ready():
	if popup_panel:
		popup_panel.hide()
	
	if tary_button:
		tary_button.pressed.connect(_on_tary_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_game)
	
	if text_edit:
		text_edit.text_changed.connect(_on_text_changed)

func _on_tary_pressed():
	popup_panel.show()
	
	# 如果勾选了使用预设，并且预设内容不为空，则填入预设内容
	if use_preset_checkbox and use_preset_checkbox.button_pressed:
		if Golbal.selected_location_name != "":
			text_edit.text = Golbal.selected_location_name
		else:
			# 如果预设为空，提示用户
			text_edit.text = ""
			print("预设内容为空，请先在预设场景中设置故事预设")
	else:
		# 如果不使用预设，清空输入框
		text_edit.text = ""
	
	text_edit.grab_focus() 

func _on_text_changed():
	var current_text = text_edit.text
	if "-1" in current_text:
		text_edit.text = current_text.replace("-1", "")
		text_edit.set_caret_line(text_edit.get_line_count())
		popup_panel.hide()
		print("检测到关闭符号，弹窗已关闭")

func _on_start_game():
	var player_story = text_edit.text.strip_edges()
	if player_story == "":
		player_story = "默认记忆：我们小时候经常在老家的院子里一起画画。"
	save_story_to_config(player_story)
	get_tree().change_scene_to_file("res://scenes/deepseek_comic_scene.tscn")

func save_story_to_config(story_content: String):
	var config = ConfigFile.new()
	config.set_value("memory", "story", story_content)
	config.save("user://game_settings.cfg")
