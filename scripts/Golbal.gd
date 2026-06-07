extends Node
var selected_location_name: String = "" 
var selected_bg_path : String = ""
var generated_gift_description = ""
var generated_chat: String =""
var material_prompts: Array[String] = []
var modifier_prompts: Array[String] = []
var item_category_prompts: Array[String] = []

## 测试页面流程控制："" | "part2" | "cg"
var test_page_phase: String = ""

## 关卡选择页面传递给 run_page 的待播放时间线名（非空时优先于场景内导出值）
var pending_timeline: String = ""

## 已解锁的 CG 键列表（对应 run_page.gd 的 CG_MAP 键）
var unlocked_cgs: Array[String] = []

const _SAVE_PATH := "user://unlocked_cgs.dat"


func _ready() -> void:
	_load_unlocked_cgs()


## 解锁指定 CG；若已解锁则忽略
func unlock_cg(key: String) -> void:
	if key in unlocked_cgs:
		return
	unlocked_cgs.append(key)
	_save_unlocked_cgs()


func _save_unlocked_cgs() -> void:
	var f := FileAccess.open(_SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(unlocked_cgs)


func _load_unlocked_cgs() -> void:
	if not FileAccess.file_exists(_SAVE_PATH):
		return
	var f := FileAccess.open(_SAVE_PATH, FileAccess.READ)
	if f:
		var data = f.get_var()
		if data is Array:
			unlocked_cgs = data
