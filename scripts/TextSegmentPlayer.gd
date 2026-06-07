extends RichTextLabel
signal all_sentences_finished

var sentence_queue = []
var is_playing = false

func play_text(full_content: String):
	_prepare_sentences(full_content)
	if not is_playing:
		_show_next_sentence()

func _prepare_sentences(full_content: String):
	var cleaned_text = full_content.replace("！", "。").replace("？", "。").replace("!", "。").replace("?", "。")
	var parts = cleaned_text.split("。")
	
	for p in parts:
		var trimmed = p.strip_edges()
		if trimmed != "":
			sentence_queue.append(trimmed + "。")

func _show_next_sentence():
	if sentence_queue.size() > 0:
		is_playing = true
		var current_text = sentence_queue.pop_front()
		_animate_text(current_text)
	else:
		is_playing = false
		all_sentences_finished.emit() # 播完了

# 内部逻辑：打字机动画
func _animate_text(final_text: String):
	self.text = final_text
	self.visible_ratio = 0
	
	var tween = create_tween()
	# 根据长度计算时间，至少1秒
	var duration = max(1.0, final_text.length() / 15.0)
	tween.tween_property(self, "visible_ratio", 1.0, duration)
	
	# 停顿一段时间后自动播放下一句
	tween.tween_interval(1.5) 
	tween.finished.connect(_show_next_sentence)
