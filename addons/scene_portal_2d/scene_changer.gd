extends Node

signal started(new_scene)
"When scene change is started, before starting transition"
signal old_scene_transitioned
"After transition out is completed"
signal new_scene_loaded(scene)
"When the new scene is loaded, before transitioning in starts"
signal completed
"After scene change is complete"

export(String) var group_to_move = "Player"
"When changing scene all the objects in this group will be moved to the target portal."
export(String) var group_to_hook = "PlayerHook"
"An group containing an empty node where the player will be connected when traversing `teleport` portals."

var _scene_stack = []
var _scene_db = {}

#################################################
# Public interface
#################################################
	
func change(path, transition=null, target_portal=-1, keep_current=false, player=null) -> void:
	"""
		Move the scene to the target resource.
		`path`: the res:// path to the scene to load, or null for same scene.
		`transition`: A transition object exposing `enter(source, target)` and 
					  `leave(source_target)`.
		`target_portal`: if > 0, will move all the objects in `Player` group
						 to the first portal with that ID found in the target
						 scene
		`keep_current`: if true, the current scene will be saved, and its state
						will be restored when changed back.
	"""
	var status = _make_status(
			_get_resource(path), 
			transition, 
			target_portal, 
			keep_current,
			player)
	_change_instance(status)
	


func push(path, source_portal, transition=null, target_portal=-1, keep_current=false, player=null) -> void:
	"""
		Move the scene to the target resource, recording the previous scene.
		`path`: the res:// path to the scene to load, or null for same scene.
		`transition`: A transition object exposing `enter(source, target)` and 
					  `leave(source_target)`.
		`target_portal_id`: if > 0, will move all the objects in `Player` group
						 to the first portal with that ID found in the target
						 scene
		`keep_current`: if true, the current scene will be saved, and its state
						will be restored when changed back.
		`source_portal_id`: the ID of the source portal
		If keep_current is not true, when pop() is invoked the current scene 
		status will *not* be restored, but reloaded and re-instantiated. 
		Calls to `push()` and `pop()` can be interleaved with `change()`,
		but if a scene is saved by either of them (using keep_current=true), 
		it will be restored when referenced by any other function.
	"""
	var current
	# Handle local enters
	if path:
		current = get_tree().current_scene.filename
	_scene_stack.append([current, source_portal])
	_change_instance(_make_status(
			_get_resource(path), 
			transition, 
			target_portal, 
			keep_current, 
			player))


func pop(transition=null, target_portal=-1, keep_current=false, player=null) -> void:
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
	if target_portal <= 0:
		target_portal = target[1]
	_change_instance(_make_status(
			_get_resource(target[0]), 
			transition, 
			target_portal, 
			keep_current,
			player))


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


#########################################################
# Private
#########################################################

func _change_instance(status) -> void:
	if status.keep:
		var current = get_tree().current_scene
		var node_name = current.filename
		if node_name == null:
			node_name = current.name
		_scene_db[node_name] = current
	call_deferred("_load_next_scene", status)


func _make_status(instance, transition, target_portal, keep_current, player):
	# force non-teleport mode if this is an intra-scene portal
	if not instance:
		player = null
	var transition_status = {
		"scene": instance,
		"transition": transition,
		"portal": target_portal,
		"keep": keep_current,
		"teleported_player": player
	}
	return transition_status


func _get_resource(path) -> Node:
	if not path:
		return null
	if _scene_db.has(path):
		return _scene_db[path]
	var resource = load(path)
	assert(resource != null)
	return resource.instance()


func _load_next_scene(status) ->void:
	status.current = get_tree().current_scene
	var player = status.teleported_player
	var saved_layer
	if player:
		# A teleported player has pending physics from the old scene,
		# we need to make it untouchable and let the phisics loop to complete.
		saved_layer = player.collision_layer
		player.collision_layer = 0
		
	emit_signal("started", status.scene)
	if status.transition != null and status.transition.will_animate_leave():
		add_child(status.transition)
		status.transition.leave(status)
		yield(status.transition, "transitioned_out")
	emit_signal("old_scene_transitioned")
	
	# The workhorse of the scene changer
	if status.scene:
		_replace_scene(status)
	if status.teleported_player:
		_hook_player_in_scene(status)
	else:
		_move_player(status)
	emit_signal("new_scene_loaded")
	
	if status.transition != null and status.transition.will_animate_enter():
		status.transition.enter(status)
		yield(status.transition, "transitioned_in")
	elif player:
		# We need to give the physics the chance to recalculate in the new scene,
		# hence we yield, but want to be called back immediately
		yield(get_tree().create_timer(0.0001), "timeout")

	if not status.keep:
		status.current.queue_free()
	if status.transition:
		remove_child(status.transition)
		status.transition.queue_free()
	if player:
		player.collision_layer = saved_layer
	emit_signal("completed")


func _replace_scene(status) -> void:
	# Save the tree, as get_tree() will be lost once we remove ourselves
	var scene = status.scene
	var tree = get_tree()
	var current = tree.current_scene
	# Eventually remove the player
	if status.teleported_player:
		status.teleported_player.get_parent().remove_child(status.teleported_player)
	tree.root.remove_child(current)
	tree.root.add_child(scene)
	# Need to update the current scene
	tree.current_scene = scene


func _move_player(status) -> void:
	var portal_id = status.portal
	if portal_id < 0:
		return

	var players = get_tree().get_nodes_in_group(group_to_move)
	if players.empty():
		return

	var target_portal = _find_portal_in_scene(portal_id)
	if target_portal:
		for player in players:
			_move_player_to_portal(player, target_portal)
		

func _find_portal_in_scene(portal_id):
	if portal_id > 0:
		var portals = get_tree().get_nodes_in_group("Portal")	
		for portal in portals:
			if portal.portal_id == portal_id:
				return portal
	return null


func _move_player_to_portal(body, portal):
	portal.exiting(body)
	body.global_position = portal.global_position
	if portal.facing != "None" and body.has_method("set_portal_facing"):
		body.set_portal_facing(portal.facing)

func _hook_player_in_scene(status):
	var portal = _find_portal_in_scene(status.portal)
	var player = status.teleported_player
	var hooks = get_tree().get_nodes_in_group(group_to_hook)
	if hooks.size() != 1:
		print("Need to have exactly one hook object in the target scene of a teleport in ", get_tree().current_scene.filename)
		assert(false)
		return
	if portal:
		portal.exiting(player)
		player.global_position = portal.global_position
	else:
		player.global_position = hooks[0].global_position
	hooks[0].add_child(player)
