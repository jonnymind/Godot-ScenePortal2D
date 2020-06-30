extends Node

export(String, FILE, "*.tscn") var nextScene
export(NodePath) var transitionControl
export(bool) var useDefaultTransition

func change() -> void:
	assert(nextScene != null)
	var transition = null
	if useDefaultTransition:
		transition = SceneChanger.get_default_transition()
	elif transitionControl != "":
		transition = get_node(transitionControl).get_transition()
	SceneChanger.change(nextScene, transition)
	yield(SceneChanger, "completed")
