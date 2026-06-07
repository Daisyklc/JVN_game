extends Control

@onready var http_request = $HTTPRequest
@onready var rich_text_label = $TextLabel/RichTextLabel 
@onready var name_label = $DialogueCharacter/NameLabel
@onready var next_button = $DialogueControl/VBoxContainer/TextureButton

var dialogue_count = 0 
var max_rounds = 5 
var player_story_context = ""
var is_ai_speaking = false
@onready var current_location = Golbal.selected_location_name if Golbal.selected_location_name != "" else "未知地点"

const EXPRESSIONS = {
	"upset": preload("res://assets/UI/emoijmeme/Msad.png"),
	"normal": preload("res://assets/UI/emoijmeme/Mpokerfaced.png"),
	"happy": preload("res://assets/UI/emoijmeme/Mhappy.png")
}

const API_KEY = "sk-492cec68524e4cc096ae85ca62a346c1"
const API_URL = "https://api.deepseek.com/chat/completions"

func _ready():
	_load_config_data()
	if current_location != "未知地点" and current_location in player_story_context:
		max_rounds = 5
	else:
		max_rounds = 2

	http_request.request_completed.connect(_on_request_completed)
	next_button.pressed.connect(_on_next_button_pressed)
	
	if rich_text_label.has_signal("all_sentences_finished"):
		rich_text_label.all_sentences_finished.connect(_on_ai_speech_done)
	
	name_label.text = "meme"
	rich_text_label.text = "点击按钮，回忆在这片土地上的点滴..."
	next_button.visible = true

func _on_next_button_pressed():
	if is_ai_speaking: return
	
	if dialogue_count >= max_rounds:
		_final_transition()
		return
	
	_trigger_next_dialogue()

func _load_config_data():
	var config = ConfigFile.new()
	var err = config.load("user://game_settings.cfg")
	if err == OK:
		player_story_context = config.get_value("memory", "story", "")
	if player_story_context == "":
		player_story_context = "这里曾是我成长的地方。"

func _trigger_next_dialogue():
	dialogue_count += 1
	is_ai_speaking = true
	next_button.visible = false
	name_label.text = "正在思考..."
	send_deepseek_request()

func send_deepseek_request():
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY 
	]
	
	var core_prompt = "你扮演名为‘meme’的玩家。当前身处：‘" + current_location + "’。背景回忆：‘" + player_story_context + "’。任务：1. 情感判定：如果当前地点与背景回忆相关，你的情绪必须表现为 [happy]；如果不相关，则表现为 [upset]；在描述普通观察时使用 [normal]。2. 格式要求：每一段回复中必须使用‘两次’表情标签，仅限使用 [normal], [upset], [happy]。3. 内容：结合地点进行独白。相关则扩充回忆细节，不相关则表现出对该地的陌生或失落感。"
	
	var body_dict = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": core_prompt},
			{"role": "user", "content": "我看向四周，心中涌现出..."}
		],
		"stream": false
	}
	
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body_dict))

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json == null or not json.has("choices"): return
		
		var raw_text = json["choices"][0]["message"]["content"]
		var current_expression = "normal"
		var regex = RegEx.new()
		regex.compile("\\[(normal|upset|happy)\\]")
		var result = regex.search(raw_text)
		if result:
			current_expression = result.get_string(1)
		
		var display_text = regex.sub(raw_text, "", true).strip_edges()
		
		if dialogue_count >= max_rounds:
			display_text = "我有一计，要赶紧回去给姐姐一个惊喜！"
			current_expression = "happy"

		var character_mgr = get_node("../PanelsContainer")
		if character_mgr and character_mgr.has_method("change_character"):
			character_mgr.change_character("center", EXPRESSIONS[current_expression])
		
		name_label.text = "meme"
		if rich_text_label.has_method("play_text"):
			rich_text_label.play_text(display_text)
	else:
		rich_text_label.text = "连接失败。"
		is_ai_speaking = false
		next_button.visible = true

func _final_transition():
	get_tree().change_scene_to_file("res://scenes/hecheng.tscn")

func _on_ai_speech_done():
	is_ai_speaking = false
	next_button.visible = true
	if dialogue_count < max_rounds:
		name_label.text = "meme"
	else:
		name_label.text = "meme (点击继续)"
