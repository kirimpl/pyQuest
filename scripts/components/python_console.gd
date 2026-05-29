class_name PythonConsole
extends PanelContainer

signal run_requested(source_code: String)

@onready var console_title_label: Label = %ConsoleTitleLabel
@onready var code_input: TextEdit = %CodeInput
@onready var console_output: TextEdit = %ConsoleOutput
@onready var run_code_button: Button = %RunCodeButton
@onready var clear_console_button: Button = %ClearConsoleButton

var default_output: String = "Python 3.12.0 (PyQuest simulator)\nType your code and press Run."
var starter_code: String = ""
var read_only_mode: bool = false

func _ready() -> void:
	run_code_button.pressed.connect(_on_run_code_pressed)
	clear_console_button.pressed.connect(_on_clear_console_pressed)
	console_output.editable = false

func setup(task: Dictionary) -> void:
	read_only_mode = false
	console_title_label.text = str(task.get("console_title", "Python Interpreter"))
	starter_code = str(task.get("starter_code", ""))
	code_input.text = starter_code
	code_input.placeholder_text = str(task.get("placeholder", "Введите Python-код здесь..."))
	default_output = str(task.get("initial_output", "Python 3.12.0 (PyQuest simulator)\nType your code and press Run."))
	console_output.text = default_output
	run_code_button.visible = true
	clear_console_button.visible = true
	set_locked(false)
	code_input.grab_focus()

func setup_example(lesson: Dictionary) -> void:
	read_only_mode = true
	console_title_label.text = str(lesson.get("console_title", "Python 3.12 - пример кода"))
	starter_code = str(lesson.get("code", ""))
	code_input.text = starter_code
	code_input.placeholder_text = ""
	default_output = _build_example_output(lesson)
	console_output.text = default_output
	run_code_button.visible = false
	clear_console_button.visible = false
	set_locked(true)

func get_code() -> String:
	return code_input.text

func set_output(output_text: String) -> void:
	console_output.text = output_text

func set_locked(is_locked: bool) -> void:
	code_input.editable = not is_locked and not read_only_mode
	run_code_button.disabled = is_locked or read_only_mode
	clear_console_button.disabled = is_locked or read_only_mode

func reset_editor() -> void:
	if read_only_mode:
		return
	code_input.text = starter_code
	console_output.text = default_output
	set_locked(false)
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
	run_requested.emit(code_input.text)

func _on_clear_console_pressed() -> void:
	reset_editor()
