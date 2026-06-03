extends Node

const TYPE_SINGLE_CHOICE: String = "single_choice"
const TYPE_FIND_ERROR: String = "find_error"
const TYPE_TEXT_INPUT: String = "text_input"
const TYPE_FILL_BLANK: String = "fill_blank"
const TYPE_CODE_ORDER: String = "code_order"
const TYPE_CODE_INPUT: String = "code_input"

func evaluate(task: Dictionary, payload: Variant) -> Dictionary:
	var task_type: String = str(task.get("type", TYPE_SINGLE_CHOICE))

	match task_type:
		TYPE_SINGLE_CHOICE, TYPE_FIND_ERROR:
			return _evaluate_choice(task, int(payload))
		TYPE_TEXT_INPUT, TYPE_FILL_BLANK:
			return _evaluate_text(task, str(payload))
		TYPE_CODE_ORDER:
			return _evaluate_code_order(task, payload)
		TYPE_CODE_INPUT:
			return _evaluate_code_input(task, str(payload))
		_:
			return {
				"is_correct": false,
				"message": "Неизвестный тип задания: %s" % task_type,
				"explanation": str(task.get("explanation", "")),
				"score": 0,
				"console_output": "Task type error: %s" % [task_type]
			}

func get_task_type_title(task_type: String) -> String:
	match task_type:
		TYPE_SINGLE_CHOICE:
			return "Выберите правильный ответ"
		TYPE_FIND_ERROR:
			return "Найдите ошибку в коде"
		TYPE_TEXT_INPUT:
			return "Введите ответ"
		TYPE_FILL_BLANK:
			return "Заполните пропуск"
		TYPE_CODE_ORDER:
			return "Соберите код из блоков"
		TYPE_CODE_INPUT:
			return "Напишите код в Python-интерпретаторе"
		_:
			return "Задание"

func _evaluate_choice(task: Dictionary, selected_index: int) -> Dictionary:
	var correct_index: int = int(task.get("correct", -1))
	var is_correct: bool = selected_index == correct_index
	return _build_result(task, is_correct)

func _evaluate_text(task: Dictionary, user_answer: String) -> Dictionary:
	var normalized_user_answer: String = _normalize_text(user_answer, bool(task.get("case_sensitive", false)))
	var accepted_answers: Array = _variant_to_array(task.get("accepted_answers", []))

	if accepted_answers.is_empty() and task.has("correct_text"):
		accepted_answers.append(task.get("correct_text"))

	for item in accepted_answers:
		var normalized_correct_answer: String = _normalize_text(str(item), bool(task.get("case_sensitive", false)))
		if normalized_user_answer == normalized_correct_answer:
			return _build_result(task, true)

	return _build_result(task, false)

func _evaluate_code_order(task: Dictionary, payload: Variant) -> Dictionary:
	if typeof(payload) != TYPE_ARRAY:
		return _build_result(task, false)

	var selected_order: Array = _variant_to_array(payload)
	var correct_order: Array = _variant_to_array(task.get("correct_order", []))

	if selected_order.size() != correct_order.size():
		return _build_result(task, false)

	for index in range(correct_order.size()):
		if int(selected_order[index]) != int(correct_order[index]):
			return _build_result(task, false)

	return _build_result(task, true)

func _evaluate_code_input(task: Dictionary, source_code: String) -> Dictionary:
	var stripped_source: String = source_code.strip_edges()
	if stripped_source.is_empty():
		var empty_result: Dictionary = _build_custom_result(
			task,
			false,
			"Код не введён.",
			"Введите решение в окно main.py и нажмите Run."
		)
		empty_result["console_output"] = _build_console_output(task, source_code, false, "SyntaxError: empty input")
		return empty_result

	var code_issue: Dictionary = _find_code_style_issue(task, source_code)
	if not code_issue.is_empty():
		var issue_result: Dictionary = _build_custom_result(
			task,
			false,
			str(code_issue.get("message", str(task.get("error_message", "Код пока неверный.")))),
			str(code_issue.get("explanation", str(task.get("explanation", ""))))
		)
		issue_result["console_output"] = _build_console_output(task, source_code, false, str(code_issue.get("console_error", "AssertionError: code style issue")))
		return issue_result

	var ignore_case: bool = bool(task.get("ignore_code_case", false))
	var ignore_string_case: bool = bool(task.get("ignore_string_case", false))
	var normalized_source: String = _normalize_code_for_comparison(source_code, ignore_case, ignore_string_case)
	var accepted_code: Array = _variant_to_array(task.get("accepted_code", []))
	var is_correct: bool = false

	for item in accepted_code:
		var normalized_expected: String = _normalize_code_for_comparison(str(item), ignore_case, ignore_string_case)
		if normalized_source == normalized_expected:
			is_correct = true
			break

	if not is_correct and bool(task.get("allow_required_lines", false)):
		is_correct = _has_required_lines(task, normalized_source)

	var result: Dictionary = _build_result(task, is_correct)
	result["console_output"] = _build_console_output(task, source_code, is_correct)
	return result

