extends Node3D

var start_time: float = 0.0
var is_game_active: bool = false
var ui_scene = preload("res://scenes/game_ui.tscn")
var ui_instance

func _ready():
	# Initialize game state
	setup_game()
	
	# Connect to cart bay signal
	$CartBay/DetectionZone.cart_returned.connect(_on_cart_returned)
	
	# Add UI
	ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	
	# Start the game
	start_game()

func setup_game():
	is_game_active = false

func start_game():
	is_game_active = true
	start_time = Time.get_unix_time_from_system()
	ui_instance.show_message("Return the cart!")

func _process(delta):
	if is_game_active:
		var current_time = Time.get_unix_time_from_system() - start_time
		ui_instance.update_timer(current_time)

func _on_cart_returned():
	if is_game_active:
		is_game_active = false
		var final_time = Time.get_unix_time_from_system() - start_time
		ui_instance.show_victory(final_time)
		$SoundManager.play_level_pass()

func _on_cart_destroyed():
	if is_game_active:
		is_game_active = false
		ui_instance.show_game_over()
		$SoundManager.play_level_fail()

func restart_game():
	# Reload the current scene
	get_tree().reload_current_scene()

func _unhandled_input(event):
	# Handle game-wide input events
	if event.is_action_pressed("ui_cancel"):
		# Will add pause menu later
		pass 
