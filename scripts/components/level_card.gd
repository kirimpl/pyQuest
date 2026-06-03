class_name LevelCard
extends Button

signal level_selected(level: int)

const CHAPTER_COLORS: Array[Color] = [
	Color(0.18, 0.39, 0.78, 1.0),
	Color(0.12, 0.55, 0.45, 1.0),
	Color(0.62, 0.42, 0.12, 1.0),
	Color(0.50, 0.25, 0.70, 1.0),
	Color(0.70, 0.22, 0.35, 1.0),
	Color(0.22, 0.50, 0.72, 1.0),
	Color(0.78, 0.55, 0.12, 1.0),
]

const LEVEL_ICON_PATHS: Dictionary = {
	1: "res://assets/icons/levels/01_intro_small.png",
	2: "res://assets/icons/levels/02_variables_small.png",
	3: "res://assets/icons/levels/03_types_small.png",
	4: "res://assets/icons/levels/04_conditions_small.png",
	5: "res://assets/icons/levels/05_loops_small.png",
	6: "res://assets/icons/levels/06_lists_small.png",
	7: "res://assets/icons/levels/07_functions_small.png",
	8: "res://assets/icons/levels/08_dicts_small.png",
	9: "res://assets/icons/levels/09_strings_small.png",
	10: "res://assets/icons/levels/10_tuples_sets_small.png",
	11: "res://assets/icons/levels/11_modules_small.png",
	12: "res://assets/icons/levels/12_files_small.png",
	13: "res://assets/icons/levels/13_exceptions_small.png",
	14: "res://assets/icons/levels/14_comprehensions_small.png",
	15: "res://assets/icons/levels/15_oop_basics_small.png",
	16: "res://assets/icons/levels/16_oop_advanced_small.png",
	17: "res://assets/icons/levels/17_adv_functions_small.png",
	18: "res://assets/icons/levels/18_generators_small.png",
	19: "res://assets/icons/levels/19_decorators_small.png",
	20: "res://assets/icons/levels/20_final_small.png",
}

@onready var icon_panel: PanelContainer = $ContentMargin/RootRow/IconPanel
@onready var icon_texture: TextureRect = %IconTexture
@onready var level_label: Label = %LevelLabel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var status_label: Label = %StatusLabel

var level: int = 1

func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_layout()

func setup(level_data: Dictionary, is_unlocked: bool, is_completed: bool, chapter_total: int = 1, chapter_completed: int = 0) -> void:
	level = int(level_data.get("level", 1))
	var raw_title: String = str(level_data.get("title", "Сектор"))
	var title: String = _clean_title(raw_title)
	var mechanic: String = str(level_data.get("mechanic", "кодовый маршрут"))
	var goal: String = str(level_data.get("goal", "дойти до выхода X"))
	var chapter: String = str(level_data.get("chapter", "Кампания"))
	var difficulty: String = str(level_data.get("difficulty", "обычная"))
	var icon_path: String = str(level_data.get("icon", ""))
	var stars: int = AppState.get_code_level_star_count(level)
	var status_text: String = "Доступен"

	icon_texture.texture = _load_icon(icon_path)
	icon_texture.modulate = Color(1, 1, 1, 0.45) if not is_unlocked else Color(1, 1, 1, 1)

	level_label.text = "ФИНАЛЬНЫЙ СЕКТОР" if _is_final_sector() else "Сектор %02d" % level
	title_label.text = title
	description_label.text = "%s · %s\n%s\nЦель: %s" % [
		_short_chapter(chapter),
		_chapter_progress_text(chapter_completed, chapter_total),
		_compact_mechanic_text(mechanic, difficulty),
		_truncate_text(goal, 58)
	]
	progress_label.text = _compact_progress_text(level, stars)

	if is_completed:
		status_text = "✓ Восстановлен"
		status_label.modulate = Color(0.60, 1.00, 0.77, 1.0)
	elif not is_unlocked:
		status_text = "Заблокирован"
		status_label.modulate = Color(1.0, 0.70, 0.75, 0.9)
	else:
		status_label.modulate = Color(0.78, 0.90, 1.0, 1.0)

	status_label.text = status_text
	disabled = not is_unlocked
	modulate = Color(1, 1, 1, 0.62) if disabled else Color(1, 1, 1, 1)
	_apply_card_style(chapter, is_unlocked, is_completed)
	_apply_icon_style(chapter, is_unlocked, is_completed)

func _apply_layout() -> void:
	custom_minimum_size = Vector2(360, 176)
	clip_text = true
	if icon_panel != null:
		icon_panel.custom_minimum_size = Vector2(88, 88)
		icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if icon_texture != null:
		icon_texture.custom_minimum_size = Vector2(64, 64)
		icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if level_label != null:
		level_label.add_theme_font_size_override("font_size", 12)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 17)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.max_lines_visible = 2
		title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if description_label != null:
		description_label.add_theme_font_size_override("font_size", 12)
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.max_lines_visible = 3
		description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if progress_label != null:
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		progress_label.max_lines_visible = 2
		progress_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF

