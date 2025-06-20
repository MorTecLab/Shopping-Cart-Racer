extends StaticBody3D

func _ready():
	# Add to the car group
	add_to_group("obstacle")
	
	# Create a collision detector
	var area = Area3D.new()
	add_child(area)
	
	# Add the collision shape to the area
	var shape = $CollisionShape3D.duplicate()
	shape.scale = Vector3(1.1, 1.1, 1.1)  # Slightly larger than the physical collision
	area.add_child(shape)
	
	# Connect the body entered signal
	area.body_entered.connect(_on_collision)
	
	print("Parked car collision detection ready")

func _on_collision(body):
	if not body.is_in_group("cart"):
		return
		
	print("Cart hit parked car")
	
	# Check if cart has the necessary properties and methods
	if body.has_method("explode"):
		var impact_speed = body.linear_velocity.length()
		if impact_speed > body.crash_speed_threshold:
			print("Cart crashed into car at speed: ", impact_speed)
			body.explode()
		else:
			print("Impact too slow to explode: ", impact_speed) 
