extends Control

@onready var character_mgr = $PanelsContainer
@onready var rich_text_label = $DialogueSystem/TextLabel/RichTextLabel 
@onready var name_label = $DialogueSystem/DialogueCharacter/NameLabel
@onready var http_request = $DialogueSystem/HTTPRequest
@onready var background = $Background
@onready var next_button = $DialogueSystem/DialogueControl/VBoxContainer/TextureButton

var dialogue_queue: Array = []
var target_scene_path: String = ""
var player_story_context: String = ""
var is_waiting_for_input: bool = false

const EXPRESSIONS = {
	"happy": preload("res://assets/UI/emoij/happy.png"),
	"angry": preload("res://assets/UI/emoij/angry.png")
}

const API_KEY = "sk-492cec68524e4cc096ae85ca62a346c1"
const API_URL = "https://api.deepseek.com/chat/completions"

func _ready():
	_load_story_data()
	http_request.request_completed.connect(_on_request_completed)
	next_button.pressed.connect(_on_next_button_pressed)
	
	if Golbal.generated_gift_description != "":
		start_auto_gift_check(Golbal.generated_gift_description)
	else:
		rich_text_label.text = "你带着礼物回来了..."

func _load_story_data():
	var config = ConfigFile.new()
	var err = config.load("user://game_settings.cfg")
	if err == OK:
		player_story_context = config.get_value("memory", "story", "我们小时候一起玩耍的回忆。")

func start_auto_gift_check(gift_text: String):
	name_label.text = "婷婷"
	rich_text_label.text = "（你递出了准备好的生日礼物...）"
	
	var prompt = "判定礼物介绍是否与童年往事相关。\n童年背景：'" + player_story_context + "'\n礼物介绍文本：'" + gift_text + "'\n规则：如果这段描述能唤起背景中的回忆，回复'TRUE'，否则回复'FALSE'。只回复单词。"

	var body = {
		"model": "deepseek-chat",
		"messages": [{"role": "system", "content": prompt}],
		"stream": false
	}
	
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + API_KEY]
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var ai_decision = json["choices"][0]["message"]["content"].strip_edges().to_upper()
		
		if "TRUE" in ai_decision:
			setup_dialogue_sequence("happy", [
				"这...这上面写的感觉...",
				"这就是我们当年的约定！",
				"谢谢你，我好开心！"
			], "res://scenes/he.tscn")
		else:
			setup_dialogue_sequence("angry", [
				"这都是些什么不知所云的东西？",
				"你根本就不记得我们的过去！",
				"别再来找我了。"
			], "res://scenes/be.tscn")
	else:
		rich_text_label.text = "（婷婷看着礼物沉默不语...）"

func setup_dialogue_sequence(emo: String, lines: Array, next_scene: String):
	dialogue_queue = lines
	target_scene_path = next_scene
	
	if character_mgr and character_mgr.has_method("change_character"):
		character_mgr.change_character("center", EXPRESSIONS[emo])
	
	show_next_line()

func show_next_line():
	if dialogue_queue.size() > 0:
		var current_line = dialogue_queue.pop_front()
		is_waiting_for_input = true
		
		if rich_text_label.has_method("play_text"):
			rich_text_label.play_text(current_line)
		else:
			rich_text_label.text = current_line
	else:
		if target_scene_path != "":
			get_tree().change_scene_to_file(target_scene_path)

func _on_next_button_pressed():
	if is_waiting_for_input:
		show_next_line()
