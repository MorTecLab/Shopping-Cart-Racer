extends Node3D

@onready var collision_area = $CollisionArea
var cart_is_inside = false

func _ready():
	# Connect to our own collision signal first
	collision_area.body_entered.connect(_on_collision)
	
	# Wait a short time for all nodes to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Try to get detection zone and connect signals
	_connect_to_detection_zone()

func _connect_to_detection_zone():
	# Find the parent cart bay node
	var cart_bay = get_parent().get_parent()
	if cart_bay:
		var detection_zone = cart_bay.get_node_or_null("DetectionZone")
		if detection_zone:
			# Connect to existing detection zone signals
			if detection_zone.has_signal("cart_entered"):
				detection_zone.connect("cart_entered", func(): cart_is_inside = true)
			if detection_zone.has_signal("cart_exited"):
				detection_zone.connect("cart_exited", func(): cart_is_inside = false)
			print("Wall collision connected to detection zone signals")
		else:
			print("Detection zone not found!")

func _on_collision(body):
	if not body.is_in_group("cart"):
		return
	
	# For debugging
	print("Wall collision detected, cart_is_inside: ", cart_is_inside)
		
	# Don't explode if cart is inside
	if cart_is_inside:
		print("Inside collision ignored")
		return
		
	# Check impact speed for explosion
	if body.has_method("explode"):
		var impact_speed = body.linear_velocity.length()
		if impact_speed > body.crash_speed_threshold:
			print("Exploding with speed: ", impact_speed)
			body.explode()
	else:
		print("Cart doesn't have explode method!") 