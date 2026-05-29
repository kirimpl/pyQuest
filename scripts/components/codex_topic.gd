class_name CodexTopic
extends Button

signal topic_selected(level: int)

var level: int = 1

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(lesson: Dictionary, is_unlocked: bool, completed_tasks: int, total_tasks: int) -> void:
	level = int(lesson.get("level", 1))
	var title: String = str(lesson.get("title", "Тема"))
	var description: String = str(lesson.get("description", ""))
	var icon_path: String = str(lesson.get("icon", ""))
	var safe_total: int = maxi(1, total_tasks)
	var safe_completed: int = clampi(completed_tasks, 0, safe_total)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon = load(icon_path) as Texture2D
	text = "Урок %d - %s\n%s\nПрогресс: %d/%d, %s" % [level, title, description, safe_completed, safe_total, ("открыто" if is_unlocked else "закрыто")]
	disabled = not is_unlocked

func _on_pressed() -> void:
	topic_selected.emit(level)
