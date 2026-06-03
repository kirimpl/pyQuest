extends Node

signal progress_changed
signal answer_result_changed
signal settings_changed

const DEFAULT_MAX_ENERGY: int = 100
const LOW_ENERGY_REBOOT_VALUE: int = 35

var selected_level: int = 1
var selected_task_index: int = 0
var max_unlocked_level: int = 1
var score: int = 0
var mistakes: int = 0
var completed_levels: Array[int] = []
var completed_task_ids: Array[int] = []

var player_energy: int = DEFAULT_MAX_ENERGY
var max_player_energy: int = DEFAULT_MAX_ENERGY
var system_alarm: int = 0
var hints_used: int = 0
var completed_mission_step_keys: Array[String] = []
var collected_artifacts: Array[String] = []
var emergency_reboots: int = 0
var completed_lesson_step_keys: Array[String] = []
var code_level_attempts: Dictionary = {}
var code_level_best_steps: Dictionary = {}
var code_level_hint_usage: Dictionary = {}
var code_level_saved_code: Dictionary = {}
var code_level_stars: Dictionary = {}
var code_level_last_report: Dictionary = {}
var code_tutorial_completed: bool = false

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

var last_mission_title: String = ""
var last_mission_event: String = ""
var last_mission_outcome: String = ""
var last_energy_delta: int = 0
var last_alarm_delta: int = 0
var last_artifact: String = ""
var last_emergency_reboot: bool = false
var last_hint_used: bool = false

func start_new_game() -> void:
	selected_level = 1
	selected_task_index = 0
	max_unlocked_level = 1
	score = 0
	mistakes = 0
	completed_levels.clear()
	completed_task_ids.clear()
	player_energy = max_player_energy
	system_alarm = 0
	hints_used = 0
	completed_mission_step_keys.clear()
	collected_artifacts.clear()
	emergency_reboots = 0
	completed_lesson_step_keys.clear()
	code_level_attempts.clear()
	code_level_best_steps.clear()
	code_level_hint_usage.clear()
	code_level_saved_code.clear()
	code_level_stars.clear()
	code_level_last_report.clear()
	code_tutorial_completed = false
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
	last_mission_title = ""
	last_mission_event = ""
	last_mission_outcome = ""
	last_energy_delta = 0
	last_alarm_delta = 0
	last_artifact = ""
	last_emergency_reboot = false
	last_hint_used = false
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

func register_hint_used() -> void:
	hints_used += 1
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

func register_mission_attempt(level: int, task_id: int, is_correct: bool, mission_title: String, event_title: String, outcome_text: String, artifact: String, used_hint: bool) -> Dictionary:
	var step_key: String = _build_mission_step_key(level, task_id)
	var already_completed: bool = completed_mission_step_keys.has(step_key)
	var energy_delta: int = 0
	var alarm_delta: int = 0
	var artifact_added: bool = false
	var emergency_reboot_happened: bool = false

	if used_hint:
		register_hint_used()

	if is_correct:
		energy_delta = 2 if used_hint else 5
		alarm_delta = -4 if not used_hint else -2
		player_energy = clampi(player_energy + energy_delta, 0, max_player_energy)
		system_alarm = clampi(system_alarm + alarm_delta, 0, 100)
		if not already_completed:
			completed_mission_step_keys.append(step_key)
			completed_mission_step_keys.sort()
			if not artifact.strip_edges().is_empty() and not collected_artifacts.has(artifact):
				collected_artifacts.append(artifact)
				artifact_added = true
	else:
		energy_delta = -12
		alarm_delta = 9
		player_energy = clampi(player_energy + energy_delta, 0, max_player_energy)
		system_alarm = clampi(system_alarm + alarm_delta, 0, 100)
		if player_energy <= 0:
			emergency_reboot_happened = true
			emergency_reboots += 1
			player_energy = LOW_ENERGY_REBOOT_VALUE
			system_alarm = clampi(system_alarm + 6, 0, 100)

	last_mission_title = mission_title
	last_mission_event = event_title
	last_mission_outcome = outcome_text
	last_energy_delta = energy_delta
	last_alarm_delta = alarm_delta
	last_artifact = artifact if artifact_added else ""
	last_emergency_reboot = emergency_reboot_happened
	last_hint_used = used_hint
	progress_changed.emit()
	answer_result_changed.emit()

	return {
		"already_completed": already_completed,
		"energy_delta": energy_delta,
		"alarm_delta": alarm_delta,
		"artifact_added": artifact_added,
		"artifact": artifact if artifact_added else "",
		"emergency_reboot": emergency_reboot_happened,
		"player_energy": player_energy,
		"system_alarm": system_alarm
	}

