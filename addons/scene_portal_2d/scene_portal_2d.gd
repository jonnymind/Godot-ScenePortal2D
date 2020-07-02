extends Area2D
"""
Portal system entry-exit.

Loads a target scene when a body enters the Collision Shape. Optionally, it can
save the status of the current scene, and optionally it can move the player 
object (any object in group 'Player') to a correspondent portal in the target 
scene. A rudimentary transition is also provided.

The global object SceneChanger is used as the internal backend for the portal 
system. SceneChanger can be used by other objects, or directly from the scripts,
to invoke scene change programmatically.

Scripts variables:
	- destination: a string representing the target scene resource. If left unset.
			this will be a intra-scene portal, moving the player to 
			another area in the same scene.
	- transition: Node path to a transition contol object.
	- use_default_transition: if true, use the default transition in the AutoLoad
			SceneController.
	- type: One of the following:
		- CHANGE: Just move to the next scene.
		- ENTER: Pushes the current scene so that the next portal of type EXIT  
			 will return to this scene.
		- EXIT: Ignores the destination and ID parameters, and restores
			the scene and position from where the last ENTER portal was 
			traversed. 
		- EXIT_TO: Ignores the destination parameter, but not the ID; restores
			the scenefrom where the last ENTER portal was 
			traversed, but will connect to the portal with the same ID. 
		- EXIT_ONLY: This portal can't be entered; they are only used to place 
			the player in this scene automatically.
	- facing: The direction the player should face when landing on this portal.
			If the player object exposes a 'set_portal_facing' method, it
			will be called with this value.
	- area_mode: If clicked, this scene is saved, and will be resumed when 
			re-entered from another area portal. If not, the scene status 
			will be discarded, and possibly re-instantiated on re-enter.
	- portal_id: Unique identifier of this portal in this scene
	- target: the player object will be moved to the portal having this ID in the
			target scene. If zero, the player object will not be moved, and will
			appear in its origin (or previous) position.
	- teleport: if true, will move the player object instance to the target 
			scene. The player will be attached to a node in the group 
			PlayerHook. Exactly one player hooks must be present in scenes
			target of teleports. This setting is ignored for intra-scene portals.
"""
signal portal_entered(portal, body)
signal portal_exited(portal, body)

enum PortalType {CHANGE, ENTER, EXIT, EXIT_TO, EXIT_ONLY}
enum FacingType {NONE, LEFT, UP, RIGHT, DOWN}

export(String, FILE, "*.tscn") var destination
export(NodePath) var transition
export(bool) var use_default_transition
export(PortalType) var type
export(bool) var area_mode = true
export(int) var portal_id = 1
export(int) var target = 1
export(bool) var teleport = false
export(String, "None", "Left", "Up", "Right", "Down") var facing = "None"

var _active = true
var _exiting = null

func exiting(body) -> void:
	_exiting = body
	_active = false


func _on_ScenePortal_body_entered(body):
	if type == PortalType.EXIT_ONLY or not _active:
		return
	
	if destination:
		_active = false
	
	var trans_inst
	if use_default_transition:
		trans_inst = SceneChanger.get_default_transition()
	elif transition != "":
		trans_inst = get_node(transition).get_transition() 
	
	var player
	if teleport:
		player = body
	emit_signal("portal_entered", self, body)
	match type:
		PortalType.CHANGE:
			SceneChanger.change(destination, trans_inst, target, area_mode, player)
		PortalType.ENTER:
			SceneChanger.push(destination, portal_id, trans_inst, target, area_mode, player)
		PortalType.EXIT:
			SceneChanger.pop(trans_inst, 0, area_mode, player)
		PortalType.EXIT_TO:
			SceneChanger.pop(trans_inst, target, area_mode, player)


func _on_ScenePortal_body_exited(body):
	if _exiting == body:
		_active = true
		_exiting = null
		emit_signal("portal_exited")

