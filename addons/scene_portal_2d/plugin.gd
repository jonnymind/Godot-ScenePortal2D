tool
extends EditorPlugin

func _enter_tree():
	add_custom_type ( 
		"ScenePortal2D", 
		"Node2D", 
		preload("res://addons/scene_portal_2d/scene_portal_2d.gd"), 
		preload("res://addons/scene_portal_2d/scene_portal_2d.png")
	)

func _exit_tree():
	 remove_custom_type("ScenePortal2D")
