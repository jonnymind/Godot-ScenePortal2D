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
	- destination: a string representing the target scene resource.
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
	- areaMode: If clicked, this scene is saved, and will be resumed when 
				 re-entered from another area portal. If not, the scene status 
				 will be discarded, and possibly re-instantiated on re-enter.
	- portalId: moves the objects in the `Player` group to the portal having the
				 same ID in the target scene. If the ID is 0, this feature is
				 disabled (and the player appears at its own origin).
	- transition: Type of transition.
	- transitionTime: Lenght of the transition in seconds. 
"""
signal portal_entered(portal, body)
signal portal_exited(portal, body)

enum PortalType {CHANGE, ENTER, EXIT, EXIT_TO, EXIT_ONLY}
enum FacingType {NONE, LEFT, UP, RIGHT, DOWN}

export(String, FILE, "*.tscn") var destination
export(NodePath) var transition
export(bool) var useDefaultTransition
export(PortalType) var type
export(bool) var areaMode = true
export(int) var portalId = 1
export(String, "None", "Left", "Up", "Right", "Down") var facing = "None"

var _active = true

func _on_ScenePortal_body_entered(body):
	if SceneChanger.is_loading():
		_active = false
		return
	
	if type == PortalType.EXIT_ONLY or not _active:
		return
	
	_active = false
	var trInstance
	if useDefaultTransition:
		trInstance = SceneChanger.get_default_transition()
	elif transition != "":
		trInstance = get_node(transition).get_transition()

	emit_signal("portal_entered", self, body)
	match type:
		PortalType.CHANGE:
			assert(destination != null)
			SceneChanger.change(destination, trInstance, portalId, areaMode)
		PortalType.ENTER:
			assert(destination != null)
			SceneChanger.push(destination, trInstance, portalId, areaMode, self)
		PortalType.EXIT:
			SceneChanger.pop(trInstance, 0, areaMode)
		PortalType.EXIT_TO:
			SceneChanger.pop(trInstance, portalId, areaMode)


func _on_ScenePortal_body_exited(body):
	if not SceneChanger.is_loading():
		_active = true
		emit_signal("portal_exited")
