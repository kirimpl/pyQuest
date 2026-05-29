extends Node

const SAVE_PATH: String = "user://pyquest_progress.json"

var save_exists: bool = false

func _ready() -> void:
	load_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Не удалось сохранить прогресс: " + SAVE_PATH)
		return

	file.store_string(JSON.stringify(AppState.to_dictionary(), "\t"))
	save_exists = true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		save_exists = false
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть сохранение: " + SAVE_PATH)
		return false

	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Файл сохранения повреждён: " + SAVE_PATH)
		return false

	var progress_data: Dictionary = parsed_data
	AppState.load_from_dictionary(progress_data)
	save_exists = true
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("pyquest_progress.json")
	save_exists = false
