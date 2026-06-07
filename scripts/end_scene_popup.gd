extends Control

@onready var popup_panel = $PopupPanel
@onready var return_button = $PopupPanel/VBoxContainer/ReturnButton
@onready var click_area = $ClickArea

const MAIN_MENU_PATH = "res://scenes/main_menu.tscn"

func _ready() -> void:
	# 初始隐藏弹窗
	if popup_panel:
		popup_panel.hide()
	
	# 连接返回按钮
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)
	
	# 连接点击区域
	if click_area:
		click_area.pressed.connect(_on_scene_clicked)

func _on_scene_clicked() -> void:
	if popup_panel and not popup_panel.visible:
		popup_panel.show()

func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