func is_mission_step_completed(level: int, task_id: int) -> bool:
	return completed_mission_step_keys.has(_build_mission_step_key(level, task_id))

func get_completed_mission_step_count_for_level(level: int) -> int:
	var prefix: String = "%d:" % [level]
	var count: int = 0
	for step_key in completed_mission_step_keys:
		if step_key.begins_with(prefix):
			count += 1
	return count

func get_total_completed_mission_steps() -> int:
	return completed_mission_step_keys.size()

func get_total_completed_lesson_steps() -> int:
	return completed_lesson_step_keys.size()

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


func complete_lesson_step(level: int, step_id: String) -> bool:
	var step_key: String = _build_lesson_step_key(level, step_id)
	if completed_lesson_step_keys.has(step_key):
		return false
	completed_lesson_step_keys.append(step_key)
	completed_lesson_step_keys.sort()
	progress_changed.emit()
	return true

func is_lesson_step_completed(level: int, step_id: String) -> bool:
	return completed_lesson_step_keys.has(_build_lesson_step_key(level, step_id))

func get_completed_lesson_step_count_for_level(level: int) -> int:
	var prefix: String = "%d:" % [level]
	var count: int = 0
	for step_key in completed_lesson_step_keys:
		if step_key.begins_with(prefix):
			count += 1
	return count


func register_code_level_attempt(level: int, success: bool, steps: int, used_hint: bool, stars: int = 0, report: String = "") -> void:
	var key: String = str(level)
	code_level_attempts[key] = int(code_level_attempts.get(key, 0)) + 1
	if used_hint:
		code_level_hint_usage[key] = true
	if not report.strip_edges().is_empty():
		code_level_last_report[key] = report
	if success:
		var previous_best: int = int(code_level_best_steps.get(key, 0))
		if previous_best <= 0 or steps < previous_best:
			code_level_best_steps[key] = steps
		var previous_stars: int = int(code_level_stars.get(key, 0))
		code_level_stars[key] = maxi(previous_stars, clampi(stars, 1, 3))
	progress_changed.emit()

func get_code_level_attempt_count(level: int) -> int:
	return int(code_level_attempts.get(str(level), 0))

func get_code_level_best_steps(level: int) -> int:
	return int(code_level_best_steps.get(str(level), 0))

func was_code_level_hint_used(level: int) -> bool:
	return bool(code_level_hint_usage.get(str(level), false))

func save_code_for_level(level: int, source_code: String) -> void:
	code_level_saved_code[str(level)] = source_code
	progress_changed.emit()

func get_code_for_level(level: int, default_code: String = "") -> String:
	var saved_code: String = str(code_level_saved_code.get(str(level), ""))
	if saved_code.strip_edges().is_empty():
		return default_code
	return saved_code

func clear_code_for_level(level: int) -> void:
	code_level_saved_code.erase(str(level))
	progress_changed.emit()

func get_code_level_star_count(level: int) -> int:
	return int(code_level_stars.get(str(level), 0))

func get_total_code_stars() -> int:
	var total: int = 0
	for key in code_level_stars.keys():
		total += int(code_level_stars.get(key, 0))
	return total

func get_code_level_last_report(level: int) -> String:
	return str(code_level_last_report.get(str(level), ""))

func get_total_code_attempts() -> int:
	var total: int = 0
	for key in code_level_attempts.keys():
		total += int(code_level_attempts.get(key, 0))
	return total

func complete_code_tutorial() -> void:
	code_tutorial_completed = true
	progress_changed.emit()

