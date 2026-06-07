extends Control

const API_URL = "https://api.deepseek.com/v1/chat/completions"
const API_KEY = "sk-492cec68524e4cc096ae85ca62a346c1"

# --- 节点引用 ---
@onready var input1 = $ma/edit/HBoxContainer/materina/MaterialLineEdit
@onready var input2 = $ma/edit/HBoxContainer/materina2/ModifierLineEdit
@onready var input3 = $ma/edit/HBoxContainer/materina3/CategoryLineEdit
@onready var http_request = $DeepSeekRequester 
@onready var synthesis_button = $hecheng/Button 

# 预设相关节点
@onready var use_preset_checkbox = $ma/edit/UsePresetCheckBox
@onready var material_option = $ma/edit/HBoxContainer/materina/MaterialOptionButton
@onready var modifier_option = $ma/edit/HBoxContainer/materina2/ModifierOptionButton
@onready var category_option = $ma/edit/HBoxContainer/materina3/CategoryOptionButton

# 自定义弹窗节点
@onready var result_panel = $ResultPanel
@onready var content_label = $ResultPanel/ContentLabel
@onready var close_button = $ResultPanel/CloseButton

func _ready():
	# 初始化：隐藏弹窗
	result_panel.visible = false
	
	# 初始化默认预设（如果为空）
	_initialize_default_presets()
	
	# 连接信号
	synthesis_button.pressed.connect(_on_start_synthesis_pressed)
	
	# 修改：点击弹窗按钮后跳转到 final 场景
	close_button.pressed.connect(_on_close_button_pressed)
	
	http_request.request_completed.connect(_on_request_completed)
	
	# 连接预设相关信号
	if use_preset_checkbox:
		use_preset_checkbox.toggled.connect(_on_use_preset_toggled)
	
	# 连接下拉菜单信号
	if material_option:
		material_option.item_selected.connect(_on_material_selected)
	if modifier_option:
		modifier_option.item_selected.connect(_on_modifier_selected)
	if category_option:
		category_option.item_selected.connect(_on_category_selected)
	
	# 初始化预设选项
	_load_preset_options()

# 跳转场景逻辑
func _on_close_button_pressed():
	get_tree().change_scene_to_file("res://scenes/final.tscn")

# 点击“开始合成”
func _on_start_synthesis_pressed():
	var p1 = input1.text.strip_edges()
	var p2 = input2.text.strip_edges()
	var p3 = input3.text.strip_edges()
	
	if p1 == "" or p2 == "" or p3 == "":
		return

	synthesis_button.disabled = true
	synthesis_button.text = "合成中..."

	# 提示词增加纯文本要求
	var user_content = "素材：'%s'、'%s'、'%s'。请写一段100字左右的生日礼物介绍，文笔神秘优雅。不要使用任何表情符号、Markdown加粗或特殊符号。" % [p1, p2, p3]
	
	send_deepseek_request(user_content)

func send_deepseek_request(content):
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + API_KEY]
	var body = JSON.stringify({
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": "你是一位炼金术士，只输出纯文本内容，禁止使用Emoji表情。"},
			{"role": "user", "content": content}
		]
	})
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result, response_code, _headers, body):
	synthesis_button.disabled = false
	synthesis_button.text = "开始合成"
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var ai_text = json["choices"][0]["message"]["content"]
		# 过滤表情和特殊字符
		var filtered_text = filter_special_symbols(ai_text)
		Golbal.generated_gift_description = filtered_text
		show_custom_popup(filtered_text)
	else:
		show_custom_popup("魔法阵失效了... (代码: %d)" % response_code)

# 修复报错后的过滤函数
func filter_special_symbols(input_text: String) -> String:
	var regex = RegEx.new()
	var pattern = "[^\\x{4e00}-\\x{9fa5}a-zA-Z0-9，。！？：、\\n\\s]"
	var err = regex.compile(pattern)
	
	
	if err == OK:
		return regex.sub(input_text, "", true).strip_edges()
	else:
		# 如果正则编译失败，返回原始文本（防止报错导致逻辑中断）
		return input_text.strip_edges()

# 显示自定义弹窗并播放打字机效果
func show_custom_popup(full_text):
	# 确保在编辑器中将 ContentLabel 的 Autowrap Mode 设置为 Word
	content_label.text = full_text
	result_panel.visible = true
	
	var tween = create_tween()
	content_label.visible_ratio = 0
	# 增加平滑的显示效果
	tween.tween_property(content_label, "visible_ratio", 1.0, 2.5).set_trans(Tween.TRANS_LINEAR)

