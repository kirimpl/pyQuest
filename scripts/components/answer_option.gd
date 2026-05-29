class_name AnswerOption
extends Button

signal selected(index: int)

var answer_index: int = -1

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(index: int, answer_text: String) -> void:
	answer_index = index
	text = answer_text
	disabled = false

func set_locked(value: bool) -> void:
	disabled = value

func _on_pressed() -> void:
	selected.emit(answer_index)
