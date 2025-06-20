extends Control

@export var lobby_url: String = "https://example.com/join/123456"

# Colors
var normal_button_color = Color("#CCCCCC")
var hover_button_color = Color("#FFFFFF")

# Tooltip variables
var tooltip_timer: Timer
var tooltip_label: Label

func _ready():
	# Setup panel styles
	setup_panel_styles()
	
	# Connect button signals
	$LeftPanel/VBoxContainer/ButtonContainer/CopyButton.connect("pressed", _on_copy_invite)
	$LeftPanel/VBoxContainer/ButtonContainer/LeaderboardsButton.connect("pressed", _on_toggle_leaderboards)
	
	# Setup hover effects for buttons
	$LeftPanel/VBoxContainer/ButtonContainer/CopyButton.connect("mouse_entered", _on_button_mouse_entered.bind($LeftPanel/VBoxContainer/ButtonContainer/CopyButton))
	$LeftPanel/VBoxContainer/ButtonContainer/CopyButton.connect("mouse_exited", _on_button_mouse_exited.bind($LeftPanel/VBoxContainer/ButtonContainer/CopyButton))
	$LeftPanel/VBoxContainer/ButtonContainer/LeaderboardsButton.connect("mouse_entered", _on_button_mouse_entered.bind($LeftPanel/VBoxContainer/ButtonContainer/LeaderboardsButton))
	$LeftPanel/VBoxContainer/ButtonContainer/LeaderboardsButton.connect("mouse_exited", _on_button_mouse_exited.bind($LeftPanel/VBoxContainer/ButtonContainer/LeaderboardsButton))
	
	# Create tooltip components
	create_tooltip()
	
	# Fade in panels
	fade_in_panels()
	
	# Test data
	var test_players = [
		{name = "Player1", title = "Speedy", score = 1250, emblem = null},
		{name = "Player2", title = "Rookie", score = 800, emblem = null},
		{name = "Player3", title = "Champion", score = 2300, emblem = null},
		{name = "Player4", title = "Veteran", score = 1800, emblem = null},
		{name = "User123WithLongName", title = "Newbie", score = 450, emblem = null},
	]
	update_players(test_players)
	
	var test_leaderboard = [
		{name = "TopPlayer", score = 5200, emblem = null},
		{name = "SecondBest", score = 4800, emblem = null},
		{name = "ThirdPlace", score = 4500, emblem = null},
		{name = "Number4", score = 4100, emblem = null},
		{name = "Number5", score = 3900, emblem = null},
		{name = "Number6", score = 3700, emblem = null},
		{name = "Number7", score = 3500, emblem = null},
		{name = "Number8", score = 3300, emblem = null},
		{name = "Number9", score = 3100, emblem = null},
		{name = "Number10", score = 2900, emblem = null},
	]
	show_leaderboards(test_leaderboard)

func setup_panel_styles():
	# Left panel already setup in scene
	
	# Setup right panel
	var right_panel_style = StyleBoxFlat.new()
	right_panel_style.bg_color = Color(0.0625, 0.0625, 0.0625, 0.6)
	$RightPanel.add_theme_stylebox_override("panel", right_panel_style)

func create_tooltip():
	tooltip_label = Label.new()
	tooltip_label.text = "LINK COPIED!"
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	
	panel.add_child(tooltip_label)
	tooltip_label.anchors_preset = Control.PRESET_FULL_RECT
	
	panel.visible = false
	panel.size = Vector2(150, 50)
	add_child(panel)
	
	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = 1.5
	tooltip_timer.connect("timeout", func(): panel.visible = false)
	add_child(tooltip_timer)
	
	# Store reference for access
	tooltip_label = tooltip_label
	tooltip_label.get_parent().position = Vector2(get_viewport_rect().size.x / 2 - 75, get_viewport_rect().size.y / 2 - 25)

func fade_in_panels():
	# Start with transparent panels
	$LeftPanel.modulate.a = 0
	$RightPanel.modulate.a = 0
	
	# Create tween for fade-in
	var tween = create_tween()
	tween.parallel().tween_property($LeftPanel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property($RightPanel, "modulate:a", 1.0, 0.3)

func _on_copy_invite():
	DisplayServer.clipboard_set(lobby_url)
	tooltip_label.get_parent().visible = true
	tooltip_timer.start()

func _on_toggle_leaderboards():
	$LeftPanel/VBoxContainer/LeaderboardsPanel.visible = !$LeftPanel/VBoxContainer/LeaderboardsPanel.visible

func _on_button_mouse_entered(button):
	var tween = create_tween()
	tween.tween_property(button, "theme_override_colors/font_color", hover_button_color, 0.15)

func _on_button_mouse_exited(button):
	var tween = create_tween()
	tween.tween_property(button, "theme_override_colors/font_color", normal_button_color, 0.15)

func update_players(players):
	var list = $RightPanel/VBoxContainer/PlayerList
	
	# Clear existing children
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	
	# Update player count label
	$RightPanel/VBoxContainer/PlayerCountLabel.text = str(players.size()) + "/8 PLAYERS"
	
	# Add player entries
	for i in range(players.size()):
		var player = players[i]
		var entry = preload("res://scenes/lobby/PlayerEntry.tscn").instantiate()
		entry.setup(player, i % 2 == 1)  # Alternating backgrounds for odd/even rows
		list.add_child(entry)

func show_leaderboards(data):
	var list = $LeftPanel/VBoxContainer/LeaderboardsPanel/ScrollContainer/VBoxContainer
	
	# Clear existing children
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	
	# Add leaderboard entries
	for i in range(data.size()):
		var entry_data = data[i]
		var entry = preload("res://scenes/lobby/LeaderboardEntry.tscn").instantiate()
		entry.setup(i + 1, entry_data)
		list.add_child(entry) 
