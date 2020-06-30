extends Control

onready var black = $Black
onready var player = $AnimationPlayer

signal on_leave_complete
signal on_enter_complete

var fadeout_time = 0
var fadein_time = 0

func leave(_from_scene, _to_scene):
	if fadeout_time > 0.0:
		player.playback_speed = 1.0/float(fadeout_time)
		player.play("fade")
		yield(player, "animation_finished")
		emit_signal("on_leave_complete")
	
func enter(_from_scene, _to_scene):
	if fadein_time > 0.0:
		player.playback_speed = 1.0/float(fadein_time)
		player.play_backwards("fade")
		yield(player, "animation_finished")
		emit_signal("on_enter_complete")
