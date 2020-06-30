extends Control

class_name TransitionControl

signal transitioning_out(from_scene, to_scene)
"Generated at the beginning of the out-transition"
signal transitioned_out(from_scene, to_scene)
"Generated at the end of the out-transition"
signal transitioning_in(from_scene, to_scene)
"Generated at the beginning of the in-transition"
signal transitioned_in(from_scene, to_scene)
"Generated at the end of the in-transition"


func leave(state) -> void:
	emit_signal("transitioning_out", state)
	_transition_leave(state)
	


func enter(state)  -> void:
	emit_signal("transitioning_in", state)
	_transition_enter(state)


func will_animate_leave() -> bool:
	return false

func will_animate_enter() -> bool:
	return false

func _transition_leave(state):
	"To be overloaded (and called at the end) by specific transition controls"
	emit_signal("transitioned_out", state)


func _transition_enter(state):
	"To be overloaded (and called at the end) by specific transition controls"
	emit_signal("transitioned_in", state)