func _find_code_style_issue(task: Dictionary, source_code: String) -> Dictionary:
	if bool(task.get("forbid_semicolon", true)) and _has_semicolon_outside_string(source_code):
		return {
			"message": str(task.get("semicolon_message", "В этом задании точка с запятой считается ошибкой.")),
			"explanation": str(task.get("semicolon_explanation", "В Python символ ; технически может разделять команды, но в учебном коде он ухудшает читаемость. В PyQuest каждая команда должна быть написана на отдельной строке без точки с запятой.")),
			"console_error": str(task.get("semicolon_console_error", "StyleError: remove ';'. Write each command on a separate line."))
		}

	if _has_unclosed_string(source_code):
		return {
			"message": "Строка не закрыта кавычкой.",
			"explanation": "Если строковое значение начинается с кавычки, его нужно закрыть такой же кавычкой. Подойдут одинарные или двойные кавычки, но пара должна быть одинаковой.",
			"console_error": "SyntaxError: unterminated string literal"
		}

	var raw_lines: PackedStringArray = source_code.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	for index in range(raw_lines.size()):
		var line: String = str(raw_lines[index]).strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("print "):
			return {
				"message": "В Python 3 для print нужны круглые скобки.",
				"explanation": "Правильно писать print(value), а не print value. PyQuest использует синтаксис Python 3.",
				"console_error": "SyntaxError: Missing parentheses in call to 'print'."
			}
		if _line_looks_like_block_header_without_colon(line):
			return {
				"message": "В строке с блоком не хватает двоеточия.",
				"explanation": "После строк с if, elif, else, for, while и def в Python ставится двоеточие. Команды внутри блока пишутся ниже с отступом.",
				"console_error": "SyntaxError: expected ':' at the end of the block header."
			}
		if line.ends_with(":"):
			var next_line: String = _find_next_code_line(raw_lines, index + 1)
			if not next_line.is_empty() and not _line_has_indent(next_line):
				return {
					"message": "После строки с двоеточием нужен отступ.",
					"explanation": "В Python тело if, for, while и def определяется отступами. Следующая команда внутри блока должна начинаться с пробелов или табуляции.",
					"console_error": "IndentationError: expected an indented block after ':'"
				}

	return {}

func _find_next_code_line(lines: PackedStringArray, start_index: int) -> String:
	for index in range(start_index, lines.size()):
		var line: String = str(lines[index])
		if line.strip_edges().is_empty() or line.strip_edges().begins_with("#"):
			continue
		return line
	return ""

func _line_has_indent(line: String) -> bool:
	return line.begins_with(" ") or line.begins_with("\t")

func _line_looks_like_block_header_without_colon(line: String) -> bool:
	if line.ends_with(":"):
		return false

	var block_prefixes: Array[String] = ["if ", "elif ", "else", "for ", "while ", "def "]
	for prefix in block_prefixes:
		if line.begins_with(prefix):
			return true

	return false

func _has_required_lines(task: Dictionary, normalized_source: String) -> bool:
	var required_lines: Array = _variant_to_array(task.get("required_lines", []))
	if required_lines.is_empty():
		return false

	for item in required_lines:
		var required_line: String = _normalize_code_for_comparison(str(item), bool(task.get("ignore_code_case", false)), bool(task.get("ignore_string_case", false)))
		if not normalized_source.contains(required_line):
			return false

	return true

func _build_result(task: Dictionary, is_correct: bool) -> Dictionary:
	return {
		"is_correct": is_correct,
		"message": str(task.get("success_message" if is_correct else "error_message", "")),
		"explanation": str(task.get("explanation", "")),
		"score": int(task.get("score", 10))
	}

func _build_custom_result(task: Dictionary, is_correct: bool, message: String, explanation: String) -> Dictionary:
	return {
		"is_correct": is_correct,
		"message": message,
		"explanation": explanation,
		"score": int(task.get("score", 10))
	}

func _build_console_output(task: Dictionary, source_code: String, is_correct: bool, custom_error: String = "") -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Python 3.12.0 (PyQuest simulator)")
	lines.append(">>> run main.py")
	lines.append("")

	if source_code.strip_edges().is_empty():
		lines.append("Traceback (most recent call last):")
		lines.append("  File \"main.py\", line 1")
		lines.append("SyntaxError: empty input")
		return "\n".join(lines)

	if is_correct:
		var expected_output: String = _get_success_output(task, source_code)
		lines.append(expected_output)
		lines.append("")
		lines.append("Process finished with exit code 0")
	else:
		var error_output: String = custom_error
		if error_output.is_empty():
			error_output = str(task.get("console_error", "AssertionError: результат не совпадает с ожидаемым ответом."))
		lines.append("Traceback (most recent call last):")
		lines.append("  File \"main.py\", line 1")
		lines.append(error_output)
		lines.append("")
		lines.append("Process finished with exit code 1")

	return "\n".join(lines)

