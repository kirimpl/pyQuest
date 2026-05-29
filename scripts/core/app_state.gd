extends Node

signal progress_changed
signal answer_result_changed
signal settings_changed

var selected_level: int = 1
var selected_task_index: int = 0
var max_unlocked_level: int = 1
var score: int = 0
var mistakes: int = 0
var completed_levels: Array[int] = []
var completed_task_ids: Array[int] = []

var music_enabled: bool = true
var sound_enabled: bool = true
var music_volume: float = 0.65
var sound_volume: float = 0.70

var last_answer_correct: bool = false
var last_explanation: String = ""
var last_task_title: String = ""
var last_awarded_score: int = 0
var last_level_completed: bool = false
var last_task_id: int = -1
var last_task_index: int = 0
var last_task_count: int = 1

func start_new_game() -> void:
	selected_level = 1
	selected_task_index = 0
	max_unlocked_level = 1
	score = 0
	mistakes = 0
	completed_levels.clear()
	completed_task_ids.clear()
	clear_last_result()
	progress_changed.emit()

func clear_last_result() -> void:
	last_answer_correct = false
	last_explanation = ""
	last_task_title = ""
	last_awarded_score = 0
	last_level_completed = false
	last_task_id = -1
	last_task_index = selected_task_index
	last_task_count = 1
	answer_result_changed.emit()

func can_open_level(level: int) -> bool:
	return level <= max_unlocked_level

func select_level(level: int) -> bool:
	if not can_open_level(level):
		return false
	selected_level = level
	selected_task_index = 0
	progress_changed.emit()
	return true

func select_task_index(task_index: int) -> void:
	selected_task_index = max(0, task_index)
	progress_changed.emit()

func add_score(value: int) -> void:
	score += value
	progress_changed.emit()

func add_mistake() -> void:
	mistakes += 1
	progress_changed.emit()

func complete_task(task_id: int) -> bool:
	if task_id < 0:
		return false
	if completed_task_ids.has(task_id):
		return false
	completed_task_ids.append(task_id)
	completed_task_ids.sort()
	progress_changed.emit()
	return true

func is_task_completed(task_id: int) -> bool:
	return completed_task_ids.has(task_id)

func complete_level(level: int, max_level: int = -1) -> void:
	if not completed_levels.has(level):
		completed_levels.append(level)
		completed_levels.sort()

	var next_unlocked_level: int = level + 1
	if max_level > 0:
		next_unlocked_level = min(next_unlocked_level, max_level)

	max_unlocked_level = max(max_unlocked_level, next_unlocked_level)
	progress_changed.emit()

func is_level_completed(level: int) -> bool:
	return completed_levels.has(level)

func set_last_result(is_correct: bool, explanation: String, task_title: String, awarded_score: int = 0, level_completed: bool = false, task_id: int = -1, task_index: int = 0, task_count: int = 1) -> void:
	last_answer_correct = is_correct
	last_explanation = explanation
	last_task_title = task_title
	last_awarded_score = awarded_score
	last_level_completed = level_completed
	last_task_id = task_id
	last_task_index = task_index
	last_task_count = max(1, task_count)
	answer_result_changed.emit()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	settings_changed.emit()

func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	settings_changed.emit()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit()

func set_sound_volume(value: float) -> void:
	sound_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit()

func to_dictionary() -> Dictionary:
	return {
		"selected_level": selected_level,
		"selected_task_index": selected_task_index,
		"max_unlocked_level": max_unlocked_level,
		"score": score,
		"mistakes": mistakes,
		"completed_levels": completed_levels,
		"completed_task_ids": completed_task_ids,
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"music_volume": music_volume,
		"sound_volume": sound_volume
	}

func load_from_dictionary(data: Dictionary) -> void:
	selected_level = int(data.get("selected_level", 1))
	selected_task_index = int(data.get("selected_task_index", 0))
	max_unlocked_level = int(data.get("max_unlocked_level", 1))
	score = int(data.get("score", 0))
	mistakes = int(data.get("mistakes", 0))
	music_enabled = bool(data.get("music_enabled", true))
	sound_enabled = bool(data.get("sound_enabled", true))
	music_volume = clampf(float(data.get("music_volume", 0.65)), 0.0, 1.0)
	sound_volume = clampf(float(data.get("sound_volume", 0.70)), 0.0, 1.0)

	completed_levels.clear()
	var saved_completed_levels: Array = _variant_to_array(data.get("completed_levels", []))
	for item in saved_completed_levels:
		completed_levels.append(int(item))
	completed_levels.sort()

	completed_task_ids.clear()
	var saved_completed_task_ids: Array = _variant_to_array(data.get("completed_task_ids", []))
	for item in saved_completed_task_ids:
		completed_task_ids.append(int(item))
	completed_task_ids.sort()

	clear_last_result()
	progress_changed.emit()
	settings_changed.emit()


func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result
