extends "res://addons/scene_portal_2d/transition_control.gd"

var fadeout_time = 0
var fadein_time = 0

onready var black = $Black
onready var player = $AnimationPlayer


func _transition_leave(state):
	if fadeout_time > 0.0:
		player.playback_speed = 1.0/float(fadeout_time)
		player.play("fade")
		yield(player, "animation_finished")
		._transition_leave(state)


func _transition_enter(state):
	if fadein_time > 0.0:
		player.playback_speed = 1.0/float(fadein_time)
		player.play_backwards("fade")
		yield(player, "animation_finished")
		._transition_enter(state)
