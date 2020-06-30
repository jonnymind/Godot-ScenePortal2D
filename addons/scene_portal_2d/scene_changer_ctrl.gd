extends Node2D

export(String, FILE, "*.tscn") var nextScene
export(float) var fadeOut = 0.0
export(float) var fadeIn = 0.0


func change() -> void:
	assert(nextScene != null)
	var fader = SceneChanger.get_fader_transition()
	fader.fadein_time = fadeIn
	fader.fadeout_time = fadeOut
	SceneChanger.change(nextScene, fader)
	yield(SceneChanger, "completed")
