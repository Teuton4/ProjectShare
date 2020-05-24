extends KinematicBody2D

#export var shell_velocity = 1
export var shell_velocity = .1
var from_player

var direction_vector = Vector2()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_motion_vector():
	direction_vector = Vector2(cos(rotation) * shell_velocity, sin(rotation) * shell_velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var collision = move_and_collide(direction_vector)
	if collision:
		#print(collision.normal)
		var new_direction_vector = direction_vector.bounce(collision.normal)
		#print((new_direction_vector * direction_vector))
		#print((new_direction_vector.length() * direction_vector.length()))
		if acos((new_direction_vector.x * direction_vector.x + new_direction_vector.y * direction_vector.y) / (new_direction_vector.length() * direction_vector.length())) > (PI/2):
			queue_free()
		direction_vector = new_direction_vector
		rotation = direction_vector.angle()
	move_and_slide(direction_vector)
	pass


