extends Node

const LESSON_INTERACTIONS_PATH: String = "res://data/lesson_interactions.json"
const REQUIRED_STEP_IDS: Array[String] = ["scan", "assemble", "console", "access"]

var interactions: Array = []

func _ready() -> void:
	reload()

func reload() -> void:
	interactions = _load_json_array(LESSON_INTERACTIONS_PATH)
	interactions.sort_custom(func(a: Variant, b: Variant) -> bool:
		var left: Dictionary = _to_dictionary(a)
		var right: Dictionary = _to_dictionary(b)
		return int(left.get("level", 0)) < int(right.get("level", 0))
	)

func get_interaction(level: int) -> Dictionary:
	for item in interactions:
		var interaction: Dictionary = _to_dictionary(item)
		if int(interaction.get("level", 0)) == level:
			return interaction
	return _missing_interaction(level)

func has_interaction(level: int) -> bool:
	for item in interactions:
		var interaction: Dictionary = _to_dictionary(item)
		if int(interaction.get("level", 0)) == level:
			return true
	return false

func get_required_step_count() -> int:
	return REQUIRED_STEP_IDS.size()

func is_lesson_lab_completed(level: int) -> bool:
	for step_id in REQUIRED_STEP_IDS:
		if not AppState.is_lesson_step_completed(level, step_id):
			return false
	return true

func get_progress_text(level: int) -> String:
	return "Интерактивный тренажер: %d/%d этапов" % [
		AppState.get_completed_lesson_step_count_for_level(level),
		get_required_step_count()
	]

func evaluate_assembly(level: int, selected_order: Array[int]) -> Dictionary:
	var interaction: Dictionary = get_interaction(level)
	var correct_order: Array = _variant_to_array(interaction.get("correct_order", []))
	if selected_order.size() != correct_order.size():
		return {
			"is_correct": false,
			"message": "Фрагмент собран не полностью. Дособери все строки модуля.",
			"details": "В рабочий модуль должны попасть все строки учебного примера."
		}

	for index in range(correct_order.size()):
		if int(selected_order[index]) != int(correct_order[index]):
			return {
				"is_correct": false,
				"message": "Порядок строк нарушен. Модуль не запускается.",
				"details": "Сравни порядок с логикой Python: сначала подготовка данных, затем действие, затем вывод или вызов функции."
			}

	return {
		"is_correct": true,
		"message": "Фрагмент собран. Код загружен в учебный терминал.",
		"details": str(interaction.get("artifact", "Учебный допуск получен."))
	}

func evaluate_console(level: int, source_code: String) -> Dictionary:
	var interaction: Dictionary = get_interaction(level)
	var expected_code: String = str(interaction.get("correct_code", ""))
	var expected_output: String = str(interaction.get("expected_output", "Код выполнен без ошибок."))
	var normalized_source: String = _normalize_code(source_code)
	var normalized_expected: String = _normalize_code(expected_code)

	if normalized_source.is_empty():
		return {
			"is_correct": false,
			"message": "Терминал пустой.",
			"console_output": _build_console_output(false, "SyntaxError: empty input", ""),
			"details": "Сначала собери фрагмент, затем запусти его через Run."
		}

	if normalized_source != normalized_expected:
		return {
			"is_correct": false,
			"message": "Терминал получил измененный код.",
			"console_output": _build_console_output(false, "AssertionError: module code does not match sector blueprint", ""),
			"details": "Для допуска нужно запустить именно тот фрагмент, который был собран на учебном стенде."
		}

	return {
		"is_correct": true,
		"message": "Код выполнен. Учебный контур работает стабильно.",
		"console_output": _build_console_output(true, "", expected_output),
		"details": str(interaction.get("unlock_text", "Допуск к миссии открыт."))
	}

func build_access_text(level: int) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(get_progress_text(level))
	lines.append("")
	lines.append(_format_step(level, "scan", "Сканер сектора"))
	lines.append(_format_step(level, "assemble", "Сборка кода"))
	lines.append(_format_step(level, "console", "Запуск терминала"))
	lines.append(_format_step(level, "access", "Допуск к миссии"))
	return "\n".join(lines)

func get_tokens(level: int) -> Array:
	return _variant_to_array(get_interaction(level).get("tokens", []))

func get_correct_code(level: int) -> String:
	return str(get_interaction(level).get("correct_code", ""))

func _format_step(level: int, step_id: String, title: String) -> String:
	var mark: String = "[✓]" if AppState.is_lesson_step_completed(level, step_id) else "[ ]"
	return "%s %s" % [mark, title]

func _normalize_code(value: String) -> String:
	var raw_lines: PackedStringArray = value.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var result_lines: PackedStringArray = PackedStringArray()
	for raw_line in raw_lines:
		var line: String = str(raw_line).strip_edges()
		if line.is_empty():
			continue
		while line.find("  ") != -1:
			line = line.replace("  ", " ")
		result_lines.append(line)
	return "\n".join(result_lines)

func _build_console_output(is_success: bool, error_text: String, output_text: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Python 3.12.0 (PyQuest simulator)")
	lines.append(">>> run sector_lab.py")
	lines.append("")
	if is_success:
		if output_text.strip_edges().is_empty():
			lines.append("Код выполнен без ошибок.")
		else:
			lines.append(output_text)
		lines.append("")
		lines.append("Sector lab finished with exit code 0")
	else:
		lines.append("Traceback (most recent call last):")
		lines.append("  File \"sector_lab.py\", line 1")
		lines.append(error_text)
		lines.append("")
		lines.append("Sector lab finished with exit code 1")
	return "\n".join(lines)

func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Файл не найден: " + path)
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть файл: " + path)
		return []
	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_data) != TYPE_ARRAY:
		push_error("JSON должен содержать массив: " + path)
		return []
	var result: Array = []
	for item in parsed_data:
		result.append(item)
	return result

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	for item in value:
		result.append(item)
	return result

func _to_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary_value: Dictionary = value
		return dictionary_value
	return {}

func _missing_interaction(level: int) -> Dictionary:
	return {
		"level": level,
		"title": "Тренажер сектора",
		"purpose": "Для этого уровня пока не задан интерактивный тренажер.",
		"scan_text": "Сканер не нашел отдельного сценария.",
		"assembly_goal": "Собери учебный фрагмент кода.",
		"tokens": [],
		"correct_order": [],
		"correct_code": "",
		"console_title": "Учебный терминал",
		"console_goal": "Запусти код в терминале.",
		"expected_output": "Код выполнен без ошибок.",
		"unlock_text": "Допуск к миссии открыт.",
		"artifact": "Учебный допуск"
	}
