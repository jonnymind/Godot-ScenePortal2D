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
	- DESTINATION: a string representing the target scene resource.
	- PORTAL_TYPE: One of the following:
		- CHANGE: Just move to the next scene.
		- ENTER: Pushes the current scene so that the next portal of type EXIT  
				 will return to this scene.
		- EXIT: Ignores the DESTINATION and ID parameters, and restores
				the scene and position from where the last ENTER portal was 
				traversed. 
		- EXIT_TO: Ignores the DESTINATION parameter, but not the ID; restores
				the scenefrom where the last ENTER portal was 
				traversed, but will connect to the portal with the same ID. 
		- EXIT_ONLY: This portal can't be entered; they are only used to place 
				the player in this scene automatically.
	- FACING: The direction the player should face when landing on this portal.
				If the player object exposes a 'set_portal_facing' method, it
				will be called with this value.
	- AREA_MODE: If clicked, this scene is saved, and will be resumed when 
				 re-entered from another area portal. If not, the scene status 
				 will be discarded, and possibly re-instantiated on re-enter.
	- PORTAL_ID: moves the objects in the `Player` group to the portal having the
				 same ID in the target scene. If the ID is 0, this feature is
				 disabled (and the player appears at its own origin).
	- TRANSITION: Type of transition.
	- TRANSITION_TIME: Lenght of the transition in seconds. 
"""
enum PortalType {CHANGE, ENTER, EXIT, EXIT_TO, EXIT_ONLY}
enum TransitionType {NONE, FADER}
enum FacingType {NONE, LEFT, UP, RIGHT, DOWN}

export(String, FILE, "*.tscn") var DESTINATION
export(PortalType) var TYPE
export(bool) var AREA_MODE = true
export(int) var PORTAL_ID = 1
export(String, "None", "Left", "Up", "Right", "Down") var FACING = "None"
export(TransitionType) var TRANSITION
export(float) var TRANSITION_TIME = 1

onready var active = true

signal portal_entered(portal, body)
signal portal_exited(portal, body)

func _on_TransferPortal_body_entered(body):
	if SceneChanger.loading_scene:
		if FACING != "None" and body.has_method("set_portal_facing"):
			body.set_portal_facing(FACING)
			emit_signal("portal_exited", self, body)
		return

	if not active or TYPE == PortalType.EXIT_ONLY:
		return
	active = false
	
	emit_signal("portal_entered", self, body)
	
	var transition
	match TRANSITION:
		TransitionType.FADER:
			transition = SceneChanger.get_fader_transition()
			transition.fadein_time = TRANSITION_TIME/2.0
			transition.fadeout_time = TRANSITION_TIME/2.0

	match TYPE:
		PortalType.CHANGE:
			assert(DESTINATION != null)
			SceneChanger.change(DESTINATION, transition, PORTAL_ID, AREA_MODE)
		PortalType.ENTER:
			assert(DESTINATION != null)
			SceneChanger.push(DESTINATION, transition, PORTAL_ID, AREA_MODE, self)
		PortalType.EXIT:
			SceneChanger.pop(transition, 0, AREA_MODE)
		PortalType.EXIT_TO:
			SceneChanger.pop(transition, PORTAL_ID, AREA_MODE)
		
func _on_TransferPortal_body_exited(_body):
	if not SceneChanger.loading_scene:
		active = true
