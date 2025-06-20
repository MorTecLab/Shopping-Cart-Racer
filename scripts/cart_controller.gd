extends RigidBody3D

@export var initial_move_force = 300.0  # Starting force when first pressing W
@export var max_move_force = 1200.0  # Maximum force after holding W for a while
@export var turn_force = 80.0   # Turning force
@export var min_speed = 4.0     # Starting speed
@export var max_speed = 15.0    # Max speed after acceleration
@export var acceleration_time = 2.0  # Time in seconds to reach max speed (changed from 4.0)
@export var wheel_friction = 0.15  # Lower friction - harder to slow down
@export var crash_speed_threshold = 2.5  # Crash detection threshold
@export var crash_spin_threshold = 1.5  # Spin crash threshold
@export var wobble_speed_threshold = 10.0  # Speed at which wobble starts
@export var wobble_intensity = 0.3  # How strong the wobble effect is
@export var wobble_frequency = 12.0  # How fast the wobble oscillates

var move_direction = Vector3.ZERO
var turn_direction = 0.0
var explosion_scene = preload("res://scenes/explosion.tscn")
var is_destroyed = false
var wobble_time = 0.0
var current_wobble = 0.0

# Acceleration variables
var current_acceleration = 0.0  # How long player has been accelerating
var is_accelerating = false     # Is the player currently holding W
var current_max_speed = min_speed  # Current speed limit based on acceleration

func _ready():
	# Set up physics material for better wheel friction
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = wheel_friction
	physics_material.rough = true
	physics_material_override = physics_material
	
	# Lock rotations except Y-axis
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	# Physics properties
	mass = 25.0  # Heavier mass for more inertia
	gravity_scale = 1.0  # Normal gravity
	linear_damp = 0.2  # Less linear damping - harder to slow down
	angular_damp = 1.0  # Normal angular damping
	
	# Improve collision detection
	contact_monitor = true
	max_contacts_reported = 16  # Increased for better detection
	body_entered.connect(_on_collision)

func _physics_process(delta):
	if is_destroyed:
		return
		
	# Get input
	move_direction = Vector3.ZERO
	turn_direction = 0.0
	var was_accelerating = is_accelerating
	is_accelerating = false
	
	if Input.is_action_pressed("move_forward"):
		move_direction.z = -1
		is_accelerating = true
	if Input.is_action_pressed("move_backward"):
		move_direction.z = 1
	if Input.is_action_pressed("turn_left"):
		turn_direction = 1
	if Input.is_action_pressed("turn_right"):
		turn_direction = -1
	
	# Handle acceleration timing
	update_acceleration(delta, was_accelerating)
	
	# Apply movement force
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	
	# Calculate force based on acceleration time
	var acceleration_percent = current_acceleration / acceleration_time
	var current_force = lerp(initial_move_force, max_move_force, acceleration_percent)
	
	# Calculate and apply movement force
	var move_force_vector = forward * move_direction.z * current_force
	apply_central_force(move_force_vector)
	
	# Apply turning force (only on Y axis)
	if abs(turn_direction) > 0:
		apply_torque(Vector3.UP * turn_direction * turn_force)
	
	# Limit speed
	var current_speed = linear_velocity.length()
	if current_speed > current_max_speed:
		linear_velocity = linear_velocity.normalized() * current_max_speed
	
	# Update camera wobble effect based on speed
	update_camera_wobble(delta, current_speed)

func update_acceleration(delta, was_accelerating):
	if is_accelerating:
		# Increase acceleration time while holding W - faster rate for 2s total
		current_acceleration = min(current_acceleration + delta, acceleration_time)
	else:
		# If released W, gradually reset acceleration - slightly faster reset 
		current_acceleration = max(current_acceleration - delta * 2.5, 0.0)
		
	# If we just stopped accelerating, don't immediately drop speed
	if was_accelerating and !is_accelerating:
		# Keep high speed for a bit, then start to drop
		pass
		
	# Calculate current max speed based on acceleration
	var acceleration_percent = current_acceleration / acceleration_time
	current_max_speed = lerp(min_speed, max_speed, ease(acceleration_percent, 2.5))  # Steeper exponential increase
	
	# Debug info
	# print("Acceleration: ", current_acceleration, " Max Speed: ", current_max_speed)

