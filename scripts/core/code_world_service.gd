extends Node

const LEVELS_PATH: String = "res://data/code_adventure_levels.json"
const TILE_WALL: String = "#"
const TILE_EMPTY: String = "."
const TILE_EXIT: String = "X"
const TILE_GEM: String = "G"
const TILE_KEY: String = "K"
const TILE_DOOR: String = "D"
const TILE_ENEMY: String = "E"
const TILE_SWITCH: String = "S"
const TILE_WATER: String = "~"

var levels: Array = []

func _ready() -> void:
	load_levels()

func load_levels() -> void:
	levels.clear()
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Не найден файл уровней: " + LEVELS_PATH)
		return

	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл уровней: " + LEVELS_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Файл уровней поврежден: " + LEVELS_PATH)
		return

	levels = parsed

func get_level_count() -> int:
	return levels.size()

func get_level(level_number: int) -> Dictionary:
	for item in levels:
		if typeof(item) == TYPE_DICTIONARY and int(item.get("level", 0)) == level_number:
			return item
	return {}

func get_campaign_title() -> String:
	return "PyQuest: Code Adventure - программирование героя на карте"

func get_campaign_progress_text() -> String:
	return "Пройдено секторов: %d/%d · Звёзды: %d/%d" % [AppState.completed_levels.size(), get_level_count(), AppState.get_total_code_stars(), get_level_count() * 3]

func get_level_min_steps(level_number: int) -> int:
	var level: Dictionary = get_level(level_number)
	if level.is_empty():
		return 0
	var stored: int = int(level.get("min_steps", 0))
	if stored > 0:
		return stored
	return _estimate_min_steps_from_solution(level)

func get_level_difficulty(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("difficulty", "обычная"))

func get_level_chapter(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("chapter", "Кампания"))

