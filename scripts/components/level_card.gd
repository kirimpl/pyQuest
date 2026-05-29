class_name LevelCard
extends Button

signal level_selected(level: int)

@onready var icon_texture: TextureRect = %IconTexture
@onready var level_label: Label = %LevelLabel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var status_label: Label = %StatusLabel

var level: int = 1

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(lesson: Dictionary, is_unlocked: bool, is_completed: bool, task_count: int = 1, completed_task_count: int = 0) -> void:
	level = int(lesson.get("level", 1))
	var title: String = str(lesson.get("title", "Уровень"))
	var description: String = str(lesson.get("description", ""))
	var icon_path: String = str(lesson.get("icon", ""))
	var safe_task_count: int = maxi(1, task_count)
	var safe_completed_count: int = clampi(completed_task_count, 0, safe_task_count)
	var status_text: String = "Доступен"

	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path) as Texture2D

	level_label.text = "Уровень %d" % level
	title_label.text = title
	description_label.text = description
	progress_label.text = "Практика: %d/%d" % [safe_completed_count, safe_task_count]

	if is_completed:
		status_text = "Пройден"
		status_label.modulate = Color(0.60, 1.00, 0.77, 1.0)
	elif not is_unlocked:
		status_text = "Заблокирован"
		status_label.modulate = Color(1.0, 0.70, 0.75, 0.9)
	else:
		status_label.modulate = Color(0.78, 0.90, 1.0, 1.0)

	status_label.text = status_text
	disabled = not is_unlocked
	modulate = Color(1, 1, 1, 0.56) if disabled else Color(1, 1, 1, 1)

func _on_pressed() -> void:
	level_selected.emit(level)