func update_camera_wobble(delta, speed):
	var camera = $Camera3D
	if not camera:
		return
	
	# Only wobble at high speeds (after accelerating for a while)
	var should_wobble = current_acceleration >= acceleration_time * 0.9 and speed >= wobble_speed_threshold
		
	# Reset camera position when slow or not fully accelerated
	if !should_wobble:
		wobble_time = 0.0
		current_wobble = 0.0
		
		# Smoothly return to original position
		if camera.rotation.z != 0:
			camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * 5.0)
		if camera.h_offset != 0 or camera.v_offset != 0:
			camera.h_offset = lerp(camera.h_offset, 0.0, delta * 5.0)
			camera.v_offset = lerp(camera.v_offset, 0.0, delta * 5.0)
		return
	
	# Calculate wobble based on speed
	wobble_time += delta
	
	# Intensity based on speed and how long we've been at max acceleration
	var accel_factor = (current_acceleration - (acceleration_time * 0.9)) / (acceleration_time * 0.1)
	var intensity = wobble_intensity * min(accel_factor, 1.0)
	
	# Higher frequency at higher speeds
	var freq = wobble_frequency * (0.8 + (speed / max_speed) * 0.5)
	
	# Calculate the wobble using sine wave
	current_wobble = sin(wobble_time * freq) * intensity
	
	# Apply wobble to camera rotation
	camera.rotation.z = current_wobble
	
	# Apply slight random shake if going really fast
	if speed > wobble_speed_threshold * 1.2:
		camera.h_offset = randf_range(-0.02, 0.02) * intensity
		camera.v_offset = randf_range(-0.02, 0.02) * intensity
	else:
		camera.h_offset = 0
		camera.v_offset = 0

func is_obstacle(node: Node) -> bool:
	# Check if this is a tree or parked car by checking the scene name or group
	if not node:
		return false
		
	# First check if it's part of the obstacle group
	if node.is_in_group("obstacle"):
		return true
	
	# Check if it's a StaticBody3D (most obstacles are static bodies)
	if node is StaticBody3D and not node.is_in_group("ground"):
		# Exclude the ground and cart bay from being considered obstacles
		if "Ground" not in node.name and "CartBay" not in node.name:
			return true
		
	# Check by scene file path
	var scene_file = node.scene_file_path if "scene_file_path" in node else ""
	if scene_file:
		if "tree.tscn" in scene_file or "parked_car.tscn" in scene_file:
			return true
			
	# Also check the node name as backup
	var name = node.name.to_lower()
	return "tree" in name or "parkedcar" in name or "car" in name

func should_crash(impact_speed: float, is_obstacle: bool) -> bool:
	# Get base threshold for this type of collision
	var speed_threshold = crash_speed_threshold
	if is_obstacle:
		speed_threshold *= 0.6  # Even more sensitive for obstacles
	
	# Check linear velocity
	if impact_speed > speed_threshold:
		return true
	
	# Check angular velocity (spinning crashes)
	var spin_speed = abs(angular_velocity.y)  # Only care about Y-axis spin
	if spin_speed > crash_spin_threshold:
		return true
	
	# Check combined effect
	# If both speed and spin are at least 40% of their thresholds, also crash
	if impact_speed > speed_threshold * 0.4 and spin_speed > crash_spin_threshold * 0.4:
		return true
		
	return false

func _on_collision(body: Node3D):
	if is_destroyed:
		return
		
	print("Cart collision with: ", body.name)
		
	# Ignore collisions with the ground
	if body.is_in_group("ground") or (body.get_parent() and body.get_parent().is_in_group("ground")):
		print("Ground collision ignored")
		return
		
	# Check if this is a cart bay collision
	var parent = body.get_parent()
	if parent and ("CartBay" in parent.name or (parent.get_parent() and "CartBay" in parent.get_parent().name)):
		# Only ignore collision with cart bay walls, not the detection zone
		if not (body.get_parent() is Area3D):
			print("Cart bay wall collision - safe inside")
			return
	
	# Get relative velocity for more accurate impact detection
	var relative_velocity = linear_velocity
	if body is RigidBody3D:
		relative_velocity -= body.linear_velocity
		
	# Check if we hit an obstacle (tree or parked car)
	var hit_obstacle = is_obstacle(body) or is_obstacle(parent) or (parent and is_obstacle(parent.get_parent()))
	print("Hit obstacle: ", hit_obstacle, " Speed: ", relative_velocity.length())
		
	# Check if we should crash based on impact and spinning
	if should_crash(relative_velocity.length(), hit_obstacle):
		print("CRASH triggered!")
		explode()
	else:
		print("Impact not hard enough to crash")
		# Add a small bounce effect for minor collisions
		apply_central_impulse(-relative_velocity.normalized() * 2.0)

func explode():
	if is_destroyed:
		return
		
	is_destroyed = true
	
	# Spawn explosion
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	# Hide cart
	visible = false
	
	# Disable physics
	freeze = true
	
	# Notify game manager
	get_parent()._on_cart_destroyed()
	
	# Wait and restart
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
	
