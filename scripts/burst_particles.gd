extends CPUParticles2D
## 粒子爆发效果：点击时在指定位置播放

func _ready() -> void:
	emitting = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 2.0
	amount = 30
	one_shot = true
	explosiveness = 1.0
	lifetime = 0.5
	spread = 180.0
	direction = Vector2(0, -1)
	set_param_min(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 80.0)
	set_param_max(CPUParticles2D.PARAM_INITIAL_LINEAR_VELOCITY, 150.0)
	set_param_min(CPUParticles2D.PARAM_SCALE, 0.2)
	set_param_max(CPUParticles2D.PARAM_SCALE, 0.6)
	scale_amount_min = 0.3
	scale_amount_max = 0.8
	color = Color(1.0, 0.95, 0.7, 1.0)


func play_at(pos: Vector2) -> void:
	global_position = pos
	restart()
	emitting = true
	# 播放完毕后自动销毁
	finished.connect(_on_finished, CONNECT_ONE_SHOT)


func _on_finished() -> void:
	queue_free()
