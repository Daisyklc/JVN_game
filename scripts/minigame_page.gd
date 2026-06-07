extends Control
## 光点小游戏：从屏幕底部涌现光点，点击产生粒子爆发，计时20秒

const GAME_DURATION: float = 20.0
const SPAWN_INTERVAL: float = 0.6
const LIGHT_POINT_SCENE: PackedScene = preload("res://scenes/light_point.tscn")
const BURST_SCENE: PackedScene = preload("res://scenes/burst_particles.tscn")

@onready var points_container: Control = $PointsContainer
@onready var particles_holder: Node2D = $ParticlesHolder
@onready var timer_label: Label = $TimerLabel
@onready var spawn_timer: Timer = $SpawnTimer

var game_timer: float = 0.0
var is_game_active: bool = true

func _ready() -> void:
	game_timer = GAME_DURATION
	_update_timer_label()
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_tick)
	spawn_timer.start()
	# 立即生成第一批
	_spawn_light_points()


func _process(delta: float) -> void:
	if not is_game_active:
		return
	game_timer -= delta
	_update_timer_label()
	# 光点缓慢向上飘动
	_drift_light_points(delta)
	if game_timer <= 0:
		_end_game()


func _drift_light_points(delta: float) -> void:
	if not points_container:
		return
	var speed := 35.0
	for child in points_container.get_children():
		if child is Control:
			child.position.y -= speed * delta


func _update_timer_label() -> void:
	if timer_label:
		timer_label.text = "剩余: %d 秒" % max(0, int(ceil(game_timer)))


func _on_spawn_tick() -> void:
	if is_game_active:
		_spawn_light_points()


func _spawn_light_points() -> void:
	if not points_container or not LIGHT_POINT_SCENE:
		return
	var view_size := get_viewport_rect().size
	# 在底部 1/4 区域内随机生成 1-3 个光点
	var count := randi_range(1, 3)
	for i in count:
		var pt: Control = LIGHT_POINT_SCENE.instantiate()
		pt.burst.connect(_on_light_point_burst.bind(pt))
		points_container.add_child(pt)
		# 随机 x，y 在底部区域
		var margin_x := 40
		var pt_size := pt.custom_minimum_size
		pt.position.x = randf_range(margin_x, view_size.x - margin_x - pt_size.x)
		pt.position.y = randf_range(view_size.y * 0.7, view_size.y - 30)


func _on_light_point_burst(light_point: Control) -> void:
	# 在光点位置产生粒子爆发
	var s := light_point.size
	if s == Vector2.ZERO:
		s = light_point.custom_minimum_size
	var burst_pos: Vector2 = light_point.global_position + s / 2
	if particles_holder and BURST_SCENE:
		var burst: CPUParticles2D = BURST_SCENE.instantiate()
		particles_holder.add_child(burst)
		burst.play_at(burst_pos)
	light_point.queue_free()


func _end_game() -> void:
	is_game_active = false
	spawn_timer.stop()
	if timer_label:
		timer_label.text = "时间到！"
	# 0.5 秒后返回测试页面
	await get_tree().create_timer(0.8).timeout
	Golbal.test_page_phase = "part2"
	get_tree().change_scene_to_file("res://scenes/test_page.tscn")
