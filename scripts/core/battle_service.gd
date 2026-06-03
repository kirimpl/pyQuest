extends Node

const MIN_NON_FINAL_ENEMY_HP: int = 1
const HINT_DAMAGE_PENALTY: int = 4
const REPLAY_DAMAGE_RATIO: float = 0.35

func ensure_level_battle(level: int) -> void:
	var enemy_data: Dictionary = ContentRepository.get_enemy_for_level(level)
	var balanced_hp: int = get_balanced_enemy_hp(level, enemy_data)

	if not AppState.is_battle_ready_for_level(level):
		AppState.start_level_battle(level, enemy_data, balanced_hp)
		return

	if AppState.enemy_hp <= 0 and not AppState.is_level_completed(level):
		AppState.start_level_battle(level, enemy_data, balanced_hp)

func restart_level_battle(level: int) -> void:
	var enemy_data: Dictionary = ContentRepository.get_enemy_for_level(level)
	AppState.start_level_battle(level, enemy_data, get_balanced_enemy_hp(level, enemy_data))

func revive_hero_for_retry() -> void:
	AppState.revive_hero_after_defeat()

func get_balanced_enemy_hp(level: int, enemy_data: Dictionary = {}) -> int:
	var configured_hp: int = int(enemy_data.get("max_hp", 0))
	if configured_hp > 0:
		return configured_hp

	var total_damage_budget: int = 0
	for item in ContentRepository.get_tasks_for_level(level):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var task: Dictionary = item
		total_damage_budget += _get_base_damage(task)

	return maxi(30, total_damage_budget + 18 + level)

func resolve_answer(task: Dictionary, is_correct: bool, first_time_task_completed: bool, used_hint: bool, is_final_task: bool) -> Dictionary:
	ensure_level_battle(AppState.selected_level)

	var result: Dictionary = {
		"message": "",
		"player_damage": 0,
		"enemy_damage": 0,
		"hero_defeated": false,
		"enemy_defeated": false,
		"combo": AppState.combo_streak
	}

	if is_correct:
		AppState.register_correct_battle_step()
		var player_damage: int = calculate_player_damage(task, first_time_task_completed, used_hint)
		AppState.damage_enemy(player_damage)

		if is_final_task:
			AppState.set_enemy_hp(0)
			AppState.register_enemy_defeated(AppState.selected_level)
		elif AppState.enemy_hp <= 0:
			AppState.set_enemy_hp(MIN_NON_FINAL_ENEMY_HP)

		var enemy_defeated: bool = AppState.enemy_hp <= 0
		result["player_damage"] = player_damage
		result["enemy_defeated"] = enemy_defeated
		result["combo"] = AppState.combo_streak
		result["message"] = _build_success_battle_message(player_damage, enemy_defeated, used_hint)
		return result

	AppState.register_wrong_battle_step()
	var enemy_damage: int = calculate_enemy_damage(task, used_hint)
	AppState.damage_hero(enemy_damage)
	var hero_defeated: bool = AppState.hero_hp <= 0
	result["enemy_damage"] = enemy_damage
	result["hero_defeated"] = hero_defeated
	result["combo"] = AppState.combo_streak
	result["message"] = _build_error_battle_message(enemy_damage, hero_defeated)
	return result

func calculate_player_damage(task: Dictionary, first_time_task_completed: bool, used_hint: bool) -> int:
	var base_damage: int = _get_base_damage(task)
	var combo_bonus: int = mini(AppState.combo_streak * 3, 15)
	var hint_penalty: int = HINT_DAMAGE_PENALTY if used_hint else 0
	var calculated_damage: int = maxi(1, base_damage + combo_bonus - hint_penalty)

	if not first_time_task_completed:
		calculated_damage = maxi(3, int(round(float(calculated_damage) * REPLAY_DAMAGE_RATIO)))

	return calculated_damage

func calculate_enemy_damage(task: Dictionary, used_hint: bool) -> int:
	var task_type: String = str(task.get("type", "single_choice"))
	var type_bonus: int = 0
	if task_type == TaskEvaluator.TYPE_CODE_INPUT:
		type_bonus = 3
	elif task_type == TaskEvaluator.TYPE_CODE_ORDER:
		type_bonus = 2
	elif task_type == TaskEvaluator.TYPE_FIND_ERROR:
		type_bonus = 1

	var hint_guard: int = 2 if used_hint else 0
	return maxi(1, AppState.enemy_attack + type_bonus - hint_guard)

func get_battle_progress_text() -> String:
	ensure_level_battle(AppState.selected_level)
	return "HP героя: %d/%d   Противник: %s %d/%d   Комбо: %d" % [
		AppState.hero_hp,
		AppState.hero_max_hp,
		AppState.enemy_name,
		AppState.enemy_hp,
		AppState.enemy_max_hp,
		AppState.combo_streak
	]

func _get_base_damage(task: Dictionary) -> int:
	var task_type: String = str(task.get("type", "single_choice"))
	var score_value: int = int(task.get("score", 10))
	var type_bonus: int = 6

	if task_type == TaskEvaluator.TYPE_CODE_INPUT:
		type_bonus = 11
	elif task_type == TaskEvaluator.TYPE_CODE_ORDER:
		type_bonus = 10
	elif task_type == TaskEvaluator.TYPE_FIND_ERROR:
		type_bonus = 8
	elif task_type == TaskEvaluator.TYPE_FILL_BLANK or task_type == TaskEvaluator.TYPE_TEXT_INPUT:
		type_bonus = 7

	return maxi(5, score_value + type_bonus)

func _build_success_battle_message(player_damage: int, enemy_defeated: bool, used_hint: bool) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Герой атаковал %s и нанёс %d урона." % [AppState.enemy_name, player_damage])
	if used_hint:
		lines.append("Подсказка помогла не ошибиться, но немного снизила силу атаки.")
	if AppState.combo_streak > 1:
		lines.append("Комбо увеличено до x%d." % AppState.combo_streak)
	if enemy_defeated:
		lines.append("Противник побеждён, уровень очищен.")
	else:
		lines.append("У противника осталось %d/%d HP." % [AppState.enemy_hp, AppState.enemy_max_hp])
	return "\n".join(lines)

func _build_error_battle_message(enemy_damage: int, hero_defeated: bool) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s контратаковал и нанёс герою %d урона." % [AppState.enemy_name, enemy_damage])
	lines.append("Комбо сброшено.")
	if hero_defeated:
		lines.append("HP героя закончилось. Нажми 'Повторить', чтобы восстановиться и попробовать ещё раз.")
	else:
		lines.append("У героя осталось %d/%d HP." % [AppState.hero_hp, AppState.hero_max_hp])
	return "\n".join(lines)