# 初始化默认预设（如果为空）
func _initialize_default_presets():
	# 如果材料预设为空，添加默认预设
	if Golbal.material_prompts.size() == 0:
		Golbal.material_prompts.append("水晶")
		Golbal.material_prompts.append("丝绸")
		Golbal.material_prompts.append("金属")
		Golbal.material_prompts.append("木材")
		Golbal.material_prompts.append("陶瓷")
		Golbal.material_prompts.append("皮革")
		Golbal.material_prompts.append("玻璃")
		Golbal.material_prompts.append("宝石")
	
	# 如果修饰词预设为空，添加默认预设
	if Golbal.modifier_prompts.size() == 0:
		Golbal.modifier_prompts.append("精致的")
		Golbal.modifier_prompts.append("优雅的")
		Golbal.modifier_prompts.append("神秘的")
		Golbal.modifier_prompts.append("温暖的")
		Golbal.modifier_prompts.append("闪亮的")
		Golbal.modifier_prompts.append("柔和的")
		Golbal.modifier_prompts.append("复古的")
		Golbal.modifier_prompts.append("现代的")
	
	# 如果物品类别预设为空，添加默认预设
	if Golbal.item_category_prompts.size() == 0:
		Golbal.item_category_prompts.append("首饰")
		Golbal.item_category_prompts.append("装饰品")
		Golbal.item_category_prompts.append("艺术品")
		Golbal.item_category_prompts.append("文具")
		Golbal.item_category_prompts.append("摆件")
		Golbal.item_category_prompts.append("收藏品")
		Golbal.item_category_prompts.append("纪念品")
		Golbal.item_category_prompts.append("礼品盒")

# 加载预设选项到下拉菜单
func _load_preset_options():
	# 确保预设已初始化
	_initialize_default_presets()
	
	# 加载材料预设
	if material_option:
		material_option.clear()
		material_option.add_item("选择材料预设...")
		if Golbal.material_prompts.size() > 0:
			for prompt in Golbal.material_prompts:
				var preview = prompt
				if preview.length() > 20:
					preview = preview.substr(0, 20) + "..."
				material_option.add_item(preview)
		print("材料预设已加载，共 ", Golbal.material_prompts.size(), " 项")
	
	# 加载修饰词预设
	if modifier_option:
		modifier_option.clear()
		modifier_option.add_item("选择修饰词预设...")
		if Golbal.modifier_prompts.size() > 0:
			for prompt in Golbal.modifier_prompts:
				var preview = prompt
				if preview.length() > 20:
					preview = preview.substr(0, 20) + "..."
				modifier_option.add_item(preview)
		print("修饰词预设已加载，共 ", Golbal.modifier_prompts.size(), " 项")
	
	# 加载物品类别预设
	if category_option:
		category_option.clear()
		category_option.add_item("选择物品类别预设...")
		if Golbal.item_category_prompts.size() > 0:
			for prompt in Golbal.item_category_prompts:
				var preview = prompt
				if preview.length() > 20:
					preview = preview.substr(0, 20) + "..."
				category_option.add_item(preview)
		print("物品类别预设已加载，共 ", Golbal.item_category_prompts.size(), " 项")

# 切换是否使用预设模板
func _on_use_preset_toggled(button_pressed: bool):
	if material_option:
		material_option.visible = button_pressed
	if modifier_option:
		modifier_option.visible = button_pressed
	if category_option:
		category_option.visible = button_pressed
	
	# 如果启用预设，确保预设已初始化并重新加载选项
	if button_pressed:
		_initialize_default_presets()
		_load_preset_options()

# 当场景重新进入时刷新预设选项
func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		# 确保默认预设已初始化
		_initialize_default_presets()
		# 如果预设功能已启用，刷新选项
		if use_preset_checkbox and use_preset_checkbox.button_pressed:
			_load_preset_options()

# 材料预设被选择
func _on_material_selected(index: int):
	if index <= 0 or index > Golbal.material_prompts.size():
		return
	
	var selected_prompt = Golbal.material_prompts[index - 1]  # -1 因为第一个是占位符
	if input1:
		# 如果输入框已有内容，追加；否则替换
		if input1.text.strip_edges() != "":
			input1.text += "、" + selected_prompt
		else:
			input1.text = selected_prompt
		# 重置下拉菜单选择
		material_option.selected = 0

# 修饰词预设被选择
func _on_modifier_selected(index: int):
	if index <= 0 or index > Golbal.modifier_prompts.size():
		return
	
	var selected_prompt = Golbal.modifier_prompts[index - 1]  # -1 因为第一个是占位符
	if input2:
		# 如果输入框已有内容，追加；否则替换
		if input2.text.strip_edges() != "":
			input2.text += "、" + selected_prompt
		else:
			input2.text = selected_prompt
		# 重置下拉菜单选择
		modifier_option.selected = 0

# 物品类别预设被选择
func _on_category_selected(index: int):
	if index <= 0 or index > Golbal.item_category_prompts.size():
		return
	
	var selected_prompt = Golbal.item_category_prompts[index - 1]  # -1 因为第一个是占位符
	if input3:
		# 如果输入框已有内容，追加；否则替换
		if input3.text.strip_edges() != "":
			input3.text += "、" + selected_prompt
		else:
			input3.text = selected_prompt
		# 重置下拉菜单选择
		category_option.selected = 0
