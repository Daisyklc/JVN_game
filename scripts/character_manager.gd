extends Control

@onready var slots = {
	"left": $CharacterPanel1,
	"right": $CharacterPanel2,
	"center": $CharacterPanelSignel
}

func change_character(pos_key: String, texture: Texture2D):
	if slots.has(pos_key):
		var target = slots[pos_key]
		if texture == null:
			target.hide()
			return
			
		target.texture = texture
		target.show()
		
		target.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(target, "modulate:a", 1.0, 0.3)

func hide_all():
	for s in slots.values():
		s.hide()
