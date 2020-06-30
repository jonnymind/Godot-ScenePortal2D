extends KinematicBody2D


const MAX_SPEED=64
const FRICTION=0.5

var frozen = false
var velocity = Vector2.ZERO

func _ready():
	SceneChanger.connect("started", self, "_on_scene_changing")
	SceneChanger.connect("completed", self, "_on_scene_changed")
	# The player will always be frozen, until unfrozen by the scene changer
	frozen = true

func _process(delta):
	if frozen: 
		return
	var dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	velocity = velocity.move_toward(dir * MAX_SPEED, MAX_SPEED/FRICTION*delta)
	
func _physics_process(delta):
	#if not SceneChanger.loading_scene:
	velocity = move_and_slide(velocity)

func _on_scene_changing(_scene):
	frozen = true
	velocity = Vector2.ZERO
	
func _on_scene_changed():
	frozen = false


# This function will be searched by the portal system
func set_portal_facing(dir):
	match dir:
		"Left":
			$Sprite.flip_h = false
		"Right":
			$Sprite.flip_h = true

