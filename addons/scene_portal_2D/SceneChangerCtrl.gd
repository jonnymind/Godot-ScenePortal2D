extends Node2D

export(String, FILE, "*.tscn") var NEXT_SCENE
export(float) var FADE_OUT = 0.0
export(float) var FADE_IN = 0.0

func change():
	assert(NEXT_SCENE != null)
	var fader = SceneChanger.get_fader_transition()
	fader.fadein_time = FADE_IN
	fader.fadeout_time = FADE_OUT
	SceneChanger.change(NEXT_SCENE, fader)
