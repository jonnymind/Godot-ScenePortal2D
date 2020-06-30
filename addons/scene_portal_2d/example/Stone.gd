extends Area2D

func _on_Stone_body_entered(_body):
	queue_free()
