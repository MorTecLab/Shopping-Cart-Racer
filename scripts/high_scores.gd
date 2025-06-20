extends Node

const SAVE_FILE = "user://highscores.save"
const MAX_SCORES = 5

static func save_score(time: float) -> bool:
	var scores = load_scores()
	scores.append(time)
	scores.sort()  # Sort ascending (fastest times first)
	
	if scores.size() > MAX_SCORES:
		scores = scores.slice(0, MAX_SCORES)
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(scores)
		return true
	return false

static func load_scores() -> Array:
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var scores = file.get_var()
			if scores != null and scores is Array:
				return scores
	return []

static func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var msec = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, msec]

static func get_formatted_scores() -> Array:
	var scores = load_scores()
	var formatted = []
	for i in range(scores.size()):
		formatted.append("%d. %s" % [i + 1, format_time(scores[i])])
	return formatted 