func reset_code_tutorial() -> void:
	code_tutorial_completed = false
	progress_changed.emit()

func get_code_level_best_text(level: int) -> String:
	var attempts: int = get_code_level_attempt_count(level)
	var best_steps: int = get_code_level_best_steps(level)
	var stars: int = get_code_level_star_count(level)
	var star_text: String = "★".repeat(stars) + "☆".repeat(3 - stars)
	if attempts <= 0:
		return "Попыток нет · %s" % star_text
	if best_steps > 0:
		return "%d попыток · рекорд %d действий · %s%s" % [attempts, best_steps, star_text, " · с подсказкой" if was_code_level_hint_used(level) else ""]
	return "%d попыток · не восстановлен · %s%s" % [attempts, star_text, " · с подсказкой" if was_code_level_hint_used(level) else ""]

func to_dictionary() -> Dictionary:
	return {
		"selected_level": selected_level,
		"selected_task_index": selected_task_index,
		"max_unlocked_level": max_unlocked_level,
		"score": score,
		"mistakes": mistakes,
		"completed_levels": completed_levels,
		"completed_task_ids": completed_task_ids,
		"player_energy": player_energy,
		"max_player_energy": max_player_energy,
		"system_alarm": system_alarm,
		"hints_used": hints_used,
		"completed_mission_step_keys": completed_mission_step_keys,
		"collected_artifacts": collected_artifacts,
		"emergency_reboots": emergency_reboots,
		"completed_lesson_step_keys": completed_lesson_step_keys,
		"code_level_attempts": code_level_attempts,
		"code_level_best_steps": code_level_best_steps,
		"code_level_hint_usage": code_level_hint_usage,
		"code_level_saved_code": code_level_saved_code,
		"code_level_stars": code_level_stars,
		"code_level_last_report": code_level_last_report,
		"code_tutorial_completed": code_tutorial_completed,
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
	max_player_energy = clampi(int(data.get("max_player_energy", DEFAULT_MAX_ENERGY)), 1, 999)
	player_energy = clampi(int(data.get("player_energy", max_player_energy)), 0, max_player_energy)
	system_alarm = clampi(int(data.get("system_alarm", 0)), 0, 100)
	hints_used = int(data.get("hints_used", 0))
	emergency_reboots = int(data.get("emergency_reboots", 0))
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

	completed_mission_step_keys.clear()
	var saved_step_keys: Array = _variant_to_array(data.get("completed_mission_step_keys", []))
	for item in saved_step_keys:
		completed_mission_step_keys.append(str(item))
	completed_mission_step_keys.sort()

	collected_artifacts.clear()
	var saved_artifacts: Array = _variant_to_array(data.get("collected_artifacts", []))
	for item in saved_artifacts:
		collected_artifacts.append(str(item))

	completed_lesson_step_keys.clear()
	var saved_lesson_step_keys: Array = _variant_to_array(data.get("completed_lesson_step_keys", []))
	for item in saved_lesson_step_keys:
		completed_lesson_step_keys.append(str(item))
	completed_lesson_step_keys.sort()

	code_level_attempts = _variant_to_dictionary(data.get("code_level_attempts", {}))
	code_level_best_steps = _variant_to_dictionary(data.get("code_level_best_steps", {}))
	code_level_hint_usage = _variant_to_dictionary(data.get("code_level_hint_usage", {}))
	code_level_saved_code = _variant_to_dictionary(data.get("code_level_saved_code", {}))
	code_level_stars = _variant_to_dictionary(data.get("code_level_stars", {}))
	code_level_last_report = _variant_to_dictionary(data.get("code_level_last_report", {}))
	code_tutorial_completed = bool(data.get("code_tutorial_completed", false))

	clear_last_result()
	progress_changed.emit()
	settings_changed.emit()

func _build_lesson_step_key(level: int, step_id: String) -> String:
	return "%d:%s" % [level, step_id]

func _build_mission_step_key(level: int, task_id: int) -> String:
	return "%d:%d" % [level, task_id]

func _variant_to_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result: Dictionary = {}
	for key in value.keys():
		result[str(key)] = value[key]
	return result

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result
