extends TextureButton

func _ready() -> void:
	pressed.connect(func(): get_tree().quit())