func _short_chapter(value: String) -> String:
	return value.replace(": ", " · ")

func _compact_mechanic_text(mechanic: String, difficulty: String) -> String:
	return "%s · %s" % [_truncate_text(mechanic, 34), difficulty]

func _truncate_text(value: String, limit: int) -> String:
	var clean: String = value.strip_edges()
	if clean.length() <= limit:
		return clean
	return clean.substr(0, max(0, limit - 1)).rstrip(" ,.;:") + "…"

func _compact_progress_text(current_level: int, stars: int) -> String:
	var attempts: int = AppState.get_code_level_attempt_count(current_level)
	var best_steps: int = AppState.get_code_level_best_steps(current_level)
	var hint_used: bool = AppState.was_code_level_hint_used(current_level)
	var parts: Array[String] = [_star_text(stars)]
	if attempts <= 0:
		parts.append("попыток нет")
	elif best_steps > 0:
		parts.append("%d попыток" % attempts)
		parts.append("рекорд %d" % best_steps)
	else:
		parts.append("%d попыток" % attempts)
		parts.append("не пройден")
	if hint_used:
		parts.append("есть сканер")
	return " · ".join(parts)

func _load_icon(explicit_path: String) -> Texture2D:
	if not explicit_path.is_empty() and ResourceLoader.exists(explicit_path):
		return load(explicit_path) as Texture2D
	var fallback_path: String = str(LEVEL_ICON_PATHS.get(level, ""))
	if fallback_path.is_empty() and level >= 21:
		fallback_path = "res://assets/icons/levels/%02d_extended_small.png" % level
	if fallback_path.is_empty() and _is_final_sector():
		fallback_path = "res://assets/icons/levels/35_extended_small.png"
	if not fallback_path.is_empty() and ResourceLoader.exists(fallback_path):
		return load(fallback_path) as Texture2D
	if ResourceLoader.exists("res://assets/ui/pyquest_emblem.png"):
		return load("res://assets/ui/pyquest_emblem.png") as Texture2D
	return null

func _clean_title(value: String) -> String:
	var prefix: String = "Сектор %02d:" % level
	if value.begins_with(prefix):
		return value.substr(prefix.length()).strip_edges()
	return value

func _chapter_progress_text(completed_count: int, total_count: int) -> String:
	return "глава %d/%d" % [completed_count, maxi(1, total_count)]

func _on_pressed() -> void:
	level_selected.emit(level)

func _star_text(stars: int) -> String:
	var safe_stars: int = clampi(stars, 0, 3)
	return "★".repeat(safe_stars) + "☆".repeat(3 - safe_stars)

func _apply_card_style(chapter: String, is_unlocked: bool, is_completed: bool) -> void:
	var base_color: Color = _chapter_color(chapter)
	if _is_final_sector():
		base_color = Color(0.88, 0.55, 0.10, 1.0)
	var bg: Color = base_color.darkened(0.58)
	var border: Color = base_color.lightened(0.20)
	if is_completed:
		bg = base_color.darkened(0.46)
		border = Color(0.62, 1.00, 0.74, 1.0)
	elif not is_unlocked:
		bg = Color(0.09, 0.10, 0.13, 1.0)
		border = Color(0.22, 0.24, 0.30, 1.0)
	add_theme_stylebox_override("normal", _make_style(bg, border, 2))
	add_theme_stylebox_override("hover", _make_style(bg.lightened(0.08), border.lightened(0.16), 2))
	add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.08), border, 2))
	add_theme_stylebox_override("disabled", _make_style(bg.darkened(0.12), border.darkened(0.25), 1))

func _apply_icon_style(chapter: String, is_unlocked: bool, is_completed: bool) -> void:
	if icon_panel == null:
		return
	var base_color: Color = _chapter_color(chapter)
	if _is_final_sector():
		base_color = Color(0.88, 0.55, 0.10, 1.0)
	var bg: Color = Color(0.05, 0.07, 0.12, 1.0)
	var border: Color = base_color.lightened(0.20)
	if is_completed:
		border = Color(0.62, 1.00, 0.74, 1.0)
	elif not is_unlocked:
		border = Color(0.25, 0.27, 0.33, 1.0)
	icon_panel.add_theme_stylebox_override("panel", _make_style(bg, border, 1))

func _chapter_color(chapter: String) -> Color:
	var chapter_index: int = 0
	for part in chapter.split(" "):
		if part.is_valid_int():
			chapter_index = maxi(0, int(part) - 1)
			break
	return CHAPTER_COLORS[chapter_index % CHAPTER_COLORS.size()]

func _make_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _is_final_sector() -> bool:
	return CodeWorldService.get_level_count() > 0 and level >= CodeWorldService.get_level_count()
