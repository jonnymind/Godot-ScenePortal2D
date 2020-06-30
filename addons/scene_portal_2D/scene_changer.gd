extends Node

signal scene_changing(target_scene)
signal scene_changed
signal scene_transitioning

var _scene_stack = []
var _scene_db = {}

var loading_scene = null
var _target_position = null

func get_fader_transition():
	return $FadeInControl

#################################################
# Public interface
#################################################
	
func change(path, transition=null, target_portal=-1, keep_current=false):
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

func push(path, transition=null, target_portal=-1, keep_current=false, source_portal=null):
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

func pop(transition=null, target_portal=-1, keep_current=false):
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
	

func clear_area():
	"Remove all the scenes saved by the other functions."
	for scene in _scene_db:
		scene.queue_free()
	_scene_db.clear()

#########################################################
# Private
#########################################################
func _change_instance(instance, transition=null, target_portal=-1, keep_current=false):
	if keep_current:
		var current = get_tree().current_scene
		var node_name = current.filename
		if node_name == null:
			node_name = current.name
		_scene_db[node_name] = current
	call_deferred("_load_next_scene", get_tree(), instance, transition, target_portal, keep_current)

func _get_resource(path):
	if _scene_db.has(path):
		return _scene_db[path]
	var resource = load(path)
	assert(resource != null)
	return resource.instance()

func _load_next_scene(tree, scene, transition, target_portal, keep_current):
	loading_scene = scene
	emit_signal("scene_changing", scene)
	var current = tree.current_scene
	if transition != null:
		transition.leave(current, scene)
		yield(transition, "on_leave_complete")

	# The workhorse of the scene changer
	_replace_scene(tree, scene)
	_move_player(target_portal)
	emit_signal("scene_transitioning")
	
	if transition != null:
		transition.enter(current, scene)
		yield(transition, "on_enter_complete")
		
	if not keep_current:
		current.queue_free()

	emit_signal("scene_changed")
	loading_scene = null
	
func _replace_scene(tree, scene):
	# Save the tree, as get_tree() will be lost once we remove ourselves
	var current = tree.current_scene
	tree.root.remove_child(current)
	tree.root.add_child(scene)
	# Need to update the current scene
	tree.current_scene = scene
	
	
func _move_player(portal_id):
	if portal_id < 0 or (portal_id == 0 and _target_position == null):
		return
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.empty():
		return

	var portal_pos 
	if portal_id == 0:
		portal_pos = _target_position
		_target_position = null
	else:
		var portals = get_tree().get_nodes_in_group("Portal")
	
		for portal in portals:
			if portal.PORTAL_ID == portal_id:
				portal_pos = portal.global_position
				break
		if not portal_pos:
			return
	for player in players:
		player.global_position = portal_pos
