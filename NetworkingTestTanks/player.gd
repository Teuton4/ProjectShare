extends KinematicBody2D

const MOTION_SPEED = 90.0
const TURRET_SPEED = .8
const MAX_TURRET_ROTATION_SPEED = .55
const TANK_ROTATION_SPEED = .5

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_turret_rotation = 0
puppet var puppet_rotation = 0

export var stunned = false


# Use sync because it will be called everywhere
sync func setup_bomb(bomb_name, pos, by_who):
	var bomb = preload("res://bomb.tscn").instance()
	bomb.set_name(bomb_name) # Ensure unique name for the bomb
	bomb.position = pos
	bomb.from_player = by_who
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(bomb)

# Use sync because it will be called everywhere
sync func launch_shell(shell_name, pos, rot, by_who):
	var shell = preload("res://Shell.tscn").instance()
	shell.set_name(shell_name) # Ensure unique name for the bomb
	shell.position = pos
	shell.rotation = rot
	shell.from_player = by_who
	shell.set_motion_vector()
	# No need to set network master to bomb, will be owned by server by default
	get_node("../..").add_child(shell)

var current_anim = ""
var prev_bombing = false
var bomb_index = 0
var shell_index = 0

func _physics_process(_delta):
	var motion = Vector2()

	if is_network_master():
		
		if Input.is_action_pressed("move_up"):
			motion += Vector2(1, 0).rotated(rotation)
		if Input.is_action_pressed("move_down"):
			motion += Vector2(-1, 0).rotated(rotation)
		if Input.is_action_pressed("move_left"):
			if Input.is_action_pressed("move_down"):
				rotation = rotation + (TANK_ROTATION_SPEED * _delta)
			else:
				rotation = rotation - (TANK_ROTATION_SPEED * _delta)
			#get_node("TurretSprite").rotation = get_node("TurretSprite").rotation - (TANK_ROTATION_SPEED * _delta)
		if Input.is_action_pressed("move_right"):
			if Input.is_action_pressed("move_down"):
				rotation = rotation - (TANK_ROTATION_SPEED * _delta)
			else:
				rotation = rotation + (TANK_ROTATION_SPEED * _delta)
			#get_node("TurretSprite").rotation = get_node("TurretSprite").rotation + (TANK_ROTATION_SPEED * _delta)
		if Input.is_action_pressed("turret_clockwise"):
			get_node("TurretSprite").rotation += _delta * TURRET_SPEED
		if Input.is_action_pressed("turret_counter_clockwise"):
			get_node("TurretSprite").rotation -= _delta * TURRET_SPEED
		
		#var angle_to_mouse = get_node("TurretSprite").global_position.angle_to_point(get_global_mouse_position())
		
		
		#if angle_to_mouse < 0:
			#angle_to_mouse+= (2 * PI)
		#angle_to_mouse+=PI
		#angle_to_mouse = fmod(angle_to_mouse, 2 * PI)
		
		#var turret_rot = get_node("TurretSprite").rotation
		
		
		#if turret_rot < 0:
			#turret_rot+= (2*PI)
		
		#turret_rot = fmod(turret_rot, 2 * PI)
		
		#var r_direction = 1
		
		#print(abs(angle_to_mouse - turret_rot))
		
		#if abs(angle_to_mouse - turret_rot) < abs((2*PI - angle_to_mouse) + turret_rot):
			#r_direction = 0
		
		#if r_direction == 1:
			#get_node("TurretSprite").rotation -= _delta * TURRET_SPEED
		#else:
			#get_node("TurretSprite").rotation += _delta * TURRET_SPEED
		
		#rotation = fmod(rotation, 2 * PI)
		
		var shooting = Input.is_action_just_pressed("shoot")
		
		var bombing = Input.is_action_pressed("set_bomb")

		if stunned:
			bombing = false
			motion = Vector2()

		if bombing and not prev_bombing:
			var bomb_name = get_name() + str(bomb_index)
			var bomb_pos = position
			rpc("setup_bomb", bomb_name, bomb_pos, get_tree().get_network_unique_id())

		prev_bombing = bombing
		
		if shooting:
			var shell_name = get_name() + str(shell_index)
			var shell_pos = get_node("TurretSprite/ShellSpawnPos2D").global_position
			var shell_rot = get_node("TurretSprite").global_rotation
			rpc("launch_shell", shell_name, shell_pos, shell_rot, get_tree().get_network_unique_id())

		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_turret_rotation", get_node("TurretSprite").rotation)
		rset("puppet_rotation", rotation)
	else:
		position = puppet_pos
		motion = puppet_motion
		get_node("TurretSprite").rotation = puppet_turret_rotation
		rotation = puppet_rotation

	var new_anim = "Idle"
	if motion.y < 0:
		new_anim = "Idle"
	elif motion.y > 0:
		new_anim = "Idle"
	elif motion.x < 0:
		new_anim = "Idle"
	elif motion.x > 0:
		new_anim = "Idle"

	if stunned:
		new_anim = "Idle"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)

	# FIXME: Use move_and_slide
	if(motion != Vector2(0, 0)):
		print(motion)
	move_and_slide(motion * MOTION_SPEED)
	if not is_network_master():
		puppet_pos = position # To avoid jitter

puppet func stun():
	stunned = true

master func exploded(_by_who):
	if stunned:
		return
	rpc("stun") # Stun puppets
	stun() # Stun master - could use sync to do both at once

func set_player_name(new_name):
	get_node("label").set_text(new_name)

func _ready():
	stunned = false
	puppet_pos = position
