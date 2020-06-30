extends "res://addons/scene_portal_2d/transitions/mechanics/transition_base.gd"

var fadeOutTime: float = 0.0
var fadeInTime: float = 0.0


func _ready():
	$Black.rect_size = Vector2(
		ProjectSettings.get_setting("display/window/size/width"),
		ProjectSettings.get_setting("display/window/size/height"))


func will_animate_leave() -> bool:
	return fadeOutTime > 0.0


func will_animate_enter() -> bool:
	return fadeInTime > 0.0


func _transition_leave(state):
	if fadeOutTime > 0.0:
		$AnimationPlayer.playback_speed = 1.0/float(fadeOutTime)
		$AnimationPlayer.play("fade")
		yield($AnimationPlayer, "animation_finished")
		._transition_leave(state)


func _transition_enter(state):
	if fadeInTime > 0.0:
		$AnimationPlayer.playback_speed = 1.0/float(fadeInTime)
		$AnimationPlayer.play_backwards("fade")
		yield($AnimationPlayer, "animation_finished")
		._transition_enter(state)

