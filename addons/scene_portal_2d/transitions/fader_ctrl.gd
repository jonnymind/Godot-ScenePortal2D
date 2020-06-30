extends Node

export(float) var fadeInTime = 0.5
export(float) var fadeOutTime = 0.5

func get_transition() -> Node:
	var scene = load("res://addons/scene_portal_2d/transitions/mechanics/fader.tscn").instance()
	scene.fadeInTime = fadeInTime
	scene.fadeOutTime = fadeOutTime
	return scene
