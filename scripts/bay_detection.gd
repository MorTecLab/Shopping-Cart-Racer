extends Area3D

signal cart_returned
signal cart_entered
signal cart_exited

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("Bay detection zone ready")

func _on_body_entered(body):
	if not body.is_in_group("cart"):
		return

	print("Cart entered bay area")
	
	# Get cart velocity direction (safe fallback)
	var velocity = Vector3.ZERO
	if body.has_method("get_linear_velocity"):
		velocity = body.get_linear_velocity().normalized()
	elif "linear_velocity" in body:
		velocity = body.linear_velocity.normalized()
		
	# Get the bay's forward direction (-Z)
	var bay_forward = -global_transform.basis.z.normalized()
	
	# Check angle using dot product
	var entry_alignment = velocity.dot(bay_forward)

	# Adjust threshold (1.0 = perfect alignment, 0.5 = ~60 degrees)
	if entry_alignment >= 0.6:
		print("Cart entered properly")
		cart_entered.emit()
		cart_returned.emit()
	else:
		print("Cart entered from wrong direction (alignment =", entry_alignment, ")")
		if body.has_method("explode"):
			body.explode()

func _on_body_exited(body):
	if body.is_in_group("cart"):
		print("Cart exited bay area")
		cart_exited.emit()
