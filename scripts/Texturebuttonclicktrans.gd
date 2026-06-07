extends TextureButton

@export_file("*.tscn") var target_scene_path: String

func _ready() -> void:
	# 连接点击信号到跳转函数
	self.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if target_scene_path != "":
		get_tree().change_scene_to_file(target_scene_path)
	else:
		print("警告：该按钮尚未设置目标场景路径！")
