extends Node

signal started(new_scene)
"When scene change is started, before starting transition"
signal old_scene_transitioned
"After transition out is completed"
signal new_scene_loaded(scene)
"When the new scene is loaded, before transitioning in starts"
signal completed
"After scene change is complete"

var _scene_stack = []
var _scene_db = {}
var _target_position = null
var _loading = false

#################################################
# Public interface
#################################################
	
func change(path, transition=null, target_portal=-1, keep_current=false) -> void:
	"""
		Move the scene to the target resource.
		`transition`: A transition object exposing `enter(source, target)` and 
					  `leave(source_target)`.
		`target_portal`: if > 0, will move all the objects in `Player` group
						 to the first portal with that ID found in the target
						 scene
		`keep_current`: if true, the current scene will be saved, and its state
						will be restored when changed back.
	"""
	_change_instance(_get_resource(path), transition, target_portal, keep_current)


func push(path, transition=null, target_portal=-1, keep_current=false, source_portal=null) -> void:
	"""
		Move the scene to the target resource, recording the previous scene.
		`transition`: A transition object exposing `enter(source, target)` and 
					  `leave(source_target)`.
		`target_portal`: if > 0, will move all the objects in `Player` group
						 to the first portal with that ID found in the target
						 scene
		`keep_current`: if true, the current scene will be saved, and its state
						will be restored when changed back.
		If keep_current is not true, when pop() is invoked the current scene 
		status will *not* be restored, but reloaded and re-instantiated. 
		
		Calls to `push()` and `pop()` can be interleaved with `change()`,
		but if a scene is saved by either of them (using keep_current=true), 
		it will be restored when referenced by any other function.
	"""
	var current = get_tree().current_scene
	var position
	if source_portal:
		position = source_portal.global_position
	_scene_stack.append([current.filename, position])
	_change_instance(_get_resource(path), transition, target_portal, keep_current)


func pop(transition=null, target_portal=-1, keep_current=false) -> void:
	"""
		Move the scene to the last previously pushed one.
		`transition`: A transition object exposing `enter(source, target)` and 
					  `leave(source_target)`.
		`target_portal`: if > 0, will move all the objects in `Player` group
						 to the first portal with that ID found in the target
						 scene
		`keep_current`: if true, the current scene will be saved, and its state
						will be restored when changed back. 
	"""
	var target = _scene_stack.pop_back()
	assert(target != null)
	_target_position = target[1]
	change(target[0], transition, target_portal, keep_current)


func clear_area() -> void:
	"Remove all the scenes saved by the other functions."
	for scene in _scene_db:
		scene.queue_free()
	_scene_db.clear()


func get_default_transition() -> Node:
	"""
	Returns the default transion for the game.
	To set up a default transition, add a link to your favorite transition
	control (`transitions/*_ctrl.tscn`) as a child of this node, and rename
	it `DefaultTransition`.
	"""
	var ctrl = get_node("/root/SceneChanger/DefaultTransition")
	if ctrl != null:
		return ctrl.get_transition()
	return null

func is_loading() -> bool:
	"Safe way to know if the scene loader is currently loading"
	return _loading
	
#########################################################
# Private
#########################################################

func _change_instance(instance, transition=null, target_portal=-1, keep_current=false) -> void:
	if keep_current:
		var current = get_tree().current_scene
		var node_name = current.filename
		if node_name == null:
			node_name = current.name
		_scene_db[node_name] = current
	var transition_status = {
		"tree": get_tree(),
		"scene": instance,
		"transition": transition,
		"portal": target_portal,
		"keep": keep_current
	}
	call_deferred("_load_next_scene", transition_status)


func _get_resource(path) -> Node:
	if _scene_db.has(path):
		return _scene_db[path]
	var resource = load(path)
	assert(resource != null)
	return resource.instance()


func _load_next_scene(status) ->void:
	_loading = true
	status.current = status.tree.current_scene
	emit_signal("started", status.scene)
	if status.transition != null and status.transition.will_animate_leave():
		add_child(status.transition)
		status.transition.leave(status)
		yield(status.transition, "transitioned_out")
	emit_signal("old_scene_transitioned")
	
	# The workhorse of the scene changer
	_replace_scene(status.tree, status.scene)
	_move_player(status.portal)
	emit_signal("new_scene_loaded")
	
	if status.transition != null and status.transition.will_animate_enter():
		status.transition.enter(status)
		yield(status.transition, "transitioned_in")

	if not status.keep:
		status.current.queue_free()
	_loading = false
	if status.transition:
		remove_child(status.transition)
		status.transition.queue_free()
	emit_signal("completed")


func _replace_scene(tree, scene) -> void:
	# Save the tree, as get_tree() will be lost once we remove ourselves
	var current = tree.current_scene
	tree.root.remove_child(current)
	tree.root.add_child(scene)
	# Need to update the current scene
	tree.current_scene = scene


func _move_player(portal_id) -> void:
	if portal_id < 0 or (portal_id == 0 and _target_position == null):
		return

	var players = get_tree().get_nodes_in_group("Player")
	if players.empty():
		return

	var portal_pos
	var portal_facing = "None"
	if portal_id == 0:
		portal_pos = _target_position
		_target_position = null
	else:
		var portals = get_tree().get_nodes_in_group("Portal")	
		for portal in portals:
			if portal.portalId == portal_id:
				portal_pos = portal.global_position
				portal_facing = portal.facing
				break
		if not portal_pos:
			return
	
	for player in players:
		player.global_position = portal_pos
		if portal_facing != "None" and player.has_method("set_portal_facing"):
			player.set_portal_facing(portal_facing)