func get_level_objectives_text(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	var objectives: Array = _variant_to_array(level.get("objectives", []))
	if objectives.is_empty():
		return _requirements_to_text(level.get("requirements", {}))
	var lines: PackedStringArray = PackedStringArray()
	for item in objectives:
		lines.append("• " + str(item))
	return "\n".join(lines)

func get_level_reward_text(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("unlock_reward", "открытие следующего сектора"))

func get_star_count_for_run(level_number: int, steps: int, used_hint: bool) -> int:
	if steps <= 0:
		return 0
	var target: int = maxi(1, get_level_min_steps(level_number))
	var stars: int = 1
	if steps <= int(ceil(float(target) * 1.35)):
		stars = 2
	if steps <= target:
		stars = 3
	if used_hint:
		stars = maxi(1, stars - 1)
	return clampi(stars, 1, 3)

func get_star_text(stars: int) -> String:
	var safe_stars: int = clampi(stars, 0, 3)
	return "★".repeat(safe_stars) + "☆".repeat(3 - safe_stars)

func get_default_code(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("starter_code", "# Напиши команды героя здесь\n"))

func get_solution_code(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("solution_code", ""))

func get_level_hint(level_number: int) -> String:
	var level: Dictionary = get_level(level_number)
	return str(level.get("hint", level.get("failure_hint", "Проверь порядок команд и цель уровня.")))

func get_initial_display_grid(level_number: int) -> Array:
	var level: Dictionary = get_level(level_number)
	if level.is_empty():
		return []
	return _variant_to_string_array(level.get("grid", []))

func simulate_level(level_number: int, source_code: String) -> Dictionary:
	var level: Dictionary = get_level(level_number)
	if level.is_empty():
		return {
			"success": false,
			"message": "Уровень не найден.",
			"log": "Level not found.",
			"display_grid": [],
			"frames": [],
			"steps": 0
		}

	var world: Dictionary = _build_world(level)
	var context: Dictionary = {
		"variables": {},
		"functions": {},
		"logs": [],
		"failed": false,
		"failure": "",
		"call_depth": 0
	}

	_append_log(context, "Запуск main.py")
	_append_log(context, "Цель: " + str(level.get("goal", "дойти до выхода X")))
	_append_log(context, "")
	_push_frame(world, context, "Старт сектора")

	var lines: Array = _split_source_lines(source_code)
	_execute_block(lines, 0, 0, world, context)

	var success: bool = false
	var message: String = ""
	if bool(context.get("failed", false)):
		success = false
		message = str(context.get("failure", "Команда не выполнена."))
	else:
		var check: Dictionary = _check_success(level, world, source_code)
		success = bool(check.get("success", false))
		message = str(check.get("message", ""))

	if success:
		_append_log(context, "")
		_append_log(context, str(level.get("success_message", "Сектор восстановлен.")))
		_push_frame(world, context, "Сектор восстановлен")
	else:
		_append_log(context, "")
		_append_log(context, "Миссия не завершена: " + message)
		_append_log(context, "Подсказка: " + str(level.get("failure_hint", "Проверь маршрут, условия победы и порядок команд.")))
		_push_frame(world, context, "Миссия не завершена")

	var steps_done: int = int(world.get("steps", 0))
	return {
		"success": success,
		"message": message,
		"log": "\n".join(context.get("logs", [])),
		"display_grid": _build_display_grid(world),
		"frames": world.get("frames", []),
		"steps": steps_done,
		"min_steps": get_level_min_steps(level_number),
		"collected": int(world.get("collected", 0)),
		"defeated": int(world.get("defeated", 0)),
		"opened_doors": int(world.get("opened_doors", 0)),
		"terminal_used": bool(world.get("terminal_used", false)),
		"inventory": world.get("inventory", []),
		"at_exit": world.get("hero", Vector2i.ZERO) == world.get("exit", Vector2i.ZERO),
		"remaining_items": int(world["gems"].size()) + int(world["keys"].size()),
		"remaining_enemies": int(world["enemies"].size()),
		"remaining_doors": int(world["doors"].size()),
		"remaining_terminals": int(world["switches"].size()) if not bool(world.get("terminal_used", false)) else 0,
		"report": _build_report(success, message, steps_done, level_number, world, context)
	}

func _build_world(level: Dictionary) -> Dictionary:
	var rows: Array = _variant_to_string_array(level.get("grid", []))
	var world: Dictionary = {
		"rows": rows,
		"walls": {},
		"water": {},
		"gems": {},
		"keys": {},
		"doors": {},
		"enemies": {},
		"switches": {},
		"trail": {},
		"exit": Vector2i.ZERO,
		"hero": Vector2i.ZERO,
		"inventory": [],
		"steps": 0,
		"collected": 0,
		"defeated": 0,
		"opened_doors": 0,
		"terminal_used": false,
		"said": [],
		"frames": []
	}

	for y in range(rows.size()):
		var row: String = str(rows[y])
		for x in range(row.length()):
			var ch: String = row.substr(x, 1)
			var pos: Vector2i = Vector2i(x, y)
			var key: String = _pos_key(pos)
			match ch:
				"#":
					world["walls"][key] = true
				"~":
					world["water"][key] = true
				"P":
					world["hero"] = pos
				"X":
					world["exit"] = pos
				"G":
					world["gems"][key] = true
				"K":
					world["keys"][key] = true
				"D":
					world["doors"][key] = true
				"E":
					world["enemies"][key] = true
				"S":
					world["switches"][key] = true

	return world

func _execute_block(lines: Array, start_index: int, base_indent: int, world: Dictionary, context: Dictionary) -> int:
	var index: int = start_index
	while index < lines.size():
		if bool(context.get("failed", false)):
			return index

		var raw_line: String = str(lines[index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			index += 1
			continue

		var indent: int = _count_indent(raw_line)
		if indent < base_indent:
			return index
		if indent > base_indent:
			index += 1
			continue

		if stripped.begins_with("for ") and stripped.ends_with(":"):
			index = _execute_for(lines, index, indent, stripped, world, context)
			continue

		if stripped.begins_with("while ") and stripped.ends_with(":"):
			index = _execute_while(lines, index, indent, stripped, world, context)
			continue

		if stripped == "try:":
			index = _execute_try(lines, index, indent, world, context)
			continue

		if stripped.begins_with("if ") and stripped.ends_with(":"):
			index = _execute_if(lines, index, indent, stripped, world, context)
			continue

		if stripped.begins_with("def ") and stripped.ends_with(":"):
			index = _register_function(lines, index, indent, stripped, context)
			continue

		if _execute_function_call(stripped, world, context):
			index += 1
			continue

		if _try_assignment(stripped, context):
			index += 1
			continue

		_execute_action(stripped, world, context)
		index += 1

	return index

func _execute_for(lines: Array, index: int, header_indent: int, line: String, world: Dictionary, context: Dictionary) -> int:
	var block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
	if block_indent < 0:
		_fail(context, "После for нужен блок команд с отступом.")
		return index + 1

	var block_end: int = _find_block_end(lines, index + 1, block_indent)
	var header: String = line.substr(4, line.length() - 5).strip_edges()
	var in_index: int = header.find(" in ")
	if in_index < 0:
		_fail(context, "Цикл должен быть записан как `for имя in range(...)` или `for имя in список`.")
		return block_end

	var variable_name: String = header.substr(0, in_index).strip_edges()
	var iterable_text: String = header.substr(in_index + 4).strip_edges()
	if not _is_identifier(variable_name):
		_fail(context, "Некорректная переменная цикла: " + variable_name)
		return block_end

	var had_previous: bool = context["variables"].has(variable_name)
	var previous_value: Variant = context["variables"].get(variable_name, null)

	if iterable_text.begins_with("range("):
		var range_values: Array = _extract_range_values(iterable_text, context)
		var normalized_range: String = iterable_text.strip_edges()
		if range_values.is_empty() and normalized_range != "range(0)" and normalized_range != "range(0, 0)":
			_fail(context, "Цикл должен использовать range(stop), range(start, stop) или range(start, stop, step).")
			return block_end
		_append_log(context, "Цикл `%s` выполняется %d раз." % [variable_name, range_values.size()])
		for repeat_index in range_values:
			context["variables"][variable_name] = repeat_index
			_execute_block(lines, index + 1, block_indent, world, context)
			if bool(context.get("failed", false)):
				break
	else:
		var iterable: Variant = _parse_value(iterable_text, context)
		if typeof(iterable) != TYPE_ARRAY:
			_fail(context, "После `in` нужен список или переменная со списком.")
			return block_end
		_append_log(context, "Цикл `%s` проходит по списку из %d элементов." % [variable_name, iterable.size()])
		for item in iterable:
			context["variables"][variable_name] = item
			_execute_block(lines, index + 1, block_indent, world, context)
			if bool(context.get("failed", false)):
				break

	if had_previous:
		context["variables"][variable_name] = previous_value
	else:
		context["variables"].erase(variable_name)
	return block_end

func _execute_while(lines: Array, index: int, header_indent: int, line: String, world: Dictionary, context: Dictionary) -> int:
	var block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
	if block_indent < 0:
		_fail(context, "После while нужен блок команд с отступом.")
		return index + 1

	var block_end: int = _find_block_end(lines, index + 1, block_indent)
	var condition: String = line.substr(6, line.length() - 7).strip_edges()
	var guard: int = 0
	while _evaluate_condition(condition, world, context):
		guard += 1
		if guard > 60:
			_fail(context, "while выполняется слишком долго. Добавь условие, которое остановит цикл.")
			break
		_append_log(context, "Итерация while: `%s`." % condition)
		_execute_block(lines, index + 1, block_indent, world, context)
		if bool(context.get("failed", false)):
			break
	return block_end

func _execute_try(lines: Array, index: int, header_indent: int, world: Dictionary, context: Dictionary) -> int:
	var block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
	if block_indent < 0:
		_fail(context, "После try нужен блок команд с отступом.")
		return index + 1
	var block_end: int = _find_block_end(lines, index + 1, block_indent)
	_append_log(context, "Запуск защищённого блока try.")
	_execute_block(lines, index + 1, block_indent, world, context)

	var next_index: int = block_end
	while next_index < lines.size():
		var raw_line: String = str(lines[next_index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			next_index += 1
			continue
		var indent: int = _count_indent(raw_line)
		if indent != header_indent:
			break
		if stripped.begins_with("except") and stripped.ends_with(":"):
			var except_indent: int = _detect_block_indent(lines, next_index + 1, header_indent)
			if except_indent < 0:
				return next_index + 1
			return _find_block_end(lines, next_index + 1, except_indent)
		break
	return next_index

func _execute_if(lines: Array, index: int, header_indent: int, line: String, world: Dictionary, context: Dictionary) -> int:
	var block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
	if block_indent < 0:
		_fail(context, "После if нужен блок команд с отступом.")
		return index + 1

	var block_end: int = _find_block_end(lines, index + 1, block_indent)
	var condition: String = line.substr(3, line.length() - 4).strip_edges()
	var is_true: bool = _evaluate_condition(condition, world, context)
	_append_log(context, "Проверка условия `%s`: %s" % [condition, "истина" if is_true else "ложь"])
	if is_true:
		_execute_block(lines, index + 1, block_indent, world, context)
		return _skip_condition_tail(lines, block_end, header_indent)

	var chain_index: int = block_end
	while chain_index < lines.size():
		var raw_line: String = str(lines[chain_index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			chain_index += 1
			continue
		var indent: int = _count_indent(raw_line)
		if indent != header_indent:
			break
		if stripped.begins_with("elif ") and stripped.ends_with(":"):
			var elif_block_indent: int = _detect_block_indent(lines, chain_index + 1, header_indent)
			if elif_block_indent < 0:
				_fail(context, "После elif нужен блок команд с отступом.")
				return chain_index + 1
			var elif_end: int = _find_block_end(lines, chain_index + 1, elif_block_indent)
			var elif_condition: String = stripped.substr(5, stripped.length() - 6).strip_edges()
			var elif_true: bool = _evaluate_condition(elif_condition, world, context)
			_append_log(context, "Проверка elif `%s`: %s" % [elif_condition, "истина" if elif_true else "ложь"])
			if elif_true:
				_execute_block(lines, chain_index + 1, elif_block_indent, world, context)
				return _skip_condition_tail(lines, elif_end, header_indent)
			chain_index = elif_end
			continue
		if stripped == "else:":
			var else_block_indent: int = _detect_block_indent(lines, chain_index + 1, header_indent)
			if else_block_indent < 0:
				_fail(context, "После else нужен блок команд с отступом.")
				return chain_index + 1
			var else_end: int = _find_block_end(lines, chain_index + 1, else_block_indent)
			_append_log(context, "Выполняется ветка else.")
			_execute_block(lines, chain_index + 1, else_block_indent, world, context)
			return else_end
		break
	return chain_index

func _skip_condition_tail(lines: Array, start_index: int, header_indent: int) -> int:
	var index: int = start_index
	while index < lines.size():
		var raw_line: String = str(lines[index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			index += 1
			continue
		var indent: int = _count_indent(raw_line)
		if indent != header_indent:
			return index
		if stripped.begins_with("elif ") and stripped.ends_with(":"):
			var elif_block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
			if elif_block_indent < 0:
				return index + 1
			index = _find_block_end(lines, index + 1, elif_block_indent)
			continue
		if stripped == "else:":
			var else_block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
			if else_block_indent < 0:
				return index + 1
			return _find_block_end(lines, index + 1, else_block_indent)
		return index
	return index

func _register_function(lines: Array, index: int, header_indent: int, line: String, context: Dictionary) -> int:
	var name_start: int = line.find("def ") + 4
	var paren_index: int = line.find("(")
	var paren_end: int = line.rfind(")")
	if paren_index <= name_start or paren_end < paren_index:
		_fail(context, "Не удалось прочитать объявление функции.")
		return index + 1

	var function_name: String = line.substr(name_start, paren_index - name_start).strip_edges()
	if not _is_identifier(function_name):
		_fail(context, "Некорректное имя функции: " + function_name)
		return index + 1

	var params_text: String = line.substr(paren_index + 1, paren_end - paren_index - 1).strip_edges()
	var params: Array = []
	if not params_text.is_empty():
		var param_parts: Array = _split_arguments(params_text)
		for param in param_parts:
			var param_name: String = str(param).strip_edges()
			if not _is_identifier(param_name):
				_fail(context, "Некорректный параметр функции: " + param_name)
				return index + 1
			params.append(param_name)

	var block_indent: int = _detect_block_indent(lines, index + 1, header_indent)
	if block_indent < 0:
		_fail(context, "После def нужен блок команд с отступом.")
		return index + 1

	var block_end: int = _find_block_end(lines, index + 1, block_indent)
	context["functions"][function_name] = {
		"lines": lines.slice(index + 1, block_end),
		"indent": block_indent,
		"params": params
	}
	_append_log(context, "Функция `%s` сохранена." % function_name)
	return block_end

func _execute_function_call(line: String, world: Dictionary, context: Dictionary) -> bool:
	if line.begins_with("hero."):
		return false
	if not line.ends_with(")"):
		return false
	var paren_index: int = line.find("(")
	if paren_index < 0:
		return false
	var function_name: String = line.substr(0, paren_index).strip_edges()
	if not _is_identifier(function_name):
		return false
	if not context["functions"].has(function_name):
		return false

	var function_data: Dictionary = context["functions"][function_name]
	var params: Array = function_data.get("params", [])
	var arg_text: String = line.substr(paren_index + 1, line.length() - paren_index - 2).strip_edges()
	var arg_parts: Array = [] if arg_text.is_empty() else _split_arguments(arg_text)
	if arg_parts.size() != params.size():
		_fail(context, "Функция `%s` ожидает аргументов: %d, передано: %d." % [function_name, params.size(), arg_parts.size()])
		return true

	var depth: int = int(context.get("call_depth", 0)) + 1
	if depth > 20:
		_fail(context, "Слишком глубокие вызовы функций. Проверь рекурсию.")
		return true
	context["call_depth"] = depth

	var previous_values: Dictionary = {}
	var had_previous: Dictionary = {}
	for i in range(params.size()):
		var param_name: String = str(params[i])
		had_previous[param_name] = context["variables"].has(param_name)
		previous_values[param_name] = context["variables"].get(param_name, null)
		context["variables"][param_name] = _parse_value(str(arg_parts[i]), context)

	_append_log(context, "Вызов функции `%s`." % function_name)
	_execute_block(function_data.get("lines", []), 0, int(function_data.get("indent", 0)), world, context)

	for param in params:
		var param_name_restore: String = str(param)
		if bool(had_previous.get(param_name_restore, false)):
			context["variables"][param_name_restore] = previous_values.get(param_name_restore, null)
		else:
			context["variables"].erase(param_name_restore)
	context["call_depth"] = depth - 1
	return true

func _try_assignment(line: String, context: Dictionary) -> bool:
	if line.contains("+=") or line.contains("-="):
		var op: String = "+=" if line.contains("+=") else "-="
		var parts_aug: PackedStringArray = line.split(op, false, 1)
		if parts_aug.size() != 2:
			return false
		var aug_name: String = str(parts_aug[0]).strip_edges()
		if not _is_identifier(aug_name):
			return false
		var current_value: Variant = context["variables"].get(aug_name, 0)
		var delta_value: Variant = _parse_value(str(parts_aug[1]).strip_edges(), context)
		if not _is_number(current_value) or not _is_number(delta_value):
			_fail(context, "Операция `%s` работает только с числами." % op)
			return true
		context["variables"][aug_name] = float(current_value) + float(delta_value) if op == "+=" else float(current_value) - float(delta_value)
		if int(context["variables"][aug_name]) == context["variables"][aug_name]:
			context["variables"][aug_name] = int(context["variables"][aug_name])
		_append_log(context, "Переменная `%s` = %s" % [aug_name, str(context["variables"][aug_name])])
		return true

	if not line.contains("=") or line.contains("==") or line.contains("!=") or line.contains(">=") or line.contains("<="):
		return false
	var parts: PackedStringArray = line.split("=", false, 1)
	if parts.size() != 2:
		return false
	var name: String = str(parts[0]).strip_edges()
	var value_text: String = str(parts[1]).strip_edges()
	if not _is_identifier(name):
		return false

	var value: Variant = _parse_value(value_text, context)
	context["variables"][name] = value
	_append_log(context, "Переменная `%s` = %s" % [name, str(value)])
	return true

func _execute_action(line: String, world: Dictionary, context: Dictionary) -> void:
	if _execute_utility_action(line, context):
		return
	if not line.begins_with("hero."):
		_fail(context, "Неизвестная команда: " + line)
		return

	var max_steps: int = 160
	world["steps"] = int(world.get("steps", 0)) + 1
	if int(world.get("steps", 0)) > max_steps:
		_fail(context, "Слишком много действий. Попробуй сократить код циклом или функцией.")
		return

	if line == "hero.move_right()":
		_move_hero(Vector2i.RIGHT, "вправо", world, context)
	elif line == "hero.move_left()":
		_move_hero(Vector2i.LEFT, "влево", world, context)
	elif line == "hero.move_up()":
		_move_hero(Vector2i.UP, "вверх", world, context)
	elif line == "hero.move_down()":
		_move_hero(Vector2i.DOWN, "вниз", world, context)
	elif line.begins_with("hero.move("):
		var direction: String = _extract_first_argument(line, context)
		_move_named_direction(direction, world, context)
	elif line == "hero.collect()":
		_collect_item(world, context)
	elif line == "hero.attack()":
		_attack_enemy(world, context)
	elif line == "hero.open_gate()":
		_open_gate(world, context)
	elif line == "hero.activate()":
		_activate_switch(world, context)
	elif line.begins_with("hero.say("):
		var text: String = _extract_first_argument(line, context)
		world["said"].append(text)
		_append_log(context, "Герой говорит: " + text)
		_push_frame(world, context, "Сообщение героя")
	elif line == "hero.scan()":
		_append_log(context, "Сканер: рядом предмет=%s, враг=%s, шлюз=%s, терминал=%s." % [
			"да" if not _find_current_or_adjacent_key(world, ["gems", "keys"]).is_empty() else "нет",
			"да" if not _find_current_or_adjacent_key(world, ["enemies"]).is_empty() else "нет",
			"да" if not _find_current_or_adjacent_key(world, ["doors"]).is_empty() else "нет",
			"да" if not _find_current_or_adjacent_key(world, ["switches"]).is_empty() else "нет"
		])
		_push_frame(world, context, "Сканирование")
	elif line == "hero.status()":
		_append_log(context, "Статус: предметов=%d, багов устранено=%d, шлюзов открыто=%d." % [int(world.get("collected", 0)), int(world.get("defeated", 0)), int(world.get("opened_doors", 0))])
		_push_frame(world, context, "Статус героя")
	elif line == "hero.wait()":
		_append_log(context, "Герой ждёт один ход.")
		_push_frame(world, context, "Ожидание")
	else:
		_fail(context, "Команда героя не поддерживается: " + line)

func _execute_utility_action(line: String, context: Dictionary) -> bool:
	if line == "pass":
		return true
	if line.begins_with("debug.log("):
		_append_log(context, "Debug: " + _extract_first_argument(line, context))
		return true
	if line.begins_with("test.assert_goal("):
		_append_log(context, "Тест цели: " + _extract_first_argument(line, context))
		return true
	if line.begins_with("logger.info("):
		_append_log(context, "Log: " + _extract_first_argument(line, context))
		return true
	return false

func _move_named_direction(direction: String, world: Dictionary, context: Dictionary) -> void:
	match direction:
		"right", "вправо":
			_move_hero(Vector2i.RIGHT, "вправо", world, context)
		"left", "влево":
			_move_hero(Vector2i.LEFT, "влево", world, context)
		"up", "вверх":
			_move_hero(Vector2i.UP, "вверх", world, context)
		"down", "вниз":
			_move_hero(Vector2i.DOWN, "вниз", world, context)
		_:
			_fail(context, "Неизвестное направление движения: " + direction)

func _move_hero(delta: Vector2i, direction_title: String, world: Dictionary, context: Dictionary) -> void:
	var current: Vector2i = world.get("hero", Vector2i.ZERO)
	var target: Vector2i = current + delta
	if not _can_enter(target, world):
		_fail(context, "Герой не может пройти " + direction_title + ": клетка заблокирована.")
		_push_frame(world, context, "Столкновение")
		return
	world["trail"][_pos_key(current)] = true
	world["hero"] = target
	_append_log(context, "Герой двигается " + direction_title + ".")
	_push_frame(world, context, "Движение " + direction_title)

func _can_enter(pos: Vector2i, world: Dictionary) -> bool:
	if not _is_inside_grid(pos, world):
		return false
	var key: String = _pos_key(pos)
	if world["walls"].has(key):
		return false
	if world["water"].has(key):
		return false
	if world["doors"].has(key):
		return false
	if world["enemies"].has(key):
		return false
	return true

func _is_inside_grid(pos: Vector2i, world: Dictionary) -> bool:
	var rows: Array = world.get("rows", [])
	if pos.y < 0 or pos.y >= rows.size():
		return false
	var row: String = str(rows[pos.y])
	return pos.x >= 0 and pos.x < row.length()

func _collect_item(world: Dictionary, context: Dictionary) -> void:
	var target_key: String = _find_current_or_adjacent_key(world, ["gems", "keys"])
	if target_key.is_empty():
		_fail(context, "Рядом нет предмета для сбора.")
		_push_frame(world, context, "Неудачный сбор")
		return

	if world["gems"].has(target_key):
		world["gems"].erase(target_key)
		world["collected"] = int(world.get("collected", 0)) + 1
		world["inventory"].append("gem")
		_append_log(context, "Собран энергетический кристалл.")
	elif world["keys"].has(target_key):
		world["keys"].erase(target_key)
		world["collected"] = int(world.get("collected", 0)) + 1
		world["inventory"].append("key")
		_append_log(context, "Собран ключ доступа.")
	_push_frame(world, context, "Предмет собран")

func _attack_enemy(world: Dictionary, context: Dictionary) -> void:
	var target_key: String = _find_current_or_adjacent_key(world, ["enemies"])
	if target_key.is_empty():
		_fail(context, "Рядом нет бага, которого можно атаковать.")
		_push_frame(world, context, "Атака не достигла цели")
		return
	world["enemies"].erase(target_key)
	world["defeated"] = int(world.get("defeated", 0)) + 1
	_append_log(context, "Баг уничтожен командой hero.attack().")
	_push_frame(world, context, "Баг устранён")

func _open_gate(world: Dictionary, context: Dictionary) -> void:
	var target_key: String = _find_current_or_adjacent_key(world, ["doors"])
	if target_key.is_empty():
		_fail(context, "Рядом нет закрытого шлюза.")
		_push_frame(world, context, "Шлюз не найден")
		return
	var inventory: Array = world.get("inventory", [])
	if not inventory.has("key") and not bool(world.get("terminal_used", false)):
		_fail(context, "Шлюз требует ключ или активированный терминал.")
		_push_frame(world, context, "Нет доступа к шлюзу")
		return
	world["doors"].erase(target_key)
	world["opened_doors"] = int(world.get("opened_doors", 0)) + 1
	_append_log(context, "Шлюз открыт.")
	_push_frame(world, context, "Шлюз открыт")

func _activate_switch(world: Dictionary, context: Dictionary) -> void:
	var target_key: String = _find_current_or_adjacent_key(world, ["switches"])
	if target_key.is_empty():
		_fail(context, "Рядом нет терминала активации.")
		_push_frame(world, context, "Терминал не найден")
		return
	world["terminal_used"] = true
	_append_log(context, "Терминал активирован. Шлюзы готовы к открытию.")
	_push_frame(world, context, "Терминал активирован")

func _find_current_or_adjacent_key(world: Dictionary, containers: Array) -> String:
	var hero: Vector2i = world.get("hero", Vector2i.ZERO)
	var candidates: Array = [hero, hero + Vector2i.RIGHT, hero + Vector2i.LEFT, hero + Vector2i.UP, hero + Vector2i.DOWN]
	for pos in candidates:
		var key: String = _pos_key(pos)
		for container_name in containers:
			if world.has(container_name) and world[container_name].has(key):
				return key
	return ""

func _check_success(level: Dictionary, world: Dictionary, source_code: String = "") -> Dictionary:
	var requirements: Dictionary = level.get("requirements", {})
	if bool(requirements.get("reach_exit", true)) and world.get("hero", Vector2i.ZERO) != world.get("exit", Vector2i.ZERO):
		return {"success": false, "message": "герой не дошел до выхода X"}
	if bool(requirements.get("collect_all", false)) and (not world["gems"].is_empty() or not world["keys"].is_empty()):
		return {"success": false, "message": "не все предметы собраны"}
	if bool(requirements.get("defeat_all", false)) and not world["enemies"].is_empty():
		return {"success": false, "message": "на карте остались баги"}
	if bool(requirements.get("open_doors", false)) and not world["doors"].is_empty():
		return {"success": false, "message": "не все шлюзы открыты"}
	if bool(requirements.get("activate_terminal", false)) and not bool(world.get("terminal_used", false)):
		return {"success": false, "message": "терминал не активирован"}
	if bool(requirements.get("use_function", false)) and not _source_uses_function(source_code):
		return {"success": false, "message": "Final sector requires a def function."}
	if bool(requirements.get("use_loop", false)) and not _source_uses_loop(source_code):
		return {"success": false, "message": "Final sector requires a for or while loop."}
	if bool(requirements.get("use_api", false)) and not source_code.contains("api.get"):
		return {"success": false, "message": "нужно получить маршрут или доступ через API-запрос"}
	if bool(requirements.get("use_sql", false)) and not (source_code.contains("db.query") or source_code.contains("SELECT")):
		return {"success": false, "message": "нужно получить маршрут через SQL-запрос"}
	var required_phrases: Array = _variant_to_string_array(requirements.get("source_contains", []))
	for phrase in required_phrases:
		if not source_code.contains(str(phrase)):
			return {"success": false, "message": "нужно использовать конструкцию темы: " + str(phrase)}
	var required_say: String = str(requirements.get("say_text", ""))
	if not required_say.is_empty() and not _world_has_said(world, required_say):
		return {"success": false, "message": "Final sector requires hero.say(\"%s\")." % required_say}
	return {"success": true, "message": "уровень завершен"}

func _source_uses_function(source_code: String) -> bool:
	for line in source_code.split("\n"):
		if line.strip_edges().begins_with("def "):
			return true
	return false

func _source_uses_loop(source_code: String) -> bool:
	for line in source_code.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("for ") or stripped.begins_with("while "):
			return true
	return false

func _world_has_said(world: Dictionary, expected_text: String) -> bool:
	for item in world.get("said", []):
		if str(item) == expected_text:
			return true
	return false

func _evaluate_condition(condition: String, world: Dictionary, context: Dictionary) -> bool:
	var cond: String = condition.strip_edges()
	if cond.is_empty():
		return false
	if cond.begins_with("not "):
		return not _evaluate_condition(cond.substr(4).strip_edges(), world, context)
	var or_parts: Array = _split_condition(cond, " or ")
	if or_parts.size() > 1:
		for part in or_parts:
			if _evaluate_condition(str(part), world, context):
				return true
		return false
	var and_parts: Array = _split_condition(cond, " and ")
	if and_parts.size() > 1:
		for part in and_parts:
			if not _evaluate_condition(str(part), world, context):
				return false
		return true

	var comparison: Dictionary = _try_evaluate_comparison(cond, context)
	if bool(comparison.get("handled", false)):
		return bool(comparison.get("value", false))

	if cond.begins_with("hero.can_move("):
		var direction: String = _extract_first_argument(cond, context)
		var delta: Vector2i = _direction_to_delta(direction)
		return _can_enter(world.get("hero", Vector2i.ZERO) + delta, world)
	if cond.begins_with("hero.near("):
		var object_name: String = _extract_first_argument(cond, context)
		match object_name:
			"gem", "crystal":
				return not _find_current_or_adjacent_key(world, ["gems"]).is_empty()
			"key":
				return not _find_current_or_adjacent_key(world, ["keys"]).is_empty()
			"enemy", "bug":
				return not _find_current_or_adjacent_key(world, ["enemies"]).is_empty()
			"door", "gate":
				return not _find_current_or_adjacent_key(world, ["doors"]).is_empty()
			"terminal", "switch":
				return not _find_current_or_adjacent_key(world, ["switches"]).is_empty()
	if cond == "hero.sees_enemy()":
		return not _find_current_or_adjacent_key(world, ["enemies"]).is_empty()
	if cond == "hero.at_exit()":
		return world.get("hero", Vector2i.ZERO) == world.get("exit", Vector2i.ZERO)
	if cond.begins_with("hero.has_item("):
		var item_name: String = _extract_first_argument(cond, context)
		var inventory: Array = world.get("inventory", [])
		return inventory.has(item_name)
	if cond.begins_with("hero.item_count("):
		return int(_parse_world_value(cond, world, context)) > 0
	if cond == "hero.has_key()":
		var inventory_keys: Array = world.get("inventory", [])
		return inventory_keys.has("key")
	if cond == "True" or cond == "true":
		return true
	if cond == "False" or cond == "false":
		return false
	if context["variables"].has(cond):
		return bool(context["variables"][cond])
	_append_log(context, "Неизвестное условие `%s`, считаю его ложным." % cond)
	return false

func _try_evaluate_comparison(cond: String, context: Dictionary) -> Dictionary:
	var operators: Array[String] = ["==", "!=", ">=", "<=", ">", "<"]
	for op in operators:
		var op_index: int = cond.find(op)
		if op_index <= 0:
			continue
		var left_text: String = cond.substr(0, op_index).strip_edges()
		var right_text: String = cond.substr(op_index + op.length()).strip_edges()
		var left_value: Variant = _parse_value(left_text, context)
		var right_value: Variant = _parse_value(right_text, context)
		var result: bool = false
		match op:
			"==":
				result = _values_equal(left_value, right_value)
			"!=":
				result = not _values_equal(left_value, right_value)
			">":
				result = _compare_numbers(left_value, right_value, op)
			"<":
				result = _compare_numbers(left_value, right_value, op)
			">=":
				result = _compare_numbers(left_value, right_value, op)
			"<=":
				result = _compare_numbers(left_value, right_value, op)
		return {"handled": true, "value": result}
	return {"handled": false, "value": false}

func _values_equal(left_value: Variant, right_value: Variant) -> bool:
	if _is_number(left_value) and _is_number(right_value):
		return float(left_value) == float(right_value)
	if typeof(left_value) != typeof(right_value):
		return false
	return left_value == right_value

func _compare_numbers(left_value: Variant, right_value: Variant, op: String) -> bool:
	if not _is_number(left_value) or not _is_number(right_value):
		return false
	var left_number: float = float(left_value)
	var right_number: float = float(right_value)
	match op:
		">":
			return left_number > right_number
		"<":
			return left_number < right_number
		">=":
			return left_number >= right_number
		"<=":
			return left_number <= right_number
	return false

func _try_parse_arithmetic(text: String, context: Dictionary) -> Dictionary:
	var operators: Array[String] = [" + ", " - ", " * ", " / "]
	for op_token in operators:
		var op_index: int = text.find(op_token)
		if op_index <= 0:
			continue
		var left_text: String = text.substr(0, op_index).strip_edges()
		var right_text: String = text.substr(op_index + op_token.length()).strip_edges()
		var left_value: Variant = _parse_value(left_text, context)
		var right_value: Variant = _parse_value(right_text, context)
		if not _is_number(left_value) or not _is_number(right_value):
			return {"handled": false, "value": 0}
		var left_number: float = float(left_value)
		var right_number: float = float(right_value)
		var value: float = 0.0
		match op_token.strip_edges():
			"+":
				value = left_number + right_number
			"-":
				value = left_number - right_number
			"*":
				value = left_number * right_number
			"/":
				if is_zero_approx(right_number):
					return {"handled": true, "value": 0}
				value = left_number / right_number
		if int(value) == value:
			return {"handled": true, "value": int(value)}
		return {"handled": true, "value": value}
	return {"handled": false, "value": 0}

func _parse_world_value(text: String, world: Dictionary, context: Dictionary) -> Variant:
	var source: String = text.strip_edges()
	if source.begins_with("hero.item_count("):
		var item_name: String = _extract_first_argument(source, context)
		var count: int = 0
		for item in world.get("inventory", []):
			if str(item) == item_name:
				count += 1
		return count
	if source == "hero.enemy_count()":
		return world.get("enemies", {}).size()
	if source == "hero.gem_count()":
		return world.get("gems", {}).size()
	return _parse_value(source, context)

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _array_to_text(value: Variant, empty_text: String = "пусто") -> String:
	if typeof(value) != TYPE_ARRAY:
		return empty_text
	var items: Array = value
	if items.is_empty():
		return empty_text
	var text_items: PackedStringArray = PackedStringArray()
	for item in items:
		text_items.append(str(item))
	return ", ".join(text_items)

func _build_report(success: bool, message: String, steps: int, level_number: int, world: Dictionary, context: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Отчёт симуляции:")
	lines.append("- Статус: " + ("сектор восстановлен" if success else "нужно исправить код"))
	lines.append("- Действий героя: %d" % steps)
	lines.append("- Целевой результат на 3 звезды: %d действий" % get_level_min_steps(level_number))
	lines.append("- Инвентарь: " + _array_to_text(world.get("inventory", []), "пусто"))
	if not success:
		lines.append("- Причина: " + message)
		lines.append("- Совет: проверь, где находится герой на последнем кадре, и сравни с целью сектора.")
	return "\n".join(lines)

func _estimate_min_steps_from_solution(level: Dictionary) -> int:
	var solution: String = str(level.get("solution_code", ""))
	var count: int = 0
	for raw_line in solution.split("\n"):
		var line: String = str(raw_line).strip_edges()
		if line.begins_with("hero."):
			count += 1
		elif line.begins_with("for ") and line.contains("range("):
			count += 2
	return maxi(1, count)

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _requirements_to_text(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "дойти до выхода X"
	var requirements: Dictionary = value
	var parts: Array[String] = []
	if bool(requirements.get("reach_exit", true)):
		parts.append("дойти до X")
	if bool(requirements.get("collect_all", false)):
		parts.append("собрать все предметы")
	if bool(requirements.get("defeat_all", false)):
		parts.append("устранить багов")
	if bool(requirements.get("open_doors", false)):
		parts.append("открыть шлюзы")
	if bool(requirements.get("activate_terminal", false)):
		parts.append("активировать терминал")
	return ", ".join(parts)

func _direction_to_delta(direction: String) -> Vector2i:
	match direction:
		"right", "вправо":
			return Vector2i.RIGHT
		"left", "влево":
			return Vector2i.LEFT
		"up", "вверх":
			return Vector2i.UP
		"down", "вниз":
			return Vector2i.DOWN
	return Vector2i.ZERO

func _build_display_grid(world: Dictionary) -> Array:
	var rows: Array = world.get("rows", [])
	var result: Array = []
	var hero: Vector2i = world.get("hero", Vector2i.ZERO)
	for y in range(rows.size()):
		var row: String = str(rows[y])
		var line: String = ""
		for x in range(row.length()):
			var pos: Vector2i = Vector2i(x, y)
			var key: String = _pos_key(pos)
			if pos == hero:
				line += "P"
			elif world["walls"].has(key):
				line += "#"
			elif world["water"].has(key):
				line += "~"
			elif world["doors"].has(key):
				line += "D"
			elif world["enemies"].has(key):
				line += "E"
			elif world["gems"].has(key):
				line += "G"
			elif world["keys"].has(key):
				line += "K"
			elif world["switches"].has(key):
				line += "S"
			elif pos == world.get("exit", Vector2i.ZERO):
				line += "X"
			elif world.has("trail") and world["trail"].has(key):
				line += "*"
			else:
				line += "."
		result.append(line)
	return result

func _push_frame(world: Dictionary, context: Dictionary, event_text: String) -> void:
	var frames: Array = world.get("frames", [])
	frames.append({
		"grid": _build_display_grid(world),
		"event": event_text,
		"steps": int(world.get("steps", 0)),
		"inventory": world.get("inventory", []).duplicate(),
		"collected": int(world.get("collected", 0)),
		"defeated": int(world.get("defeated", 0)),
		"opened_doors": int(world.get("opened_doors", 0)),
		"terminal_used": bool(world.get("terminal_used", false)),
		"remaining_items": int(world["gems"].size()) + int(world["keys"].size()),
		"remaining_enemies": int(world["enemies"].size()),
		"remaining_doors": int(world["doors"].size()),
		"at_exit": world.get("hero", Vector2i.ZERO) == world.get("exit", Vector2i.ZERO)
	})
	world["frames"] = frames

func _split_source_lines(source_code: String) -> Array:
	var normalized: String = source_code.replace("\r\n", "\n").replace("\r", "\n")
	var raw: PackedStringArray = normalized.split("\n")
	var lines: Array = []
	for line in raw:
		lines.append(str(line))
	return lines

func _detect_block_indent(lines: Array, start_index: int, parent_indent: int) -> int:
	for index in range(start_index, lines.size()):
		var raw_line: String = str(lines[index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			continue
		var indent: int = _count_indent(raw_line)
		if indent > parent_indent:
			return indent
		return -1
	return -1

func _find_block_end(lines: Array, start_index: int, block_indent: int) -> int:
	for index in range(start_index, lines.size()):
		var raw_line: String = str(lines[index])
		var stripped: String = raw_line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			continue
		var indent: int = _count_indent(raw_line)
		if indent < block_indent:
			return index
	return lines.size()

func _count_indent(line: String) -> int:
	var count: int = 0
	for index in range(line.length()):
		var ch: String = line.substr(index, 1)
		if ch == " ":
			count += 1
		elif ch == "\t":
			count += 4
		else:
			break
	return count

func _extract_range_count(text: String, context: Dictionary) -> int:
	return _extract_range_values(text, context).size()

func _extract_range_values(text: String, context: Dictionary) -> Array:
	var source: String = text.strip_edges()
	var start: int = source.find("range(")
	if start < 0:
		return []
	start += 6
	var end: int = source.rfind(")")
	if end < start:
		return []
	var args_text: String = source.substr(start, end - start).strip_edges()
	var args: Array = [] if args_text.is_empty() else _split_arguments(args_text)
	if args.is_empty() or args.size() > 3:
		return []
	var range_start: int = 0
	var range_stop: int = 0
	var range_step: int = 1
	if args.size() == 1:
		range_stop = int(_parse_value(str(args[0]), context))
	elif args.size() == 2:
		range_start = int(_parse_value(str(args[0]), context))
		range_stop = int(_parse_value(str(args[1]), context))
	else:
		range_start = int(_parse_value(str(args[0]), context))
		range_stop = int(_parse_value(str(args[1]), context))
		range_step = int(_parse_value(str(args[2]), context))
	if range_step == 0:
		return []
	var values: Array = []
	var guard: int = 0
	var current: int = range_start
	while (range_step > 0 and current < range_stop) or (range_step < 0 and current > range_stop):
		values.append(current)
		current += range_step
		guard += 1
		if guard > 80:
			break
	return values

func _parse_value(value_text: String, context: Dictionary) -> Variant:
	var text: String = value_text.strip_edges()
	if _looks_like_index_access(text):
		return _parse_index_access(text, context)
	if context["variables"].has(text):
		return context["variables"][text]
	if text.begins_with("api.get(") and text.ends_with(")"):
		return _parse_api_get(text, context)
	if text.begins_with("db.query(") and text.ends_with(")"):
		return _parse_db_query(text, context)
	if _is_route_helper_call(text):
		return _parse_route_helper(text, context)
	if text.begins_with("len(") and text.ends_with(")"):
		var inner_len: String = text.substr(4, text.length() - 5).strip_edges()
		var len_value: Variant = _parse_value(inner_len, context)
		if typeof(len_value) == TYPE_ARRAY or typeof(len_value) == TYPE_STRING or typeof(len_value) == TYPE_DICTIONARY:
			if typeof(len_value) == TYPE_ARRAY:
				return len_value.size()
			if typeof(len_value) == TYPE_DICTIONARY:
				return (len_value as Dictionary).size()
			return str(len_value).length()
		return 0
	var arithmetic_result: Dictionary = _try_parse_arithmetic(text, context)
	if bool(arithmetic_result.get("handled", false)):
		return arithmetic_result.get("value", 0)
	if text.begins_with("[") and text.ends_with("]"):
		var inner: String = text.substr(1, text.length() - 2).strip_edges()
		var result: Array = []
		if inner.is_empty():
			return result
		for part in _split_arguments(inner):
			result.append(_parse_value(str(part), context))
		return result
	if text.begins_with("(") and text.ends_with(")"):
		var tuple_inner: String = text.substr(1, text.length() - 2).strip_edges()
		var tuple_result: Array = []
		if tuple_inner.is_empty():
			return tuple_result
		for tuple_part in _split_arguments(tuple_inner):
			tuple_result.append(_parse_value(str(tuple_part), context))
		return tuple_result
	if text.begins_with("set(") and text.ends_with(")"):
		var set_inner: String = text.substr(4, text.length() - 5).strip_edges()
		var set_value: Variant = _parse_value(set_inner, context)
		var set_result: Array = []
		if typeof(set_value) == TYPE_ARRAY:
			for set_item in set_value:
				if not set_result.has(set_item):
					set_result.append(set_item)
		return set_result
	if text.begins_with("{") and text.ends_with("}"):
		return _parse_dictionary_literal(text, context)
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	if (text.begins_with(""") and text.ends_with(""")) or (text.begins_with("'") and text.ends_with("'")):
		return text.substr(1, text.length() - 2)
	if text == "true" or text == "True":
		return true
	if text == "false" or text == "False":
		return false
	return text

func _looks_like_index_access(text: String) -> bool:
	var bracket_index: int = text.find("[")
	return bracket_index > 0 and text.ends_with("]")

func _parse_index_access(text: String, context: Dictionary) -> Variant:
	var bracket_index: int = text.find("[")
	var base_name: String = text.substr(0, bracket_index).strip_edges()
	var key_text: String = text.substr(bracket_index + 1, text.length() - bracket_index - 2).strip_edges()
	if not context["variables"].has(base_name):
		return text
	var base_value: Variant = context["variables"].get(base_name)
	var key_value: Variant = _parse_value(key_text, context)
	if typeof(base_value) == TYPE_DICTIONARY:
		return (base_value as Dictionary).get(key_value, [])
	if typeof(base_value) == TYPE_ARRAY and _is_number(key_value):
		var idx: int = int(key_value)
		var arr: Array = base_value as Array
		if idx >= 0 and idx < arr.size():
			return arr[idx]
	return text

func _parse_dictionary_literal(text: String, context: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var inner: String = text.substr(1, text.length() - 2).strip_edges()
	if inner.is_empty():
		return result
	for pair_text in _split_arguments(inner):
		var pair: String = str(pair_text)
		var colon_index: int = pair.find(":")
		if colon_index <= 0:
			continue
		var key_text: String = pair.substr(0, colon_index).strip_edges()
		var value_text_inner: String = pair.substr(colon_index + 1).strip_edges()
		var key_value: Variant = _parse_value(key_text, context)
		result[key_value] = _parse_value(value_text_inner, context)
	return result

func _is_route_helper_call(text: String) -> bool:
	var prefixes: Array[String] = [
		"file.read_lines", "module.load_route", "route.generate", "generate_route",
		"controller.plan", "data.load", "json.load", "json.loads",
		"algorithm.shortest_path", "automation.plan", "package.load", "async.fetch",
		"config.load"
	]
	for prefix in prefixes:
		if text.begins_with(prefix + "(") and text.ends_with(")"):
			return true
	return false

func _parse_route_helper(text: String, context: Dictionary) -> Array:
	var key: String = _extract_first_argument(text, context)
	return _script_for_sector(key)

func _parse_api_get(text: String, context: Dictionary) -> Variant:
	var endpoint: String = _extract_first_argument(text, context)
	if endpoint == "/auth":
		return "ACCESS_GRANTED"
	if endpoint.contains("sector/30/route"):
		return _script_for_sector("sector_30_route")
	if endpoint.contains("sector/30/exit"):
		return _script_for_sector("sector_30_exit")
	if endpoint.contains("route"):
		return _script_for_sector(endpoint)
	return []

func _parse_db_query(text: String, context: Dictionary) -> Array:
	var query: String = _extract_first_argument(text, context)
	if query.contains("route_34"):
		return _script_for_sector("sector_34")
	return []

func _script_for_sector(key: String) -> Array:
	match key:
		"sector_14", "sector_14.py", "module_14":
			return ["right", "right", "attack", "right", "right", "right", "right", "right", "activate", "left", "left", "left", "left", "left", "left", "left", "down", "down", "collect", "right", "right", "right", "right", "open", "right", "right", "right", "right", "collect", "right", "right", "collect", "up", "up", "right", "right"]
		"sector_15", "sector_15.txt":
			return ["right", "right", "right", "collect", "right", "right", "collect", "right", "right", "collect", "right", "right", "collect", "right", "right", "right", "right"]
		"sector_17":
			return ["right", "attack", "right", "right", "right", "right", "right", "right"]
		"sector_18":
			return ["right", "right", "activate", "right", "right", "open", "left", "left", "left", "left", "down", "down", "attack", "right", "right", "right", "right", "right", "collect", "left", "left", "left", "up", "up", "right", "right", "right", "right", "right", "right", "collect", "right", "right", "right"]
		"sector_20":
			return ["down", "down", "right", "right", "attack", "right", "right", "right", "collect", "right", "right", "open", "up", "up", "collect", "right", "right", "right", "right"]
		"sector_22", "dataset_22":
			return ["right", "right", "right", "collect", "right", "right", "right", "right"]
		"sector_28":
			return ["right", "right", "attack", "right", "right", "right", "right", "activate", "left", "left", "left", "left", "left", "left", "down", "down", "collect", "right", "right", "right", "collect", "right", "right", "right", "right", "attack", "right", "right", "right", "collect", "left", "left", "left", "left", "left", "left", "left", "left", "left", "down", "down", "right", "right", "right", "collect", "right", "right", "right", "right", "right", "right", "up", "up", "up", "up", "open", "right", "right", "right"]
		"sector_29", "sector_29.json":
			return ["right", "right", "right", "collect", "right", "right", "right", "right"]
		"sector_30_route":
			return ["right", "right", "right", "right", "right"]
		"sector_30_exit":
			return ["right", "right", "right", "right", "right"]
		"sector_31":
			return ["right", "attack", "right", "right", "right", "right", "right", "right"]
		"sector_32", "pyquest.routing":
			return ["right", "right", "activate", "open", "right", "right", "right", "right", "right"]
		"sector_33":
			return ["right", "right", "right", "collect", "left", "down", "down", "left", "left", "collect", "right", "right", "open", "right", "right", "right", "right", "collect", "right"]
		"sector_34":
			return ["right", "right", "right", "right", "right", "right", "right"]
		_:
			return []

func _extract_first_argument(line: String, context: Dictionary) -> String:
	var start: int = line.find("(")
	var end: int = line.rfind(")")
	if start < 0 or end <= start:
		return ""
	var text: String = line.substr(start + 1, end - start - 1).strip_edges()
	var args: Array = _split_arguments(text)
	if args.is_empty():
		return ""
	var value: Variant = _parse_value(str(args[0]), context)
	return str(value)

func _split_arguments(text: String) -> Array:
	var result: Array = []
	var current: String = ""
	var quote: String = ""
	var bracket_depth: int = 0
	for i in range(text.length()):
		var ch: String = text.substr(i, 1)
		if not quote.is_empty():
			current += ch
			if ch == quote:
				quote = ""
			continue
		if ch == "\"" or ch == "'":
			quote = ch
			current += ch
			continue
		if ch == "[":
			bracket_depth += 1
			current += ch
			continue
		if ch == "]":
			bracket_depth = max(0, bracket_depth - 1)
			current += ch
			continue
		if ch == "," and bracket_depth == 0:
			result.append(current.strip_edges())
			current = ""
			continue
		current += ch
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	return result

func _split_condition(text: String, separator: String) -> Array:
	var result: Array = []
	var current: String = ""
	var quote: String = ""
	var i: int = 0
	while i < text.length():
		var ch: String = text.substr(i, 1)
		if not quote.is_empty():
			current += ch
			if ch == quote:
				quote = ""
			i += 1
			continue
		if ch == "\"" or ch == "'":
			quote = ch
			current += ch
			i += 1
			continue
		if text.substr(i, separator.length()) == separator:
			result.append(current.strip_edges())
			current = ""
			i += separator.length()
			continue
		current += ch
		i += 1
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	return result

func _is_identifier(text: String) -> bool:
	if text.is_empty():
		return false
	var first: String = text.substr(0, 1)
	if not _is_letter(first) and first != "_":
		return false
	for index in range(1, text.length()):
		var ch: String = text.substr(index, 1)
		if not _is_letter(ch) and not ch.is_valid_int() and ch != "_":
			return false
	return true

func _is_letter(ch: String) -> bool:
	var lower: String = ch.to_lower()
	return lower >= "a" and lower <= "z"

func _variant_to_string_array(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(str(item))
	return result

func _pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]

func _append_log(context: Dictionary, text: String) -> void:
	context["logs"].append(text)

func _fail(context: Dictionary, message: String) -> void:
	context["failed"] = true
	context["failure"] = message
	_append_log(context, "Ошибка: " + message)
