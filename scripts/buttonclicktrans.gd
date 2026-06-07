extends Button

# 在右侧属性检查器中选择要跳转的场景文件
@export_file("*.tscn") var target_scene_path: String

# 当节点进入场景树时调用
func _ready() -> void:
	# 连接按钮按下的信号到跳转函数
	# 使用代码连接可以避免在编辑器里手动连线的麻烦
	self.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	# 检查是否设置了路径
	if target_scene_path != "":
		print("正在跳转场景: ", target_scene_path)
		# 执行切换场景逻辑
		get_tree().change_scene_to_file(target_scene_path)
	else:
		# 如果忘记设置路径，控制台会打印警告
		push_warning("警告：按钮 " + name + " 未设置跳转路径！")

# UI 脚本通常不需要每帧更新，所以建议删除 _process 以优化性能
