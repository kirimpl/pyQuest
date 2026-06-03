class_name PythonConsole
extends PanelContainer

signal run_requested(source_code: String)

var console_title_label: Label
var code_input: TextEdit
var console_output: TextEdit
var run_code_button: Button
var clear_console_button: Button

var default_output: String = "Python 3.12.0 (PyQuest simulator)\nType your code and press Run."
var starter_code: String = ""
var read_only_mode: bool = false

func _ready() -> void:
	_cache_nodes()
	_connect_buttons()
	if console_output != null:
		console_output.editable = false

func setup(task: Dictionary) -> void:
	_cache_nodes()
	read_only_mode = false
	starter_code = str(task.get("starter_code", ""))
	default_output = str(task.get("initial_output", "Python 3.12.0 (PyQuest simulator)\nType your code and press Run."))

	_set_title(str(task.get("console_title", "Python Interpreter")))
	set_code(starter_code)
	if code_input != null:
		code_input.placeholder_text = str(task.get("placeholder", "Введите Python-код здесь..."))
	if console_output != null:
		console_output.text = default_output
	if run_code_button != null:
		run_code_button.visible = true
	if clear_console_button != null:
		clear_console_button.visible = true
	set_locked(false)
	_focus_editor()

func setup_example(lesson: Dictionary) -> void:
	_cache_nodes()
	read_only_mode = true
	starter_code = str(lesson.get("code", ""))
	default_output = _build_example_output(lesson)

	_set_title(str(lesson.get("console_title", "Python 3.12 - пример кода")))
	set_code(starter_code)
	if code_input != null:
		code_input.placeholder_text = ""
	if console_output != null:
		console_output.text = default_output
	if run_code_button != null:
		run_code_button.visible = false
	if clear_console_button != null:
		clear_console_button.visible = false
	set_locked(true)

func get_code() -> String:
	_cache_nodes()
	if code_input == null:
		return ""
	return code_input.text

func set_code(source_code: String) -> void:
	_cache_nodes()
	if code_input != null:
		code_input.text = source_code

func is_code_empty() -> bool:
	return get_code().strip_edges().is_empty()

func set_output(output_text: String) -> void:
	_cache_nodes()
	if console_output != null:
		console_output.text = output_text

func set_locked(is_locked: bool) -> void:
	_cache_nodes()
	if code_input != null:
		code_input.editable = not is_locked and not read_only_mode
	if run_code_button != null:
		run_code_button.disabled = is_locked or read_only_mode
	if clear_console_button != null:
		clear_console_button.disabled = is_locked or read_only_mode

func reset_editor() -> void:
	if read_only_mode:
		return
	set_code(starter_code)
	set_output(default_output)
	set_locked(false)
	_focus_editor()

func _cache_nodes() -> void:
	if console_title_label == null:
		console_title_label = get_node_or_null("ConsoleRoot/HeaderPanel/HeaderMargin/HeaderRow/ConsoleTitleLabel") as Label
		if console_title_label == null:
			console_title_label = find_child("ConsoleTitleLabel", true, false) as Label
	if code_input == null:
		code_input = get_node_or_null("ConsoleRoot/BodyMargin/BodyBox/CodeInput") as TextEdit
		if code_input == null:
			code_input = find_child("CodeInput", true, false) as TextEdit
	if console_output == null:
		console_output = get_node_or_null("ConsoleRoot/BodyMargin/BodyBox/ConsoleOutput") as TextEdit
		if console_output == null:
			console_output = find_child("ConsoleOutput", true, false) as TextEdit
	if run_code_button == null:
		run_code_button = get_node_or_null("ConsoleRoot/HeaderPanel/HeaderMargin/HeaderRow/RunCodeButton") as Button
		if run_code_button == null:
			run_code_button = find_child("RunCodeButton", true, false) as Button
	if clear_console_button == null:
		clear_console_button = get_node_or_null("ConsoleRoot/HeaderPanel/HeaderMargin/HeaderRow/ClearConsoleButton") as Button
		if clear_console_button == null:
			clear_console_button = find_child("ClearConsoleButton", true, false) as Button

func _connect_buttons() -> void:
	if run_code_button != null and not run_code_button.pressed.is_connected(_on_run_code_pressed):
		run_code_button.pressed.connect(_on_run_code_pressed)
	if clear_console_button != null and not clear_console_button.pressed.is_connected(_on_clear_console_pressed):
		clear_console_button.pressed.connect(_on_clear_console_pressed)

func _set_title(title_text: String) -> void:
	_cache_nodes()
	if console_title_label != null:
		console_title_label.text = title_text

func _focus_editor() -> void:
	if code_input != null and code_input.is_inside_tree():
		code_input.grab_focus()

func _build_example_output(lesson: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Python 3.12.0 (PyQuest simulator)")
	lines.append(">>> run main.py")
	lines.append("")

	var output_text: String = str(lesson.get("example_output", ""))
	if output_text.strip_edges().is_empty():
		lines.append("Код выполнен без ошибок.")
	else:
		lines.append(output_text)

	lines.append("")
	lines.append("Process finished with exit code 0")
	return "\n".join(lines)

func _on_run_code_pressed() -> void:
	run_requested.emit(get_code())

func _on_clear_console_pressed() -> void:
	reset_editor()
