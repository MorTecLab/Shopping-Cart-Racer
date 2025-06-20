extends HBoxContainer

var hover_style_box: StyleBoxFlat
var background_style_box: StyleBoxFlat
var default_style_box: StyleBoxFlat

# The rank colors (gold, silver, bronze for top 3, normal for others)
var rank_colors = [
	Color("#FFD700"),  # Gold
	Color("#C0C0C0"),  # Silver
	Color("#CD7F32"),  # Bronze
	Color("#FFFFFF")   # Default white
]

func _ready():
	# Create stylebox for hover effect
	hover_style_box = StyleBoxFlat.new()
	hover_style_box.bg_color = Color(1, 1, 1, 0.1)
	
	# Create stylebox for alternating row backgrounds
	background_style_box = StyleBoxFlat.new()
	background_style_box.bg_color = Color(1, 1, 1, 0.05)
	
	# Create default (transparent) stylebox
	default_style_box = StyleBoxFlat.new()
	default_style_box.bg_color = Color(0, 0, 0, 0)
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(rank, player_data):
	# Set rank with proper color
	$MarginContainer/HBoxContainer/RankLabel.text = "#" + str(rank)
	
	# Set rank color based on position
	var color_index = min(rank - 1, 3)  # 0=gold, 1=silver, 2=bronze, 3+=white
	$MarginContainer/HBoxContainer/RankLabel.add_theme_color_override("font_color", rank_colors[color_index])
	
	# Set player data
	$MarginContainer/HBoxContainer/NameLabel.text = player_data.name
	$MarginContainer/HBoxContainer/ScoreLabel.text = str(player_data.score)
	
	# Set emblem if available
	if player_data.emblem != null:
		$MarginContainer/HBoxContainer/EmblemRect.texture = player_data.emblem
	else:
		# Use placeholder emblem with rank color border
		var placeholder = create_placeholder_emblem(rank_colors[color_index])
		$MarginContainer/HBoxContainer/EmblemRect.texture = placeholder
	
	# Set background color for alternating rows
	if rank % 2 == 0:  # Even ranks get background
		add_theme_stylebox_override("panel", background_style_box)
	else:
		add_theme_stylebox_override("panel", default_style_box)

func create_placeholder_emblem(border_color = Color.WHITE):
	# Create a placeholder emblem (colored border)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Fill with transparency
	image.fill(Color(0, 0, 0, 0))
	
	# Draw colored border (2px)
	for x in range(32):
		for y in range(32):
			if x < 2 or x >= 30 or y < 2 or y >= 30:
				image.set_pixel(x, y, border_color)
	
	# Create and return ImageTexture
	var texture = ImageTexture.create_from_image(image)
	return texture

func _on_mouse_entered():
	# Apply hover effect
	add_theme_stylebox_override("panel", hover_style_box)
	
	# Pulse animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _on_mouse_exited():
	# Remove hover effect
	var rank_text = $MarginContainer/HBoxContainer/RankLabel.text
	var rank = int(rank_text.substr(1))
	
	if rank % 2 == 0:  # Even ranks get background
		add_theme_stylebox_override("panel", background_style_box)
	else:
		add_theme_stylebox_override("panel", default_style_box) 
