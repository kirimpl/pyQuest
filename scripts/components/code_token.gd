class_name CodeToken
extends Button

signal token_selected(index: int, token_text: String)

var token_index: int = -1
var token_text: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(index: int, value: String) -> void:
	token_index = index
	token_text = value
	text = value
	disabled = false

func set_locked(value: bool) -> void:
	disabled = value

func _on_pressed() -> void:
	token_selected.emit(token_index, token_text)