func _get_success_output(task: Dictionary, source_code: String) -> String:
	var simulated_output_mode: String = str(task.get("simulated_output_mode", ""))
	if simulated_output_mode == "assigned_string_value":
		var assigned_value: String = _extract_first_assigned_string_value(source_code)
		if not assigned_value.is_empty():
			return assigned_value

	return str(task.get("expected_output", "Код выполнен без ошибок."))

func _extract_first_assigned_string_value(source_code: String) -> String:
	var raw_lines: PackedStringArray = source_code.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	for raw_line in raw_lines:
		var line: String = str(raw_line).strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var equal_index: int = line.find("=")
		if equal_index == -1:
			continue
		var right_part: String = line.substr(equal_index + 1).strip_edges()
		var string_value: String = _extract_first_string_literal(right_part)
		if not string_value.is_empty():
			return string_value

	return ""

func _extract_first_string_literal(value: String) -> String:
	var in_string: bool = false
	var quote_character: String = ""
	var escape_next: bool = false
	var collected: String = ""

	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if in_string:
			if escape_next:
				collected += character
				escape_next = false
			elif character == "\\":
				escape_next = true
			elif character == quote_character:
				return collected
			else:
				collected += character
		else:
			if character == "\"" or character == "'":
				in_string = true
				quote_character = character
				collected = ""

	return ""

func _normalize_text(value: String, case_sensitive: bool) -> String:
	var result: String = value.strip_edges()

	while result.find("  ") != -1:
		result = result.replace("  ", " ")

	if not case_sensitive:
		result = result.to_lower()

	return result

func _normalize_code_for_comparison(value: String, ignore_case: bool, ignore_string_case: bool) -> String:
	var raw_lines: PackedStringArray = value.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var result_lines: PackedStringArray = PackedStringArray()

	for raw_line in raw_lines:
		var line: String = str(raw_line).strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		line = _strip_inline_comment_outside_string(line)
		var normalized_line: String = _normalize_code_line(line, ignore_string_case)
		if not normalized_line.is_empty():
			result_lines.append(normalized_line)

	var result: String = "\n".join(result_lines)
	if ignore_case:
		result = result.to_lower()
	return result

func _normalize_code_line(value: String, ignore_string_case: bool) -> String:
	var result: String = ""
	var in_string: bool = false
	var quote_character: String = ""
	var escape_next: bool = false

	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if in_string:
			if escape_next:
				result += character.to_lower() if ignore_string_case else character
				escape_next = false
			elif character == "\\":
				result += character
				escape_next = true
			elif character == quote_character:
				result += "\""
				in_string = false
			else:
				result += character.to_lower() if ignore_string_case else character
		else:
			if character == "\"" or character == "'":
				result += "\""
				in_string = true
				quote_character = character
			elif character == " " or character == "\t":
				continue
			else:
				result += character

	return result

func _strip_inline_comment_outside_string(value: String) -> String:
	var in_string: bool = false
	var quote_character: String = ""
	var escape_next: bool = false
	var result: String = ""

	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if in_string:
			result += character
			if escape_next:
				escape_next = false
			elif character == "\\":
				escape_next = true
			elif character == quote_character:
				in_string = false
		else:
			if character == "#":
				return result.strip_edges()
			result += character
			if character == "\"" or character == "'":
				in_string = true
				quote_character = character

	return result.strip_edges()

func _has_semicolon_outside_string(value: String) -> bool:
	var in_string: bool = false
	var quote_character: String = ""
	var escape_next: bool = false

	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if in_string:
			if escape_next:
				escape_next = false
			elif character == "\\":
				escape_next = true
			elif character == quote_character:
				in_string = false
		else:
			if character == ";":
				return true
			if character == "\"" or character == "'":
				in_string = true
				quote_character = character

	return false

func _has_unclosed_string(value: String) -> bool:
	var in_string: bool = false
	var quote_character: String = ""
	var escape_next: bool = false

	for index in range(value.length()):
		var character: String = value.substr(index, 1)
		if in_string:
			if escape_next:
				escape_next = false
			elif character == "\\":
				escape_next = true
			elif character == quote_character:
				in_string = false
		else:
			if character == "\"" or character == "'":
				in_string = true
				quote_character = character

	return in_string

func _variant_to_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result_array: Array = []
	for item in value:
		result_array.append(item)
	return result_array
