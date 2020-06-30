extends Node2D

var changed = false

func _process(delta):
	if not changed and Input.is_key_pressed(KEY_SPACE):
		changed = true
		$SceneChangerCtrl.change()
