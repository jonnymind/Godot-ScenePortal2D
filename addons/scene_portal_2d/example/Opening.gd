extends Node2D

func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		$SceneChangerCtrl.change()
