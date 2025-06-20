extends Node

@onready var background_music = $BackgroundMusic
@onready var level_pass = $LevelPass
@onready var level_fail = $LevelFail

func _ready():
	# Start background music when game starts
	background_music.play()

func play_level_pass():
	background_music.stop()
	level_pass.play()
	
func play_level_fail():
	background_music.stop()
	level_fail.play()
	
# Called when either success or fail sound finishes
func _on_jingle_finished():
	# Resume background music
	background_music.play() 